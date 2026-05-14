# Long score table

Returns a data frame with one row per participant × questionnaire ×
administration (i.e. all history is retained).

## Usage

``` r
scores_long(obj, include_meta = TRUE)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

- include_meta:

  Logical. If `TRUE` (default), participant metadata columns are
  included.

## Value

A `data.frame` with columns: participant metadata (optional),
`questionnaire_id`, `completed_at`, `score`.
