# Interpret a questionnaire score

Returns a clinical interpretation for a given score on a given
questionnaire, matching the score bands used in the ScoreMe app.

## Usage

``` r
interpret_score(id, score)
```

## Arguments

- id:

  Character. Questionnaire identifier.

- score:

  Numeric score (or named list for PSQI).

## Value

A list with elements `label`, `color` (hex), and `description`.

## Examples

``` r
interpret_score("ess", 12)
#> $label
#> [1] "Excessive"
#> 
#> $color
#> [1] "#EA580C"
#> 
#> $description
#> [1] "Excessive daytime sleepiness. Consider clinical review."
#> 
interpret_score("meq", 65)
#> $label
#> [1] "Moderate morning type"
#> 
#> $color
#> [1] "#84CC16"
#> 
#> $description
#> [1] "Moderate preference for mornings."
#> 
```
