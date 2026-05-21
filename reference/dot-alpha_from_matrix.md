# Compute Cronbach's alpha from a numeric item matrix

Compute Cronbach's alpha from a numeric item matrix

## Usage

``` r
.alpha_from_matrix(mat, conf_level = 0.95)
```

## Arguments

- mat:

  A numeric matrix (participants × items) with no missing columns left
  after `na_action`.

- conf_level:

  Confidence level for the CI.

## Value

Named list with `alpha`, `n_items`, `n_obs`, `ci_lower`, `ci_upper`.
