# List available instruments

Returns a data frame listing all built-in questionnaires supported by
tallieR, with their IDs, full titles, clinical domain, maximum score,
and beta status.

## Usage

``` r
available_instruments()
```

## Value

A `data.frame` with columns `id`, `title`, `domain`, `max_score`,
`beta`, `has_reverse`, and `returns_list`. The `max_score` column refers
to the primary scalar score; instruments where `returns_list = TRUE`
(PSQI, MCTQ, DASS-21, PANSS, WHOQOL-BREF) return a named list of
subscale scores rather than a single number, and `max_score` reflects
the global or total component only.

## Details

Beta instruments (`beta = TRUE`) are included in ScoreMe but have not
yet been through full validation review in tallieR. Scoring algorithms
match the ScoreMe app exactly; use with appropriate caution in clinical
contexts.

## Examples

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
#>                domain max_score  beta has_reverse returns_list
#> 1               Sleep        24 FALSE       FALSE        FALSE
#> 2               Sleep        28 FALSE       FALSE        FALSE
#> 3               Sleep        10 FALSE       FALSE        FALSE
#> 4               Sleep        86 FALSE       FALSE        FALSE
#> 5               Sleep        21 FALSE       FALSE         TRUE
#> 6               Sleep        24 FALSE       FALSE        FALSE
#> 7               Sleep         8 FALSE       FALSE        FALSE
#> 8               Sleep        10 FALSE       FALSE        FALSE
#> 9               Sleep        NA FALSE       FALSE         TRUE
#> 10      Mental Health         6  TRUE       FALSE        FALSE
#> 11      Mental Health        27  TRUE       FALSE        FALSE
#> 12      Mental Health        30  TRUE       FALSE        FALSE
#> 13      Mental Health        21  TRUE       FALSE        FALSE
#> 14      Mental Health         6  TRUE       FALSE        FALSE
#> 15      Mental Health        63  TRUE       FALSE        FALSE
#> 16      Mental Health        63  TRUE       FALSE        FALSE
#> 17      Mental Health        42  TRUE       FALSE         TRUE
#> 18      Mental Health       210  TRUE       FALSE         TRUE
#> 19      Mental Health        80  TRUE        TRUE        FALSE
#> 20      Mental Health        80  TRUE        TRUE        FALSE
#> 21          Wellbeing       100  TRUE       FALSE         TRUE
#> 22          Wellbeing        20  TRUE       FALSE        FALSE
#> 23  Physical Activity        NA  TRUE       FALSE        FALSE
#> 24  Physical Activity        NA  TRUE       FALSE        FALSE
#> 25 Neurodevelopmental       112  TRUE       FALSE        FALSE
#> 26 Neurodevelopmental        10  TRUE       FALSE        FALSE

# View only stable instruments
subset(available_instruments(), !beta)
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
#>   max_score  beta has_reverse returns_list
#> 1        24 FALSE       FALSE        FALSE
#> 2        28 FALSE       FALSE        FALSE
#> 3        10 FALSE       FALSE        FALSE
#> 4        86 FALSE       FALSE        FALSE
#> 5        21 FALSE       FALSE         TRUE
#> 6        24 FALSE       FALSE        FALSE
#> 7         8 FALSE       FALSE        FALSE
#> 8        10 FALSE       FALSE        FALSE
#> 9        NA FALSE       FALSE         TRUE

# View only beta instruments
subset(available_instruments(), beta)
#>               id                                                      title
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
#>                domain max_score beta has_reverse returns_list
#> 10      Mental Health         6 TRUE       FALSE        FALSE
#> 11      Mental Health        27 TRUE       FALSE        FALSE
#> 12      Mental Health        30 TRUE       FALSE        FALSE
#> 13      Mental Health        21 TRUE       FALSE        FALSE
#> 14      Mental Health         6 TRUE       FALSE        FALSE
#> 15      Mental Health        63 TRUE       FALSE        FALSE
#> 16      Mental Health        63 TRUE       FALSE        FALSE
#> 17      Mental Health        42 TRUE       FALSE         TRUE
#> 18      Mental Health       210 TRUE       FALSE         TRUE
#> 19      Mental Health        80 TRUE        TRUE        FALSE
#> 20      Mental Health        80 TRUE        TRUE        FALSE
#> 21          Wellbeing       100 TRUE       FALSE         TRUE
#> 22          Wellbeing        20 TRUE       FALSE        FALSE
#> 23  Physical Activity        NA TRUE       FALSE        FALSE
#> 24  Physical Activity        NA TRUE       FALSE        FALSE
#> 25 Neurodevelopmental       112 TRUE       FALSE        FALSE
#> 26 Neurodevelopmental        10 TRUE       FALSE        FALSE
```
