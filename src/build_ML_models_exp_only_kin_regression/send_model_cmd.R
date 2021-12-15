#!/usr/bin/env Rscript

library(here)
library(tidyverse)

fold_ids = read_rds(here('results/single_model_exp_only_kin_regression/CV_split_row_nums.rds'))

for (feature_num in c(100,200,300,400,500,1000,1500,2000)) {
	for (fold_num in unique(fold_ids)) {
		
		job_name = sprintf('RF_%d_%04d',feature_num,fold_num)
		
		command = sprintf('sbatch --job-name=%s --mem=64G -c 8 --time=1-00:00:00 --wrap "./build_random_forest_models_no_tune.R --feature_num %d --CV_fold_ID %d"', job_name, feature_num, fold_num)
		
		# print(command)
		system(command)
	}
}

for (feature_num in c(500,1000,1500,2000)) {
	for (fold_num in unique(fold_ids)) {
		for (trees in c(1000,1500,2000)) {
			
			job_name = sprintf('RF_%d_%04d_%dt',feature_num,fold_num,trees)
			
			command = sprintf('sbatch --job-name=%s --mem=64G -c 8 --time=12:00:00 --wrap "./build_random_forest_models.R --feature_num %d --CV_fold_ID %d --trees %d"', job_name, feature_num, fold_num, trees)
			
			# print(command)
			system(command)
		}
	}
}

for (feature_num in c(100,200,300,400,500,1000,1500,2000)) {
	for (fold_num in unique(fold_ids)) {
		
		job_name = sprintf('XG_%d_%04d',feature_num,fold_num)
		
		command = sprintf('sbatch --job-name=%s --mem=64G --time=1-00:00:00 --wrap "./build_xgboost_models_no_tune.R --feature_num %d --CV_fold_ID %d"', job_name, feature_num, fold_num)
		
		# print(command)
		system(command)
	}
}

for (feature_num in c(100,200,300,400,500,1000,1500,2000)) {
	for (fold_num in unique(fold_ids)) {
		
		job_name = sprintf('Lin_%d_%04d',feature_num,fold_num)
		
		command = sprintf('sbatch --job-name=%s --mem=64G --time=1-00:00:00 --wrap "./build_linear_models.R --feature_num %d --CV_fold_ID %d"', job_name, feature_num, fold_num)
		
		# print(command)
		system(command)
	}
}