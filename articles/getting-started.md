# Getting started with tallieR

tallieR is the R companion to the [ScoreMe
app](https://scoreme.circadia-lab.uk). It imports participant JSON
exports and returns tidy data frames ready for analysis.

## Installation

``` r

# install.packages("pak")
pak::pkg_install("circadia-bio/tallieR")
```

## Basic workflow

### 1. Read an export

ScoreMe can export all participants in one JSON file. Point
[`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md)
at it:

``` r

library(tallieR)

path <- system.file("extdata", "example_export.json", package = "tallieR")
exp  <- read_scoreme(path)
exp
#> ℹ tallier_export: 2 participants | exported 2026-05-14T10:00:00.000Z
```

Or read a whole folder of exports at once:

``` r

study <- read_scoreme_dir("~/Downloads/my_study_exports/")
```

### 2. Wide score table

One row per participant, one column per questionnaire (most recent
session):

``` r

wide <- scores_wide(exp)
wide[, c("code", "age", "sex", "ess", "isi")]
#>   code age    sex ess isi
#> 1 P001  28 female  10   5
#> 2 P002  45   male  20  22
```

### 3. Long score table

One row per participant × questionnaire × administration (full history):

``` r

long <- scores_long(exp)
head(long[, c("code", "questionnaire_id", "completed_at", "score")])
#>   code questionnaire_id             completed_at score
#> 1 P001              ess 2026-01-10T09:05:00.000Z    10
#> 2 P001              isi 2026-01-10T09:10:00.000Z     5
#> 3 P001              meq 2026-01-10T09:15:00.000Z    59
#> 4 P002              ess 2026-01-11T10:05:00.000Z    20
#> 5 P002              isi 2026-01-11T10:10:00.000Z    22
#> 6 P002         stopbang 2026-01-11T10:20:00.000Z     6
```

### 4. Item-level data

One row per item response — useful for reliability analysis or IRT:

``` r

items <- items_long(exp)
head(items[, c("code", "questionnaire_id", "item_id", "response")])
#>   code questionnaire_id item_id response
#> 1 P001              ess    ess1        2
#> 2 P001              ess    ess2        1
#> 3 P001              ess    ess3        0
#> 4 P001              ess    ess4        3
#> 5 P001              ess    ess5        1
#> 6 P001              ess    ess6        0
```

## Scoring and interpretation

tallieR rescores all questionnaires from raw item responses by default.
You can also call the scoring functions directly:

``` r

score_questionnaire("ess", list(
  ess1 = 2, ess2 = 1, ess3 = 0, ess4 = 3,
  ess5 = 1, ess6 = 0, ess7 = 2, ess8 = 1
))
#> [1] 10

interpret_score("ess", 10)
#> $label
#> [1] "Excessive"
#> 
#> $color
#> [1] "#EA580C"
#> 
#> $description
#> [1] "Excessive daytime sleepiness. Consider clinical review."
```

PSQI returns a named list of component scores alongside the global
score:

``` r

psqi_answers <- list(
  psqi9 = 2, psqi2 = 35, psqi5a = 2, psqi4 = 5.5,
  psqi1 = list(hour = 0, minute = 30),
  psqi3 = list(hour = 7, minute = 0),
  psqi5b=2, psqi5c=1, psqi5d=0, psqi5e=1,
  psqi5f=0, psqi5g=1, psqi5h=1, psqi5i=0,
  psqi6 = 1, psqi7 = 2, psqi8 = 2
)
score_questionnaire("psqi", psqi_answers)
#> $global
#> [1] 11
#> 
#> $C1
#> [1] 2
#> 
#> $C2
#> [1] 2
#> 
#> $C3
#> [1] 2
#> 
#> $C4
#> [1] 1
#> 
#> $C5
#> [1] 1
#> 
#> $C6
#> [1] 1
#> 
#> $C7
#> [1] 2
```

## Available instruments

``` r

available_instruments()
#>         id                                                     title domain
#> 1      ess                                  Epworth Sleepiness Scale  Sleep
#> 2      isi                                   Insomnia Severity Index  Sleep
#> 3   dbas16 Dysfunctional Beliefs and Attitudes about Sleep (DBAS-16)  Sleep
#> 4      meq                     Morningness-Eveningness Questionnaire  Sleep
#> 5     psqi                            Pittsburgh Sleep Quality Index  Sleep
#> 6  rusated                               RU-SATED Sleep Health Scale  Sleep
#> 7 stopbang                                   STOP-BANG Questionnaire  Sleep
#> 8      kss                               Karolinska Sleepiness Scale  Sleep
#> 9     mctq                           Munich Chronotype Questionnaire  Sleep
#>   max_score
#> 1        24
#> 2        28
#> 3        10
#> 4        86
#> 5        21
#> 6        24
#> 7         8
#> 8        10
#> 9        NA
```
