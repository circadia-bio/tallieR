# Wide score table

Returns a data frame with one row per participant and one column per
questionnaire. When a participant completed a questionnaire more than
once, only the most recent administration is included (use
[`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)
to retain all administrations).

## Usage

``` r
scores_wide(obj, include_meta = TRUE)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

- include_meta:

  Logical. If `TRUE` (default), participant metadata columns (code,
  name, age, sex, etc.) are prepended.

## Value

A `data.frame` with columns: participant metadata (if requested)
followed by one score column per questionnaire. For most instruments the
column is numeric. For composite instruments (PSQI, MCTQ, DASS-21,
PANSS, WHOQOL-BREF) the column contains the primary summary scalar: the
global score for PSQI, total for DASS-21/PANSS/WHOQOL-BREF, and MSFsc
for MCTQ. Use
[`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)
followed by a join with
[`interpret_all()`](https://tallier.circadia-lab.uk/reference/interpret_all.md)
to access all subscale components.

## Examples

``` r
if (FALSE) { # \dontrun{
study <- read_scoreme_dir("exports/")
wide  <- scores_wide(study)
head(wide)
} # }
```
