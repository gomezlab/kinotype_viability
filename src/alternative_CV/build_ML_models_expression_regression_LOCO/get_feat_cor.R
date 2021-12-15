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

dir.create(here('results/single_model_expression_regression_LOCO'), recursive = T)

source(here('src/build_ML_models_expression_regression_LOCO/shared_feature_selection_functions.r'))

###############################################################################
# Load Data
###############################################################################

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy_1.2_exclude.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	ungroup()

if (file.exists(here('results/single_model_expression_regression_LOCO/CV_split_row_nums.rds'))) {
	fold_ids = read_rds(here('results/single_model_expression_regression_LOCO/CV_split_row_nums.rds'))
} else {
	compound_id_nums = data.frame(drug = unique(PRISM_klaeger_imputed$drug)) %>%
		mutate(drug_id = 1:n())
	
	fold_ids = PRISM_klaeger_imputed %>%
		left_join(compound_id_nums) %>% 
		pull(drug_id)
	
	write_rds(fold_ids, here('results/single_model_expression_regression_LOCO/CV_split_row_nums.rds'))
}

stopifnot(args$CV_fold_ID <= max(fold_ids))

###############################################################################
# Calc Feature Cor and Output
###############################################################################

feature_cor = find_feature_correlations(row_indexes = which(fold_ids != args$CV_fold_ID))

dir.create(here('results/single_model_expression_regression_LOCO/CV_feature_cors/'), recursive = T, showWarnings = F)

write_rds(feature_cor,
					here('results/single_model_expression_regression_LOCO/CV_feature_cors/',sprintf('%04d.rds',args$CV_fold_ID)),
					compress = 'gz')
toc()