#!/usr/bin/env Rscript

library(here)
library(tidyverse)

fold_ids = read_rds(here('results/proteo_adj/CV_split_row_nums.rds'))

for (this_fold_id in unique(fold_ids)) {
	job_name = sprintf('CV_%d',this_fold_id)
	
	command = sprintf('sbatch --job-name=%s --mem=60G --time=2:00:00 --wrap "./get_feat_cor.R --CV_fold_ID %d"', job_name, this_fold_id)
	
	# print(command)
	system(command)
}