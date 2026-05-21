# Pivot items for one questionnaire into a participant x item matrix

Extracts numeric items from a filtered
[`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md)
slice, drops items that cannot be coerced to numeric (e.g. MCTQ time
lists, STOP-BANG yes/no), and keeps only complete cases.

## Usage

``` r
.items_to_matrix(df, min_numeric = 0.5)
```

## Arguments

- df:

  A data frame as produced by
  [`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md)
  filtered to one `questionnaire_id`.

- min_numeric:

  Minimum fraction of items that must be numeric to proceed (default
  0.5). If fewer items survive, returns `NULL`.
