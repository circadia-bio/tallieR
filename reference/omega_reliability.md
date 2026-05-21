# McDonald's omega for one or more questionnaires

Computes McDonald's omega (\\\omega_t\\, total omega) as a measure of
internal consistency for each questionnaire present in a
`tallier_export` or `tallier_study` object. Omega is generally preferred
over Cronbach's alpha for non-tau-equivalent items (i.e. items with
unequal factor loadings), which is the norm in most psychological
questionnaires.

## Usage

``` r
omega_reliability(obj, questionnaires = NULL, min_items = 2L)
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

- min_items:

  Integer. Minimum number of numeric items required to attempt
  estimation (default `2`).

## Value

A `data.frame` with one row per questionnaire and columns:

- questionnaire_id:

  Questionnaire identifier.

- omega:

  McDonald's omega_t. Range: 0 to 1.

- n_items:

  Number of numeric items used.

- n_obs:

  Number of complete observations (participants).

- note:

  `NA` on success, or a short message explaining why estimation failed.

## Details

Estimation uses a single-factor EFA via
[`stats::factanal()`](https://rdrr.io/r/stats/factanal.html). The
formula applied is: \$\$\omega_t = \frac{(\sum \lambda_i)^2}{(\sum
\lambda_i)^2 + \sum(1 - \lambda_i^2)}\$\$ where \\\lambda_i\\ are the
standardised factor loadings.

Non-numeric items (e.g. MCTQ clock times, STOP-BANG yes/no) are silently
dropped before estimation. Questionnaires with fewer items than
observations, fewer than 2 numeric items, or non-convergent factor
solutions return `NA` with an explanatory note.

## References

McDonald, R. P. (1999). *Test theory: A unified treatment*. Lawrence
Erlbaum Associates.

Revelle, W., & Zinbarg, R. E. (2009). Coefficients alpha, beta, omega,
and the glb: Comments on Sijtsma. *Psychometrika*, 74(1), 145–154.
[doi:10.1007/s11336-008-9102-z](https://doi.org/10.1007/s11336-008-9102-z)

## See also

[`cronbach_alpha()`](https://tallier.circadia-lab.uk/reference/cronbach_alpha.md)

## Examples

``` r
if (FALSE) { # \dontrun{
study <- read_scoreme_dir("exports/")

# All questionnaires
omega_reliability(study)

# Compare alpha and omega side by side
alpha <- cronbach_alpha(study, questionnaires = c("ess", "isi"))
omega <- omega_reliability(study, questionnaires = c("ess", "isi"))
merge(alpha[, c("questionnaire_id", "alpha", "n_obs")],
      omega[, c("questionnaire_id", "omega")],
      by = "questionnaire_id")
} # }
```
