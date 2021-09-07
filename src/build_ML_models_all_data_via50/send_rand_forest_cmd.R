#!/usr/bin/env Rscript

library(here)

for (feature_num in c(200,300,400)) {
	for (hyper_num in seq(1,10)) {
		for (fold_num in 1:10) {
		
			command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models.R --feature_num %d --hyper_slice %d --fold_number %d"', feature_num, hyper_num, fold_num)	
			
			# print(command)
			system(command)
		}
	}
}