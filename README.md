# Kinase Inhibitor Cell Viability Modeling

This repository contains the source code used to organize the data and build models associated with:

Berginski ME, Joisa C, et al. In process

## Overall Code Organization, Philosophy and Prerequisites

Nearly all of the code in this respository is written in R, almost all using tidyverse-esque idioms. All of the computational modeling code uses the tidymodel framework to faciliate model testing and usage. If you want to get a full handle on this codebase and these concepts are a bit unknown, you would be well served to work through [R for Data Science](https://r4ds.had.co.nz/) and the [tidymodels tutorial](https://www.tidymodels.org/start/models/). Hopefully my coding style is clear enough to make it possible to follow along without these resources, but they are the first places I would send someone who was interested in digging into the code. As for the actual code, I generally work in Rmarkdown documents except in cases where I'm going to need supercomputing resources.

Otherwise, everything in this respository was written using Rstudio, but I don't think Rstudio is strickly necessary to run or modify the code. Typically, when I'm working on this project the first thing I do is open the R project file present in the top level directory. 

The raw data used for this work is too large to fit into this repository, but I've made a copy of the data organized into the directory structure the rest of the code expects on zenodo. A majority of the data sets were downloaded from the [depmap data portal](https://depmap.org/portal/download/) and compressed, with the remainder coming from journal supplemental data sections. These files should end up in a top level "/data" directory.

As for the overall organization of the code, there are three primary divisions:

* Code for organizing the raw data: located in [`src/data_organization`](src/data_organization)
* Code for testing models: this is a majority of the rest of the code, so in the modeling section I'll point towards specific locations to look for code related to the models in the paper
* Code for organizing the validation data: located in [`src/validation_screen`](src/validation_screen)

Before diving into the rest of the code, you should take a look at and run [`src/package_check.R`](src/package_check.R). This is a script that uses the pacman library to check for library installations and if missing installs them. It also installs two packages from github that I maintain ([DarkKinaseTools](https://github.com/IDG-Kinase/DarkKinaseTools) and [BerginskiRMisc](https://github.com/mbergins/BerginskiRMisc). 

I'll finish off this section by mentioning that I've only ever tested this code on Linux (Ubuntu) and the supercomputing cluster at UNC. I think a majority of the code will work on other platforms, but I haven't tested it.

# Data Organization Code

This section of the code base deals with organizing, reformatting and otherwise preparing the raw downloaded data sets for the modeling sections of the code. In general, I try to divide the code into sections that directly touch the raw data (this code) and code that only deals with the output of this section (the rest of the code). As mentioned above, all the code is in [`src/data_organization`](src/data_organaization) and the following Rmarkdown scripts contain the critical code:

## Reproducibility



# Modeling Code

# Validation Data Code

# Reproducibility
