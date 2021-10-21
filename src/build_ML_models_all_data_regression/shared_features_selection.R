find_feature_correlations <- function(row_indexes = NA) {
	if (is.na(row_indexes)) {
		row_indexes = 1:dim(PRISM_klaeger_imputed)[1]
	}
	
	##############################################################################
	# PRISM - CCLE Proteomics Correlations
	##############################################################################
	proteomics_cor = data.frame()
	
	proteomics_var_split = split(names(proteomics_data),c(1:10))
	
	for (i in 1:10) {
		PRISM_proteomics_cor = PRISM_klaeger_imputed %>%
			slice(row_indexes) %>%
			left_join(proteomics_data %>%
									select(c(proteomics_var_split[[i]],"DepMap_ID")),
								by=c('depmap_id' = 'DepMap_ID')) %>%
			select(-depmap_id,-drug,-klaeger_conc) %>%
			identity()
		
		this_proteomics_cor = cor(PRISM_proteomics_cor %>% pull(imputed_viability), PRISM_proteomics_cor %>% select(-imputed_viability)) %>%
			as.data.frame() %>%
			pivot_longer(everything(), names_to = "feature", values_to = "cor")
		
		proteomics_cor = bind_rows(
			proteomics_cor,
			this_proteomics_cor
		)
		
		rm(PRISM_proteomics_cor)
		gc()
		
	}
	
	##############################################################################
	# PRISM - Klaeger Activation Correlations
	##############################################################################
	PRISM_klaeger_cor = PRISM_klaeger_imputed %>%
		slice(row_indexes) %>%
		left_join(klaeger_wide, by = c('drug'='drug', 'klaeger_conc' = 'concentration_M')) %>%
		select(-depmap_id,-drug,-klaeger_conc) %>%
		identity()
	
	activation_cor = cor(PRISM_klaeger_cor %>% pull(imputed_viability), PRISM_klaeger_cor %>% select(-imputed_viability)) %>%
		as.data.frame() %>%
		pivot_longer(everything(), names_to = "feature",values_to = "cor")
	
	rm(PRISM_klaeger_cor)
	gc()
	
	##############################################################################
	# PRISM - CCLE CNV Correlations
	##############################################################################
	CNV_cor = data.frame()
	
	CNV_var_split = split(names(CNV_data),c(1:10))
	
	for (i in 1:10) {
		PRISM_CNV_cor = PRISM_klaeger_imputed %>%
			slice(row_indexes) %>%
			left_join(CNV_data %>%
									select(c(CNV_var_split[[i]],"DepMap_ID")),
								by=c('depmap_id' = 'DepMap_ID')) %>%
			select(-depmap_id,-drug,-klaeger_conc) %>%
			identity()
		
		this_CNV_cor = cor(PRISM_CNV_cor %>% pull(imputed_viability), PRISM_CNV_cor %>% select(-imputed_viability)) %>%
			as.data.frame() %>%
			pivot_longer(everything(), names_to = "feature", values_to = "cor")
		
		CNV_cor = bind_rows(
			CNV_cor,
			this_CNV_cor
		)
		
		rm(PRISM_CNV_cor)
		gc()
	}
	
	##############################################################################
	# PRISM - Depmap Correlations
	##############################################################################
	depmap_cor = data.frame()
	
	depmap_var_split = split(names(depmap_data),c(1:10))
	
	for (i in 1:10) {
		PRISM_depmap_cor = PRISM_klaeger_imputed %>%
			slice(row_indexes) %>%
			left_join(depmap_data %>%
									select(c(depmap_var_split[[i]],"DepMap_ID")),
								by=c('depmap_id' = 'DepMap_ID')) %>%
			select(-depmap_id,-drug,-klaeger_conc) %>%
			identity()
		
		this_depmap_cor = cor(PRISM_depmap_cor %>% pull(imputed_viability), PRISM_depmap_cor %>% select(-imputed_viability)) %>%
			as.data.frame() %>%
			pivot_longer(everything(), names_to = "feature", values_to = "cor")
		
		depmap_cor = bind_rows(
			depmap_cor,
			this_depmap_cor
		)
		
		rm(PRISM_depmap_cor)
		gc()
		
	}
	
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
	
	all_cor = bind_rows(activation_cor, depmap_cor, CCLE_cor, CNV_cor, proteomics_cor) %>% 
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
		select(any_of(feature_cor$feature[1:num_features]),'drug','concentration_M')
	
	CCLE_set = CCLE_data %>%
		select(any_of(feature_cor$feature[1:num_features]),'DepMap_ID')
	
	depmap_set = depmap_data %>%
		select(any_of(feature_cor$feature[1:num_features]),'DepMap_ID')
	
	CNV_set = CNV_data %>%
		select(any_of(feature_cor$feature[1:num_features]),'DepMap_ID')
	
	prot_set = proteomics_data %>%
		select(any_of(feature_cor$feature[1:num_features]),'DepMap_ID')
	
	regression_viability = PRISM_klaeger_imputed %>%
		left_join(activation_set, by = c('drug'='drug', 'klaeger_conc' = 'concentration_M')) %>%
		left_join(CCLE_set, by=c('depmap_id' = 'DepMap_ID')) %>%
		left_join(depmap_set, by=c('depmap_id' = 'DepMap_ID')) %>%
		left_join(CNV_set, by=c('depmap_id' = 'DepMap_ID')) %>%
		left_join(prot_set, by=c('depmap_id' = 'DepMap_ID')) %>%
		mutate(target_viability = imputed_viability)
	
	return(regression_viability)
}