# R/questionnaires.R -- Central registry and public API
#
# Domain-specific scoring functions live in:
#   questionnaires_sleep.R
#   questionnaires_mental_health.R
#   questionnaires_wellbeing.R
#   questionnaires_physical_activity.R
#   questionnaires_neurodevelopmental.R
#
# This file merges all domain registries into .INSTRUMENTS and exposes the
# public API: available_instruments(), score_questionnaire(),
# score_all(), interpret_score().

# --- Merged registry ----------------------------------------------------------

.INSTRUMENTS <- c(
  .SLEEP_INSTRUMENTS,
  .MENTAL_HEALTH_INSTRUMENTS,
  .WELLBEING_INSTRUMENTS,
  .PHYSICAL_ACTIVITY_INSTRUMENTS,
  .NEURODEVELOPMENTAL_INSTRUMENTS
)

# --- Public API ---------------------------------------------------------------

#' List available instruments
#'
#' Returns a data frame listing all built-in questionnaires supported by
#' tallieR, with their IDs, full titles, clinical domain, maximum score, and
#' beta status.
#'
#' Beta instruments (`beta = TRUE`) are included in ScoreMe but have not yet
#' been through full validation review in tallieR. Scoring algorithms match
#' the ScoreMe app exactly; use with appropriate caution in clinical contexts.
#'
#' @return A `data.frame` with columns `id`, `title`, `domain`, `max_score`,
#'   `beta`.
#'
#' @examples
#' available_instruments()
#'
#' # View only stable instruments
#' subset(available_instruments(), !beta)
#'
#' # View only beta instruments
#' subset(available_instruments(), beta)
#'
#' @export
available_instruments <- function() {
  data.frame(
    id        = names(.INSTRUMENTS),
    title     = vapply(.INSTRUMENTS, `[[`, character(1), "title"),
    domain    = vapply(.INSTRUMENTS, `[[`, character(1), "domain"),
    max_score = vapply(.INSTRUMENTS, `[[`, numeric(1),   "max_score"),
    beta      = vapply(.INSTRUMENTS, `[[`, logical(1),   "beta"),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' Score a questionnaire from item-level answers
#'
#' Computes the score for a single questionnaire using the official scoring
#' algorithm embedded in tallieR.
#'
#' @param id Character. Questionnaire identifier (e.g. `"ess"`, `"psqi"`).
#'   See [available_instruments()] for valid IDs.
#' @param answers A named list of item responses, as exported by ScoreMe.
#'   Keys are item IDs (e.g. `"ess1"`, `"psqi2"`); values are the raw
#'   responses (numeric, character `"yes"`/`"no"`, or clock-time list).
#'
#' @return For most instruments: a single numeric score. For composite
#'   instruments (PSQI, MCTQ, DASS-21, PANSS, WHOQOL-BREF): a named list
#'   of subscale and total scores.
#'
#' @details
#' Instruments marked `beta = TRUE` in [available_instruments()] are newer
#' additions whose scoring has been ported from ScoreMe but has not yet been
#' independently validated in tallieR. A warning is emitted for these
#' instruments; suppress with `suppressWarnings()` if needed.
#'
#' @examples
#' score_questionnaire("ess", list(ess1 = 2, ess2 = 1, ess3 = 0,
#'                                 ess4 = 3, ess5 = 1, ess6 = 0,
#'                                 ess7 = 2, ess8 = 1))
#'
#' @export
score_questionnaire <- function(id, answers) {
  inst <- .INSTRUMENTS[[tolower(id)]]
  if (is.null(inst)) {
    rlang::abort(paste0(
      "Unknown questionnaire id: '", id, "'. ",
      "Use available_instruments() to see valid IDs."
    ))
  }
  if (isTRUE(inst$beta)) {
    rlang::warn(paste0(
      "'", id, "' is a beta instrument. Scoring matches the ScoreMe app ",
      "but has not yet been independently validated in tallieR. ",
      "Suppress with suppressWarnings() if this is intentional."
    ))
  }
  inst$score(answers)
}

#' Score all questionnaires in an export
#'
#' Convenience wrapper that rescores every result entry in a
#' `tallier_export` or `tallier_study` object. This is called automatically
#' when `rescore = TRUE` in [read_scoreme()].
#'
#' @param obj A `tallier_export` or `tallier_study` object.
#'
#' @return The same object with scores updated in-place.
#'
#' @export
score_all <- function(obj) {
  obj$participants <- lapply(obj$participants, function(p) {
    p$results <- lapply(p$results, function(r) {
      rescored <- tryCatch(
        suppressWarnings(score_questionnaire(r$questionnaire_id, r$answers)),
        error = function(e) NULL
      )
      if (!is.null(rescored)) r$score <- rescored
      r
    })
    p
  })
  obj
}

#' Interpret a questionnaire score
#'
#' Returns a clinical interpretation for a given score on a given
#' questionnaire, matching the score bands used in the ScoreMe app.
#'
#' @param id Character. Questionnaire identifier.
#' @param score Numeric score (or named list for composite instruments).
#'
#' @return A list with elements `label`, `color` (hex), and `description`.
#'
#' @examples
#' interpret_score("ess", 12)
#' interpret_score("meq", 65)
#'
#' @export
interpret_score <- function(id, score) {
  inst <- .INSTRUMENTS[[tolower(id)]]
  if (is.null(inst)) {
    rlang::abort(paste0("Unknown questionnaire id: '", id, "'."))
  }
  inst$interpret(score)
}
