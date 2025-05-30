--- 
title: "Bayesian models in R and Python"
author: "Kristin Broms"
date: "2025-05-29"
site: bookdown::bookdown_site
output: bookdown::gitbook
documentclass: book
bibliography: [book.bib, packages.bib]
biblio-style: apalike
link-citations: yes
github-repo: rstudio/BayesInPython
description: "This is a tutorial for R users to convert their code into Python. In particular, fitting GLMMs, hierchical BAyesian models, and non-linear Bayesian models."
---



# Introduction {#intro}


I have used R, in conjunction with Rmarkdown documents, in an RStudio GUI for over a decade. It is a beautiful setup, with great work flows and clean coding. It is perfect for non-production level analyses, visualizations, interactive documents, web apps, and reports.

However, the world seems to prefer Python. Perhaps it is because computer programmers rule the world more than statisticians and scientists. In that vein, I am writing this tutorial to fit GLMM's, hierarchical Bayesian models (with Gaussian Processes and random effects), and non-linear Bayesian models in Python. 

The intended audience here is someone who is proficient at fitting statistical models in R, but would like to fit those same models in Python instead. In particular, fitting complex Bayesian hierarchical models.

I have two purposes:

1. To learn if I can fit complex non-linear Bayesian models with multi-dimensional Gaussian Processes in Python. I currently have custom algorithms written in Matlab for these models, and I want to fit the same models in Python.

2. To get better acquainted with Python.


All models are written mathematically and fit in both R and Python. Frequentist versions are fit, when available, in addition to the Bayesian versions. There are four chapters: GLMM's in R; GLMM's in Python; non-linear models in R; and non-linear models in Python.

The first chapter fits GLMM's in R. The "GLMM's in Python" has parallel text and code chunks to easily see how commands correspond between the different software.


## Case Study

We are analyzing moth count data collected from traps from rice fields in Indonesia. There are a total of 10 locations that are sampled throughout a field season. At each location, there is one treatment (trt A) field with 4 traps and one control field with 4 traps. These traps are sampled and reset approximately every 10 days for the entire growing season, but sometimes that interval varies.

It is expected that the treatment field (trt A) will catch fewer moths than the control fields. The research questions are: how much fewer moths are caught, i.e., what is the trapping reduction associated with the PFP traps? And, is the same trapping reduction (TR) observed for the entire season?

These data have a spatial and temporal component. Spatially, the traps have a certain proximity to each other within a location, and the locations may be clumped across the landscape. Temporally, the same traps are sampled over time. 

These data are based on the data from Iqbal et al. (2023) (link: https://jurnal.pei-pusat.org/index.php/jei/article/view/783), _but have been heavily manipulated in terms of location coordinates, location names, and trap counts to preserve privacy rights. The results presented in this tutorial are NOT representative of true product performance._

Full citation:
Iqbal, M., Marman, M., Arintya, F., Broms, K. ., Clark, T., & Srigiriraju, L. . (2023). Mating disruption technology: An innovative tool for managing yellow stem borer (Scirpophaga incertulas Walker) of rice in Indonesia: Teknologi gangguan kawin: Inovasi untuk pengendalian penggerek batang kuning (Scirpophaga incertulas Walker) pada padi di Indonesia. Jurnal Entomologi Indonesia, 20(2), 129.

### Case study objectives

How well does the treatment work?


At each location, there is one rice field that is a control group and one rice field that is treated with pheromones. **The objective is to determine how good the treatment is at reducing moth populations. This is measured as a reduction of moth counts in the traps in the treatment fields compared to the traps in the control fields.**

The performance metric of interest is trap reduction (TR), which is a derived parameter of the regression coefficient:

$$
TR = 100 - 100 e ^{(-\beta_1)}
$$

If trapping reduction were 100%, no moths would ever be caught in the treatment traps. However, some random moths will inevitably land in any trap. Instead, product performance is considered good if 90% trapping reduction is achieved, meaning that 90% fewer moths are caught in the treatment traps. When trapping reduction goes below 0%, the parameter no longer makes sense and cannot be interpreted.

It should also be noted that treatment performance may decline over time. Perhaps there is not enough pheromone to last for the entire season, or the ecosystem may change during the season in a way that somehow lessens product performance (e.g., the pheromones from the plants may change and interact with the product.)

## Outline

* Introduce the data to be used throughout the tutorial.

* Fit generalized linear models (GLMs, here Poisson and negative binomial regressions). Models are fit in both frequentist and Bayesian frameworks to lay the groundwork for the more complicated models.

* Fit generalized linear models with random effects (GLMMs) to allow for correlations in space and time. Models are fit in both frequentist and Bayesian frameworks.

