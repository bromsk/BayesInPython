# Bayes In Python

Fitting generalized linear regression models (GLMMs) and complex non-linear models with Gaussian Processes in Bayesian framework. 

Comparing R (stan and jags libraries) and Python (Bambi and PyMC modules) code and performance.

**The intended audience here is someone who is proficient at fitting statistical models in R and using Rmarkdown files, but would like to fit those same models in Python instead. In particular, fitting complex Bayesian hierarchical models.**

I have two purposes:

1. To learn if I can fit complex non-linear Bayesian models with multi-dimensional Gaussian Processes in Python. I currently have custom algorithms written in Matlab for these models, and I want to fit the same models in Python.

2. To get better acquainted with Python.

All models are written mathematically and fit in both R and Python. Frequentist versions are fit when available as well as Bayesian versions.

The R and Python codes are written within an Rmarkdown (.Rmd) file which is read and compiled within the RStudio GUI.

Code is split into four (4) files: two (2) are the R code versions fo GLMMs and nonlinear Bayesian models; and two (@) are parallel versions written in Python instead.
