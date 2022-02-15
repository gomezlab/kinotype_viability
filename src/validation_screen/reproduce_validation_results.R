#!/usr/bin/env Rscript

library(rmarkdown)
library(here)
library(tictoc)

tic()
render(here('src/validation_screen/process_PRISM_replication.Rmd'))
render(here('src/validation_screen/process_validation_screen.Rmd'))
render(here('src/validation_screen/process_double_negative_validation_screen.Rmd'))

render(here('src/validation_screen/assess_PRISM_replication.Rmd'))
render(here('src/validation_screen/assess_viability_validation.Rmd'))
render(here('src/validation_screen/assess_double_negative_validation.Rmd'))
toc()
