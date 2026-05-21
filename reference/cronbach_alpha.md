# Cronbach's alpha for one or more questionnaires

Computes Cronbach's alpha (a measure of internal consistency) for each
questionnaire present in a `tallier_export` or `tallier_study` object.
Item-level responses are extracted via
[`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md),
coerced to numeric, and a participant × item matrix is constructed per
questionnaire.

## Usage

``` r
cronbach_alpha(obj, questionnaires = NULL, conf_level = 0.95, min_items = 2L)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object, or a data frame as
  returned by
  [`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md)
  (must contain columns `participant_id`, `questionnaire_id`, `item_id`,
  `completed_at`, `response`).

- questionnaires:

  Character vector of questionnaire IDs to include. Defaults to all
  questionnaires present in `obj`.

- conf_level:

  Numeric. Confidence level for the CI (default `0.95`). Uses the exact
  F-distribution method of Feldt et al. (1987).

- min_items:

  Integer. Minimum number of numeric items required to attempt
  estimation (default `2`).

## Value

A `data.frame` with one row per questionnaire and columns:

- questionnaire_id:

  Questionnaire identifier.

- alpha:

  Cronbach's alpha (standardised scale: −∞ to 1).

- ci_lower:

  Lower bound of the `conf_level` CI.

- ci_upper:

  Upper bound of the `conf_level` CI.

- n_items:

  Number of numeric items used.

- n_obs:

  Number of complete observations (participants).

- note:

  `NA` on success, or a short message explaining why estimation failed.

## Details

Non-numeric items (e.g. MCTQ clock times, STOP-BANG yes/no) are silently
dropped before estimation. Questionnaires with fewer than 2 numeric
items or fewer than 2 complete observations return `NA` with an
explanatory note.

## References

Cronbach, L. J. (1951). Coefficient alpha and the internal structure of
tests. *Psychometrika*, 16(3), 297–334.
[doi:10.1007/BF02310555](https://doi.org/10.1007/BF02310555)

Feldt, L. S., Woodruff, D. J., & Salih, F. A. (1987). Statistical
inference for coefficient alpha. *Applied Psychological Measurement*,
11(1), 93–103.
[doi:10.1177/014662168701100107](https://doi.org/10.1177/014662168701100107)

## Examples

``` r
if (FALSE) { # \dontrun{
study <- read_scoreme_dir("exports/")

# All questionnaires
cronbach_alpha(study)

# Specific subset
cronbach_alpha(study, questionnaires = c("ess", "isi", "phq9"))

# From an items_long() data frame (e.g. already filtered)
items <- items_long(study)
cronbach_alpha(items)
} # }
```
