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
#>               id                                                      title
#> 1            ess                                   Epworth Sleepiness Scale
#> 2            isi                                    Insomnia Severity Index
#> 3         dbas16  Dysfunctional Beliefs and Attitudes about Sleep (DBAS-16)
#> 4            meq                      Morningness-Eveningness Questionnaire
#> 5           psqi                             Pittsburgh Sleep Quality Index
#> 6        rusated                                RU-SATED Sleep Health Scale
#> 7       stopbang                                    STOP-BANG Questionnaire
#> 8            kss                                Karolinska Sleepiness Scale
#> 9           mctq                            Munich Chronotype Questionnaire
#> 10          phq2                     Patient Health Questionnaire - 2 items
#> 11          phq9                     Patient Health Questionnaire - 9 items
#> 12         phq15 Patient Health Questionnaire - 15 items (Somatic Symptoms)
#> 13          gad7                     Generalised Anxiety Disorder - 7 items
#> 14          gad2                     Generalised Anxiety Disorder - 2 items
#> 15          bdi2                 Beck Depression Inventory - Second Edition
#> 16           bai                                     Beck Anxiety Inventory
#> 17        dass21                Depression Anxiety Stress Scales - 21 items
#> 18         panss                       Positive and Negative Syndrome Scale
#> 19        stai_s             State-Trait Anxiety Inventory - State subscale
#> 20        stai_t             State-Trait Anxiety Inventory - Trait subscale
#> 21   whoqol_bref  World Health Organization Quality of Life - Brief version
#> 22 macarthur_sss                MacArthur Scale of Subjective Social Status
#> 23    ipaq_short International Physical Activity Questionnaire - Short Form
#> 24          gpaq                     Global Physical Activity Questionnaire
#> 25           gsq                              Glasgow Sensory Questionnaire
#> 26          aq10                Autism Spectrum Quotient - 10 item screener
#>                domain max_score  beta
#> 1               Sleep        24 FALSE
#> 2               Sleep        28 FALSE
#> 3               Sleep        10 FALSE
#> 4               Sleep        86 FALSE
#> 5               Sleep        21 FALSE
#> 6               Sleep        24 FALSE
#> 7               Sleep         8 FALSE
#> 8               Sleep        10 FALSE
#> 9               Sleep        NA FALSE
#> 10      Mental Health         6  TRUE
#> 11      Mental Health        27  TRUE
#> 12      Mental Health        30  TRUE
#> 13      Mental Health        21  TRUE
#> 14      Mental Health         6  TRUE
#> 15      Mental Health        63  TRUE
#> 16      Mental Health        63  TRUE
#> 17      Mental Health        42  TRUE
#> 18      Mental Health       210  TRUE
#> 19      Mental Health        80  TRUE
#> 20      Mental Health        80  TRUE
#> 21          Wellbeing       100  TRUE
#> 22          Wellbeing        20  TRUE
#> 23  Physical Activity        NA  TRUE
#> 24  Physical Activity        NA  TRUE
#> 25 Neurodevelopmental       112  TRUE
#> 26 Neurodevelopmental        10  TRUE
```
