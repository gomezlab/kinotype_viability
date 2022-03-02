library(tidyverse)
library(here)

data_for_model_production = read_rds(here('results/single_model_expression_regression/full_model_data_set_500feat.rds'))

exp_names = data.frame(temp = names(data_for_model_production)) %>% 
	separate(temp,into=c("type","hgnc_symbol"),sep = "_") %>% 
	filter(type == "exp")

ensembl <- biomaRt::useEnsembl(biomart = "genes", dataset = "hsapiens_gene_ensembl", mirror = 'useast')
hgnc_to_ENST = biomaRt::getBM(attributes = c('hgnc_symbol','ensembl_transcript_id'), mart = ensembl)

exp_names_to_ENST = exp_names %>% 
	left_join(hgnc_to_ENST) %>% 
	select(-type)

if (length(unique(exp_names_to_ENST$hgnc_symbol)) != length(unique(exp_names$hgnc_symbol))) {
	print("PROBLEM WITH ENST MATCHING")
}

write_csv(exp_names_to_ENST, 
					here('results/single_model_expression_regression/model_expression_genes_ENST.csv'))

hgnc_to_refseq = biomaRt::getBM(attributes = c('hgnc_symbol','refseq_mrna'), 
																mart = ensembl, 
																filters = 'hgnc_symbol', 
																values = exp_names$hgnc_symbol)

exp_names_to_refseq = exp_names %>% 
	left_join(hgnc_to_refseq) %>% 
	filter(refseq_mrna != '') %>%
	select(-type)

if (length(unique(exp_names_to_refseq$hgnc_symbol)) != length(unique(exp_names$hgnc_symbol))) {
	print("PROBLEM WITH REFSEQ MATCHING")
}

write_csv(exp_names_to_refseq, 
					here('results/single_model_expression_regression/model_expression_genes_refseq.csv'))


hgnc_to_entrez = biomaRt::getBM(attributes = c('hgnc_symbol','entrezgene_id'), 
																mart = ensembl, 
																filters = 'hgnc_symbol', 
																values = exp_names$hgnc_symbol)
