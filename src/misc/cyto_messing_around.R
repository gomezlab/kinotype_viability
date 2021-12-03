library(here)
library(tidyverse)

klaeger_full_tidy %>% 
	filter(gene_name == "ACTR3", relative_intensity != 1) %>% 
	ggplot(aes(x=log10(concentration_M),y=relative_intensity,color=drug)) + 
	geom_point() + 
	geom_line() +
	labs(y="Arp3 Protein Abundance (Ratio with DMSO)",x="Log10 Compound Concentration (M)",color='') +
	theme(aspect.ratio = 1:1) +
	BerginskiRMisc::theme_berginski()
ggsave(here('arp3_kin_inhib_pulldown.png'),width=5,height=5)
BerginskiRMisc::trimImage(here('arp3_kin_inhib_pulldown.png'))

cob_temp = klaeger_full_tidy %>% 
	filter(drug == "Cobimetinib", relative_intensity != 1)

klaeger_full_tidy %>% 
	filter(drug == "Cobimetinib", relative_intensity != 1) %>% 
	ggplot(aes(x=log10(concentration_M),y=relative_intensity, color=gene_name)) + 
	geom_hline(aes(yintercept=1), linetype = 2, alpha = 0.5) +	
	geom_line() +
	geom_point() +
	BerginskiRMisc::theme_berginski()

ggsave(here('Cobimetinib_hits.png'))

gil_temp = klaeger_full_tidy %>% 
	filter(drug == "Gilteritinib", relative_intensity != 1)

klaeger_full_tidy %>% 
	filter(drug == "Gilteritinib", relative_intensity != 1) %>% 
	ggplot(aes(x=log10(concentration_M),y=relative_intensity, color=gene_name)) + 
	geom_hline(aes(yintercept=1), linetype = 2, alpha = 0.5) +	
	geom_line() +
	geom_point() +
	BerginskiRMisc::theme_berginski()

ggsave(here('Gilteritinib_hits.png'))

klaeger_full_tidy %>% 
	filter(gene_name == "ACTR2", relative_intensity != 1) %>% 
	ggplot(aes(x=log10(concentration_M),y=relative_intensity,color=drug)) + 
	geom_point() + 
	geom_line() +
	labs(y="Ratio of Protein Abundance Against DMSO",x="Log10 Compound Concentration (M)",color='') +
	theme(aspect.ratio = 1:1) +
	BerginskiRMisc::theme_berginski()
ggsave(here('arp2_kin_inhib_pulldown.png'),width=5,height=5)
BerginskiRMisc::trimImage(here('arp2_kin_inhib_pulldown.png'))

tal_temp = klaeger_full_tidy %>% 
	filter(drug == "Talmapimod", relative_intensity != 1)

klaeger_full_tidy %>% 
	filter(drug == "Talmapimod", relative_intensity != 1) %>% 
	ggplot(aes(x=log10(concentration_M),y=relative_intensity, color=gene_name)) + 
	geom_hline(aes(yintercept=1), linetype = 2, alpha = 0.5) +	
	geom_line() +
	geom_point() +
	BerginskiRMisc::theme_berginski()
ggsave(here('Talmapimod_hits.png'))

cyto_hits = data.frame(gene_names = c("ACTR2","ACTR3","ADD2","CAPZA1","CKAP5","CTTN","DYNLL1","FLNB","MYH10","MYH14","PRPH","OSBPL3")) %>%
	mutate("act_str" = paste0("act_",gene_names))

klaeger_full_tidy %>% 
	filter(drug == "Selumetinib", relative_intensity != 1) %>% 
	ggplot(aes(x=log10(concentration_M),y=relative_intensity, color=gene_name)) + 
	geom_hline(aes(yintercept=1), linetype = 2, alpha = 0.5) +	
	geom_line() +
	geom_point() +
	BerginskiRMisc::theme_berginski()

ggsave(here('Selumetinib_hits.png'))

###############################################################################
TNK2_hits = klaeger_full_tidy %>% 
	filter(gene_name == "TNK2", relative_intensity != 1)

strong_TNK2 = klaeger_full_tidy %>% 
	filter(gene_name == "TNK2", relative_intensity == 0)

klaeger_full_tidy %>% 
	filter(drug == "ASP-3026", relative_intensity != 1) %>% 
	ggplot(aes(x=log10(concentration_M),y=relative_intensity, color=gene_name)) + 
	geom_hline(aes(yintercept=1), linetype = 2, alpha = 0.5) +	
	geom_line() +
	geom_point() +
	BerginskiRMisc::theme_berginski()

ggsave(here('ASP-3026_hits.png'))

asp_hits = klaeger_full_tidy %>%
	filter(drug == "ASP-3026", relative_intensity != 1)

tofact_hits = klaeger_full_tidy %>%
	filter(drug == "Tofacitinib", relative_intensity != 1)
