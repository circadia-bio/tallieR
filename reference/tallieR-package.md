# tallieR: Import and score ScoreMe app questionnaire data

tallieR is the R companion to the ScoreMe app. It imports the JSON
exports produced by ScoreMe, re-scores validated questionnaires using
the same algorithms embedded in the app, and returns tidy data frames
ready for downstream analysis.

### Main workflow

    library(tallieR)

    # 1. Read one export file
    export <- read_scoreme("path/to/export.json")

    # 2. Or read a whole directory of exports
    study  <- read_scoreme_dir("path/to/exports/")

    # 3. Wide table: one row per participant × questionnaire session
    wide   <- scores_wide(study)

    # 4. Long table: one row per participant × questionnaire × administration
    long   <- scores_long(study)

    # 5. Item-level: one row per participant × questionnaire × item
    items  <- items_long(study)

## See also

Useful links:

- <https://tallier.circadia-lab.uk>

- <https://github.com/circadia-bio/tallieR>

- Report bugs at <https://github.com/circadia-bio/tallieR/issues>

## Author

**Maintainer**: Lucas França <lucas.franca@northumbria.ac.uk>
([ORCID](https://orcid.org/0000-0003-0853-1319))

Authors:

- Lucas França <lucas.franca@northumbria.ac.uk>
  ([ORCID](https://orcid.org/0000-0003-0853-1319))

- Mario Leocadio-Miguel ([ORCID](https://orcid.org/0000-0002-7248-3529))
