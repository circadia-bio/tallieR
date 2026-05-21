# Coerce a tallier_study to a tibble

Converts a `tallier_study` object to a tibble by calling
[`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md)
and coercing the result. One row per participant, one column per
questionnaire, with participant metadata prepended by default.

## Usage

``` r
as_tibble.tallier_study(x, ...)
```

## Arguments

- x:

  A `tallier_study` object.

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
study <- read_scoreme_dir("exports/")
tibble::as_tibble(study)
} # }
```
