#!/usr/bin/env Rscript

for (hyper_num in 1:100) {
	for (fold_num in 1:10) {
		command = sprintf('sbatch --mem=32G --time=24:00:00 --wrap "./build_random_forest_models.R --hyper_slice %d --fold_number %d"', hyper_num,fold_num)
		system(command)
	}
}
