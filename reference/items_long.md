# Item-level long table

Returns a data frame with one row per participant × questionnaire
administration × item. Useful for factor analysis, IRT, or item-level
reliability checks.

## Usage

``` r
items_long(obj, include_meta = TRUE, scored_items = FALSE, instruments = NULL)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

- include_meta:

  Logical. If `TRUE` (default), participant metadata columns are
  included.

- scored_items:

  Logical. If `TRUE`, adds a `response_scored` column with
  reverse-scored values applied for instruments that define
  `reverse_items` (currently STAI-S and STAI-T). For all other items and
  instruments, `response_scored` equals `response`. Non-numeric
  responses (e.g. clock-time lists, yes/no) are left as-is. Defaults to
  `FALSE` to preserve existing behaviour.

- instruments:

  An optional named list of additional registry entries from
  [`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)
  or
  [`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md),
  used when `scored_items = TRUE` to resolve reverse-scoring metadata
  for custom instruments.

## Value

A `data.frame` with columns: participant metadata (optional),
`questionnaire_id`, `completed_at`, `item_id`, `response`, and
optionally `response_scored`.
