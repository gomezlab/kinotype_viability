#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(argparse)

tic()

###############################################################################
# Parse Parameters/Check for Fold IDs file
###############################################################################

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--CV_fold_ID', default = 1, type="integer")

args = parser$parse_args()

dir.create(here('results/single_model_data_scramble'), recursive = T, showWarnings = F)

source(here('src/alternative_data_sets/build_ML_models_data_scramble/shared_feature_selection_functions.r'))

###############################################################################
# Load Data
###############################################################################

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	ungroup()

###########################################################
# Data Set Scramble
###########################################################

if (file.exists(here('results/single_model_data_scramble/sample_scamble.rds'))) {
	sample_scramble = read_rds(here('results/single_model_data_scramble/sample_scamble.rds'))
} else {
	sample_scramble = PRISM_klaeger_imputed %>% 
		select(depmap_id,drug) %>% 
		unique() %>% 
		mutate(start_id = 1:n()) %>% 
		mutate(scramble_id = sample(start_id))
	
	sample_scramble = sample_scramble %>%
		left_join(sample_scramble,
							by=c('start_id'='scramble_id'),
							suffix = c('_start','_scramble'))
	
	write_rds(sample_scramble, 
						here('results/single_model_data_scramble/sample_scamble.rds'),
						compress = 'gz')
}

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	left_join(sample_scramble %>%
							select(-contains('start_id'),-scramble_id),
						by = c('depmap_id'='depmap_id_start',
									 'drug'='drug_start')) %>%
	select(-depmap_id, -drug) %>%
	rename(depmap_id = depmap_id_scramble,
				 drug = drug_scramble)

###########################################################
# Cross Validation Fold ID
###########################################################

if (file.exists(here('results/single_model_data_scramble/CV_split_row_nums.rds'))) {
	fold_ids = read_rds(here('results/single_model_data_scramble/CV_split_row_nums.rds'))
} else {
	combo_id_nums = PRISM_klaeger_imputed %>%
		select(depmap_id,drug) %>%
		unique() %>%
		mutate(id_num = sample(rep(1:10,length.out = n())))

	fold_ids = PRISM_klaeger_imputed %>%
		left_join(combo_id_nums) %>%
		pull(id_num)

	write_rds(fold_ids, here('results/single_model_data_scramble/CV_split_row_nums.rds'))
}

stopifnot(args$CV_fold_ID <= max(fold_ids))

###############################################################################
# Calc Feature Cor and Output
###############################################################################

feature_cor = find_feature_correlations(row_indexes = which(fold_ids != args$CV_fold_ID))

dir.create(here('results/single_model_data_scramble/CV_feature_cors/'), recursive = T, showWarnings = F)

write_rds(feature_cor,
					here('results/single_model_data_scramble/CV_feature_cors/',sprintf('%04d.rds',args$CV_fold_ID)),
					compress = 'gz')
toc()