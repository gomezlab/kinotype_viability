# Kinase Inhibitor Cell Viability Modeling

This repository contains the source code used to organize the data and build models associated with:

Berginski ME, Joisa C, et al. In process

## Audience

This is written to give an overview of the computational side of this work to an interested grad student. I'm basically trying to write down what I would tell you if you were sitting next to me and wanted an overview of this work. You probably have 1-2 years of experience writing R code and associated computing effort, including interacting with the command line and high-throughput computing resources. If this doesn't describe you, don't despair, you can probably still get something out of this repository.

## Overall Code Organization, Philosophy and Prerequisites

Nearly all of the code in this respository is written in R, almost all using tidyverse-esque idioms. All of the computational modeling code uses the tidymodel framework to faciliate model testing and usage. If you want to get a full handle on this codebase and these concepts are a bit unknown, you would be well served to work through [R for Data Science](https://r4ds.had.co.nz/) and the [tidymodels tutorial](https://www.tidymodels.org/start/models/). Hopefully my coding style is clear enough to make it possible to follow along without these resources, but they are the first places I would send someone who was interested in digging into the code. As for the actual code, I generally work in Rmarkdown documents except in cases where I'm going to need supercomputing resources in which case I write standard R scripts that can be run at the command line.

Otherwise, everything in this respository was written using Rstudio, but I don't think Rstudio is strickly necessary to run or modify the code. Typically, when I'm working on this project the first thing I do is open the R project file present in the top level directory. 

The raw data used for this work is too large to fit into this repository, but I've made a copy of the data organized into the directory structure the rest of the code expects on zenodo. A majority of the data sets were downloaded from the [depmap data portal](https://depmap.org/portal/download/) and compressed, with the remainder coming from journal supplemental data sections. These files should end up in a top level "/data" directory.

As for the overall organization of the code, there are three primary divisions:

* Code for organizing the raw data: located in [`src/data_organization`](src/data_organization)
* Code for testing models: this is a majority of the rest of the code, so in the modeling section I'll point towards specific locations to look for code related to the models in the paper
* Code for organizing the validation data: located in [`src/validation_screen`](src/validation_screen)

Before diving into the rest of the code, you should take a look at and run [`package_check.R`](src/package_check.R). This is a script that uses the pacman library to check for library installations and if missing installs them. It also installs two packages from github that I maintain ([DarkKinaseTools](https://github.com/IDG-Kinase/DarkKinaseTools) and [BerginskiRMisc](https://github.com/mbergins/BerginskiRMisc)). 

I've only ever tested this code on Linux (Ubuntu) and the supercomputing cluster at UNC. I think a majority of the code will work on other platforms, but I haven't tested it.

## Data Organization Code

This section of the code base deals with organizing, reformatting and otherwise preparing the raw downloaded data sets for the modeling sections of the code. In general, I tried to divide the code into sections that directly touch the raw data (this code) and code that only deals with the output of this section (the rest of the code). As mentioned above, all the code is in [`src/data_organization`](src/data_organaization) and the following Rmarkdown scripts contain the critical code:

* [`Klaeger Data`](src/data_organization/process_klaeger_data/klaeger_data_processing.Rmd): This code takes supplemental table 2 from Klaeger 2017 and converts it into a machine learning ready RDS file. There are quite a few decisions that went into getting the data into shape and this is all documented in the text surrounding the code.
* [`PRISM Viability`](src/data_organization/prep_PRISM_for_ML/prep_PRISM_for_ML.Rmd): This code takes the responce curve values provided by the PRISM consortium and imputes cell viability values at all of the concentrations used by Klaeger et al.
* [`DepMap CRISPR-KO`](src/data_organization/prep_depmap_data_for_ML/prep_depmap_for_ML.Rmd): The data from the DepMap consortium is very well organized, so not much was really necesary here. I simplified the names provided for each gene and filtered out a few lines with unexpected NAs.
* [`CCLE Data Sets`](src/data_organization/prep_CCLE_data_for_ML/prep_CCLE_for_ML.Rmd): The data from the CCLE is similarly well organized, so all that was really needed was some gene name simplification.
* [`CCLE Proteomics`](src/data_organization/prep_CCLE_proteomics_data/prep_CCLE_proteomics_data.Rmd): The code takes table S2 from the CCLE proteomics project, available from the Gygi lab [website](https://gygi.hms.harvard.edu/publications/ccle.html), and converts it into a machine learning ready RDS file. This part of the processing pipeline is a bit more complex as we need to deal with a larger amount of missing readings here and the associated imputation.

All the other script files in the [`data organization`](src/data_organaization) are related to other ideas we've had that weren't important in the paper. I thought about scrubbing all the unnecessary files out, but maybe someone will find something interesting in them.

### Reproducibility

I've made a simple script that runs the above scripts in sequence to produce all the files needed for the modelling effort ([`reproduce_data_org.R`](src/data_organization/reproduce_data_org.R)). On my computer (Ryzen 7 5800x) it took about 3 minutes and used 4.7 GB of RAM.

## Modeling Code

As I mentioned above, all the modeling code is written using the tidymodels framework and each modeling attempt has two parts. The first part of the modeling code calculates the correlation coefficients between cell viability and each of the potential model features using the cross validation folds if to divide the data if requested. The second part of the modeling method then uses those correlation values and a given number of features to then build and test the model. Since the primary model we selected in the paper was a random forest with 500 features selected from the kinase activation states and gene expression, I'll use those files as examples.

### Sample Modeling Code

All of these files can be found in [`src/build_ML_models_expression_regression`](src/build_ML_models_expression_regression). If you find my folding naming scheme inscrutable, I'll describe it in the other modeling code section. 

* [`get_feat_cor.R`](src/build_ML_models_expression_regression/get_feat_cor.R): This script reads in the data set from the data organization section and finds the correlations between cell viability and each of the features. In the case of this file, it only reads and searches the Klaeger activation states and gene expression, but this varies depending on the data sets the model includes. The feature correlation calculations are calculated in a cross validation aware fashion. This script also contains the code for making the cross validation fold assignments and building the full data file needed to make the final model that includes all of the data. Normally, with new model testing, I run this code once to make the CV fold assignments (saved to disk) to ensure that I don't accidentally use multiple cross validation assignments. You might be wondering why I don't just the built in CV code in tidymodels and it's because tidymodels doesn't support out of the differing feature selection across folds and this also makes it possible to run all the CV folds independently on the supercomputer.
* [`build_random_forest_models_no_tune.R`](src/build_ML_models_expression_regression/build_random_forest_models_no_tune.R): Hopefully you will forgive my overly wordy file names, but as you can hopefully guess, this script builds a random forest model for CV testing without tuning. It takes two parameters, the cross validation fold ID to run on and the number of features to include in the model, although the code will also run without specifying any parameter with a default of 100 features and CV fold ID 1. The other model types ([`XGBoost`](src/build_ML_models_expression_regression/build_xgboost_models_no_tune.R) and [`linear regression`](src/build_ML_models_expression_regression/build_linear_models.R)) get their own files that look very similar to this one (thanks tidymodels).

There are two other smaller scripts used to automate cycling through the CV folds and modeling types [`send_feat_cor_cmd.R`](src/build_ML_models_expression_regression/send_feat_cor_cmd.R) and [`send_model_cmd.R`](src/build_ML_models_expression_regression/send_model_cmd.R). These scripts simply build the commands needed to run the feature correlations and modeling runs and send them into the computational queue on the supercomputer at UNC. If you have access to a slurm cluster these will probably work, but if not you can use them as a template to run your models locally or on whatever supercomputing system you use.

I'll point out the purpose of a few of the other files in the folder:

* [`make_model_pred.Rmd`](src/build_ML_models_expression_regression/make_model_pred.Rmd): This code takes in the full data set and builds the final model used to make predictions for the rest of the data outside the model. It also includes a section to build a simplier model that we are going to use a power a webapp.
* [`annotate_kinase_interactors.Rmd`](src/build_ML_models_expression_regression/annotate_kinase_interactors.Rmd): This code uses the STRING database to annotate which expression features interact with kinases for use in interpretting the expression modeling features.

The other files in this folder are related to models not in the paper or code to build the figures in the paper. I'll get to figure reproduction at the end of this document.

### Other Modeling Code

All of the other modeling code in the paper has the same backbone as the kinase activation and gene expression model. As far as the folder names for the modeling code, in general I tried to make it clear what data sources or how they were modified along with some indication of the target of the modeling effort. Some of the naming choices are also related to differentiating a folder from a similar modeling effort that has since been removed. For example, at the beginning of this project I started off building models to classify whether a cell viability value was above or below the median, but this was quickly discarded when it became clear that regression would work reasonablely well. Also, since kinase activation state is so important for the models, I don't explicity call that data type out in the folder names as it was always included by default.

I've tried many variations on ways to modify the cross validation strategy, data sources used and feature selection techniques. Only two of these feature prominently in the paper:

* [`build_ML_models_expression_regression`](src/build_ML_models_expression_regression): This is the code detailed in the sample modeling code section, it builds and tests the kinase activation and gene expression model.
* [`build_ML_models_all_data_regression`](src/build_ML_models_all_data_regression): This code uses all the data types (gene expression, CNV, proteomics and CRISPR-KO) for modeling. These results are included in the paper as the all data model.

#### Cross Validation Strategy Variation

Aside from the per cell line-compound combo cross valdiation covered in the paper, there are two alternative cross valdiation strategies we thought about:

* [`Leave One Compound Out`](src/alternative_CV/build_ML_models_expression_regression_LOCO/): Run cross validation by leaving a single compound out of the training.
* [`Leave One Cell Line Out`](src/alternative_CV/build_ML_models_expression_regression_LOLO/): Run cross validation by leaving a single cell line out of the training

We discarded both of these as too computationally expensive.

#### Data Sources Variation

We've had lots questions about how the model would preform in situtations beyond the two outlined in the main paper. As a catch all term, I call these [`alternative data sets`](src/alternative_data_sets/). One question relates to how the kinase activation state and expression model performs when various parts of the data are removed:

* [`Expression Only`](src/alternative_data_sets/exp_only_regression/): These files handle trying to build a model using only the gene expression data, it doesn't go well.
* [`Only Kinases and Expression`](src/alternative_data_sets/only_kinase_regression/): Since there are lots of non-kinases in the Klaeger results (49%), we also tested out building the models without the non-kinase activation states. This model performs nearly as well, but there is still a fair amount of information coming from the non-kinases.
* [`Only All Data Lines`](src/alternative_data_sets/build_ML_models_exp_only_all_data_lines/): Since the all data model has to include substantially fewer cell lines, to be fair, I also rebuilt the activation and expression models with only those same lines.

Another question these models tackle is can we modify the activation data to make it match more with the actual proteome complement of each cell line. Basically, the activation state of a given protein shouldn't matter if that protein isn't present in that cell line. Neither of these method ultimately worked out, but I thought they were interesting enough to make sure I documented them. We looked at two ways to do this:

* [`Baseline MIBs`](src/alternative_data_sets/MIB_adj_and_pred/): [Previous work](https://doi.org/10.18632/oncotarget.24337) has used a MIBs based assay to determine the kinase complement of some TNBC cell lines. We took this data and changed the activation values for proteins not present in a given cell line. This still might work if you used a more sophisticated method to weight the activation values.
* [`Gene Expression`](src/alternative_data_sets/exp_adj/): Similar to the baseline MIBs except using the measured gene expression to block activation values for proteins with low expression values. The real question here is what's the appropriate TPM threshold for making a change and should this threshold be modified for the distribution of a given gene's expression values. Once again, I think a more sophisticated method of weighting might make this work.

Finally, I also tested out [`scrambling the compound and cell line labels`](src/alternative_data_sets/build_ML_models_data_scramble/), working under the assumption that the model would mostly revert back to baseline if these biological relationships were broken. This worked exactly as expected with the model reverting to almost perfectly match the dose-only baseline.

#### Feature Selection Techniques

We used the absolute value of the spearman correlation between cell viability and the features to pick out which features to include in the model. This isn't the only method to detect a relationship between two variables though. We tested two others, mutual information and representative features from clustering to pick out features as well:

* [`Mutual Information`](src/alternative_feature_selection/build_ML_models_expression_regression_MI/): This code using the [infotheo](https://cran.r-project.org/web/packages/infotheo/index.html) package to calculate the mutual information as an alternative to correlation for feature selection. This didn't outperform spearman correlation, maybe because the relationships picked out by MI are too complex for the models we tested? It might be interesting to try out a neural net with these features to see if that technique was better able to tease out the relationships.
* [`Cluster Representatives`](src/alternative_feature_selection/build_ML_models_expression_regression_cluster/): This is a bit more complicated. The concept I started with was that it's highly likely that many of the features selected for the model are correlated with one another and so aren't contributing much new information to the system. Thus, maybe we can get more total information out of the features by first clustering the features with one another and then asking the clustering result to give us a specific number of clusters that are relatively uncorrelated with one another. From those clusters, we then pull out a single representative feature (highest abs spearman correlation) to act as the cluster's representative feature. This was a bit of a computational nightmare as even getting the clustering to work required about 400 GB of RAM. Ultimately, this selection method didn't improve the CV results and my best guess for why is because random forest actually requires some degree of redundancy between data to work well. Another good candidate for revisting with neural nets.

### Reproducibility

All of the [`send_feat_cor_cmd.R`]() and [`send_model_cmd.R`]() should reproduce the model runs for each of the modeling code sections described above. I thought about writing a single script to run each of these, but since I suspect that anyone will likely need to modify these files to get them to work in their local environment, I haven't written it. If there is demand for such a file, I'll be glad to give it a shot. 

Since I ran all of this code on UNC's supercomputer, I don't have a very precise idea of how long it would take to completely reproduce the CV model runs. As a test, I ran one of the CV folds through all of the modeling types used in the paper for the activation and expression model. It took 3.6 hours and the RAM usage peaked at 36 GB. Extrapolating that out means about 36 hours of computational time (8 cores on a Ryzen 7 5800x) and you should probably have 64 GB of RAM to be safe.

## Validation Data Code

### Reproducibility


## Figure Production Code

