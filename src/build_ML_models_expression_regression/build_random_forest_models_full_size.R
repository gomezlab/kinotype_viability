#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(argparse)

tic()

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--feature_num', default = 100, type="integer")
parser$add_argument('--CV_fold_ID', default = 1, type="integer")

args = parser$parse_args()
print(sprintf('Fold: %02d',args$CV_fold_ID))

dir.create(here('results/single_model_expression_regression/', 
								sprintf('rand_forest/%dfeat_notune/',args$feature_num)), 
					 showWarnings = F, recursive = T)

full_output_file = here('results/single_model_expression_regression/', 
									 sprintf('rand_forest/%dfeat_notune/',args$feature_num),
									 sprintf('fold%04d_test.rds',args$CV_fold_ID))

dir.create(here('results/single_model_expression_regression/', 
								sprintf('rand_forest/%dfeat_notune_pred/',args$feature_num)), showWarnings = F)

pred_output_file = here('results/single_model_expression_regression/', 
									 sprintf('rand_forest/%dfeat_notune_pred/',args$feature_num),
									 sprintf('fold%04d_test.rds',args$CV_fold_ID))

feature_cor = read_rds(here('results/single_model_expression_regression/CV_feature_cors/',
														sprintf('%04d.rds',args$CV_fold_ID)))

fold_ids = read_rds(here('results/single_model_expression_regression/CV_split_row_nums.rds'))

source(here('src/build_ML_models_expression_regression/shared_feature_selection_functions.r'))

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

data_for_model_production = PRISM_klaeger_imputed %>% 
	left_join(klaeger_wide, by = c('drug'='drug','klaeger_conc'='concentration_M')) %>% 
	left_join(CCLE_data, by=c('depmap_id'='DepMap_ID')) %>%
	mutate(target_viability = imputed_viability)

###############################################################################
# Setup and Run Model
###############################################################################

###########################################################
# Run Model
###########################################################
PRISM_klaeger_recipe = recipe(target_viability ~ ., data_for_model_production) %>%
	update_role(-starts_with("act_"),
							-starts_with("exp_"),
							-starts_with("dep_"),
							-starts_with("target_"), new_role = "id variable") %>%
	prep()

rand_forest_spec <- rand_forest() %>% 
	set_engine("ranger", num.threads = 16,importance = "impurity") %>%
	set_mode("regression")

rand_forest_wf <- workflow() %>%
	add_model(rand_forest_spec) %>%
	add_recipe(PRISM_klaeger_recipe)

rand_forest_model = rand_forest_wf %>%
	fit(data = data_for_model_production) %>%
	write_rds(here('results/single_model_expression_regression/full_scale_model.rds'), compress = 'gz')


write_rds(model_results$.predictions[[1]], pred_output_file, compress = 'gz')

toc()