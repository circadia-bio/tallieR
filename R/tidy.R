# R/tidy.R — Tidy output tables from tallier_export / tallier_study objects

# ─── Internal helpers ─────────────────────────────────────────────────────────

#' @keywords internal
.participants_to_df <- function(obj) {
  # Works on both tallier_export and tallier_study
  participants <- obj[["participants"]]

  purrr::map_dfr(participants, function(p) {
    meta <- p$meta
    as.data.frame(meta, stringsAsFactors = FALSE)
  })
}

#' @keywords internal
.results_to_df <- function(obj) {
  participants <- obj[["participants"]]

  purrr::map_dfr(participants, function(p) {
    meta <- p$meta

    if (length(p$results) == 0) return(NULL)

    purrr::map_dfr(p$results, function(r) {
      score_val <- r$score
      # Flatten composite scores (e.g. named list) to a JSON string
      if (is.list(score_val)) {
        score_val <- jsonlite::toJSON(score_val, auto_unbox = TRUE)
      }
      data.frame(
        participant_id   = meta$participant_id %||% NA_character_,
        code             = meta$code           %||% NA_character_,
        questionnaire_id = r$questionnaire_id,
        completed_at     = r$completed_at,
        score            = as.character(score_val),
        stringsAsFactors = FALSE
      )
    })
  })
}

#' @keywords internal
.items_to_df <- function(obj) {
  participants <- obj[["participants"]]

  purrr::map_dfr(participants, function(p) {
    meta <- p$meta

    if (length(p$results) == 0) return(NULL)

    purrr::map_dfr(p$results, function(r) {
      if (length(r$answers) == 0) return(NULL)

      item_ids  <- names(r$answers)
      item_vals <- vapply(r$answers, function(v) {
        if (is.list(v)) jsonlite::toJSON(v, auto_unbox = TRUE)
        else as.character(v)
      }, character(1))

      data.frame(
        participant_id   = meta$participant_id %||% NA_character_,
        code             = meta$code           %||% NA_character_,
        questionnaire_id = r$questionnaire_id,
        completed_at     = r$completed_at,
        item_id          = item_ids,
        response         = item_vals,
        stringsAsFactors = FALSE
      )
    })
  })
}

# ─── Public API ───────────────────────────────────────────────────────────────

#' Wide score table
#'
#' Returns a data frame with one row per participant and one column per
#' questionnaire. When a participant completed a questionnaire more than once,
#' only the most recent administration is included (use [scores_long()] to
#' retain all administrations).
#'
#' @param obj A `tallier_export` or `tallier_study` object.
#' @param include_meta Logical. If `TRUE` (default), participant metadata
#'   columns (code, name, age, sex, etc.) are prepended.
#'
#' @return A `data.frame` with columns: participant metadata (if requested)
#'   followed by one numeric score column per questionnaire.
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#' wide  <- scores_wide(study)
#' head(wide)
#' }
#'
#' @export
scores_wide <- function(obj, include_meta = TRUE) {
  long  <- scores_long(obj)
  if (nrow(long) == 0) return(long)

  # Keep only the most recent administration per participant × questionnaire
  long <- long[order(long$completed_at, decreasing = TRUE), ]
  long <- long[!duplicated(paste(long$participant_id, long$questionnaire_id)), ]

  wide <- tidyr::pivot_wider(
    long,
    id_cols     = c("participant_id", "code"),
    names_from  = "questionnaire_id",
    values_from = "score"
  )

  if (include_meta) {
    meta <- .participants_to_df(obj)
    wide <- merge(meta, wide, by = c("participant_id", "code"), all.x = TRUE)
  }

  wide
}

#' Long score table
#'
#' Returns a data frame with one row per participant × questionnaire ×
#' administration (i.e. all history is retained).
#'
#' @param obj A `tallier_export` or `tallier_study` object.
#' @param include_meta Logical. If `TRUE` (default), participant metadata
#'   columns are included.
#'
#' @return A `data.frame` with columns: participant metadata (optional),
#'   `questionnaire_id`, `completed_at`, `score`.
#'
#' @export
scores_long <- function(obj, include_meta = TRUE) {
  results <- .results_to_df(obj)
  if (is.null(results) || nrow(results) == 0) {
    return(data.frame())
  }

  if (include_meta) {
    meta    <- .participants_to_df(obj)
    results <- merge(meta, results,
                     by = c("participant_id", "code"),
                     all.y = TRUE)
  }

  results
}

#' Item-level long table
#'
#' Returns a data frame with one row per participant × questionnaire
#' administration × item. Useful for factor analysis, IRT, or item-level
#' reliability checks.
#'
#' @param obj A `tallier_export` or `tallier_study` object.
#' @param include_meta Logical. If `TRUE` (default), participant metadata
#'   columns are included.
#'
#' @return A `data.frame` with columns: participant metadata (optional),
#'   `questionnaire_id`, `completed_at`, `item_id`, `response`.
#'
#' @export
items_long <- function(obj, include_meta = TRUE) {
  items <- .items_to_df(obj)
  if (is.null(items) || nrow(items) == 0) {
    return(data.frame())
  }

  if (include_meta) {
    meta  <- .participants_to_df(obj)
    items <- merge(meta, items,
                   by = c("participant_id", "code"),
                   all.y = TRUE)
  }

  items
}
