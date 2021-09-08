#!/usr/bin/env Rscript

library(here)
library(tidyverse)

# rand_forest_grid = read_rds(here('results/single_model_all_data_via50/hyper_param_search_space.rds'))

# for (feature_num in c(200,500,1000,1500)) {
# 	for (hyper_num in 1:dim(rand_forest_grid)[1]) {
# 		for (fold_num in 1:10) {
# 		
# 			command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models.R --feature_num %d --hyper_slice %d --fold_number %d"', feature_num, hyper_num, fold_num)	
# 			
# 			# print(command)
# 			system(command)
# 		}
# 	}
# }

for (feature_num in c(200,500,1000,1500)) {
	for (hyper_num in 1:1) {
		for (fold_num in 1:10) {
			
			command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models_no_tune.R --feature_num %d --hyper_slice %d --fold_number %d"', feature_num, hyper_num, fold_num)	
			
			# print(command)
			system(command)
		}
	}
}