#!/usr/bin/env Rscript

library(here)
library(tidyverse)

fold_ids = read_rds(here('results/exclude_1.0_test/CV_split_row_nums.rds'))

for (feature_num in c(50,100,200,300,400,500,1000,1500,2000,3000,4000,5000)) {
	for (fold_num in unique(fold_ids)) {
		
		job_name = sprintf('RF_%d_%04d',feature_num,fold_num)
		
		command = sprintf('sbatch --job-name=%s --mem=64G -c 8 --time=7-00:00:00 --wrap "./build_random_forest_models_no_tune.R --feature_num %d --CV_fold_ID %d"', job_name, feature_num, fold_num)
		
		# print(command)
		system(command)
	}
}