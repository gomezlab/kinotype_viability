#!/usr/bin/env Rscript

library(here)

missing = 0
for (hyper_num in seq(1,10)) {
	for (fold_num in 1:10) {
		target_file = sprintf('hyper%03d_fold%02d.rds',hyper_num,fold_num)
		if (file.exists(here('results/single_model_only_CCLE_via_50/rand_forest_param_scan/',target_file))) {
			next
		} else {
			missing = missing + 1
			command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models.R --hyper_slice %d --fold_number %d"', hyper_num,fold_num)
			# command = sprintf('./build_random_forest_models.R --hyper_slice %d --fold_number %d', hyper_num,fold_num)
			
			# print(command)
			system(command)
		}
	}
}