library(tidyverse)
library(here)
library(synergyfinder)

SUM159_reshaped = ReshapeData(
	data = SUM159_processed,
	data_type = 'viability',
	impute = TRUE,
	noise = TRUE
)

SUM159_synergy_predictions <- CalculateSynergy(
	data = SUM159_reshaped,
	method = c("ZIP", "HSA", "Bliss", "Loewe"),
	correct_baseline = 'all')

SUM159_all_drug_summaries = SUM159_synergy_predictions$drug_pairs

HCC1806_reshaped = ReshapeData(
	data = HCC1806_processed,
	data_type = 'viability',
	impute = TRUE,
	noise = TRUE
)

HCC1806_synergy_predictions_filtered <- CalculateSynergy(
	data = HCC1806_reshaped,
	method = c("ZIP", "HSA", "Bliss", "Loewe"),
	correct_baseline = 'all')

HCC1806_all_drug_summaries_filtered = HCC1806_synergy_predictions$drug_pairs

write_csv(SUM159_all_drug_summaries, here('results/SUM159_synergy_summaries_filtered.csv'))
write_csv(HCC1806_all_drug_summaries, here('results/HCC1806_synergy_summaries_filtered.csv'))

write_rds(SUM159_synergy_predictions, here('results/SUM159_synergy_predictions_filtered.rds'))
write_rds(HCC1806_synergy_predictions, here('results/HCC1806_synergy_predictions_filtered.rds'))