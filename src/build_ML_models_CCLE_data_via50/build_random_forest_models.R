#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(argparse)

tic()

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--hyper_slice', default = 1, type="integer")
parser$add_argument('--fold_number', default = 1, type="integer")

args = parser$parse_args()
print(sprintf('Hyper: %03d, Fold: %02d',args$hyper_slice,args$fold_number))

dir.create(here('results/single_model_via_50/rand_forest_param_scan/'), showWarnings = F)

output_file = here('results/single_model_via_50/rand_forest_param_scan/',
									 sprintf('hyper%03d_fold%02d.rds',args$hyper_slice,args$fold_number))

binarized_viability_CV = read_rds(here('results/single_model_via_50/CV_splits/',sprintf('%02d.rds',args$fold_number)))

###############################################################################
# Build Models
###############################################################################

PRISM_klaeger_recipe = recipe(target_viability_split ~ ., binarized_viability_CV$splits[[1]]$data) %>%
	update_role(-starts_with("exp_"),-starts_with("act_"),-starts_with("target_"), new_role = "id variable") %>%
	prep()

rand_forest_spec <- rand_forest(
	trees = tune(),
	mtry = tune(),
	min_n = tune()
) %>% set_engine("ranger") %>%
	set_mode("classification")

rand_forest_grid <- grid_latin_hypercube(
	trees(c(1000,5000)),
	min_n(),
	finalize(mtry(),binarized_viability_CV),
	size = 10
) %>% slice(args$hyper_slice)

rand_forest_wf <- workflow() %>%
	add_model(rand_forest_spec) %>%
	add_recipe(PRISM_klaeger_recipe)

model_results <- tune_grid(
	rand_forest_wf,
	resamples = binarized_viability_CV,
	grid = rand_forest_grid,
	control = control_grid(save_pred = TRUE)
) %>% write_rds(output_file, compress = 'gz')

toc()