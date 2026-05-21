# Package index

## Import

Read ScoreMe JSON exports into R.

- [`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md)
  : Read a ScoreMe JSON export
- [`read_scoreme_dir()`](https://tallier.circadia-lab.uk/reference/read_scoreme_dir.md)
  : Read a directory of ScoreMe JSON exports

## Custom instruments

Load any ScoreMe-compatible JSON instrument spec for use in tallieR.

- [`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)
  : Load a custom instrument from a ScoreMe JSON spec
- [`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md)
  : Load all custom instruments from a directory

## Tidy output

Reshape imported data into analysis-ready data frames.

- [`scores_wide()`](https://tallier.circadia-lab.uk/reference/scores_wide.md)
  : Wide score table
- [`scores_long()`](https://tallier.circadia-lab.uk/reference/scores_long.md)
  : Long score table
- [`items_long()`](https://tallier.circadia-lab.uk/reference/items_long.md)
  : Item-level long table
- [`completion_summary()`](https://tallier.circadia-lab.uk/reference/completion_summary.md)
  : Completion summary
- [`as_tibble.tallier_export()`](https://tallier.circadia-lab.uk/reference/as_tibble.tallier_export.md)
  : Coerce a tallier_export to a tibble
- [`as_tibble.tallier_study()`](https://tallier.circadia-lab.uk/reference/as_tibble.tallier_study.md)
  : Coerce a tallier_study to a tibble

## Questionnaire scoring

Score and interpret validated instruments from raw item responses.

- [`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md)
  : Score a questionnaire from item-level answers
- [`score_all()`](https://tallier.circadia-lab.uk/reference/score_all.md)
  : Score all questionnaires in an export
- [`interpret_score()`](https://tallier.circadia-lab.uk/reference/interpret_score.md)
  : Interpret a questionnaire score
- [`interpret_all()`](https://tallier.circadia-lab.uk/reference/interpret_all.md)
  : Interpret all questionnaire scores in an export
- [`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)
  : List available instruments

## Reliability

Internal consistency and reliability statistics.

- [`cronbach_alpha()`](https://tallier.circadia-lab.uk/reference/cronbach_alpha.md)
  : Cronbach's alpha for one or more questionnaires
- [`omega_reliability()`](https://tallier.circadia-lab.uk/reference/omega_reliability.md)
  : McDonald's omega for one or more questionnaires

## Study monitoring

Summarise and inspect study objects.

- [`summary(`*`<tallier_export>`*`)`](https://tallier.circadia-lab.uk/reference/summary.tallier_export.md)
  : Summarise a tallier_export object
- [`summary(`*`<tallier_study>`*`)`](https://tallier.circadia-lab.uk/reference/summary.tallier_study.md)
  : Summarise a tallier_study object

## Package

Package-level documentation.

- [`tallieR`](https://tallier.circadia-lab.uk/reference/tallieR-package.md)
  [`tallieR-package`](https://tallier.circadia-lab.uk/reference/tallieR-package.md)
  : tallieR: Import and score ScoreMe app questionnaire data
