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

dir.create(here('results/single_model_all_data_regression'), recursive = T)

source(here('src/build_ML_models_all_data_regression/shared_features_selection.R'))

###############################################################################
# Load Data
###############################################################################

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds'))
PRISM_IDs = unique(PRISM_klaeger_imputed$depmap_id)

depmap_data = read_rds(here('results/single_model/full_depmap_for_ML.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

CNV_data = read_rds(here('results/single_model/full_CCLE_CNV_set_for_ML.rds'))

proteomics_data = read_csv(here('data/CCLE_data/CCLE_proteomics_imputed_wide.csv.gz')) %>%
	select(-CCLE_cell_line_name,-tenplex_number) %>% 
	rename_with( ~ paste0("prot_", .x), -DepMap_ID)

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% depmap_data$DepMap_ID) %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	filter(depmap_id %in% CNV_data$DepMap_ID) %>%
	filter(depmap_id %in% proteomics_data$DepMap_ID) %>%
	ungroup()

write_rds(unique(PRISM_klaeger_imputed$depmap_id),
					here('results/single_model_all_data_regression/all_data_cell_lines.rds'))

if (file.exists(here('results/single_model_all_data_regression/CV_split_row_nums.rds'))) {
	fold_ids = read_rds(here('results/single_model_all_data_regression/CV_split_row_nums.rds'))
} else {
	combo_id_nums = PRISM_klaeger_imputed %>%
		select(depmap_id,drug) %>%
		unique() %>%
		mutate(id_num = sample(rep(1:10,length.out = n())))
	
	fold_ids = PRISM_klaeger_imputed %>%
		left_join(combo_id_nums) %>% 
		pull(id_num)
	
	write_rds(fold_ids, here('results/single_model_all_data_regression/CV_split_row_nums.rds'))
}

stopifnot(args$CV_fold_ID <= max(fold_ids))

###############################################################################
# Output Full Data Set for Final Model Building
###############################################################################

if (! file.exists(here('results/single_model_all_data_regression/full_model_data_set_500feat.rds'))) {
	all_cor = find_feature_correlations()
	write_rds(all_cor,here('results/single_model_all_data_regression/full_data_cor.rds'))
	build_regression_viability_set(all_cor,500) %>%
		write_rds(here('results/single_model_all_data_regression/full_model_data_set_500feat.rds'), compress='gz')
}

###############################################################################
# Calc Feature Cor and Output
###############################################################################

feature_cor = find_feature_correlations(row_indexes = which(fold_ids != args$CV_fold_ID))

dir.create(here('results/single_model_all_data_regression/CV_feature_cors/'), recursive = T, showWarnings = F)

write_rds(feature_cor,
					here('results/single_model_all_data_regression/CV_feature_cors/',sprintf('%04d.rds',args$CV_fold_ID)),
					compress = 'gz')
toc()