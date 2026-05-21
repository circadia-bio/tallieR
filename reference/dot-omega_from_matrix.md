# Compute McDonald's omega (total) from a numeric item matrix

Uses a single-factor EFA via
[`stats::factanal()`](https://rdrr.io/r/stats/factanal.html) to extract
factor loadings, then applies the omega_t formula:
`omega = (sum(lambda))^2 / ((sum(lambda))^2 + sum(1 - lambda^2))` where
`lambda` are the standardised factor loadings.

## Usage

``` r
.omega_from_matrix(mat)
```

## Arguments

- mat:

  A numeric matrix (participants x items), complete cases only.

## Value

Named list with `omega`, `n_items`, `n_obs`, `note`.
