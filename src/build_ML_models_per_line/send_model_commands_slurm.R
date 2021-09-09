#!/usr/bin/env Rscript

library(tidyverse)
library(here)

rand_forest_commands = data.frame(
	depmap_ids = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds')) %>% 
		pull(depmap_id) %>% 
		unique()
) %>%
	mutate(command = paste0("sbatch -c 16 --time=24:00:00 --wrap=\"./build_random_forest_models.R --depmap_id ", depmap_ids, "\""))

for (this_command in rand_forest_commands$command) {
	system(this_command)
}

