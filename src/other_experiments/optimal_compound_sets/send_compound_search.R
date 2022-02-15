for (i in 1:500) {
	job_name = sprintf('nd_%d_sn_%0d',10,i)
	
	system(paste0("./optimal_compound_search_script.R --num_drugs 10 --search_number ",i))
}

for (i in 1:500) {
	job_name = sprintf('nd_%d_sn_%0d',20,i)
	
	system(paste0("./optimal_compound_search_script.R --num_drugs 20 --search_number ",i))
}

for (i in 1:500) {
	job_name = sprintf('nd_%d_sn_%0d',30,i)
	
	system(paste0("./optimal_compound_search_script.R --num_drugs 30 --search_number ",i))
}

for (i in 1:500) {
	job_name = sprintf('nd_%d_sn_%0d',40,i)
	
	system(paste0("./optimal_compound_search_script.R --num_drugs 40 --search_number ",i))
}