# Score a questionnaire from item-level answers

Computes the score for a single questionnaire using the official scoring
algorithm embedded in tallieR.

## Usage

``` r
score_questionnaire(id, answers)
```

## Arguments

- id:

  Character. Questionnaire identifier (e.g. `"ess"`, `"psqi"`). See
  [`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)
  for valid IDs.

- answers:

  A named list of item responses, as exported by ScoreMe. Keys are item
  IDs (e.g. `"ess1"`, `"psqi2"`); values are the raw responses (numeric,
  character `"yes"`/`"no"`, or clock-time list).

## Value

For most instruments: a single numeric score. For PSQI: a named list
with the global score and component scores C1-C7.

## Examples

``` r
score_questionnaire("ess", list(ess1 = 2, ess2 = 1, ess3 = 0,
                                ess4 = 3, ess5 = 1, ess6 = 0,
                                ess7 = 2, ess8 = 1))
#> [1] 10
```
