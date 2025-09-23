---
output: html_document
editor_options: 
  chunk_output_type: console
---

# GLMM's in Python {#GLMMsPython}

## Getting started with Python

Python is a lot more complicated than R!

1. Download Python.

2. Decide how you want to interact with Python. Yes, you can technically use the terminal and use Python directly, but a GUI is preferable so that it is easier to run the code, add comments, view the output, etc. This is even more true for Python than it is for R. 

Originally, I downloaded Jupyter Notebook directly, but I didn't like the way things loaded. So, I downloaded Anaconda and then accessed Jupyter from there. However, I  don't love Jupyter-- the notebooks don't optimize the screen's size like RStudio does. In RStudio, I love having my code on one side of the screen, and my outputs on the other. Screens are wide, not long. 

Soon, I came across the "reticulate" package, which allows for Python coding in an Rmarkdown script! So far, awesome and it is how I run the all the analyses. Here, I switch between R and Python code chunks, but the package also allows objects written in one language to be used within both languages. Pretty cool. It's not for production-level code, but seems perfect for R users switching to Python. 

To interact with Python via RMarkdowns in RStudio, check out the `reticulate` package [website](https://rstudio.github.io/reticulate/articles/r_markdown.html).

Here is another helpful link: [Primer on Python for R users](https://rstudio.github.io/reticulate/articles/python_primer.html)


3. Set up a Python environment for your work. (Second code chunk in the setup.) Here is why that is important:

Python environments:
"When installing Python packages it’s best practice to isolate them within a Python environment (a named Python installation that exists for a specific project or purpose). This provides a measure of isolation, so that updating a Python package for one project doesn’t impact other projects. The risk for package incompatibilities is significantly higher with Python packages than it is with R packages, because unlike CRAN, PyPI does not enforce, or even check, if the current versions of packages currently available are compatible."
https://rstudio.github.io/reticulate/articles/python_packages.html

Anaconda and reticulate both help the user keep specific environments for each Python "project" that one may be working on.

A Python virtual environment is a basic tool to isolate project dependencies within a Python installation, while a Conda environment is a more comprehensive package manager that not only creates isolated environments but also allows for managing complex dependencies across different programming languages. To keep things simpler, I use a Python virtual environment.


4. Install Python modules as needed.

Python libraries or packages are called __modules__. To use them with `reticulate`, you first have to import them (third code chunk). The lines in the third code chunk below must be called exactly once each for each new python module used; it does not need to re-run.


## Setup

As in the R chapters, all modules (i.e., packages) are loaded and the data are uploaded and manipulated at the start of the script. The "Getting started with Python" section above goes into details on the rhyme and reason for some of these code chunks.

Because I am newer to Python, the required modules are often included in the code chunks as well as a reminder of what modules are used for what functions. They are included in the setup to ensure that there are no issues upon loading.



``` r
knitr::opts_chunk$set(cache = T, message = F, warning = F, 
  out.width = '100%')
library(kableExtra) # to make a pretty table
library(tidyverse) # %>% function, and others
library(reticulate) # library to use Python within R
use_virtualenv("r-reticulate-BayesInPython")

# make sure these packages are installed in R before installing pymer4:
# install.packages(c("lme4", "lmerTest", "emmeans"))
# Ensure pymer4 is installed in the desired Python environment
# py_require("pymer4")
```

``` r
## Uncomment the code below and run once, the first time you work through the tutorial:

# create a new environment
# virtualenv_create("r-reticulate-BayesInPython")
# 
# # install a module
# virtualenv_install("r-reticulate-BayesInPython", "pandas")
# 
# indicate that we want to use a specific virtualenv
# use_virtualenv("r-reticulate-BayesInPython")
# 

## (Uncomment this code instead if you prefer a Conda environment) 
# # create a new environment 
# conda_create("r-reticulate-BayesInPython")
# 
# # install a module, e.g., SciPy
# conda_install("r-reticulate-BayesInPython", "scipy")
# 
# # indicate that we want to use a specific condaenv
# use_condaenv("r-reticulate-BayesInPython")
```

``` python
## Install modules if you have not used them before

# code chunk is here for easy retrieval
# replace module name as needed.
!pip install staticmap

# installing googlemaps needs a modification to the command above:
# !pip install  --use-pep517 googlemaps

# to install pymer4, you need to type the following commands from Terminal:
# you may need Anaconda installed
## https://eshinjolly.com/pymer4/installation.html
# conda create --name pymer4 -c ejolly -c conda-forge -c defaults pymer4
# conda activate pymer4
```


``` python
import pandas as pd
import numpy as np

import pprint
from staticmap import StaticMap, CircleMarker # plot trap locations on a map
import arviz as az
import matplotlib.pyplot as plt 
from formulae import design_matrices

import patsy # for dmatrix function

from plotnine import * # using ggplot in Python
import seaborn as sns 

import os # save API key in .env file
import gmplot ## ggmap 

from patsy import dmatrices # for dmatrices function
import statsmodels.api as sm # for regressions
import math

from scipy.stats import nbinom

import bambi as bmb
import pymc as pm

import pickle # to write, read python objects to file


mycolors = ["#9E0142", "#66C2A5"] # color names from R script
```

``` python
## Define some functions to use in this script.

# calculate trapping reduction for frequentist model fits.
def getTR(mod):
    """Calculate TR with confidence interval for stats model"""
    # Function body
    import pandas as pd

    b1 = mod.params.iloc[1]
    seb1 = mod.bse.iloc[1]
    
    outTR = {'TR': [round(100 * (1 - math.exp(b1)),1)], 
    'lowerCI': [round(100 * (1 - math.exp(b1 + 1.96*seb1)),1)],
    'upperCI': [round(100 * (1 - math.exp(b1 - 1.96*seb1)),1)]}
    df = pd.DataFrame(outTR)
    return df
```

``` python
## Read in the moth data:

import pandas as pd

datP = pd.read_csv("data/moths.csv", delimiter = ",")

# check data values: 
# (Results not shown for succinctness)
datP.info()
```

``` python
pd.set_option('display.max_columns', None) # Display all columns
datP.describe(percentiles=[0.5], include = 'all')
```

``` python
for col in datP:
  if (datP[col].dtype == 'object'):
    print(col)
    print(datP[col].unique())
```

``` python
## manipulate data as needed:

# convert dates to dates in case further manipulation on them is needed:
# but first keep object version of samplingdate:
datP['SamplingDateC'] = datP['SamplingDate']
cols = ['TransplantDate', 'DispInstallDate', 'TrapInstallDate', 'SamplingDate']
for col in cols:
    datP[col] = pd.to_datetime(datP[col])
datP['SamplingDate'].describe()
```

``` python
# standardize the counts
datP['mothsperday'] = datP['nYSB'] / datP['DaysOfCatch']

# un-comment if we need to fix levels in non-alpha order
# datR <- datP %>%
#   mutate(TreatmentF = factor(Treatment), 
         # LocationF = as.factor(Location),


## average counts for each location, date
mean_cts = datP.groupby(['Location', 'Treatment', 'AssessmentNumber', 'SamplingDate', 'SamplingDateC', 'DATI'], as_index=False).agg({'nYSB': 'mean', 'mothsperday': 'mean'})
mean_cts.describe(include='all')
```

## Data exploration

### The data

Here is what the data look like after the above manipulation. 

(While one can easily print the data frame from Python, here I make the output "pretty" within the Rmarkdown/bookdown environment using the `knitr` function from R.)


``` r
kable(head(py$datP, 5)) %>%
  kable_styling() %>%
  scroll_box(width = "100%", box_css = "border: 0px;")
```

<div style="border: 0px;overflow-x: scroll; width:100%; "><table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> Location </th>
   <th style="text-align:left;"> Treatment </th>
   <th style="text-align:right;"> TrapID </th>
   <th style="text-align:right;"> Longitude </th>
   <th style="text-align:right;"> Latitude </th>
   <th style="text-align:left;"> TransplantDate </th>
   <th style="text-align:left;"> TrapInstallDate </th>
   <th style="text-align:left;"> DispInstallDate </th>
   <th style="text-align:right;"> AssessmentNumber </th>
   <th style="text-align:left;"> SamplingDate </th>
   <th style="text-align:right;"> nYSB </th>
   <th style="text-align:right;"> DaysOfCatch </th>
   <th style="text-align:right;"> DATI </th>
   <th style="text-align:right;"> DADI </th>
   <th style="text-align:right;"> DAT </th>
   <th style="text-align:left;"> SamplingDateC </th>
   <th style="text-align:right;"> mothsperday </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Loc9 </td>
   <td style="text-align:left;"> Trt </td>
   <td style="text-align:right;"> 201 </td>
   <td style="text-align:right;"> 111.6028 </td>
   <td style="text-align:right;"> -7.233634 </td>
   <td style="text-align:left;"> 2023-08-05 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 2023-08-22 18:00:00 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:left;"> 2023-08-23 </td>
   <td style="text-align:right;"> 0.4000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Loc9 </td>
   <td style="text-align:left;"> Trt </td>
   <td style="text-align:right;"> 201 </td>
   <td style="text-align:right;"> 111.6028 </td>
   <td style="text-align:right;"> -7.233634 </td>
   <td style="text-align:left;"> 2023-08-05 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> 2023-09-02 18:00:00 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 28 </td>
   <td style="text-align:left;"> 2023-09-03 </td>
   <td style="text-align:right;"> 0.5454545 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Loc9 </td>
   <td style="text-align:left;"> Trt </td>
   <td style="text-align:right;"> 201 </td>
   <td style="text-align:right;"> 111.6028 </td>
   <td style="text-align:right;"> -7.233634 </td>
   <td style="text-align:left;"> 2023-08-05 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 2023-09-11 18:00:00 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:right;"> 37 </td>
   <td style="text-align:left;"> 2023-09-12 </td>
   <td style="text-align:right;"> 0.6666667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Loc9 </td>
   <td style="text-align:left;"> Trt </td>
   <td style="text-align:right;"> 201 </td>
   <td style="text-align:right;"> 111.6028 </td>
   <td style="text-align:right;"> -7.233634 </td>
   <td style="text-align:left;"> 2023-08-05 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 2023-09-22 18:00:00 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:right;"> 48 </td>
   <td style="text-align:left;"> 2023-09-23 </td>
   <td style="text-align:right;"> 2.1818182 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Loc9 </td>
   <td style="text-align:left;"> Trt </td>
   <td style="text-align:right;"> 201 </td>
   <td style="text-align:right;"> 111.6028 </td>
   <td style="text-align:right;"> -7.233634 </td>
   <td style="text-align:left;"> 2023-08-05 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:left;"> 2023-08-12 18:00:00 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 2023-10-01 18:00:00 </td>
   <td style="text-align:right;"> 43 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 50 </td>
   <td style="text-align:right;"> 50 </td>
   <td style="text-align:right;"> 57 </td>
   <td style="text-align:left;"> 2023-10-02 </td>
   <td style="text-align:right;"> 4.7777778 </td>
  </tr>
</tbody>
</table></div>

Column descriptions: 

* **Location**-- data were collected from 10 trial locations, 

* **Treatment**-- Control or Treatment (Trt), 

* **TrapID**-- each trap within a trial location has a unique ID, 

* **Longitude**, **Latitude**-- the coordinates of each unique trap,

* **TransplantDate**-- the date that the rice seedlings were transplanted into the field,

* **TrapInstallDate**-- the trap installation date, which is usually the same as the dispenser installation date, 

* **DispInstallDate**-- the treatment (pheromone dispenser) installation date; 

* **AssessmentNumber**-- traps are sampled 10 times each. Using assessment number is a way to standardize the sampling dates across locations, 

* **SamplingDate**-- the date on which the trap was checked and moths were counted,

* **nYSB**-- the moth counts (number of YSB moths) associated with each trap, location, and date, 

* **DaysOfCatch**-- the number of days since the trap was previously sampled or the number of days since trap installation if it is assessment number 1,

* **DATI** is days after trap installation; 

* **DADI**-- days after dispenser installation; and 

* **DAT**-- days after transplant. 

* **mothsperday**-- moths caught per day, nYSB / DaysOfCatch, and

* **SamplingDateC**-- Sampling Date as a character/string (for model in Section \\@ref(glmm_datesC)),


### Moth counts plotted

The data are the moth counts collected at each trap (average per day), within each location and throughout the season. Note how the y-axis changes for each plot in the figure.

The `plotnine` module allows us to use `ggplot2` package in Python. It is fantastic to quickly make a beautiful plot using previously acquired R skills, and it does so with a fraction of the code required to make a similar figure using Python's `seaborn` and/or `matplotlib` modules.


``` python
from plotnine import * # using ggplot in Python
import matplotlib.pyplot as plt 

pmoths = (ggplot(datP, aes(x = 'DATI', y='mothsperday', color = 'Treatment')) +
        geom_jitter(height = 0, width = 0.75, alpha = 0.5) +
        geom_smooth(se=False) +
        facet_wrap(['Location'], scales = "free_y") +
        scale_color_manual(values = mycolors) +
        labs(title = "Male YSB moth counts for each location and trap",
             subtitle = "with smoothing lines",
             y = "Moth counts per trap per day",
             x = "Days after installation (DAI)",
             color = "Treatment"))
pmoths.draw(True)
```

<img src="03-GLMMsInPython_files/figure-html/plotMothsPy-1.png" width="100%" />



### Trial locations

Trial locations in relation to each other. Some trial locations are closer to each other than others.


``` python
## average coords for each location
loc_coords = datP.groupby(['Location'], as_index=False).agg({'Latitude': 'mean', 'Longitude': 'mean'})
colors = ["#7F3B08", "#B35806", "#E08214", "#FDB863", "#FEE0B6", "#D8DAEB", "#B2ABD2", "#8073AC", "#542788", "#2D004B"]

m = StaticMap(600, 300)
for i in range(0, len(loc_coords["Longitude"])):
  # add outline first to make points easier to see:
  m.add_marker(CircleMarker((loc_coords["Longitude"][i], loc_coords["Latitude"][i]), "black", 12))
  m.add_marker(CircleMarker((loc_coords["Longitude"][i], loc_coords["Latitude"][i]), colors[i], 10))

image = m.render(zoom=7)
image.save('output/trial_locs.png')
```

<div class="figure">
<img src="output/trial_locs.png" alt="Example trial locations." width="100%" />
<p class="caption">(\#fig:unnamed-chunk-2)Example trial locations.</p>
</div>

There are 4 traps per treatment at each location.

<!-- ![Trial locations](output/trial_locs.png "Trial locations.") -->

<!-- Within each location, the treatment traps have a slightly different alignment. The R version of this figure naturally renders in an easier to read fashion. -->





<!-- ![Trap coords](output/traplocs.png "Trap coordinates.") -->

## Fitted GLM models {#fit-glmPy}

To start, we ignore all the spatial and temporal relationships in the data and assume each data point is independent and identically distributed (iid). **This is not a good model for the data!** It is just our starting off point.

When building hierarchical Bayesian models, it is always a good idea to start simple, make sure everything works as expected, and then build up.

See Section \@ref(glm) for the associated mathematical models.

### Frequentist Poisson model

These models show a very tight confidence intervals for our coefficient estimates and our predictions. But also, the residual deviance is MUCH greater than the degree of freedom, indicating a lack of fit. The plot of the predictions (Figure \@ref(fig:p1p-glmFig)) overlaid on the data also demonstrate the lack of fit.


``` python
import numpy as np
from patsy import dmatrices # for dmatrices function
import statsmodels.api as sm # for regressions
import math

# POISSON regression
form = """ nYSB ~ Treatment"""
y, X = dmatrices(form, datP, return_type = 'dataframe')
mod1p = sm.GLM(y, X, 
              offset=np.log(datP["DaysOfCatch"]),
              family = sm.families.Poisson())
results1p = mod1p.fit()
print(results1p.summary())
```

```
##                  Generalized Linear Model Regression Results                  
## ==============================================================================
## Dep. Variable:                   nYSB   No. Observations:                  672
## Model:                            GLM   Df Residuals:                      670
## Model Family:                 Poisson   Df Model:                            1
## Link Function:                    Log   Scale:                          1.0000
## Method:                          IRLS   Log-Likelihood:                -14034.
## Date:                Tue, 23 Sep 2025   Deviance:                       25678.
## Time:                        10:43:50   Pearson chi2:                 4.24e+04
## No. Iterations:                     6   Pseudo R-squ. (CS):              1.000
## Covariance Type:            nonrobust                                         
## ====================================================================================
##                        coef    std err          z      P>|z|      [0.025      0.975]
## ------------------------------------------------------------------------------------
## Intercept            1.3960      0.009    162.829      0.000       1.379       1.413
## Treatment[T.Trt]    -2.1665      0.027    -80.933      0.000      -2.219      -2.114
## ====================================================================================
```

#### Predictions

See Section \@ref(defineTR) for definition of trapping reduction (TR).


``` python
## obtain TR estimate for comparison later (custom function in Setup code)
TR_1p = getTR(results1p)
print(TR_1p)
```

```
##      TR  lowerCI  upperCI
## 0  88.5     87.9     89.1
```

For a check of model fit, I compare predicted moths per day to the observed moths per day.

Note: when I predict for new data, I set $DaysOfCatch = 1$, and then I compare to the moths per day variable ($mothsperday = nYSB / DaysOfCatch$). I want to exclude any patterns related to the varying time intervals.


``` python
# predict from poisson regression:
preds1p = results1p.get_prediction(X, which = 'linear')
preds1pDFtmp = preds1p.summary_frame() #summary_frame() returns a pandas DF
# preds1pDFtmp.describe()

preds1pDF = datP
preds1pDF['exp_values'] = preds1pDFtmp['predicted'].apply(math.exp)
preds1pDF['lowerCI'] = preds1pDFtmp['ci_lower'].apply(math.exp)
preds1pDF['upperCI'] = preds1pDFtmp['ci_upper'].apply(math.exp)

## plot predicted and actual:
freqplot1p = (ggplot(preds1pDF, 
                aes(x = 'DATI', y='exp_values', color = 'Treatment')) +
        geom_line() +
        geom_ribbon(aes(ymin = 'lowerCI', ymax = 'upperCI', fill = 'Treatment'),
              alpha = 0.3) +
        geom_point(aes(x='DATI', y='mothsperday', color = 'Treatment'), 
            data = mean_cts, size = 1.1) +
        facet_wrap(['Location'], scales = "free_y") +
        scale_color_manual(values = mycolors) +
        scale_fill_manual(values = mycolors) +
        labs(title = "Poisson GLM predictions",
             subtitle = "Lines are predictions, points are the data",
             x = "Days after installation (DAI)",
             y = "Moth counts per day"))
# freqplot1p.save(filename='freqplot1p.png', path='output/')
freqplot1p.draw(True)
```

<div class="figure">
<img src="03-GLMMsInPython_files/figure-html/p1p-glmFigPy-1.png" alt="Poisson GLM predictions (Python)." width="100%" />
<p class="caption">(\#fig:p1p-glmFigPy)Poisson GLM predictions (Python).</p>
</div>

The model is such a bad fit to the data, it is hard to even tell what is going on in the figure above.

### Frequentist NB model {#nb1Py}

For the negative binomial (NB) model, our confidence intervals are a little wider, but we are still ignoring all the correlations in our data. And the plot of the predictions again indicates the lack of fit (Figure \@ref(fig:p1nb-glmFigPy)).


``` python
from scipy.stats import nbinom

form = """ nYSB ~ Treatment"""
y, X = dmatrices(form, datP, return_type = 'dataframe')
mod1nb = sm.NegativeBinomial(y,X, offset=np.log(datP["DaysOfCatch"]))
results1nb = mod1nb.fit()
```

``` python
# print(results1nb.summary())
```

#### Predictions


```
##      TR  lowerCI  upperCI
## 0  88.5     86.0     90.5
```

<div class="figure">
<img src="03-GLMMsInPython_files/figure-html/p1nb-glmFigPy-3.png" alt="Negative binomial GLM predictions (Python)." width="100%" />
<p class="caption">(\#fig:p1nb-glmFigPy)Negative binomial GLM predictions (Python).</p>
</div>

### Bayesian (bambi) model

`Bambi` is the Python module that is *very* similar to `brms` package in R. I am pretty sure the defaults use different algorithms though (which may affect your results), so be sure to read up on the details of both! However, both run `stan` on the back-end for the MCMC algorithms.

Because the models take a few minutes to fit, I usually fit them when I am initially running through my code, save them, and then only load the model fit when rendering the Rmarkdown file and creating the resulting figures.

`Bambi` creates InferenceData objects. Read the [reference guide](https://python.arviz.org/en/latest/getting_started/WorkingWithInferenceData.html#)-- it is very helpful!


``` python
# https://bambinos.github.io/bambi/notebooks/negative_binomial.html
import bambi as bmb
## build the model:
model_bmb1nb = bmb.Model("nYSB ~ Treatment + offset(log(DaysOfCatch))", 
                    datP, family="negativebinomial",
                    priors = {
                        "Intercept": bmb.Prior("Normal", mu = 0, sigma = 2),
                        "Treatment": bmb.Prior("Normal", mu = 0, sigma = 2),
                        "alpha": bmb.Prior("HalfCauchy", beta = 1)
                    })
filename = 'output/idata_bmb1nb.pkl'
```

``` python
## not run
import bambi as bmb
## fit the model:
idata_bmb1nb = model_bmb1nb.fit(tune = 500, draws=2000, chains=6, random_seed = 5000)
# tune = warmup; draws = iter
print(az.summary(idata_bmb1nb))

# save bambi object to file.
import pickle 
with open(filename, 'wb') as file:
    pickle.dump(idata_bmb1nb, file)
```


``` python
import arviz as az
import matplotlib.pyplot as plt 
import pickle

# Load the object from the file
with open(filename, 'rb') as file:
    idata_bmb1nb = pickle.load(file)

# to see the priors:
# model_bmb1nb

# summary stats
print(az.summary(idata_bmb1nb))
```

```
##                  mean     sd  hdi_3%  hdi_97%  mcse_mean  mcse_sd  ess_bulk  \
## alpha           0.656  0.035   0.588    0.721      0.000    0.000   17917.0   
## Intercept       1.402  0.067   1.276    1.530      0.000    0.001   18638.0   
## Treatment[Trt] -2.159  0.099  -2.343   -1.974      0.001    0.001   17245.0   
## 
##                 ess_tail  r_hat  
## alpha             8766.0    1.0  
## Intercept         9286.0    1.0  
## Treatment[Trt]   10039.0    1.0
```

The Bayesian parameter estimates match very closely to the frequentist estimates (copied here from Section 3.3.2):

The matching parameter estimates are expected, but reassuring that we have built the correct foundation for the more complicated models to come.

One difference however is that the frequentist model gives only a point estimate for the shape parameter while the Bayesian model gives us a distribution and therefore 95% credible intervals for the parameter.

#### Predictions


``` python
# CALC TR:
b1 = idata_bmb1nb.posterior["Treatment"].stack(sample=("chain", "draw")).to_dataframe(name = "Trt")

TR1nb = 100 * (1 - np.exp(b1['Trt']))
print(round(TR1nb.quantile(q=[0.025, 0.5, 0.975])))
```

```
## 0.025    86.0
## 0.500    88.0
## 0.975    90.0
## Name: Trt, dtype: float64
```

``` python
# Plot the predictions
# Make predictions of the mean without offset effect:
bmbPreds1nb = datP.copy() ## IMPORTANT DIFF FROM R!!!
## if newdf = olddf, changes to newdf affect olddf!!!
bmbPreds1nb["DaysOfCatch"] = 1
predictions1nb = model_bmb1nb.predict(idata_bmb1nb, data=bmbPreds1nb, kind = "response_params", inplace = False)
post1nb = predictions1nb.posterior
# post1nb
bmbPreds1nb["preds"] = post1nb.mean(dim=["chain", "draw"])["mu"].values
bmbPreds1nb["lowerCI"] = post1nb.quantile(dim=["chain", "draw"], q = 0.025)["mu"].values
bmbPreds1nb["upperCI"] = post1nb.quantile(dim=["chain", "draw"], q = 0.975)["mu"].values
# bmbPreds1nb.describe()

plot1nb = (ggplot(bmbPreds1nb, 
                aes(x = 'DATI', y='preds', color = 'Treatment')) +
        geom_line() +
        geom_ribbon(aes(ymin = 'lowerCI', ymax = 'upperCI', fill = 'Treatment'),
              alpha = 0.3) +
        geom_point(aes(x='DATI', y='mothsperday', color = 'Treatment'), 
            data = mean_cts, size = 1.1) +
        facet_wrap(['Location'], scales = "free_y") +
        scale_color_manual(values = mycolors) +
        scale_fill_manual(values = mycolors) +
        labs(title = "Bayes (bambi) NB GLM predictions",
             subtitle = "Lines are predictions, points are the data",
             x = "Days after installation",
             y = "Moth counts per day"))
# plot1nb.save(filename='plot1nb.png', path='output/')
# plot1nb.draw(True)
plot1nb.show()
```

<img src="03-GLMMsInPython_files/figure-html/nbBambi1TR-5.png" width="100%" />

The figure looks almost identical to the the frequent predictions (Figure 3.4). Comparisons of all TR estimates, coefficient estimates, and predicted moth counts can be found at the end of the page (Section 3.7.1).


### Bayesian (PyMC) models-- Python

For most needs, the `bambi` module should suffice. However, when building complicated non-linear functions with multi-dimensional Gaussian Processes, I may need a more foundational module-- PyMC. Therefore, I  also build the models using this module. Learning PyMC will also help with extracting derived parameters and predictions, etc. from bambi.


``` python
# NB Bayes:
#https://discourse.pymc.io/t/biased-results-from-poisson-regression-model/4349/5
import numpy as np
import pandas as pd

from formulae import design_matrices
import pymc as pm
# Create the design matrix using formulae
# Wrapping the variable in 'C()' enforces categorical values, with the first entry as the reference
dm = design_matrices('nYSB ~ C(Treatment)', data=datP, na_action='error')
# print(dm.common.as_dataframe().head())

# Expand out into X and y
X = dm.common.as_dataframe()
y = dm.response.as_dataframe().squeeze() # This ensures y is 1-dimensional. 

DaysOfCatch = datP['DaysOfCatch']

# Create labelled coords which help the model keep track of everything(i.e., use factor names)
c = {'predictors': X.columns, # Model now aware of number of and labels of predictors
     'N': range(len(y))} # and number of observations

with pm.Model(coords = c) as model_pymc1nb:
    # Set the data, and convert to NumPy arrays (to use matrix multiplication
    Xdata = pm.Data('Xdata', X.to_numpy())
    Ydata = pm.Data('Ydata', y.to_numpy())
    
    # priors
    # factor_coefs = pm.Normal('factor_coefs', mu=0, sigma=2, shape=len(X.columns))    
    beta = pm.Normal('beta', mu=0, sigma=2, dims = 'predictors')
    alpha = pm.HalfCauchy('alpha', beta = 1)

    # TR derived parameter:
    TR = pm.Deterministic('TR', 100 - 100 * np.exp(beta[1]))
    
    # likelihood:
    mu = pm.math.exp(Xdata @ beta + # pm.math.dot(X, factor_coefs) + #@ operator is for matrix multiplication 
                     np.log(DaysOfCatch)) 
    pm.NegativeBinomial('y', mu=mu, alpha = alpha, observed=Ydata)
    
    # Sample according to your specifications, but tune for longer and take fewer draws
    pymc1nb = pm.sample(draws=1000, tune=3000, cores=4, random_seed=45, step=pm.NUTS())#Metropolis())
    # pymc1nb is called 'trace' in lots of the help files


import pickle # to save PyMC object to file.
filename = 'output/respymc1nb.pkl'
# save bambi object to file.
with open(filename, 'wb') as file:
    pickle.dump(pymc1nb, file)
```


``` python
# Load the object from the file
import pickle
filename = 'output/respymc1nb.pkl'
with open(filename, 'rb') as file:
    pymc1nb = pickle.load(file)

# summary stats
print(az.summary(pymc1nb))
```

```
##                            mean     sd  hdi_3%  hdi_97%  mcse_mean  mcse_sd  \
## beta[Intercept]           1.402  0.067   1.279    1.532      0.001    0.001   
## beta[C(Treatment)[Trt]]  -2.160  0.099  -2.348   -1.981      0.002    0.001   
## alpha                     0.655  0.035   0.591    0.720      0.001    0.001   
## TR                       88.406  1.141  86.308   90.527      0.024    0.017   
## 
##                          ess_bulk  ess_tail  r_hat  
## beta[Intercept]            2275.0    2726.0    1.0  
## beta[C(Treatment)[Trt]]    2184.0    2559.0    1.0  
## alpha                      3165.0    2350.0    1.0  
## TR                         2184.0    2559.0    1.0
```

``` python
# CALC TR!
print(az.summary(pymc1nb, var_names=['TR']))
```

```
##       mean     sd  hdi_3%  hdi_97%  mcse_mean  mcse_sd  ess_bulk  ess_tail  \
## TR  88.406  1.141  86.308   90.527      0.024    0.017    2184.0    2559.0   
## 
##     r_hat  
## TR    1.0
```

``` python
# outTR1nb = round(TR1nb.quantile(q=[0.025, 0.5, 0.975]).to_pandas())
```


## Summary of estimates

### Compare TR estimates

Here, the trapping reduction estimates from all of the models are compared. As expected, the median TR estimates are very close from model to model, but the uncertainty in that estimate increase (i.e., the confidence/credible intervals get wider) when we properly account for the correlations in our data.


``` python
data = np.array([round(TR_1nb.quantile(q=[0.025, 0.5, 0.975]))) 
                 # round(TR2nb.quantile(q=[0.025, 0.5, 0.975])), 
                 # round(TR3nb.quantile(q=[0.025, 0.5, 0.975])),
                 # round(TR4nb.quantile(q=[0.025, 0.5, 0.975]))])

df = pd.DataFrame(data, columns = ["TR", "lowerCI", "upperCI"])
df["Model_name"] = ["GLM", "GLMM (location)", "GLMM (location, date)", "GLMM (location) with GP"]
df["Distribution"] = ["Neg Binomial", "Neg Binomial", "Neg Binomial", "Neg Binomial"]
df["Framework"] = ["Bayesian", "Bayesian", "Bayesian", "Bayesian"]
print(df[["Framework", "Distribution", "Model_name", "TR", "lowerCI", "upperCI"]])
```

### Compare coefficients

Because TR is a non-linear function of $\beta_1$, the differences in the model output get slightly distorted from the transformation. Thereofre, the $\beta_1$ coefficients are displayed as well:


``` python
dfB = pd.concat([az.summary(idata_bmb1nb, var_names=["Treatment"])[["mean", "sd"]],
az.summary(idata_bmb2nb, var_names=["Treatment"])[["mean", "sd"]]], ignore_index=True)

dfB = pd.concat([dfB,
az.summary(idata_bmb3nb, var_names=["Treatment"])[["mean", "sd"]]], ignore_index=True)
dfB = pd.concat([dfB,
az.summary(idata_bmb4nb, var_names=["Treatment"])[["mean", "sd"]]], ignore_index=True)
dfB

dfB["Model_name"] = ["GLM", "GLMM (location)", "GLMM (location, date)", "GLMM (location) with GP"]
dfB["Distribution"] = ["Neg Binomial", "Neg Binomial", "Neg Binomial", "Neg Binomial"]
dfB["Framework"] = ["Bayesian", "Bayesian", "Bayesian", "Bayesian"]
print(dfB[["Framework", "Distribution", "Model_name", "mean", "sd"]])
```


### Plot comparisons

Unfortunately, a drawback of using plotnine module is that you cannot readily draw figures sid-by-side.
