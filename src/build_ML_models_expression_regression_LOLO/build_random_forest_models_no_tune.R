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
parser$add_argument('--fold_number', default = 1, type="integer")


args = parser$parse_args()
print(sprintf('Fold: %02d',args$fold_number))

dir.create(here('results/single_model_expression_regression_LOLO/', 
								sprintf('rand_forest_param_scan_%dfeat_notune/',args$feature_num)), showWarnings = F)

output_file = here('results/single_model_expression_regression_LOLO/', 
									 sprintf('rand_forest_param_scan_%dfeat_notune/',args$feature_num),
									 sprintf('fold%04d.rds',args$fold_number))

viability_CV = read_rds(here('results/single_model_expression_regression_LOLO',
																			 sprintf('CV_splits_%dfeat/',args$feature_num),
																			 sprintf('%04d.rds',args$fold_number)))

###############################################################################
# Build Models
###############################################################################

PRISM_klaeger_recipe = recipe(target_viability ~ ., viability_CV$splits[[1]]$data) %>%
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
	resamples = viability_CV,
	control = control_grid(save_pred = TRUE)
) %>% write_rds(output_file, compress = 'gz')

toc()