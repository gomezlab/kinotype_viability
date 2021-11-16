#!/usr/bin/env Rscript

library(here)
library(tidyverse)

# for (feature_num in c(500,1000,1500)) {
# 	for (hyper_num in 1:dim(rand_forest_grid)[1]) {
# 		for (fold_num in 1:10) {
# 			job_name = sprintf('RF_%d_%d_%d',feature_num,hyper_num,fold_num)
# 			
# 			command = sprintf('sbatch --job-name=%s --mem=64G --time=24:00:00 --wrap "./build_random_forest_models.R --feature_num %d --hyper_slice %d --fold_number %d"', job_name, feature_num, hyper_num, fold_num)
# 			
# 			# print(command)
# 			system(command)
# 		}
# 	}
# }

for (feature_num in c(50,100,150,200,300,400,500,1000,1500,2000)) {
	for (fold_num in 1:10) {
		job_name = sprintf('RF_%d_%d',feature_num,fold_num)
		
		command = sprintf('sbatch --job-name=%s --mem=64G -c 8 --time=7-00:00:00 --wrap "./build_random_forest_models_no_tune.R --feature_num %d --fold_number %d"', job_name, feature_num, fold_num)
		
		# print(command)
		system(command)
	}
}


# for (feature_num in c(200,500,1000,1500)) {
# 	for (hyper_num in 1:1) {
# 		for (fold_num in 1:10) {
# 			
# 			command = sprintf('sbatch --mem=64G --job-name=xg_%d_%d --time=24:00:00 --wrap "./build_xgboost_models_no_tune.R --feature_num %d --hyper_slice %d --fold_number %d"',feature_num, fold_num, feature_num, hyper_num, fold_num)
# 			
# 			# print(command)
# 			system(command)
# 		}
# 	}
# }
