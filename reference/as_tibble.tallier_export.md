# Coerce a tallier_export to a tibble

Converts a `tallier_export` object to a tibble by calling
[`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md)
and coercing the result. One row per participant, one column per
questionnaire, with participant metadata prepended by default.

## Usage

``` r
as_tibble.tallier_export(x, ...)
```

## Arguments

- x:

  A `tallier_export` object.

- ...:

  Additional arguments passed to
  [`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md)
  (e.g. `include_meta = FALSE`).

## Value

A tibble; see
[`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md)
for column details.

## Details

This method is registered for
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
and is available automatically when the `tibble` package is loaded.

## Examples

``` r
if (FALSE) { # \dontrun{
exp <- read_scoreme("export.json")
tibble::as_tibble(exp)
tibble::as_tibble(exp, include_meta = FALSE)
} # }
```
