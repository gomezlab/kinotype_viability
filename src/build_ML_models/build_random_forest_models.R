#!/usr/bin/env Rscript

library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(optigrab)

tic()

this_depmap_id = opt_get('depmap_id')
if (is.na(this_depmap_id)) {
	this_depmap_id = "ACH-000007"
}

dir.create(here('results/rand_forest_classification_models/'), showWarnings = F)

doParallel::registerDoParallel(cores=detectCores() - 2)

###############################################################################
# Load Data
###############################################################################

klaeger_wide = read_rds(here('results/klaeger_full_tidy.rds')) %>%
	pivot_wider(names_from = gene_name, values_from = relative_intensity)

PRISM_klaeger_viability = read_rds(here('results/PRISM_klaeger_imputed_tidy.rds')) %>%
	left_join(klaeger_wide, by = c('drug'='drug', 'klaeger_conc' = 'concentration_M')) %>%
	ungroup()

###############################################################################
# Prep Cross Validation Splits
###############################################################################

cell_line_data = PRISM_klaeger_viability %>%
	filter(depmap_id == this_depmap_id)

median_viability = median(cell_line_data$imputed_viability)

cell_line_data = cell_line_data %>%
	mutate(viability_split = as.factor(imputed_viability < median_viability)) %>%
	select(-depmap_id,-klaeger_conc,-imputed_viability) %>%
	ungroup()

splits = list()
index = 1
id = c()
for (exclude_compound in unique(cell_line_data$drug)) {
	assessment_ids = which(cell_line_data$drug == exclude_compound)
	analysis_ids = which(cell_line_data$drug != exclude_compound)

	splits[[index]] = make_splits(list("analysis" = analysis_ids,"assessment" = assessment_ids),
																cell_line_data %>% select(-drug))
	index = index + 1

	id = c(id,exclude_compound)
}

cell_line_compound_splits = new_rset(
	splits = splits,
	ids = id,
	attrib = paste0("Per compound cv splits for ", this_depmap_id),
	subclass = c("vfold_cv", "rset")
)

###############################################################################
# Build Models
###############################################################################

rand_forest_spec <- rand_forest(
	trees = tune(),
	mtry = tune(),
	min_n = tune()
) %>% set_engine("ranger") %>%
	set_mode("classification")

rand_forest_grid <- grid_latin_hypercube(
	trees(c(1000,5000)),
	min_n(),
	finalize(mtry(),cell_line_compound_splits),
	size = 100
)

rand_forest_wf <- workflow() %>%
	add_formula(viability_split ~ .) %>%
	add_model(rand_forest_spec)

tune_grid(
	rand_forest_wf,
	resamples = cell_line_compound_splits,
	grid = rand_forest_grid,
	control = control_grid(save_pred = TRUE)
) %>% write_rds(here('results/rand_forest_classification_models/', paste0(this_depmap_id,'.rds')), compress = 'gz')

toc()