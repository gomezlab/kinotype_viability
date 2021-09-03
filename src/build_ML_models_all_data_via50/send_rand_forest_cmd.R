#!/usr/bin/env Rscript

library(here)

missing = 0
for (hyper_num in seq(1,10)) {
	for (fold_num in 1:10) {
		target_file = sprintf('hyper%03d_fold%02d.rds',hyper_num,fold_num)
		
		missing = missing + 1
		command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models_500feat.R --hyper_slice %d --fold_number %d"', hyper_num,fold_num)
		# command = sprintf('./build_random_forest_models.R --hyper_slice %d --fold_number %d', hyper_num,fold_num)
		
		# print(command)
		system(command)
		
		command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models_1000feat.R --hyper_slice %d --fold_number %d"', hyper_num,fold_num)
		# command = sprintf('./build_random_forest_models.R --hyper_slice %d --fold_number %d', hyper_num,fold_num)
		
		# print(command)
		system(command)
		
		command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models_1500feat.R --hyper_slice %d --fold_number %d"', hyper_num,fold_num)
		# command = sprintf('./build_random_forest_models.R --hyper_slice %d --fold_number %d', hyper_num,fold_num)
		
		# print(command)
		system(command)
	}
}