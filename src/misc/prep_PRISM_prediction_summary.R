library(tidyverse)
library(here)

PRISM_klaeger_imputed_tidy <- read_rds(here("results/PRISM_klaeger_imputed_tidy.rds"))
model_predictions_500feat <- read_rds(here("results/single_model_expression_regression/model_predictions_500feat.rds"))

all_data = bind_rows(
	PRISM_klaeger_imputed_tidy %>% 
		rename(pred_via = imputed_viability, concentration_M = klaeger_conc),
	model_predictions_500feat
)

#make sure there aren't any duplicates
dim(all_data %>% select(-pred_via) %>% unique())[1] == dim(all_data)[1]

per_compound_summary = all_data %>%
	group_by(drug, concentration_M) %>%
	summarise(mean_via = mean(pred_via),
						lower_bound = quantile(pred_via,c(0.025)),
						upper_bound = quantile(pred_via,c(0.975))) %>%
	write_rds(here('results/single_model_expression_regression/CCLE_prediction_summary.rds'), compress = 'gz')
