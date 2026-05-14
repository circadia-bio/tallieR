# Item-level long table

Returns a data frame with one row per participant × questionnaire
administration × item. Useful for factor analysis, IRT, or item-level
reliability checks.

## Usage

``` r
items_long(obj, include_meta = TRUE)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

- include_meta:

  Logical. If `TRUE` (default), participant metadata columns are
  included.

## Value

A `data.frame` with columns: participant metadata (optional),
`questionnaire_id`, `completed_at`, `item_id`, `response`.
