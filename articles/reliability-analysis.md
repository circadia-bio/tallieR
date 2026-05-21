# Reliability analysis in tallieR

tallieR provides two measures of internal consistency: Cronbach’s alpha
and McDonald’s omega. This vignette explains what each measures, when to
prefer one over the other, and how to use both functions.

## Why internal consistency matters

When questionnaire items are summed or averaged into a scale score,
internal consistency tells you how well those items measure the same
underlying construct. Low consistency suggests the items may not belong
together; high consistency is a prerequisite for treating the total
score as meaningful.

## Cronbach’s alpha

Cronbach’s alpha assumes that all items have *equal* factor loadings
(tau-equivalence). Under that assumption, alpha is the expected
correlation between the current scale and any other scale of the same
length drawn from the same item pool.

``` r

library(tallieR)

study <- read_scoreme_dir("exports/")

# All questionnaires in the study
cronbach_alpha(study)

# Specific subset
cronbach_alpha(study, questionnaires = c("ess", "isi", "phq9"))
```

The output is a data frame with one row per questionnaire:

| Column                  | Description                            |
|-------------------------|----------------------------------------|
| `questionnaire_id`      | Questionnaire identifier               |
| `alpha`                 | Cronbach’s alpha                       |
| `ci_lower` / `ci_upper` | Exact 95% CI (Feldt et al., 1987)      |
| `n_items`               | Number of numeric items used           |
| `n_obs`                 | Number of complete observations        |
| `note`                  | `NA` on success, or reason for failure |

The confidence interval uses the exact F-distribution method of Feldt et
al. (1987) rather than a bootstrap approximation. A wider interval
reflects fewer participants, not a worse instrument.

### Interpreting alpha

Conventional thresholds (Nunnally, 1978):

| Alpha       | Interpretation                           |
|-------------|------------------------------------------|
| \< 0.60     | Poor                                     |
| 0.60 – 0.70 | Questionable                             |
| 0.70 – 0.80 | Acceptable                               |
| 0.80 – 0.90 | Good                                     |
| \>= 0.90    | Excellent (may indicate item redundancy) |

These are rules of thumb, not hard cutoffs. Context matters: a screener
with 3 items and alpha = 0.72 may be perfectly adequate for its purpose.

## McDonald’s omega

Omega relaxes the tau-equivalence assumption. It uses the factor
loadings from a single-factor EFA to estimate the proportion of scale
variance attributable to the common factor:

``` math
\omega_t = \frac{(\sum \lambda_i)^2}{(\sum \lambda_i)^2 + \sum(1 - \lambda_i^2)}
```

When items have unequal loadings (which is the norm in psychological
questionnaires), omega is a less biased estimate of reliability than
alpha. Alpha systematically underestimates reliability for congeneric
scales, and can overestimate it when items are highly correlated for
reasons unrelated to the construct.

``` r

omega_reliability(study)
omega_reliability(study, questionnaires = c("ess", "isi"))
```

Output columns: `questionnaire_id`, `omega`, `n_items`, `n_obs`, `note`.

## When to use which

| Situation | Recommendation |
|----|----|
| Tau-equivalent items (equal loadings assumed) | Either; alpha is conventional |
| Congeneric items (unequal loadings, typical) | Prefer omega |
| Comparing against published norms that report alpha | Report both; flag the difference |
| Small sample (\< 30) | Alpha with exact CI; omega may not converge |
| Reporting for publication | Report both with sample size and n items |

## Comparing alpha and omega side by side

``` r

alpha_res <- cronbach_alpha(study, questionnaires = c("ess", "isi", "phq9"))
omega_res  <- omega_reliability(study, questionnaires = c("ess", "isi", "phq9"))

merge(
  alpha_res[, c("questionnaire_id", "alpha", "ci_lower", "ci_upper", "n_obs")],
  omega_res[, c("questionnaire_id", "omega")],
  by = "questionnaire_id"
)
```

## Using an `items_long()` data frame directly

Both functions accept either a study object or a data frame produced by
[`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md).
This is useful when you want to filter to a specific group or time point
before computing reliability:

``` r

items <- items_long(study)

# Only control group
control_items <- items[items$group == "control", ]
cronbach_alpha(control_items)

# Only baseline session
baseline_items <- items[items$session == "baseline", ]
omega_reliability(baseline_items)
```

## Handling non-numeric items

Some instruments include items that cannot be coerced to numeric — MCTQ
clock times, STOP-BANG yes/no responses. These are silently dropped
before estimation. The `n_items` column in the output tells you how many
numeric items were actually used, so you can detect if unexpected items
were dropped.

## Failure modes

Questionnaires that cannot be estimated return `NA` with an explanatory
note:

| Situation | Note |
|----|----|
| Fewer than 2 numeric items | “Need at least 2 numeric items.” |
| Fewer than 2 complete observations | “Need at least 2 complete observations.” |
| Zero variance in row totals (alpha) | “Zero variance in row totals.” |
| More items than observations (omega) | “More items than observations; covariance matrix is singular.” |
| EFA non-convergence (omega) | “Factor analysis did not converge.” |

## References

Cronbach, L. J. (1951). Coefficient alpha and the internal structure of
tests. *Psychometrika*, 16(3), 297–334.

Feldt, L. S., Woodruff, D. J., & Salih, F. A. (1987). Statistical
inference for coefficient alpha. *Applied Psychological Measurement*,
11(1), 93–103.

McDonald, R. P. (1999). *Test theory: A unified treatment*. Lawrence
Erlbaum Associates.

Nunnally, J. C. (1978). *Psychometric theory* (2nd ed.). McGraw-Hill.

Revelle, W., & Zinbarg, R. E. (2009). Coefficients alpha, beta, omega,
and the glb: Comments on Sijtsma. *Psychometrika*, 74(1), 145–154.
