#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(argparse)

tic()

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--feature_num', default = 1500, type="integer")
parser$add_argument('--CV_fold_ID', default = 1, type="integer")

args = parser$parse_args()
print(sprintf('Fold: %02d',args$CV_fold_ID))

dir.create(here('results/single_model_expression_regression_1.2_trunc/', 
								sprintf('rand_forest_%dfeat_notune/',args$feature_num)), showWarnings = F)

full_output_file = here('results/single_model_expression_regression_1.2_trunc/', 
									 sprintf('rand_forest_%dfeat_notune/',args$feature_num),
									 sprintf('fold%04d_test.rds',args$CV_fold_ID))

dir.create(here('results/single_model_expression_regression_1.2_trunc/', 
								sprintf('rand_forest_%dfeat_notune_pred/',args$feature_num)), showWarnings = F)

pred_output_file = here('results/single_model_expression_regression_1.2_trunc/', 
									 sprintf('rand_forest_%dfeat_notune_pred/',args$feature_num),
									 sprintf('fold%04d_test.rds',args$CV_fold_ID))

feature_cor = read_rds(here('results/single_model_expression_regression_1.2_trunc/CV_feature_cors/',
														sprintf('%04d.rds',args$CV_fold_ID)))

fold_ids = read_rds(here('results/single_model_expression_regression_1.2_trunc/CV_split_row_nums.rds'))

source(here('src/build_ML_models_expression_regression_1.2_trunc/shared_feature_selection_functions.r'))

###############################################################################
# Load Data
###############################################################################

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy_1.2_trunc.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	ungroup()

###############################################################################
# Setup and Run Model
###############################################################################

###########################################################
# Build Cross Validation Data Set
###########################################################
splits = list()

splits[[1]] = make_splits(list("analysis" = which(fold_ids != args$CV_fold_ID),
															 "assessment" = which(fold_ids == args$CV_fold_ID)),
													build_regression_viability_set(feature_cor,args$feature_num))

id = sprintf("Fold%02d",args$CV_fold_ID)

cross_validation_set = new_rset(
	splits = splits,
	ids = id,
	attrib = sprintf("Per compound cv splits for fold ", args$CV_fold_ID),
	subclass = c("vfold_cv", "rset")
)

###########################################################
# Run Model
###########################################################
PRISM_klaeger_recipe = recipe(target_viability ~ ., cross_validation_set$splits[[1]]$data) %>%
	update_role(-starts_with("act_"),
							-starts_with("exp_"),
							-starts_with("dep_"),
							-starts_with("target_"), new_role = "id variable") %>%
	prep()

rand_forest_spec <- rand_forest() %>% 
	set_engine("ranger", num.threads = 8) %>%
	set_mode("regression")

rand_forest_wf <- workflow() %>%
	add_model(rand_forest_spec) %>%
	add_recipe(PRISM_klaeger_recipe)

model_results <- tune_grid(
	rand_forest_wf,
	resamples = cross_validation_set,
	control = control_grid(save_pred = TRUE)
) %>% write_rds(full_output_file, compress = 'gz')

write_rds(model_results$.predictions[[1]], pred_output_file, compress = 'gz')

toc()