# Feature Selection Functions


find_feature_MI <- function(row_indexes = NA) {
	if (is.na(row_indexes)) {
		row_indexes = 1:dim(PRISM_klaeger_imputed)[1]
	}
	
	##############################################################################
	# PRISM - Klaeger Activation Mutual Information
	##############################################################################
	
	PRISM_klaeger_MI = PRISM_klaeger_imputed %>%
		slice(row_indexes) %>%
		left_join(klaeger_wide, by = c('drug'='drug', 'klaeger_conc' = 'concentration_M')) %>%
		select(-depmap_id,-drug,-klaeger_conc) %>%
		identity()
	
	discritized_klaeger = PRISM_klaeger_MI %>%
		select(contains("act_")) %>%
		infotheo::discretize()
	
	discritized_via = PRISM_klaeger_MI %>%
		pull(imputed_viability) %>%
		infotheo::discretize()
	
	all_MI_vals = data.frame()
	
	for (this_col in names(discritized_klaeger)) {
		all_MI_vals = bind_rows(
			all_MI_vals,
			data.frame(feature = this_col,
								 MI = infotheo::mutinformation(discritized_klaeger %>% pull(this_col), discritized_via))
		)
	}
	rm(PRISM_klaeger_MI, discritized_klaeger, discritized_via)
	gc()
	
	##############################################################################
	# PRISM - CCLE Expression Mutual Information
	##############################################################################
	
	CCLE_var_split = split(names(CCLE_data),c(1:10))
	
	for (i in 1:10) {
		PRISM_CCLE_MI = PRISM_klaeger_imputed %>%
			slice(row_indexes) %>%
			left_join(CCLE_data %>%
									select(c(CCLE_var_split[[i]],"DepMap_ID")),
								by=c('depmap_id' = 'DepMap_ID')) %>%
			select(-depmap_id,-drug,-klaeger_conc) %>%
			identity()
		
		discritized_CCLE = PRISM_CCLE_MI %>%
			select(contains("exp_")) %>%
			infotheo::discretize()
		
		discritized_via = PRISM_CCLE_MI %>%
			pull(imputed_viability) %>%
			infotheo::discretize()
		
		for (this_col in names(discritized_CCLE)) {
			all_MI_vals = bind_rows(
				all_MI_vals,
				data.frame(feature = this_col,
									 MI = infotheo::mutinformation(discritized_CCLE %>% pull(this_col), discritized_via))
			)
		}
		
		rm(PRISM_CCLE_MI, discritized_CCLE, discritized_via)
		gc()
		
	}

	
	all_MI_vals = all_MI_vals %>% 
		arrange(desc(MI)) %>% 
		mutate(rank = 1:n()) %>%
		mutate(feature_type = case_when(
			str_detect(feature, "^act_") ~ "Activation",
			str_detect(feature, "^exp_") ~ "Expression",
			str_detect(feature, "^dep_") ~ "Depmap",
			str_detect(feature, "^cnv_") ~ "CNV",
			str_detect(feature, "^prot_") ~ "Proteomics",
			T ~ feature
		))
	
	return(all_MI_vals)
}

build_regression_viability_set <- function(feature_MI, num_features) {
	
	activation_set = klaeger_wide %>% 
		select(any_of(feature_MI$feature[1:num_features]),'drug','concentration_M')
	
	CCLE_set = CCLE_data %>%
		select(any_of(feature_MI$feature[1:num_features]),'DepMap_ID')
	
	regression_viability = PRISM_klaeger_imputed %>%
		left_join(activation_set, by = c('drug'='drug', 'klaeger_conc' = 'concentration_M')) %>%
		left_join(CCLE_set, by=c('depmap_id' = 'DepMap_ID')) %>%
		mutate(target_viability = imputed_viability)
	
	return(regression_viability)
}