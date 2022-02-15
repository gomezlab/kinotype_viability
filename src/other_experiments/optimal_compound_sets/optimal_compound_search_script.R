#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tictoc)
library(argparse)

tic()

parser <- ArgumentParser(description='Process input paramters')
parser$add_argument('--num_samples', default = 100000, type="integer")
parser$add_argument('--num_drugs', default = 10, type="integer")
parser$add_argument('--search_number', default = 1, type="integer")

args = parser$parse_args()

klaeger_tidy = read_rds(here('results/klaeger_full_tidy.rds'))

klaeger_binary = klaeger_tidy %>% filter(relative_intensity != 1) %>%
	select(drug, gene_name) %>%
	unique()

klaeger_binary_wide = klaeger_binary %>%
	mutate(hit = 1) %>%
	pivot_wider(names_from = gene_name, values_from = hit, values_fill = 0) %>%
	column_to_rownames(var = "drug")

count_hits <- function(row_nums = 1:5) {
	return(sum(colSums(klaeger_binary_wide[row_nums,]) > 0))
}

get_hit_dist = function(num_samples = 10000, num_drugs = 10) {
	data.frame(index = 1:num_samples) %>% 
		mutate(test_rows = map(index, ~sample(1:dim(klaeger_binary_wide)[1],num_drugs))) %>% 
		mutate(hits = map_dbl(test_rows, ~count_hits(.x))) %>%
		mutate(frac_hit = hits/dim(klaeger_binary_wide)[2]) %>%
		select(-index) %>% 
		return()
}

tic()
test_combos = get_hit_dist(num_samples = args$num_samples, num_drugs = args$num_drugs)
toc()

dir.create(here('results/optimal_compound_search/best_hits'), showWarnings = F, recursive = T)
best_combo = test_combos %>% 
	filter(frac_hit == max(frac_hit)) %>%
	write_rds(here('results/optimal_compound_search/best_hits',paste0('best_combo_',args$num_drugs,'_',args$search_number,'.rds')))
	