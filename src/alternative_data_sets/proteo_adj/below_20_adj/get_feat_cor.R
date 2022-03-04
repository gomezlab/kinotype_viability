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

dir.create(here('results/proteo_adj/below_20_adj'), recursive = T)

source(here('src/alternative_data_sets/proteo_adj/shared_feature_selection_functions.r'))

###############################################################################
# Load Data
###############################################################################

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds'))

klaeger_wide = read_rds(here('results/proteo_adj/klaeger_wide_below_20_per_adj.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% klaeger_wide$DepMap_ID) %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	ungroup()

if (file.exists(here('results/proteo_adj/CV_split_row_nums.rds'))) {
	fold_ids = read_rds(here('results/proteo_adj/CV_split_row_nums.rds'))
} else {
	combo_id_nums = PRISM_klaeger_imputed %>%
		select(depmap_id,drug) %>%
		unique() %>%
		mutate(id_num = sample(rep(1:10,length.out = n())))

	fold_ids = PRISM_klaeger_imputed %>%
		left_join(combo_id_nums) %>%
		pull(id_num)

	write_rds(fold_ids, here('results/proteo_adj/CV_split_row_nums.rds'))
}

stopifnot(args$CV_fold_ID <= max(fold_ids))

###############################################################################
# Calc Feature Cor and Output
###############################################################################

feature_cor = find_feature_correlations(row_indexes = which(fold_ids != args$CV_fold_ID))

dir.create(here('results/proteo_adj/below_20_adj/CV_feature_cors/'), recursive = T, showWarnings = F)

write_rds(feature_cor,
					here('results/proteo_adj/below_20_adj/CV_feature_cors/',sprintf('%04d.rds',args$CV_fold_ID)),
					compress = 'gz')
toc()