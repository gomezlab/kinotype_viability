#!/usr/bin/env Rscript

# to find all the library commands run:
#  grep -Rh library * | sort | uniq
# 
# then reformat the library calls to use p_load as below, plus dealing with the github only packages

if("pacman" %in% rownames(installed.packages()) == FALSE) {
	install.packages("pacman")
}

library(pacman)

p_load(amap)
p_load(argparse)
p_load(attempt)
p_load(BerginskiRMisc)
p_load(broom)
p_load(cividis)
p_load(conflicted)
p_load(DarkKinaseTools)
p_load(doParallel)
p_load(furrr)
p_load(GEOquery)
p_load(gghighlight)
p_load(ggrepel)
p_load(ggridges)
p_load(ggupset)
p_load(glue)
p_load(gt)
p_load(here)
p_load(IDACombo)
p_load(infotheo)
p_load(janitor)
p_load(keras)
p_load(metR)
p_load(Metrics)
p_load(pacman)
p_load(parallel)
p_load(patchwork)
p_load(purrr)
p_load(ranger)
p_load(rayshader)
p_load(readxl)
p_load(ROCR)
p_load(rstatix)
p_load(stringr)
p_load(synergyfinder)
p_load(tictoc)
p_load(tidyHeatmap)
p_load(tidymodels)
p_load(tidyverse)
p_load(vip)
p_load(vroom)
p_load(webchem)
p_load(writexl)

p_load(ranger)
p_load(xgboost)

p_load_gh('mbergins/BerginskiRMisc')
p_load_gh('IDG-Kinase/DarkKinaseTools')
