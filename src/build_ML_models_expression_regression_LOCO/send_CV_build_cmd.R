#!/usr/bin/env Rscript

library(here)
library(tidyverse)

fold_ids = read_rds(here('results/single_model_expression_regression_LOLO/CV_split_row_nums.rds'))

for (this_fold_id in unique(fold_ids)) {
	job_name = sprintf('CV_%d',this_fold_id)
	
	command = sprintf('sbatch --job-name=%s --mem=25G --time=2:00:00 --wrap "./build_CV_data_set.R --CV_fold_ID %d"', job_name, this_fold_id)
	
	# print(command)
	system(command)
}
