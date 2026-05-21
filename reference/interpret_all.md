# Interpret all questionnaire scores in an export

Returns a long data frame with one row per participant x questionnaire x
administration, augmented with clinical interpretation columns (`label`,
`color`, `description`). Mirrors the shape of
[`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)
so the two can be joined by `participant_id` + `questionnaire_id` +
`completed_at`.

## Usage

``` r
interpret_all(obj, include_meta = TRUE, instruments = NULL)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

- include_meta:

  Logical. If `TRUE` (default), participant metadata columns are
  prepended (same columns as
  [`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)).

- instruments:

  An optional named list of additional registry entries from
  [`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)
  or
  [`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md).

## Value

A `data.frame` with columns: participant metadata (optional),
`questionnaire_id`, `completed_at`, `score`, `label`, `color`,
`description`.

## Details

Scores that cannot be interpreted (unknown instrument, `NA` score, or
composite score with no matching band) return `NA` in all three
interpretation columns rather than an error, so the rest of the study
data is unaffected.

## See also

[`interpret_score()`](https://tallier.circadia-lab.uk/reference/interpret_score.md),
[`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)

## Examples

``` r
if (FALSE) { # \dontrun{
study <- read_scoreme_dir("exports/")
interps <- interpret_all(study)

# Join with scores_long() if you need both
scores <- scores_long(study)
full   <- merge(scores, interps[
  c("participant_id", "questionnaire_id", "completed_at",
    "label", "color", "description")
], by = c("participant_id", "questionnaire_id", "completed_at"),
  all.x = TRUE)
} # }
```
