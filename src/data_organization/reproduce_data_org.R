#!/usr/bin/env Rscript

library(rmarkdown)
library(here)
library(tictoc)

tic()
# Data Pre-processing and Organization
render(here('src/data_organization/process_klaeger_data/klaeger_data_processing.Rmd'))
render(here('src/data_organization/prep_PRISM_for_ML/prep_PRISM_for_ML.Rmd'))
render(here('src/data_organization/prep_depmap_data_for_ML/prep_depmap_for_ML.Rmd'))
render(here('src/data_organization/prep_CCLE_proteomics_data/prep_CCLE_proteomics_data.Rmd'))
toc()
