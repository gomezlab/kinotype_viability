#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(argparse)

tic()

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--feature_num', default = 500, type="integer")
parser$add_argument('--CV_fold_ID', default = 1, type="integer")

args = parser$parse_args()
print(sprintf('Fold: %02d',args$CV_fold_ID))

dir.create(here('results/single_dose_model/', 
								sprintf('rand_forest_no_klaeger/%dfeat_notune/',args$feature_num)), 
					 showWarnings = F, recursive = T)

full_output_file = here('results/single_dose_model/', 
									 sprintf('rand_forest_no_klaeger/%dfeat_notune/',args$feature_num),
									 sprintf('fold%04d_test.rds',args$CV_fold_ID))

dir.create(here('results/single_dose_model/', 
								sprintf('rand_forest_no_klaeger/%dfeat_notune_pred/',args$feature_num)), showWarnings = F)

pred_output_file = here('results/single_dose_model/', 
									 sprintf('rand_forest_no_klaeger/%dfeat_notune_pred/',args$feature_num),
									 sprintf('fold%04d_test.rds',args$CV_fold_ID))

feature_cor = read_rds(here('results/single_dose_model/CV_feature_cors/',
														sprintf('%04d.rds',args$CV_fold_ID))) %>%
	filter(feature_type != "Activation")

fold_ids = read_rds(here('results/single_dose_model/CV_split_row_nums.rds'))

source(here('src/other_experiments/single_dose_model/shared_feature_selection_functions.r'))

###############################################################################
# Load Data
###############################################################################

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

max_via_conc = read_rds(here('results/single_dose_model/max_single_dose_stdev.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	mutate(drug_conc = paste(drug, klaeger_conc, sep="-")) %>%
	filter(drug_conc %in% max_via_conc$drug_conc) %>%
	select(-drug_conc) %>%
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