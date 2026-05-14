#' tallieR: Import and score ScoreMe app questionnaire data
#'
#' @description
#' tallieR is the R companion to the ScoreMe app. It imports the JSON exports
#' produced by ScoreMe, re-scores validated questionnaires using the same
#' algorithms embedded in the app, and returns tidy data frames ready for
#' downstream analysis.
#'
#' ## Main workflow
#'
#' ```r
#' library(tallieR)
#'
#' # 1. Read one export file
#' export <- read_scoreme("path/to/export.json")
#'
#' # 2. Or read a whole directory of exports
#' study  <- read_scoreme_dir("path/to/exports/")
#'
#' # 3. Wide table: one row per participant × questionnaire session
#' wide   <- scores_wide(study)
#'
#' # 4. Long table: one row per participant × questionnaire × administration
#' long   <- scores_long(study)
#'
#' # 5. Item-level: one row per participant × questionnaire × item
#' items  <- items_long(study)
#' ```
#'
#' @keywords internal
"_PACKAGE"
