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

## Questionnaire scoring

Score and interpret validated instruments from raw item responses.

- [`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md)
  : Score a questionnaire from item-level answers
- [`score_all()`](https://tallier.circadia-lab.uk/reference/score_all.md)
  : Score all questionnaires in an export
- [`interpret_score()`](https://tallier.circadia-lab.uk/reference/interpret_score.md)
  : Interpret a questionnaire score
- [`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)
  : List available instruments

## Reliability

Internal consistency and reliability statistics.

- [`cronbach_alpha()`](https://tallier.circadia-lab.uk/reference/cronbach_alpha.md)
  : Cronbach's alpha for one or more questionnaires

## Package

Package-level documentation.

- [`tallieR`](https://tallier.circadia-lab.uk/reference/tallieR-package.md)
  [`tallieR-package`](https://tallier.circadia-lab.uk/reference/tallieR-package.md)
  : tallieR: Import and score ScoreMe app questionnaire data
