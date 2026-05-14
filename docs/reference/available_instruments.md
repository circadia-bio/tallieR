# List available instruments

Returns a data frame listing all built-in questionnaires supported by
tallieR, with their IDs, full titles, clinical domain, and maximum
score.

## Usage

``` r
available_instruments()
```

## Value

A `data.frame` with columns `id`, `title`, `domain`, `max_score`.

## Examples

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
