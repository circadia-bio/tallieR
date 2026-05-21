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
#
# .INSTRUMENTS is assembled in R/zzz.R, which is sourced last, after all
# domain files (questionnaires_*.R) have been loaded. Referencing the
# domain lists here at top level would fail if this file sorts before them
# alphabetically (e.g. because custom_instruments.R forces a re-sort).
# Functions below reference .INSTRUMENTS only inside their bodies, which
# are not evaluated until called -- so load order doesn't matter there.

.INSTRUMENTS <- list()   # populated by .onLoad() in zzz.R

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
#' algorithm embedded in tallieR, or a custom scoring function compiled from
#' a ScoreMe JSON spec via [load_instrument()].
#'
#' @param id Character. Questionnaire identifier (e.g. `"ess"`, `"psqi"`).
#'   See [available_instruments()] for valid IDs. For custom instruments,
#'   this must match the `id` field in the spec passed to `instruments`.
#' @param answers A named list of item responses, as exported by ScoreMe.
#'   Keys are item IDs (e.g. `"ess1"`, `"psqi2"`); values are the raw
#'   responses (numeric, character `"yes"`/`"no"`, or clock-time list).
#' @param instruments An optional named list of additional instrument
#'   registry entries, as returned by [load_instrument()] or
#'   [load_instrument_dir()]. These are searched first, before the built-in
#'   registry, so a custom entry can override a built-in if needed.
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
#' \dontrun{
#' # Score using a custom instrument loaded from a JSON spec
#' my_instr <- load_instrument("path/to/fss.json")
#' score_questionnaire("fss", answers, instruments = my_instr)
#' }
#'
#' @seealso [load_instrument()], [load_instrument_dir()]
#'
#' @export
score_questionnaire <- function(id, answers, instruments = NULL) {
  # Custom instruments take precedence over built-ins
  registry <- if (!is.null(instruments)) c(instruments, .INSTRUMENTS) else .INSTRUMENTS
  inst <- registry[[tolower(id)]]
  if (is.null(inst)) {
    rlang::abort(paste0(
      "Unknown questionnaire id: '", id, "'. ",
      "Use available_instruments() to see valid IDs, or load a custom ",
      "instrument with load_instrument()."
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
#' @param instruments An optional named list of additional registry entries
#'   from [load_instrument()] or [load_instrument_dir()], merged with the
#'   built-in registry before scoring. Entries in `instruments` take
#'   precedence over built-ins with the same id.
#'
#' @return The same object with scores updated in-place.
#'
#' @export
score_all <- function(obj, instruments = NULL) {
  obj$participants <- lapply(obj$participants, function(p) {
    p$results <- lapply(p$results, function(r) {
      rescored <- tryCatch(
        suppressWarnings(score_questionnaire(r$questionnaire_id, r$answers, instruments = instruments)),
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
#' @param instruments An optional named list of additional registry entries
#'   from [load_instrument()] or [load_instrument_dir()].
#'
#' @return A list with elements `label`, `color` (hex), and `description`.
#'
#' @examples
#' interpret_score("ess", 12)
#' interpret_score("meq", 65)
#'
#' @export
interpret_score <- function(id, score, instruments = NULL) {
  registry <- if (!is.null(instruments)) c(instruments, .INSTRUMENTS) else .INSTRUMENTS
  inst <- registry[[tolower(id)]]
  if (is.null(inst)) {
    rlang::abort(paste0("Unknown questionnaire id: '", id, "'."))
  }
  inst$interpret(score)
}

#' Interpret all questionnaire scores in an export
#'
#' Returns a long data frame with one row per participant x questionnaire x
#' administration, augmented with clinical interpretation columns (`label`,
#' `color`, `description`). Mirrors the shape of [scores_long()] so the two
#' can be joined by `participant_id` + `questionnaire_id` + `completed_at`.
#'
#' Scores that cannot be interpreted (unknown instrument, `NA` score, or
#' composite score with no matching band) return `NA` in all three
#' interpretation columns rather than an error, so the rest of the study
#' data is unaffected.
#'
#' @param obj A `tallier_export` or `tallier_study` object.
#' @param include_meta Logical. If `TRUE` (default), participant metadata
#'   columns are prepended (same columns as [scores_long()]).
#' @param instruments An optional named list of additional registry entries
#'   from [load_instrument()] or [load_instrument_dir()].
#'
#' @return A `data.frame` with columns: participant metadata (optional),
#'   `questionnaire_id`, `completed_at`, `score`, `label`, `color`,
#'   `description`.
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#' interps <- interpret_all(study)
#'
#' # Join with scores_long() if you need both
#' scores <- scores_long(study)
#' full   <- merge(scores, interps[
#'   c("participant_id", "questionnaire_id", "completed_at",
#'     "label", "color", "description")
#' ], by = c("participant_id", "questionnaire_id", "completed_at"),
#'   all.x = TRUE)
#' }
#'
#' @seealso [interpret_score()], [scores_long()]
#'
#' @export
interpret_all <- function(obj, include_meta = TRUE, instruments = NULL) {
  participants <- obj[["participants"]]

  rows <- purrr::map_dfr(participants, function(p) {
    meta <- p$meta

    if (length(p$results) == 0L) return(NULL)

    purrr::map_dfr(p$results, function(r) {
      interp <- tryCatch(
        suppressWarnings(interpret_score(r$questionnaire_id, r$score, instruments = instruments)),
        error = function(e) list(label = NA_character_, color = NA_character_, description = NA_character_)
      )

      score_val <- r$score
      if (is.list(score_val)) {
        score_val <- jsonlite::toJSON(score_val, auto_unbox = TRUE)
      }

      data.frame(
        participant_id   = meta$participant_id %||% NA_character_,
        code             = meta$code           %||% NA_character_,
        questionnaire_id = r$questionnaire_id,
        completed_at     = r$completed_at,
        score            = as.character(score_val),
        label            = interp$label       %||% NA_character_,
        color            = interp$color       %||% NA_character_,
        description      = interp$description %||% NA_character_,
        stringsAsFactors = FALSE
      )
    })
  })

  if (is.null(rows) || nrow(rows) == 0L) return(data.frame())

  if (include_meta) {
    meta_df <- purrr::map_dfr(participants, function(p) {
      as.data.frame(p$meta, stringsAsFactors = FALSE)
    })
    rows <- merge(meta_df, rows,
                  by = c("participant_id", "code"),
                  all.y = TRUE)
  }

  rows
}
