# Custom instruments in tallieR

tallieR includes 27 built-in instruments, but many studies use
questionnaires that are not in the package — proprietary tools,
study-specific scales, or newer measures that haven’t been reviewed for
inclusion yet. The custom instrument system lets you load any
questionnaire defined as a ScoreMe-compatible JSON spec and use it
through the same API as built-in instruments, without modifying tallieR
source code.

## The JSON spec format

A custom instrument is defined in a single `.json` file. The required
fields are `id`, `title`, and `items`. Everything else is optional but
recommended.

tallieR ships with a worked example — the Fatigue Severity Scale (FSS):

``` r

library(tallieR)

fss_path <- system.file("extdata", "example_instrument.json", package = "tallieR")
```

The spec structure looks like this (abbreviated):

``` json
{
  "id": "fss",
  "title": "Fatigue Severity Scale",
  "domain": "Fatigue",
  "maxScore": 63,
  "scoringMethod": {
    "type": "mean",
    "items": ["fss1", "fss2", "fss3", "fss4", "fss5", "fss6", "fss7", "fss8", "fss9"]
  },
  "scoreBands": [
    { "min": 1.0, "max": 3.9, "label": "No significant fatigue",
      "color": "#2E7D32", "description": "Below clinical threshold." },
    { "min": 4.0, "max": 5.4, "label": "Moderate fatigue",
      "color": "#F59E0B", "description": "May be affecting daily activities." },
    { "min": 5.5, "max": 7.0, "label": "Severe fatigue",
      "color": "#DC2626", "description": "Significant impact on functioning." }
  ],
  "items": [
    { "id": "fss1", "number": 1,
      "text": "My motivation is lower when I am fatigued.",
      "type": "scale_1_10" }
  ]
}
```

### Supported scoring types

| `scoringMethod.type` | Behaviour |
|----|----|
| `"sum"` | Sum of item values |
| `"weighted_sum"` | Sum of item values x `multiplier` |
| `"mean"` | Mean of item values (1 d.p.) x `multiplier` |
| `"composite"` | Cannot be auto-compiled — see [Composite scoring](#composite-scoring) below |

### Key fields reference

| Field | Required | Description |
|----|----|----|
| `id` | yes | Short identifier used in tallieR (e.g. `"fss"`) |
| `title` | yes | Full instrument name |
| `items` | yes | Array of item objects, each with `id` and `type` |
| `domain` |  | Clinical domain (defaults to `"Custom"`) |
| `maxScore` |  | Maximum possible score |
| `beta` |  | Mark as unvalidated (`true`/`false`) |
| `scoringMethod` |  | Scoring algorithm definition |
| `scoreBands` |  | Clinical interpretation bands (`min`, `max`, `label`, `color`, `description`) |
| `scoreBandDirection` |  | `"asc"` (default) or `"desc"` |

## Loading a custom instrument

[`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)
reads the JSON file, compiles scoring and interpretation functions, and
returns a named registry entry:

``` r

fss <- load_instrument(fss_path)
#> ✔ Loaded instrument "Fatigue Severity Scale" ("fss") from example_instrument.json
```

The registry is a named list whose name matches the instrument `id`:

``` r

names(fss)
#> [1] "fss"
fss$fss$title
#> [1] "Fatigue Severity Scale"
fss$fss$domain
#> [1] "Fatigue"
fss$fss$max_score
#> [1] 63
```

## Scoring with a custom instrument

Pass the registry to
[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md)
via the `instruments` argument:

``` r

fss_answers <- list(
  fss1 = 5, fss2 = 6, fss3 = 5, fss4 = 6,
  fss5 = 5, fss6 = 4, fss7 = 5, fss8 = 4, fss9 = 5
)

score_questionnaire("fss", fss_answers, instruments = fss)
#> [1] 5
interpret_score("fss", 5.0, instruments = fss)
#> $label
#> [1] "Moderate fatigue"
#> 
#> $color
#> [1] "#F59E0B"
#> 
#> $description
#> [1] "Mean score above the clinical threshold. Fatigue may be affecting daily activities."
```

The `instruments` argument is available on all scoring and tidy
functions:
[`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md),
[`read_scoreme_dir()`](https://tallier.circadia-lab.uk/reference/read_scoreme_dir.md),
[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md),
[`interpret_score()`](https://tallier.circadia-lab.uk/reference/interpret_score.md),
[`interpret_all()`](https://tallier.circadia-lab.uk/reference/interpret_all.md),
[`cronbach_alpha()`](https://tallier.circadia-lab.uk/reference/cronbach_alpha.md),
and
[`omega_reliability()`](https://tallier.circadia-lab.uk/reference/omega_reliability.md).

## Using custom instruments with imports

Pass the registry to
[`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md)
so that custom instruments in the export are scored on import:

``` r

fss  <- load_instrument("instruments/fss.json")
exp  <- read_scoreme("my_export.json", instruments = fss)
wide <- scores_wide(exp)
```

## Loading multiple instruments

Combine registries with [`c()`](https://rdrr.io/r/base/c.html):

``` r

registry <- c(
  load_instrument("instruments/fss.json"),
  load_instrument("instruments/vas_pain.json")
)
```

Or load everything in a folder at once:

``` r

registry <- load_instrument_dir("instruments/")
exp      <- read_scoreme("export.json", instruments = registry)
```

## Composite scoring

Instruments with `"composite"` scoring (multi-component algorithms like
PSQI) cannot be auto-compiled from the JSON spec. Loading such a spec
succeeds, but scoring returns `NA` with a warning. Override the compiled
`score` function after loading:

``` r

my_scale <- load_instrument("composite_scale.json")

my_scale$composite_scale$score <- function(answers) {
  component_a <- as.numeric(answers[["item1"]]) + as.numeric(answers[["item2"]])
  component_b <- as.numeric(answers[["item3"]])
  component_a + component_b
}

score_questionnaire("composite_scale", answers, instruments = my_scale)
```

## Inspecting a loaded registry

Custom instruments do not appear in
[`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)
— that lists only built-ins. To see what is in a custom registry:

``` r

data.frame(
  id        = names(fss),
  title     = vapply(fss, `[[`, character(1), "title"),
  domain    = vapply(fss, `[[`, character(1), "domain"),
  max_score = vapply(fss, `[[`, numeric(1),   "max_score")
)
#>      id                  title  domain max_score
#> fss fss Fatigue Severity Scale Fatigue        63
```

Custom entries take precedence over built-ins when the same `id` is
used, so a custom entry can also override a built-in scoring algorithm
if needed.
