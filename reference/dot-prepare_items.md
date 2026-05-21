# Validate and prepare item-level data for reliability functions

Shared internal helper used by
[`cronbach_alpha()`](https://tallier.circadia-lab.uk/reference/cronbach_alpha.md)
and
[`omega_reliability()`](https://tallier.circadia-lab.uk/reference/omega_reliability.md).
Accepts either a tallier object or a pre-built
[`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md)
data frame, validates required columns, optionally filters to a subset
of questionnaires, and warns about unknown IDs.

## Usage

``` r
.prepare_items(obj, questionnaires, empty_fn)
```

## Value

A list with `items` (data frame) and `all_qs` (character vector of
questionnaire IDs to process), or calls
[`rlang::warn`](https://rlang.r-lib.org/reference/abort.html)/[`rlang::abort`](https://rlang.r-lib.org/reference/abort.html)
and returns `NULL` when the input is invalid or empty.
