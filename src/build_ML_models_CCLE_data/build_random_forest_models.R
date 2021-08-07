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

dir.create(here('results/rand_forest_klaeger_CCLE_models/'), showWarnings = F)

output_file = here('results/rand_forest_klaeger_CCLE_models/',
									 sprintf('hyper%03d_fold%02d.rds',args$hyper_slice,args$fold_number))

binarized_viability_CV = read_rds(here('results/klaeger_CCLE_CV_splits/',sprintf('%02d.rds',args$fold_number)))

###############################################################################
# Build Models
###############################################################################

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
	size = 100
) %>% slice(args$hyper_slice)

rand_forest_wf <- workflow() %>%
	add_formula(viability_split ~ .) %>%
	add_model(rand_forest_spec)

model_results <- tune_grid(
	rand_forest_wf,
	resamples = binarized_viability_CV,
	grid = rand_forest_grid,
	control = control_grid(save_pred = TRUE)
) %>% write_rds(output_file, compress = 'gz')

toc()