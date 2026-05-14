# 🧮 tallieR

**Import and score ScoreMe app questionnaire data in R.**

[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://tallier.circadia-lab.uk/LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D4.1-276DC3)](https://www.r-project.org/)
[![Status](https://img.shields.io/badge/status-early%20development-orange)](https://github.com/circadia-bio/tallieR)
[![R CMD
CHECK](https://github.com/circadia-bio/tallieR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/circadia-bio/tallieR/actions/workflows/R-CMD-check.yaml)

------------------------------------------------------------------------

> \[!WARNING\] **tallieR is in early development and has not been
> formally tested.** The API may change without notice, scoring
> algorithms have not been validated against reference implementations,
> and the package has not undergone peer review. Use with caution and
> verify outputs independently before using in any research context.

------------------------------------------------------------------------

## 📖 What is tallieR?

tallieR is the official R companion to the [ScoreMe
app](https://scoreme.circadia-lab.uk). When a study session ends,
ScoreMe exports all participant data as a single JSON file. tallieR
reads that file — or a whole directory of exports — re-scores every
questionnaire from raw item-level responses using the same algorithms
embedded in the app, and hands you tidy data frames ready for downstream
analysis.

It is designed to work alongside
[slumbR](https://github.com/circadia-bio/slumbR): ScoreMe handles the
questionnaire side of a study, Sleep Diaries handles the diary side, and
the two R packages bring both streams together in R.

------------------------------------------------------------------------

## ✨ Features

- 📥
  **[`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md)**
  — parse a ScoreMe JSON export into a structured `tallier_export`
  object
- 📂
  **[`read_scoreme_dir()`](https://tallier.circadia-lab.uk/reference/read_scoreme_dir.md)**
  — batch-read a whole directory of exports into a `tallier_study`
- 📊
  **[`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md)**
  — one row per participant, one column per questionnaire (most recent
  session)
- 📋
  **[`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)**
  — one row per participant × questionnaire × administration (full
  history retained)
- 🔬
  **[`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md)**
  — one row per item response, for factor analysis, IRT, or reliability
  checks
- 🧮
  **[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md)**
  — re-score any built-in instrument from a raw answers list
- 💬
  **[`interpret_score()`](https://tallier.circadia-lab.uk/reference/interpret_score.md)**
  — return the clinical score band (label, colour, description) for any
  score
- 📋
  **[`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)**
  — list all supported questionnaires with IDs and score ranges

------------------------------------------------------------------------

## 🗂️ Project Structure

    tallieR/
    ├── R/
    │   ├── tallieR-package.R     # package-level docs and workflow overview
    │   ├── import.R              # read_scoreme(), read_scoreme_dir()
    │   ├── tidy.R                # scores_wide(), scores_long(), items_long()
    │   └── questionnaires.R      # score_questionnaire(), interpret_score(), available_instruments()
    ├── inst/extdata/
    │   └── example_export.json   # bundled 2-participant simulated export
    ├── man/                      # roxygen2-generated documentation
    ├── vignettes/
    │   └── getting-started.Rmd  # end-to-end worked example
    ├── tests/testthat/
    │   ├── test-questionnaires.R
    │   └── test-import.R
    ├── DESCRIPTION
    ├── LICENSE
    └── tallieR.Rproj

------------------------------------------------------------------------

## 🚀 Getting Started

### Prerequisites

- R ≥ 4.1
- The following packages (installed automatically): `jsonlite`, `dplyr`,
  `tidyr`, `purrr`, `rlang`, `cli`

### Installation

``` r

# Install from GitHub (requires remotes)
remotes::install_github("circadia-bio/tallieR")
```

### Basic usage

``` r

library(tallieR)

# ── Single export file ──────────────────────────────────────────────────────
exp <- read_scoreme("my_study_export.json")
exp
#> ℹ tallier_export: 12 participants | exported 2026-05-14T10:00:00.000Z

# ── Wide table: one row per participant ──────────────────────────────────────
wide <- scores_wide(exp)
wide[, c("code", "age", "sex", "ess", "isi", "meq")]
#>   code age    sex ess isi meq
#> 1 P001  28 female  10   5  59
#> 2 P002  45   male  20  22  NA

# ── Long table: full administration history ──────────────────────────────────
long <- scores_long(exp)
head(long[, c("code", "questionnaire_id", "completed_at", "score")])

# ── Item-level data ──────────────────────────────────────────────────────────
items <- items_long(exp)
head(items[, c("code", "questionnaire_id", "item_id", "response")])

# ── Re-score a questionnaire directly ───────────────────────────────────────
score_questionnaire("ess", list(
  ess1 = 2, ess2 = 1, ess3 = 0, ess4 = 3,
  ess5 = 1, ess6 = 0, ess7 = 2, ess8 = 1
))
#> [1] 10

interpret_score("ess", 10)
#> $label
#> [1] "Excessive"
#> $color
#> [1] "#EA580C"
#> $description
#> [1] "Excessive daytime sleepiness. Consider clinical review."
```

### Try it with the bundled example data

> \[!NOTE\] The bundled dataset is entirely **simulated**. The two
> participants (Alice Example, Bob Example) and all their questionnaire
> responses are artificially generated for demonstration purposes. They
> do not represent real people or real study data.

``` r

path  <- system.file("extdata", "example_export.json", package = "tallieR")
exp   <- read_scoreme(path)
wide  <- scores_wide(exp)
```

See
[`vignette("getting-started", package = "tallieR")`](https://tallier.circadia-lab.uk/articles/getting-started.md)
for a full worked example.

------------------------------------------------------------------------

## 🧮 Supported questionnaires

| ID | Full name | Score range | Reference |
|----|----|----|----|
| `ess` | Epworth Sleepiness Scale | 0–24 | Johns (1991) |
| `isi` | Insomnia Severity Index | 0–28 | Morin et al. (2011) |
| `dbas16` | Dysfunctional Beliefs and Attitudes about Sleep | 0–10 (mean) | Morin et al. (2007) |
| `meq` | Morningness–Eveningness Questionnaire | 16–86 | Horne & Östberg (1976) |
| `psqi` | Pittsburgh Sleep Quality Index | 0–21 + C1–C7 | Buysse et al. (1989) |
| `rusated` | RU-SATED Sleep Health Scale | 0–24 | Buysse (2014) |
| `stopbang` | STOP-BANG Questionnaire | 0–8 | Chung et al. (2016) |
| `kss` | Karolinska Sleepiness Scale | 1–10 | Åkerstedt & Gillberg (1990) |
| `mctq` | Munich Chronotype Questionnaire | MSFsc + SJL (hours) | Roenneberg et al. (2003) |

> **Note on MCTQ:** `score_questionnaire("mctq", answers)` returns a
> named list: `msfsc` (chronotype midpoint, decimal hours), `sjl`
> (social jetlag, hours), plus `msw`, `msf`, `sd_w`, `sd_f`. Expected
> answer keys: `bt_w`, `sl_w`, `wt_w`, `bt_f`, `sl_f`, `wt_f` (times as
> `{hour, minute}` lists or decimal hours; latencies as numeric
> minutes), and `wd` (workdays per week).

> **Note on PSQI:** `score_questionnaire("psqi", answers)` returns a
> named list with the global score and all seven component scores
> (C1–C7). Use `result$global` for the total or access individual
> components directly.

> **Note on licensing:** Some instruments require institutional
> permission for research use. Please verify licensing requirements for
> each instrument before use in a study.

------------------------------------------------------------------------

## 📦 Dependencies

| Package  | Version | Purpose                      |
|----------|---------|------------------------------|
| jsonlite | ≥ 1.8.0 | JSON parsing                 |
| dplyr    | ≥ 1.1.0 | Data manipulation            |
| tidyr    | ≥ 1.3.0 | Pivoting wide/long           |
| purrr    | ≥ 1.0.0 | Functional iteration         |
| rlang    | ≥ 1.1.0 | Error/warning infrastructure |
| cli      | ≥ 3.6.0 | Progress and messages        |

------------------------------------------------------------------------

## 👥 Authors

| Role | Name | Affiliation |
|----|----|----|
| Author, maintainer | Lucas França | Northumbria University, Circadia Lab |
| Author | Mario Leocadio-Miguel | Northumbria University, Circadia Lab |

------------------------------------------------------------------------

## 🤝 Related Tools

- 📱 [**ScoreMe**](https://github.com/circadia-bio/ScoreMe) — the
  cross-platform app that administers questionnaires and generates the
  exports tallieR reads
- 🌙 [**SleepDiaries**](https://github.com/circadia-bio/SleepDiaries) —
  the companion Sleep Diaries app for actigraphy and diary data
  collection
- 🧪 [**slumbR**](https://github.com/circadia-bio/slumbR) — R companion
  for Sleep Diaries exports
- 🔬 [**circadia-bio**](https://github.com/circadia-bio) — the Circadia
  Lab GitHub organisation

------------------------------------------------------------------------

## 📄 Licence

Released under the [MIT
License](https://tallier.circadia-lab.uk/LICENSE).

Copyright © Lucas França, Mario Leocadio-Miguel, 2026
