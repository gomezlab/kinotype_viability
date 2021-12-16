# Feature Selection Functions


find_feature_correlations <- function(row_indexes = NA) {
	if (is.na(row_indexes)) {
		row_indexes = 1:dim(PRISM_klaeger_imputed)[1]
	}
	
	##############################################################################
	# PRISM - Klaeger Activation Correlations
	##############################################################################
	PRISM_klaeger_cor = PRISM_klaeger_imputed %>%
		slice(row_indexes) %>%
		left_join(klaeger_wide, by = c('drug'='drug', 'klaeger_conc' = 'concentration_M', 'depmap_id' = 'DepMap_ID')) %>%
		select(-depmap_id,-drug,-klaeger_conc) %>%
		identity()
	
	activation_cor = cor(PRISM_klaeger_cor %>% pull(imputed_viability), PRISM_klaeger_cor %>% select(-imputed_viability)) %>%
		as.data.frame() %>%
		pivot_longer(everything(), names_to = "feature",values_to = "cor")
	
	rm(PRISM_klaeger_cor)
	gc()
	
	##############################################################################
	# PRISM - CCLE Expression Correlations
	##############################################################################
	CCLE_cor = data.frame()
	
	CCLE_var_split = split(names(CCLE_data),c(1:10))
	
	for (i in 1:10) {
		PRISM_CCLE_cor = PRISM_klaeger_imputed %>%
			slice(row_indexes) %>%
			left_join(CCLE_data %>%
									select(c(CCLE_var_split[[i]],"DepMap_ID")),
								by=c('depmap_id' = 'DepMap_ID')) %>%
			select(-depmap_id,-drug,-klaeger_conc) %>%
			identity()
		
		this_CCLE_cor = cor(PRISM_CCLE_cor %>% pull(imputed_viability), PRISM_CCLE_cor %>% select(-imputed_viability)) %>%
			as.data.frame() %>%
			pivot_longer(everything(), names_to = "feature", values_to = "cor")
		
		CCLE_cor = bind_rows(
			CCLE_cor,
			this_CCLE_cor
		)
		
		rm(PRISM_CCLE_cor)
		gc()
		
	}
	
	all_cor = bind_rows(activation_cor, CCLE_cor) %>% 
		mutate(abs_cor = abs(cor)) %>% 
		arrange(desc(abs_cor)) %>% 
		mutate(rank = 1:n()) %>%
		mutate(feature_type = case_when(
			str_detect(feature, "^act_") ~ "Activation",
			str_detect(feature, "^exp_") ~ "Expression",
			str_detect(feature, "^dep_") ~ "Depmap",
			str_detect(feature, "^cnv_") ~ "CNV",
			str_detect(feature, "^prot_") ~ "Proteomics",
			T ~ feature
		))
	
	return(all_cor)
}

build_regression_viability_set <- function(feature_cor, num_features) {
	
	activation_set = klaeger_wide %>% 
		select(any_of(feature_cor$feature[1:num_features]),'drug','concentration_M','DepMap_ID')
	
	CCLE_set = CCLE_data %>%
		select(any_of(feature_cor$feature[1:num_features]),'DepMap_ID')
	
	regression_viability = PRISM_klaeger_imputed %>%
		left_join(activation_set, by = c('drug'='drug', 'klaeger_conc' = 'concentration_M', 'depmap_id' = 'DepMap_ID')) %>%
		left_join(CCLE_set, by=c('depmap_id' = 'DepMap_ID')) %>%
		mutate(target_viability = imputed_viability)
	
	return(regression_viability)
}