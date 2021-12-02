#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(patchwork)
library(argparse)
library(amap)

tic()

###############################################################################
# Parse Parameters/Check for Fold IDs file
###############################################################################

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--CV_fold_ID', default = 1, type="integer")

args = parser$parse_args()

dir.create(here('results/exclude_1.0_test'), recursive = T)

source(here('src/build_ML_models_expression_regression_combo_10fold/shared_feature_selection_functions.r'))

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

temp = PRISM_klaeger_imputed %>% 
	slice_sample(prop=0.001) %>%
	left_join(klaeger_wide, by = c('drug'='drug','klaeger_conc'='concentration_M')) %>% 
	left_join(CCLE_data, by=c('depmap_id'='DepMap_ID')) %>%
	mutate(target_viability = imputed_viability)

cross_cor_mat = amap::Dist(
	temp %>% select(starts_with("act_"),starts_with("exp_")) %>% t(),
	method="correlation")

# if (file.exists(here('results/exclude_1.0_test/CV_split_row_nums.rds'))) {
# 	fold_ids = read_rds(here('results/exclude_1.0_test/CV_split_row_nums.rds'))
# } else {
# 	combo_id_nums = PRISM_klaeger_imputed %>%
# 		select(depmap_id,drug) %>%
# 		unique() %>%
# 		mutate(id_num = sample(rep(1:10,length.out = n())))
# 	
# 	fold_ids = PRISM_klaeger_imputed %>%
# 		left_join(combo_id_nums) %>% 
# 		pull(id_num)
# 	
# 	write_rds(fold_ids, here('results/exclude_1.0_test/CV_split_row_nums.rds'))
# }

# stopifnot(args$CV_fold_ID <= max(fold_ids))

# ###############################################################################
# # Calc Feature Cor and Output
# ###############################################################################
# 
# feature_cor = find_feature_correlations(row_indexes = which(fold_ids != args$CV_fold_ID))
# 
# dir.create(here('results/exclude_1.0_test/CV_feature_cors/'), recursive = T, showWarnings = F)
# 
# write_rds(feature_cor,
# 					here('results/exclude_1.0_test/CV_feature_cors/',sprintf('%04d.rds',args$CV_fold_ID)),
# 					compress = 'gz')
# toc()