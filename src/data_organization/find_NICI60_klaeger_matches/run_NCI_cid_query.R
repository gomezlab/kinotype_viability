library(webchem)
library(here)
library(tidyverse)

NCI_cids = get_cid(unique(NCI60_SID_list$PubChemSID), from = "sid", domain = "substance", match = "all", verbose = TRUE) %>% 
	rename('NCI_SID' = query )

write_csv(NCI_cids, here('results/NCI60_all_compound_CIDS.csv'))