
<!-- README.md is generated from README.Rmd. Please edit that file -->

# xrayspecs

<!-- badges: start -->

<!-- badges: end -->

The goal of xrayspecs is to display model-agnostic iterpretations of
black-box models.

## Installation

You cannot currently install xrayspecs from
[CRAN](https://CRAN.R-project.org). However, you can install the
development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("mt-edwards/xrayspecs")
```

## Example

``` r
library(xrayspecs)
```

### Data set

The `mtcars` data set is used for this example. The `dplyr` package is
used to transform the categorical features (`cyl`, `vs`, `am`, `gear`
and `carb`) to factors. These trasformations are required so that the
`dependence_plot` function knows how to plot the feature predictions.
For example, the predictions of continuous features are displayed with
line plots and the predictions of categorical features are displayed
with bar plots.

``` r
library(dplyr)

mtcars <- mtcars %>% 
  mutate(
    cyl = factor(cyl),
    vs = factor(vs),
    am = factor(am),
    gear = factor(gear),
    carb = factor(carb)
  )
```

### Random forest and linear regression models

A [random forest](https://en.wikipedia.org/wiki/Random_forest) and a
[linear regression](https://en.wikipedia.org/wiki/Linear_regression)
model are fit to the `mtcars` data set using the `parsnip` package. The
`parsnip` package provides a unified framework for fitting models in
`R`. The models that are available for fitting in `parsnip` are listed
[here](https://tidymodels.github.io/parsnip/articles/articles/Models.html).
The `xrayspecs` package is designed to integrate into the `parsnip`
package’s unified framework.

``` r
library(parsnip)

# Random forest
rf <- rand_forest(mode = "regression") %>% 
  set_engine("ranger") %>% 
  fit(mpg ~ ., data = mtcars)

# Linear regression
lr <- linear_reg() %>% 
  set_engine("lm") %>% 
  fit(mpg ~ ., data = mtcars)
```

### Permutation importance plot

To display a [permutation
importance](https://christophm.github.io/interpretable-ml-book/feature-importance.html)
plot of the random forest and linear regression features all you need to
do is pipe the `rf` and `lr` objects into the `importance_plot` function
along with the data set (`mtcars`). Multiple plots are displayed using
the `cowplot` package.

``` r
library(cowplot)

# Random forest
p1 <- rf %>% 
  importance_plot(mtcars) +
  labs(subtitle = "Random Forest")

# Linear regression
p2 <- lr %>% 
  importance_plot(mtcars) +
  labs(subtitle = "Linear Regression")

plot_grid(p1, p2)
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

### Partial dependence plot

To display a [partial
dependence](https://christophm.github.io/interpretable-ml-book/pdp.html)
plot of a random forest feature all you need to do is pipe the `rf`
object into the `dependence_plot` function along with the data set
(`mtcars`) and the name of the feature. Here the the partial dependece
plots of the most “important” continuous and categorical features (`wt`
and `cyl`) are displayed.

``` r
# Random forest
p1 <- rf %>% 
  dependence_plot(mtcars, wt) +
  labs(subtitle = "Random Forest")

# Linear regression
p2 <- lr %>% 
  dependence_plot(mtcars, wt) +
  labs(subtitle = "Linear Regression")

plot_grid(p1, p2)
```

<img src="man/figures/README-unnamed-chunk-6-1.png" width="100%" />

``` r
# Random forest
p1 <- rf %>% 
  dependence_plot(mtcars, cyl) +
  labs(subtitle = "Random Forest")

# Linear regression
p2 <- lr %>% 
  dependence_plot(mtcars, cyl) +
  labs(subtitle = "Linear Regression")

plot_grid(p1, p2)
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />
