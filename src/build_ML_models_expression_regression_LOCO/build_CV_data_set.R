#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(patchwork)
library(argparse)

tic()

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--CV_fold_ID', default = 1, type="integer")
parser$add_argument('--feat_num', default = 1500, type="integer")

args = parser$parse_args()



fold_ids = read_rds(here('results/single_model_expression_regression_LOCO/CV_split_row_nums.rds'))

stopifnot(args$CV_fold_ID <= max(fold_ids))

# Load Data

dir.create(here('results/single_model_expression_regression_LOCO'), recursive = T)

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	mutate(act_gene_name = paste0("act_",gene_name)) %>%
	select(-gene_name) %>%
	pivot_wider(names_from = act_gene_name, values_from = relative_intensity)

PRISM_klaeger_imputed = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds'))

CCLE_data = read_rds(here('results/single_model/full_CCLE_expression_set_for_ML.rds'))

PRISM_klaeger_imputed = PRISM_klaeger_imputed %>%
	filter(depmap_id %in% CCLE_data$DepMap_ID) %>%
	ungroup()


source(here('src/build_ML_models_expression_regression_LOLO/shared_feature_selection_functions.r'))

if (file.exists(here('results/single_model_expression_regression_LOCO/CV_split_row_nums.rds'))) {
	fold_ids = read_rds(here('results/single_model_expression_regression_LOCO/CV_split_row_nums.rds'))
} else {
	drug_id_nums = data.frame(drug = unique(PRISM_klaeger_imputed$drug)) %>% 
		mutate(drug_id_num = 1:n())
	fold_ids = PRISM_klaeger_imputed %>%
		left_join(drug_id_nums) %>%
		pull(drug_id_num)
	write_rds(fold_ids, here('results/single_model_expression_regression_LOCO/CV_split_row_nums.rds'))
}

feature_cor = find_feature_correlations(row_indexes = which(fold_ids != args$CV_fold_ID))

dir.create(here('results/single_model_expression_regression_LOCO/CV_feature_cors/'), recursive = T, showWarnings = F)

write_rds(feature_cor,
					here('results/single_model_expression_regression_LOCO/CV_feature_cors/',sprintf('%04d.rds',args$CV_fold_ID)),
					compress = 'gz')

target_dir = here('results/single_model_expression_regression_LOCO/',sprintf('CV_splits_%sfeat',args$feat_num))
dir.create(target_dir,recursive = T, showWarnings = F)

splits = list()

via_set = build_regression_viability_set(feature_cor,args$feat_num)

splits[[1]] = make_splits(list("analysis" = which(fold_ids != args$CV_fold_ID),"assessment" = which(fold_ids == args$CV_fold_ID)),
													build_regression_viability_set(feature_cor,args$feat_num))

id = sprintf("Fold%02d",args$CV_fold_ID)

cross_validation_set = new_rset(
	splits = splits,
	ids = id,
	attrib = sprintf("Per compound cv splits for fold ", args$CV_fold_ID),
	subclass = c("vfold_cv", "rset")
)	%>% write_rds(here(target_dir,sprintf('%04d.rds',args$CV_fold_ID)), compress = 'gz')

toc()