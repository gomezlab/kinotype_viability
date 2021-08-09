#!/usr/bin/env Rscript

library(here)
num = 0
for (hyper_num in 1:100) {
	for (fold_num in 1:10) {
		target_file = sprintf('hyper%03d_fold%02d.rds',hyper_num,fold_num)
		if (file.exists(here('results/rand_forest_klaeger_CCLE_models/',target_file))) {
			next
		} else {
			command = sprintf('sbatch --mem=64G --time=24:00:00 --wrap "./build_random_forest_models.R --hyper_slice %d --fold_number %d"', hyper_num,fold_num)

			system(command)
		}
	}
}
