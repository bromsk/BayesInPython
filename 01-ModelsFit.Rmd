# Mathematical models

These are the models fit to our data.

For a good reference on additional details related to GLMM's, check [here](https://bbolker.github.io/mixedmodels-misc/glmmFAQ).

## GLM models {#glm}

The first model ignores all the spatial and temporal relationships in the data and assumes each data point is independent and identically distributed (_iid_). **This is not a good model for the data!** It is just our starting off point.

When building hierarchical Bayesian models, it is always a good idea to start simple, make sure everything works as expected, and then build up.

Our response variable is a count, therefore we use either a Poisson or negative binomial distribution as the basis for our model. These models are known as generalized linear models (GLMs).
 
The model includes an offset to account for the varying time intervals between sample. (If the traps are left unchecked for more days, we naturally expect the traps to have more moths. This varying effort is accounted for by the offset.)

See Section \@ref(fit-glmR) for the associated model fits in R.

### Poisson regression model

We start with a Poisson regression model:

$$
y_i \sim Pois(\lambda_i) \\
log(\lambda_i ) = \beta_0 + \beta_1 x_{Trt, i} + \mbox{ln} \left(DaysOfCatch_i\right)
$$

where, for data samples $i = 1, ..., N$, 

$y_i$ is moth count $i$,

$\lambda_i$ is the expected moth count for sample $i$,

$\beta_0$ is the intercept of the model. Here, it provides the expected moth count for our control treatment.

$\beta_1$ is the expected difference in moth counts between the control group and the treatment group, 

$x_{Trt, i}$ is an indicator variable that equals 1 if sample $i$ is from a treatment field and equals 0 otherwise, and

$DaysOfCatch_i$ is the offset to account for the varying time interval between samples. This is necessary because with a longer time interval, more moths will fly into the trap.

### Negative binomial regression model

In ecology, there is always additional variability in our data than what the Poisson distribution allows. To account for the additional variability in our data, we switch the model to a negative binomial distribution:

$$
y_i \sim NegBinom(\lambda_i, \theta) \\
log(\lambda_i ) = \beta_0 + \beta_1 x_{Trt,i} + \mbox{ln} \left(DaysOfCatch_i\right)
$$

"Negative binomial regression is used to model count data for which the variance is higher than the mean." (https://www.pymc.io/projects/examples/en/latest/generalized_linear_models/GLM-negative-binomial-regression.html)

(Alternatively, we could fit over-dispersed Poisson regressions or quasi-Poisson regressions. A zero-inflated model or a Tweedie distribution may also be appropriate and worth assessing. None of these options are pursued further in the tutorial because they are not a part of the objectives here.)

For the negative binomial regression, all variables and parameters are defined as before, but the model has an additional parameter, $\theta$, that allows for the additional variation. The negative binomial distribution and regression model can be written in many ways. In our models, $\theta$ is defined through the following formula where the variance associated with an expected moth count, $\lambda$, is:

$$
Var(\lambda) = \lambda + \frac{\lambda^2}{\theta}
$$

(For a Poisson distribution, $Var(\lambda) = \lambda$.)

Here, small values for $\theta$ will lead to extra variability in the response variable, i.e., our counts. 

(https://cran.r-project.org/web/packages/pscl/vignettes/countreg.pdf)

### Bayesian model

Using a Bayesian framework here builds the foundation for the more complex models that come later.

For the Bayesian models, I only show the negative binomial version.

To make our models Bayesian, we add priors to our parameters:

$$
y_i \sim NegBinom(\lambda_i, \theta) \\
log(\lambda_i ) = \beta_0 + \beta_1 x_{Trt,i} + \mbox{ln} \left(DaysOfCatch_i\right) \\
\beta_0 \sim Normal(0, 2) \\
\beta_1 \sim Normal(0, 2) \\
\theta \sim HalfCauchy(0,1)
$$

The models use slightly informative priors. When working on a log-scale (e.g., with Poisson or negative binomial distributions), this often becomes essential to avoid parameter estimates on the boundaries. (See Hooten and Hobbs (2015)^[Hobbs, N.T. and Hooten, M.B. *Bayesian Models: A Statistical Primer for Ecologists.* Princeton University Press, 2015.] for a good discussion on this issue.) Normal distributions are the typical choice for the regression coefficients; and the half-Cauchy distribution for the $\theta$ parameter allows for a diffuse distribution.


### Trapping reduction defined {#defineTR}

As a reminder, the primary metric of interest from these models is a derived parameter that we call trapping reduction (TR):

$$
TR = 100 - 100 e ^{(-\beta_1)}
$$

To obtain a 95% confidence interval for TR (for the frequentist version of our model), we use the following approximation:

$$
TR = 100 - 100 e ^{(-\beta_1 \pm 2 \cdot SE(\beta_1))}
$$

For the Bayesian version, the derived parameter is sampled as part of the MCMC iterations, and the 95% credible interval is the 2.5%, 97.5% quantiles of its resulting distribution.

## GLMM: Random effects (RE) for locations {#glmm}

The first fix we make to the model is acknowledging that overall average moth population pressure vary from location to location (see Figure \@ref(fig:mothctsFig) of moth counts). In other words, some locations have more moths than others. To add this information to the model, we add a location random effect (RE) and our model becomes a generalized linear mixed-effects model (GLMM or GLMER).

We also want to acknowledge that the treatment effect may vary from location to location-- sometimes we see a big difference in moth counts between control and treatment fields, and sometimes the difference is smaller. For inference though, we are only interested in the larger picture, which is the overall trapping reduction. (We are not interested in what happens at these exact locations per se, we are more interested in the average, expected treatment effect at a new location.) Therefore, we also add a treatment random effect to the model (random slopes).

See Section \@ref(fit-glmmR) for the associated model fits in R.


### GLMM mathematical model

Going forward, I only show the negative binomial (NB) regression models, the Poisson versions are straightforward extensions.

$$
y_{ik} \sim NegBinom(\lambda_{ik}, \theta) \\
log(\lambda_{ik} ) = \beta_0 + \beta_1 x_{Trt,i} + \gamma_{0k} x_{ik}  + \gamma_{1k} x_{Trt,i} x_{ik} + \mbox{ln} \left(DaysOfCatch_i\right) \\
\boldsymbol\gamma_{k} \sim Normal(\mathbf{0}, \Sigma) \\
$$

where, in addition to the variables and parameters defined for the GLM, we have

$k = 1,..., K=10$ represents the locations, 

$y_{ik}$ is moth count $i$ from location $k$,

$\lambda_{ik}$ is the expected moth count for sample $i$  from location $k$,

$\beta_0$ provides the expected moth count for the control group at a new location,

$\beta_1$ provides the expected difference in moth counts between the control group and the treatment group at a new location, 

$\gamma_{0k}$ is the random intercept associated with location $k$, which leads to different _background (control group) moth pressures_ at each location. The $\gamma_{0k}$ come from a Normal distribution.

$\gamma_{1k}$ is the random slope associated with location $k$, which leads to different _treatment_ effects at each location. The $\gamma_{1k}$ come from a Normal distribution, and

$x_{ik}$ is an indicator variable that equals 1 if moth count $i$ is associated with location $k$ and 0 otherwise.

The distributions for the $\gamma_{0k}$ and the $\gamma_{1k}$ are combined into a multivariate Normal distribution to reflect the correlation that exists between them. (The model may also be specified with uncorrelated intercept and slope, see [here](https://bbolker.github.io/mixedmodels-misc/glmmFAQ.html#model-specification)).


### Bayesian version

Here is the same model within a Bayesian framework. To make our models Bayesian, we add priors to our parameters.

Model:

$$
y_{ik}\sim NegBinom(\lambda_{ik}, \theta) \\
log(\lambda_{ik} ) = \beta_0 + \beta_1 x_{Trt,i} + \gamma_{0k} x_{ik}  + \gamma_{1k} x_{Trt,i} x_{ik} + \mbox{ln} \left(DaysOfCatch_i\right) \\ 
\boldsymbol\gamma_{k} \sim Normal(\mathbf{0}, \Sigma_k) \\
$$

<!-- $\Sigma = \begin{pmatrix}\sigma_0^2 & \rho \\\rho & \sigma_1^2 \end{pmatrix}$. -->

where $\Sigma_k = D(\boldsymbol\sigma)\Omega D(\boldsymbol\sigma)$,
$D(\boldsymbol\sigma) = \begin{pmatrix}\sigma_0^2 & 0 \\ 0 & \sigma_1^2 \end{pmatrix}$. 

Priors:

$$
\boldsymbol\beta \sim Normal(\mathbf{0}, 2\mathbf{I}) \\
\Omega \sim LKJ(\zeta = 1) \\
\sigma^2_{0} \sim HalfCauchy(0,1) \\
\sigma^2_{1} \sim HalfCauchy(0,1) \\
\theta \sim HalfCauchy(0,1) \\
$$

In the `brms` package used to fit the models, the default setting is for the random effects to be correlated, which matches the `glmer`, `glmer.nb` functions from the `lme4` package, which is typically used to fit frequentist GLMM's in R, and is the model shown here. See the `brms` [vignette](https://cran.r-project.org/web/packages/brms/vignettes/brms_overview.pdf) for a description of the LKJ distribution. It is the default distribution that they use for this parameter, which is why this prior is chosen here.



The priors for the $\boldsymbol\beta$ coefficients can equivalently be written:

$$
\beta_0 \sim Normal(0, 2) \\
\beta_1 \sim Normal(0, 2) \\
$$


<!-- $$ -->
<!-- \mathbf{Y} \sim NegBinom(\boldsymbol\lambda, \phi) \\ -->
<!-- log(\boldsymbol\lambda) = \mathbf{X}\boldsymbol\beta + \mathbf{Z}\boldsymbol\gamma  + \mbox{ln} \left(\bf{DaysOfCatch}\right) \\ -->
<!-- \boldsymbol\beta \sim Normal(\mathbf{0}, 2\mathbf{I}) \\ -->
<!-- \boldsymbol\gamma \sim Normal(\mathbf{0}, \boldsymbol\sigma^2 \mathbf{I}) \\ -->
<!-- \boldsymbol\sigma^2 \sim HalfCauchy(\mathbf{0}, 1\mathbf{I})) \\ -->
<!-- \phi \sim HalfCauchy(0,1) -->
<!-- $$ -->


## GLMM: RE for Location, SamplingDate {#glmm-dates}

In this version of the model, we acknowledge that sampling on different days of the season adds to the variability of the moth counts, and that counts from the same sampling date are more similar than for a different date. In this model, however,  the correlation between sampling dates is ignored.

This model is included here because it is important to think about whether you have nested or crossed random effects (if applicable) ([Good nested vs crossed reference](https://stats.stackexchange.com/questions/228800/crossed-vs-nested-random-effects-how-do-they-differ-and-how-are-they-specified)). Here, we are assuming crossed random effects because Java island (i.e., Indonesia) is fairly homogeneous in terms of weather and ecosystem, and the rice for our trials are generally transplanted within a couple of weeks of each other, so it makes sense for all samples from one date to be considered one group, regardless of location. For example, the moth populations of the island tend to peak on certain dates and then decrease as the rice matures.

This model allows us to include sampling date in our model as a random effect and still fit the model quickly in a frequentist framework. 

We include dates in our model because samples within a date will be more similar than samples across all dates at a location. We only include random intercepts, and do not add a random effect for date X treatment effect.

See Section \@ref(fit-glmm-datesR) for the associated model fits in R.

### Frequentist version

$$
y_{ikj} \sim NegBinom(\lambda_{ikj}, \theta) \\
log(\lambda_{ikj} ) = \beta_0 + \beta_1 x_{Trt,i} + \gamma_{0k} x_{ik}  + \gamma_{1k} x_{Trt,i} x_{ik}  + \gamma_{00j} x_{ij}  + \mbox{ln} \left(DaysOfCatch_i\right) \\
\boldsymbol\gamma_{k} \sim Normal(\mathbf{0}, \Sigma) \\
\gamma_{00j} \sim Normal(0, \sigma^2_{00}) \\
$$

where, in addition to the variables and parameters defined previously, we have

$k = 1,..., K=10$ represents the locations, 

$j = 1, ..., J = 62$ represents the unique sampling dates,

$y_{ikj}$ is moth count $i$ from location $k$ on date $j$,

$\lambda_{ikj}$ is the expected moth count for sample $i$  from location $k$ on date $j$,

$\beta_0$ provides the expected moth count for the control field for a new location,

$\beta_1$ provides the expected difference in moth counts between the control group and the treatment group for a new location, 

$\gamma_{0k}$ is the random intercept associated with location $k$, which leads to different background moth pressures at each location,

$\gamma_{1k}$ is the random slope associated with location $k$, which leads to a different treatment effect at each location, 

$x_{ik}$ is an indicator variable that equals 1 if moth count $i$ is associated with location $k$ and 0 otherwise,

$\gamma_{00j}$ is the random intercept associated with date $j$, which leads to different background moth pressures for each date, and 

$x_{ij}$ is an indicator variable that equals 1 if moth count $i$ is associated with date $j$ and 0 otherwise.

Note that the crossed random effect (sampling date) is not correlated with the intercept and slope random effects associated with location.

### Bayesian version

Model:

$$
y_{ik}\sim NegBinom(\lambda_{ik}, \theta) \\
log(\lambda_{ikj} ) = \beta_0 + \beta_1 x_{Trt,i} + \gamma_{0k} x_{ik}  + \gamma_{1k} x_{Trt,i} x_{ik}  + \gamma_{00j} x_{ij}  + \mbox{ln} \left(DaysOfCatch_i\right) \\
\boldsymbol\gamma_{k} \sim Normal(\mathbf{0}, \Sigma_k) \\
\Sigma_k = \begin{pmatrix}\sigma_0^2 & 0 \\ 0 & \sigma_1^2 \end{pmatrix}\Omega \begin{pmatrix}\sigma_0^2 & 0 \\ 0 & \sigma_1^2 \end{pmatrix} \\
\gamma_{00j} \sim Normal(0, \sigma^2_{00}) \\
$$

With the following priors:

$$
\boldsymbol\beta \sim Normal(\mathbf{0}, 2\mathbf{I}) \\
\Omega \sim LKJ(\zeta = 1) \\
\sigma^2_{0} \sim HalfCauchy(0,1) \\
\sigma^2_{1} \sim HalfCauchy(0,1) \\
\sigma^2_{00} \sim HalfCauchy(0,1) \\
\theta \sim HalfCauchy(0,1) \\
$$

<!-- $$ -->
<!-- \mathbf{Y} \sim NegBinom(\boldsymbol\lambda, \phi) \\ -->
<!-- log(\boldsymbol\lambda) = \mathbf{X}\boldsymbol\beta + \mathbf{Z}\boldsymbol\gamma  + \mathbf{z_{00}}\gamma_{00}  + \mbox{ln} \left(\bf{DaysOfCatch}\right) \\ -->
<!-- \boldsymbol\beta \sim Normal(\mathbf{0}, 2\mathbf{I}) \\ -->
<!-- \boldsymbol\gamma \sim Normal(\mathbf{0}, \boldsymbol\sigma^2 \mathbf{I}) \\ -->
<!-- \gamma_{00} \sim Normal(0, \sigma^2) \\ -->
<!-- \boldsymbol\sigma^2 \sim HalfCauchy(\mathbf{0}, 1\mathbf{I})) \\ -->
<!-- \sigma^2_{00} \sim HalfCauchy(0,1) \\ -->
<!-- \phi \sim HalfCauchy(0,1) -->
<!-- $$ -->


## GLMM with Gaussian Processes: RE for Trial, GP for Date {#glmm-gp}

Now we are in the territory where we _have_ to fit the models in a Bayesian framework. If our response variable was continuous (i.e., the regression model was based on a Normal distribution), then we could still use maximum likelihood estimation, but the theorems (i.e., CLT) and approximations do not extend to all exponential family distributions.

See Section \@ref(fit-glmm-gpR) for the associated model fits in R.


### Bayesian mathematical model

Model:

$$
y_{ijk} \sim NegBinom(\lambda_{ijk}, \theta) \\
log(\lambda_{ikj} ) = \beta_0 + \beta_1 x_{Trt,i} + \gamma_{0k} x_{ik}  + \gamma_{1k} x_{Trt,i} x_{ik}  + GP_{ijk}  + \mbox{ln} \left(DaysOfCatch_i\right) \\
\boldsymbol\gamma \sim Normal(\mathbf{0}, \boldsymbol\Sigma_{\gamma}) \\ 
\Sigma_{\gamma} = \begin{pmatrix}\sigma_0^2 & 0 \\ 0 & \sigma_1^2 \end{pmatrix}\Omega \begin{pmatrix}\sigma_0^2 & 0 \\ 0 & \sigma_1^2 \end{pmatrix} \\
\mathbf{GP_k} \sim MVN(0, \boldsymbol\Sigma_k) \\
$$
Priors:

$$
\boldsymbol\beta \sim Normal(\mathbf{0}, 2\mathbf{I}) \\
\Omega \sim LKJ(\zeta = 1) \\
\sigma^2_{0} \sim HalfCauchy(0,1) \\
\sigma^2_{1} \sim HalfCauchy(0,1) \\
\Sigma_{k} = \tau_k \cdot e^{-\frac{|d_l - d_m|^2}{l_k^2}} \\
\tau_k \sim Normal(0, 2, lb = 0) \\
l_k \sim HalfCauchy(0, 1) \\
\theta \sim HalfCauchy(0,1) \\
$$

where, in addition to the variables and parameters defined previously, we have

$k = 1,..., K=10$ represents the locations, 

$j = 1, ..., J = 62$ represents the unique dates,

$y_{ikj}$ is moth count $i$ from location $k$ on date $j$,

$\lambda_{ikj}$ is the expected moth count for sample $i$  from location $k$ on date $j$,

$\beta_0$ is the expected moth count for the control treatment for a new location,

$\beta_1$ is the expected difference in moth counts between the control group and the treatment group for a new location, 

$\gamma_{0k}$ is the random intercept associated with location $k$, which leads to different background moth pressures at each location,

$\gamma_{1k}$ is the random slope associated with location $k$, which leads to different treatment effects at each location, 

$x_{ik}$ is an indicator variable that equals 1 if moth count $i$ is associated with location $k$ and 0 otherwise,

$\Sigma_{\gamma}$ is the matrix of variances and correlations associated with the random effects,

$\mathbf{GP_k}$ is the matrix of Gaussian Process (GP) effects for location $k$ where each GP cell is a function of the general noise of the data and how close two data points are to each other,

$\tau_k$ is the standard deviation of $GP_k$ which determines how noisy the relationship is between data points for location $k$,

$l_k$ is length-scale associated with location $k$ which determines how far the correlation extends to, and

$\theta$ is our shape parameter for the NB distribution.

Some notes on this model:

* Using squared-exponential covariance function (quite typical choice).

* We have a different Gaussian Process (GP) for each location (each location has its own parameters for the function). This is done to further account for expected differences between locations. 

* I have skimmed over _many_ decisions in reaching this model. PLease be in touch if you would like to discuss any of them in detail!


