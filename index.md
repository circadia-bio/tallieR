# 🧮 tallieR

**Import, score, and analyse ScoreMe questionnaire data in R.**

[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://tallier.circadia-lab.uk/LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D4.1-276DC3)](https://www.r-project.org/)
[![Status](https://img.shields.io/badge/status-early%20development-orange)](https://github.com/circadia-bio/tallieR)
[![R CMD
CHECK](https://github.com/circadia-bio/tallieR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/circadia-bio/tallieR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://img.shields.io/badge/docs-tallier.circadia--lab.uk-4A7BB5)](https://tallier.circadia-lab.uk)

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

It covers **27 validated instruments** across five clinical domains:
sleep, mental health, wellbeing, physical activity, and
neurodevelopmental screening. Custom instruments defined in
ScoreMe-compatible JSON files can be loaded and scored with the same
API, without modifying the package.

tallieR is designed to work alongside
[slumbR](https://github.com/circadia-bio/slumbR): ScoreMe handles the
questionnaire side of a study, Sleep Diaries handles the diary side, and
the two R packages bring both data streams together in R.

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
  — one row per item response; optional `scored_items = TRUE` applies
  reverse-scoring
- ✅
  **[`completion_summary()`](https://tallier.circadia-lab.uk/reference/completion_summary.md)**
  — participant × questionnaire completion matrix (long or wide format)
- 🧮
  **[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md)**
  — re-score any built-in instrument from a raw answers list
- 💬
  **[`interpret_score()`](https://tallier.circadia-lab.uk/reference/interpret_score.md)**
  — return the clinical score band (label, colour, description) for any
  score
- 💬
  **[`interpret_all()`](https://tallier.circadia-lab.uk/reference/interpret_all.md)**
  — return clinical interpretations for all results in a study as a long
  data frame
- 📋
  **[`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)**
  — list all supported questionnaires with IDs, domains, beta status,
  reverse-scoring flags, and a `returns_list` indicator for composite
  instruments
- 📁
  **[`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)**
  — compile a custom questionnaire from a ScoreMe JSON spec
- 📁
  **[`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md)**
  — batch-load a directory of custom instrument specs
- 📐
  **[`cronbach_alpha()`](https://tallier.circadia-lab.uk/reference/cronbach_alpha.md)**
  — compute Cronbach’s α with exact 95% CIs for any questionnaire in the
  data
- 📐
  **[`omega_reliability()`](https://tallier.circadia-lab.uk/reference/omega_reliability.md)**
  — compute McDonald’s ω (total omega) via single-factor EFA
- 🗂️ **[`summary()`](https://rdrr.io/r/base/summary.html)** — print
  participant count, instruments, completion rates, and date range for
  any study object
- 📊
  **[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)**
  — coerce any study object directly to a tibble via
  [`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md)

------------------------------------------------------------------------

## 🗂️ Project Structure

    tallieR/
    ├── R/
    │   ├── tallieR-package.R              # package-level docs and workflow overview
    │   ├── import.R                       # read_scoreme(), read_scoreme_dir(),
    │   │                                  # print/summary S3 methods
    │   ├── tidy.R                         # scores_wide(), scores_long(), items_long(),
    │   │                                  # completion_summary(), as_tibble methods
    │   ├── questionnaires.R               # score_questionnaire(), interpret_score(),
    │   │                                  # interpret_all(), available_instruments(),
    │   │                                  # score_all()
    │   ├── questionnaires_sleep.R         # ESS, ISI, DBAS-16, MEQ, PSQI, RU-SATED,
    │   │                                  # STOP-BANG, KSS, MCTQ
    │   ├── questionnaires_mental_health.R # PHQ-2/9/15, GAD-7/2, BDI-II, BAI,
    │   │                                  # DASS-21, PANSS, STAI-S/T
    │   ├── questionnaires_wellbeing.R     # WHOQOL-BREF, MacArthur SSS
    │   ├── questionnaires_physical_activity.R  # IPAQ-S, GPAQ
    │   ├── questionnaires_neurodevelopmental.R # GSQ, AQ-10
    │   ├── custom_instruments.R           # load_instrument(), load_instrument_dir()
    │   ├── reliability.R                  # cronbach_alpha(), omega_reliability()
    │   └── zzz.R                          # `%||%` operator; .onLoad() assembles .INSTRUMENTS registry
    ├── inst/extdata/
    │   ├── example_export.json            # bundled 2-participant simulated export
    │   └── example_instrument.json       # example custom instrument spec
    ├── man/                               # roxygen2-generated documentation
    ├── vignettes/
    │   ├── getting-started.Rmd            # end-to-end worked example
    │   └── custom-instruments.Rmd         # loading and scoring custom questionnaires
    ├── tests/testthat/
    │   ├── test-questionnaires.R
    │   ├── test-import.R
    │   └── test-reliability.R
    ├── logo.png
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
#>    Instruments (4): ess, isi, meq, psqi

# ── Wide table: one row per participant ──────────────────────────────────────
wide <- scores_wide(exp)
wide[, c("code", "age", "sex", "ess", "isi", "meq", "phq9")]
#>   code age    sex ess isi meq phq9
#> 1 P001  28 female  10   5  59    3
#> 2 P002  45   male  20  22  NA   14

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

path <- system.file("extdata", "example_export.json", package = "tallieR")
exp  <- read_scoreme(path)
wide <- scores_wide(exp)
```

See
[`vignette("getting-started", package = "tallieR")`](https://tallier.circadia-lab.uk/articles/getting-started.md)
for a full worked example.

------------------------------------------------------------------------

## 🧮 Supported instruments

### 😴 Sleep

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

> **Note on PSQI:** `score_questionnaire("psqi", answers)` returns a
> named list with `global` and seven component scores (`C1`–`C7`). Use
> `result$global` for the total.

> **Note on MCTQ:** `score_questionnaire("mctq", answers)` returns a
> named list: `msfsc` (corrected mid-sleep on free days, decimal hours),
> `sjl` (absolute social jetlag, hours), `sjl_rel` (signed social
> jetlag, hours), `msw`, `msf`, `sd_w`, `sd_f`, `sd_week` (weighted
> average sleep duration), `alarm_w`, `alarm_f` (logical alarm flags,
> `NA` if not captured). Expected answer keys: `bt_w`, `sl_w`, `wt_w`,
> `bt_f`, `sl_f`, `wt_f` (times as `{hour, minute}` lists or decimal
> hours; latencies as numeric minutes), `wd` (workdays per week), and
> optionally `alarm_w`/`alarm_f` (`"yes"`/`"no"`).

### 🧠 Mental Health *(beta)*

| ID | Full name | Score range |
|----|----|----|
| `phq2` | Patient Health Questionnaire – 2 items | 0–6 |
| `phq9` | Patient Health Questionnaire – 9 items | 0–27 |
| `phq15` | Patient Health Questionnaire – 15 items (somatic) | 0–30 |
| `gad7` | Generalised Anxiety Disorder – 7 items | 0–21 |
| `gad2` | Generalised Anxiety Disorder – 2 items | 0–6 |
| `bdi2` | Beck Depression Inventory – Second Edition | 0–63 |
| `bai` | Beck Anxiety Inventory | 0–63 |
| `dass21` | Depression Anxiety Stress Scales – 21 items | 0–42 + subscales |
| `panss` | Positive and Negative Syndrome Scale | 30–210 + subscales |
| `stai_s` | State-Trait Anxiety Inventory – State subscale | 20–80 |
| `stai_t` | State-Trait Anxiety Inventory – Trait subscale | 20–80 |

> **Note on DASS-21:** returns a named list with `total`, `depression`,
> `anxiety`, and `stress` subscale scores (all scaled × 2 to align with
> DASS-42 norms).

> **Note on PANSS:** returns a named list with `total`, `positive`,
> `negative`, and `general` subscale scores.

### 🌿 Wellbeing *(beta)*

| ID | Full name | Score range |
|----|----|----|
| `whoqol_bref` | WHO Quality of Life – Brief | 0–100 (+ 4 domain scores) |
| `macarthur_sss` | MacArthur Scale of Subjective Social Status | 0–20 |

> **Note on WHOQOL-BREF:** returns a named list with `total` and four
> domain scores (`physical`, `psychological`, `social`, `environment`),
> each scaled 0–100.

### 🏃 Physical Activity *(beta)*

| ID | Full name | Score |
|----|----|----|
| `ipaq_short` | International Physical Activity Questionnaire – Short Form | MET-min/week |
| `gpaq` | Global Physical Activity Questionnaire | MET-min/week |

### 🧩 Neurodevelopmental *(beta)*

| ID     | Full name                                   | Score range |
|--------|---------------------------------------------|-------------|
| `gsq`  | Glasgow Sensory Questionnaire               | 0–112       |
| `aq10` | Autism Spectrum Quotient – 10 item screener | 0–10        |

> **Note on licensing:** Several instruments require institutional
> permission for research use. Please verify licensing requirements for
> each instrument before use in a study.

Instruments marked **beta** are included in ScoreMe and have scoring
ported from the app, but have not yet been independently validated in
tallieR. A warning is emitted when scoring beta instruments; suppress
with [`suppressWarnings()`](https://rdrr.io/r/base/warning.html) if
intentional.

------------------------------------------------------------------------

## 📁 Custom Instruments

tallieR can score questionnaires not built into the package, as long as
they are defined in a ScoreMe-compatible JSON spec. This allows
study-specific or proprietary instruments to flow through the same
pipeline without modifying tallieR source code.

``` r

# Load a single custom instrument
my_instr <- load_instrument("path/to/fss.json")

# Score it with the standard API
score_questionnaire("fss", answers, instruments = my_instr)

# Load a whole directory of specs
custom <- load_instrument_dir("instruments/")

# Use with read_scoreme() so custom instruments are scored on import
exp  <- read_scoreme("export.json", instruments = custom)
wide <- scores_wide(exp)
```

Supported scoring types compiled from the JSON spec: `"sum"`,
`"weighted_sum"`, `"mean"`. Instruments with `"composite"` scoring
(e.g. PSQI-style multi-component algorithms) can be loaded but return
`NA` for scoring; you can override the compiled `score` function by
assigning a custom one after loading:

``` r

my_instr$my_id$score <- function(answers) { ... }
```

See
[`vignette("custom-instruments", package = "tallieR")`](https://tallier.circadia-lab.uk/articles/custom-instruments.md)
and
`system.file("extdata", "example_instrument.json", package = "tallieR")`
for the full JSON spec schema.

------------------------------------------------------------------------

## 📐 Reliability Analysis

[`cronbach_alpha()`](https://tallier.circadia-lab.uk/reference/cronbach_alpha.md)
computes Cronbach’s α with exact 95% confidence intervals (Feldt et al.,
1987).
[`omega_reliability()`](https://tallier.circadia-lab.uk/reference/omega_reliability.md)
computes McDonald’s ω_t (total omega) via single-factor EFA — generally
preferred for non-tau-equivalent items. Both functions share the same
interface and output shape, making them easy to compare side by side.

``` r

study <- read_scoreme_dir("exports/")

# Cronbach's alpha with exact CIs
cronbach_alpha(study)
#>  questionnaire_id alpha ci_lower ci_upper n_items n_obs note
#>               ess  0.87     0.82     0.91       8    48   NA
#>               isi  0.91     0.87     0.94       7    48   NA
#>  ...

# McDonald's omega
omega_reliability(study)

# Compare both side by side
alpha <- cronbach_alpha(study, questionnaires = c("ess", "isi"))
omega <- omega_reliability(study, questionnaires = c("ess", "isi"))
merge(alpha[, c("questionnaire_id", "alpha", "n_obs")],
      omega[, c("questionnaire_id", "omega")],
      by = "questionnaire_id")

# Both accept an items_long() data frame directly
items <- items_long(study)
cronbach_alpha(items)
```

Non-numeric items (MCTQ clock times, STOP-BANG yes/no) are silently
dropped before estimation.

------------------------------------------------------------------------

## 📊 Study Monitoring

[`summary()`](https://rdrr.io/r/base/summary.html) gives a quick
overview of any study object.
[`completion_summary()`](https://tallier.circadia-lab.uk/reference/completion_summary.md)
returns a tidy data frame of completion status per participant and
questionnaire — useful for longitudinal data monitoring.

``` r

# Quick console overview
summary(study)
#> ── tallier_study ───────────────────────────────────────
#> • Participants: 48
#> • Source files: 3
#> • Instruments:  9
#> ── Completion ─────────────────────────────────────────
#>  ess: 48/48 (100%)
#>  isi: 45/48 (93.8%)
#>  ...

# Programmatic access
s <- summary(study)
s$completion

# Tidy completion matrix (long format)
completion_summary(study)

# Wide format: one row per participant, one column per questionnaire
completion_summary(study, wide = TRUE)
```

------------------------------------------------------------------------

## 💬 Clinical Interpretations

[`interpret_all()`](https://tallier.circadia-lab.uk/reference/interpret_all.md)
returns a long data frame of clinical interpretations for every result
in a study, joinable with
[`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)
on `participant_id` + `questionnaire_id` + `completed_at`.

``` r

interps <- interpret_all(study)
head(interps[, c("code", "questionnaire_id", "score", "label", "description")])

# Join with scores for a complete picture
scores  <- scores_long(study)
full    <- merge(
  scores,
  interps[, c("participant_id", "questionnaire_id", "completed_at",
               "label", "color", "description")],
  by = c("participant_id", "questionnaire_id", "completed_at"),
  all.x = TRUE
)
```

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

![](logo.png)

Copyright © Lucas França, Mario Leocadio-Miguel, 2026

Released under the [MIT
License](https://tallier.circadia-lab.uk/LICENSE).

> **Note on third-party questionnaire instruments:** The validated
> questionnaires supported by tallieR are the intellectual property of
> their respective authors and institutions. Their inclusion in this
> open-source package does not grant any rights to use them beyond what
> is permitted by each instrument’s licence. It is the responsibility of
> the researcher to obtain any necessary permissions before use in a
> study.
