library(tidyverse)
library(here)
library(tidymodels)
library(tictoc)
library(doParallel)
library(patchwork)
library(ROCR)

fit_1500 = get_classification_fit(1500, final_model_data)
metrics_1500 = collect_metrics(fit_1500)
predictions_1500 = collect_predictions(fit_1500)

roc_curve = predictions_1500 %>%
	roc_curve(truth = viability_binary, .pred_0) %>%
	autoplot() + 
	ggtitle(round(metrics_1500$mean[2], 4))


pr_curve = predictions_1500 %>%
	pr_curve(truth = viability_binary, .pred_0) %>%
	autoplot() +
	ggtitle(round(metrics_1500$mean[1], 4))

c = roc_curve + pr_curve + plot_annotation(title = '10-fold CV ALMANAC Classification Model Results',
																					 subtitle = 'Classify Viability Below Median')

ggsave(here('figures/ALMANAC_truncated_classification_model_results_1500_features.png'))

fit_2000 = get_classification_fit(2000, final_model_data)
metrics_2000 = collect_metrics(fit_2000)
predictions_2000 = collect_predictions(fit_2000)

roc_curve = predictions_2000 %>%
	roc_curve(truth = viability_binary, .pred_0) %>%
	autoplot() + 
	ggtitle(round(metrics_2000$mean[2], 4))


pr_curve = predictions_2000 %>%
	pr_curve(truth = viability_binary, .pred_0) %>%
	autoplot() +
	ggtitle(round(metrics_2000$mean[1], 4))

c = roc_curve + pr_curve + plot_annotation(title = '10-fold CV ALMANAC Classification Model Results',
																					 subtitle = 'Classify Viability Below Median')

ggsave(here('figures/ALMANAC_modelling/truncated/ALMANAC_truncated_classification_model_results_2000_features.png'))

fit_2500 = get_classification_fit(2500, final_model_data)
metrics_2500 = collect_metrics(fit_2500)
predictions_2500 = collect_predictions(fit_2500)

roc_curve = predictions_2500 %>%
	roc_curve(truth = viability_binary, .pred_0) %>%
	autoplot() + 
	ggtitle(round(metrics_2500$mean[2], 4))

pr_curve = predictions_2500 %>%
	pr_curve(truth = viability_binary, .pred_0) %>%
	autoplot() +
	ggtitle(round(metrics_2500$mean[1], 4))

c = roc_curve + pr_curve + plot_annotation(title = '10-fold CV ALMANAC Classification Model Results',
																					 subtitle = 'Classify Viability Below Median')

ggsave(here('figures/ALMANAC_modelling/truncated/ALMANAC_truncated_classification_model_results_2500_features.png'))