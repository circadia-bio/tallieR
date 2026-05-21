# Completion summary

Returns a data frame showing which questionnaires each participant has
completed. Useful for monitoring data collection progress in
longitudinal or multi-site studies.

## Usage

``` r
completion_summary(obj, wide = FALSE, include_date = TRUE, include_meta = TRUE)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

- wide:

  Logical. If `FALSE` (default), returns a long data frame with one row
  per participant × questionnaire and a `completed` logical column. If
  `TRUE`, returns a wide data frame with one row per participant and one
  logical column per questionnaire.

- include_date:

  Logical. If `TRUE` (default), adds a `completed_at` column in long
  format showing the timestamp of the most recent administration.
  Ignored when `wide = TRUE`.

- include_meta:

  Logical. If `TRUE` (default), participant metadata columns are
  prepended.

## Value

In long format: a `data.frame` with columns: participant metadata
(optional), `questionnaire_id`, `completed` (logical, `FALSE` — not `NA`
— for questionnaires the participant never started), and optionally
`completed_at` (character timestamp of most recent administration; `NA`
when `completed = FALSE`). In wide format: a `data.frame` with one row
per participant and one logical column per questionnaire (`FALSE`
indicates not completed).

## Details

When a participant has completed a questionnaire more than once, it is
counted as complete and the most recent `completed_at` timestamp is
reported (when `include_date = TRUE`).

## See also

[`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md),
[`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)

## Examples

``` r
if (FALSE) { # \dontrun{
study <- read_scoreme_dir("exports/")

# Long format: one row per participant x questionnaire
completion_summary(study)

# Wide format: one row per participant
completion_summary(study, wide = TRUE)

# Without timestamps
completion_summary(study, include_date = FALSE)
} # }
```
