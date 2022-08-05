#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(patchwork)
library(argparse)

tic()

###############################################################################
# Parse Parameters/Check for Fold IDs file
###############################################################################

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--CV_fold_ID', default = 1, type="integer")

args = parser$parse_args()

dir.create(here('results/single_dose_model'), recursive = T)

source(here('src/other_experiments/single_dose_model/shared_feature_selection_functions.r'))

###############################################################################
# Load Data
###############################################################################

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

max_via_conc = read_rds(here('results/single_dose_model/max_single_dose_stdev.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	mutate(drug_conc = paste(drug, klaeger_conc, sep="-")) %>%
	filter(drug_conc %in% max_via_conc$drug_conc) %>%
	select(-drug_conc) %>%
	ungroup()

if (file.exists(here('results/single_dose_model/CV_split_row_nums.rds'))) {
	fold_ids = read_rds(here('results/single_dose_model/CV_split_row_nums.rds'))
} else {
	combo_id_nums = PRISM_klaeger_imputed %>%
		select(depmap_id,drug) %>%
		unique() %>%
		mutate(id_num = sample(rep(1:10,length.out = n())))
	
	fold_ids = PRISM_klaeger_imputed %>%
		left_join(combo_id_nums) %>% 
		pull(id_num)
	
	write_rds(fold_ids, here('results/single_dose_model/CV_split_row_nums.rds'))
}

stopifnot(args$CV_fold_ID <= max(fold_ids))

###############################################################################
# Output Full Data Set for Final Model Building
###############################################################################

if (! file.exists(here('results/single_dose_model/full_model_data_set_500feat.rds'))) {
	all_cor = find_feature_correlations()
	write_rds(all_cor,here('results/single_dose_model/full_data_cor.rds'))
	build_regression_viability_set(all_cor,500) %>%
		write_rds(here('results/single_dose_model/full_model_data_set_500feat.rds'), compress='gz')
}

###############################################################################
# Calc Feature Cor and Output
###############################################################################

feature_cor = find_feature_correlations(row_indexes = which(fold_ids != args$CV_fold_ID))

dir.create(here('results/single_dose_model/CV_feature_cors/'), recursive = T, showWarnings = F)

write_rds(feature_cor,
					here('results/single_dose_model/CV_feature_cors/',sprintf('%04d.rds',args$CV_fold_ID)),
					compress = 'gz')
toc()