#!/usr/bin/env Rscript

library(here)
library(tidyverse)

fold_ids = read_rds(here('results/single_model_expression_regression_MI/CV_split_row_nums.rds'))

for (feature_num in c(100,200,300,400,500,1000,1500,2000)) {
	for (fold_num in unique(fold_ids)) {
		
		job_name = sprintf('RF_%d_%04d',feature_num,fold_num)
		
		command = sprintf('sbatch --job-name=%s --mem=64G -c 8 --time=12:00:00 --wrap "./build_random_forest_models_no_tune.R --feature_num %d --CV_fold_ID %d"', job_name, feature_num, fold_num)
		
		# print(command)
		system(command)
	}
}
