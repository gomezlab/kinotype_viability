#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(argparse)

tic()

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--feature_num', default = 200, type="integer")
parser$add_argument('--hyper_slice', default = 1, type="integer")
parser$add_argument('--fold_number', default = 1, type="integer")


args = parser$parse_args()
print(sprintf('Hyper: %03d, Fold: %02d',args$hyper_slice,args$fold_number))

dir.create(here('results/single_model_expression_regression/', 
								sprintf('xgboost_param_scan_%dfeat_notune/',args$feature_num)), showWarnings = F)

output_file = here('results/single_model_expression_regression/', 
									 sprintf('xgboost_param_scan_%dfeat_notune/',args$feature_num),
									 sprintf('hyper%03d_fold%02d.rds',args$hyper_slice,args$fold_number))

viability_CV = read_rds(here('results/single_model_expression_regression',
																			 sprintf('CV_splits_%dfeat/',args$feature_num),
																			 sprintf('%02d.rds',args$fold_number)))

###############################################################################
# Build Models
###############################################################################

PRISM_klaeger_recipe = recipe(target_viability ~ ., viability_CV$splits[[1]]$data) %>%
	update_role(-starts_with("act_"),
							-starts_with("exp_"),
							-starts_with("dep_"),
							-starts_with("target_"), new_role = "id variable") %>%
	prep()

xgboost_spec <- boost_tree() %>% 
	set_engine("xgboost") %>%
	set_mode("regression")

xgboost_wf <- workflow() %>%
	add_model(xgboost_spec) %>%
	add_recipe(PRISM_klaeger_recipe)

model_results <- tune_grid(
	xgboost_wf,
	resamples = viability_CV,
	control = control_grid(save_pred = TRUE)
) %>% write_rds(output_file, compress = 'gz')

toc()