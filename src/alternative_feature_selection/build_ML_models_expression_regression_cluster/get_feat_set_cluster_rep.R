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

dir.create(here('results/single_model_expression_regression_cluster/CV_cluster_sets'),
					 showWarnings = F, recursive = T)

cluster_file = here('results/single_model_expression_regression_cluster/CV_cluster_sets',
											sprintf('%04d.rds', args$CV_fold_ID))

###############################################################################
# Load Data
###############################################################################

fold_ids = read_rds(here('results/single_model_expression_regression_cluster/CV_split_row_nums.rds'))

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	ungroup()

###############################################################################
# Combine Data and 
###############################################################################

combined_data = PRISM_klaeger_imputed %>% 
	slice(which(fold_ids != args$CV_fold_ID)) %>%
	left_join(klaeger_wide, by = c('drug'='drug','klaeger_conc'='concentration_M')) %>% 
	left_join(CCLE_data, by=c('depmap_id'='DepMap_ID')) %>%
	mutate(target_viability = imputed_viability)

sd_vals = apply(combined_data,2,sd)

combined_data = combined_data %>%
	select(-any_of(names(which(sd_vals == 0))))

cross_cor_mat = 1 - HiClimR::fastCor(combined_data %>% select(starts_with("act_"),starts_with("exp_")), 
																		 optBLAS = T, nSplit = 100, upperTri = T)

write_rds(hclust(as.dist(cross_cor_mat)), cluster_file)

toc()