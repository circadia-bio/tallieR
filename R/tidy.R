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
#' @param scored_items Logical. If `TRUE`, adds a `response_scored` column
#'   with reverse-scored values applied for instruments that define
#'   `reverse_items` (currently STAI-S and STAI-T). For all other items and
#'   instruments, `response_scored` equals `response`. Non-numeric responses
#'   (e.g. clock-time lists, yes/no) are left as-is. Defaults to `FALSE` to
#'   preserve existing behaviour.
#' @param instruments An optional named list of additional registry entries
#'   from [load_instrument()] or [load_instrument_dir()], used when
#'   `scored_items = TRUE` to resolve reverse-scoring metadata for custom
#'   instruments.
#'
#' @return A `data.frame` with columns: participant metadata (optional),
#'   `questionnaire_id`, `completed_at`, `item_id`, `response`, and
#'   optionally `response_scored`.
#'
#' @export
items_long <- function(obj, include_meta = TRUE, scored_items = FALSE,
                       instruments = NULL) {
  items <- .items_to_df(obj)
  if (is.null(items) || nrow(items) == 0) {
    return(data.frame())
  }

  if (scored_items) {
    registry <- if (!is.null(instruments)) c(instruments, .INSTRUMENTS) else .INSTRUMENTS

    items$response_scored <- mapply(
      function(qid, item_id, response) {
        inst    <- registry[[tolower(qid)]]
        rev_def <- inst[["reverse_items"]]
        if (is.null(rev_def) || !item_id %in% rev_def$item_ids) return(response)
        raw <- suppressWarnings(as.numeric(response))
        if (is.na(raw)) return(response)  # non-numeric (e.g. time, yes/no): leave as-is
        as.character(rev_def$max_val + 1L - raw)
      },
      items$questionnaire_id,
      items$item_id,
      items$response,
      SIMPLIFY = TRUE,
      USE.NAMES = FALSE
    )
  }

  if (include_meta) {
    meta  <- .participants_to_df(obj)
    items <- merge(meta, items,
                   by = c("participant_id", "code"),
                   all.y = TRUE)
  }

  items
}

#' Completion summary
#'
#' Returns a data frame showing which questionnaires each participant has
#' completed. Useful for monitoring data collection progress in longitudinal
#' or multi-site studies.
#'
#' When a participant has completed a questionnaire more than once, it is
#' counted as complete and the most recent `completed_at` timestamp is
#' reported (when `include_date = TRUE`).
#'
#' @param obj A `tallier_export` or `tallier_study` object.
#' @param wide Logical. If `FALSE` (default), returns a long data frame with
#'   one row per participant × questionnaire and a `completed` logical column.
#'   If `TRUE`, returns a wide data frame with one row per participant and one
#'   logical column per questionnaire.
#' @param include_date Logical. If `TRUE` (default), adds a `completed_at`
#'   column in long format showing the timestamp of the most recent
#'   administration. Ignored when `wide = TRUE`.
#' @param include_meta Logical. If `TRUE` (default), participant metadata
#'   columns are prepended.
#'
#' @return In long format: a `data.frame` with columns: participant metadata
#'   (optional), `questionnaire_id`, `completed` (logical), and optionally
#'   `completed_at` (character timestamp of most recent administration).
#'   In wide format: a `data.frame` with one row per participant and one
#'   logical column per questionnaire.
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#'
#' # Long format: one row per participant x questionnaire
#' completion_summary(study)
#'
#' # Wide format: one row per participant
#' completion_summary(study, wide = TRUE)
#'
#' # Without timestamps
#' completion_summary(study, include_date = FALSE)
#' }
#'
#' @seealso [scores_wide()], [scores_long()]
#'
#' @export
completion_summary <- function(obj, wide = FALSE, include_date = TRUE,
                               include_meta = TRUE) {
  participants <- obj[["participants"]]

  if (length(participants) == 0L) return(data.frame())

  # Collect all questionnaire IDs across the whole study
  all_q_ids <- sort(unique(unlist(lapply(participants, function(p) {
    vapply(p$results, `[[`, character(1), "questionnaire_id")
  }))))

  if (length(all_q_ids) == 0L) return(data.frame())

  # Build long table: one row per participant x questionnaire
  rows <- purrr::map_dfr(participants, function(p) {
    meta    <- p$meta
    p_id    <- meta$participant_id %||% NA_character_
    p_code  <- meta$code           %||% NA_character_

    # Index results by questionnaire id -> most recent completed_at
    completed_qs <- list()
    for (r in p$results) {
      qid  <- r$questionnaire_id
      date <- r$completed_at %||% NA_character_
      # Keep the most recent timestamp
      if (is.null(completed_qs[[qid]]) ||
          (!is.na(date) && (is.na(completed_qs[[qid]]) || date > completed_qs[[qid]]))) {
        completed_qs[[qid]] <- date
      }
    }

    purrr::map_dfr(all_q_ids, function(qid) {
      is_complete <- !is.null(completed_qs[[qid]])
      data.frame(
        participant_id   = p_id,
        code             = p_code,
        questionnaire_id = qid,
        completed        = is_complete,
        completed_at     = if (is_complete) completed_qs[[qid]] else NA_character_,
        stringsAsFactors = FALSE
      )
    })
  })

  # Optionally drop the date column
  if (!include_date || wide) {
    rows$completed_at <- NULL
  }

  # Optionally prepend participant metadata
  if (include_meta) {
    meta_df <- .participants_to_df(obj)
    rows    <- merge(meta_df, rows, by = c("participant_id", "code"), all.y = TRUE)
  }

  if (!wide) return(rows)

  # Wide pivot: one logical column per questionnaire
  wide_df <- tidyr::pivot_wider(
    rows[, c("participant_id", "code", "questionnaire_id", "completed")],
    id_cols     = c("participant_id", "code"),
    names_from  = "questionnaire_id",
    values_from = "completed"
  )

  if (include_meta) {
    meta_df <- .participants_to_df(obj)
    wide_df <- merge(meta_df, wide_df, by = c("participant_id", "code"), all.x = TRUE)
  }

  wide_df
}

# ─── as_tibble() S3 methods ────────────────────────────────────────────────────────

#' Coerce a tallier_export to a tibble
#'
#' Converts a `tallier_export` object to a tibble by calling [scores_wide()]
#' and coercing the result. One row per participant, one column per
#' questionnaire, with participant metadata prepended by default.
#'
#' This method is registered for `tibble::as_tibble()` and is available
#' automatically when the `tibble` package is loaded.
#'
#' @param x A `tallier_export` object.
#' @param ... Additional arguments passed to [scores_wide()] (e.g.
#'   `include_meta = FALSE`).
#'
#' @return A tibble; see [scores_wide()] for column details.
#'
#' @examples
#' \dontrun{
#' exp <- read_scoreme("export.json")
#' tibble::as_tibble(exp)
#' tibble::as_tibble(exp, include_meta = FALSE)
#' }
#'
#' @export
as_tibble.tallier_export <- function(x, ...) {
  if (!requireNamespace("tibble", quietly = TRUE)) {
    rlang::abort('Package "tibble" is required. Install it with install.packages("tibble").')
  }
  tibble::as_tibble(scores_wide(x, ...))
}

#' Coerce a tallier_study to a tibble
#'
#' Converts a `tallier_study` object to a tibble by calling [scores_wide()]
#' and coercing the result. One row per participant, one column per
#' questionnaire, with participant metadata prepended by default.
#'
#' This method is registered for `tibble::as_tibble()` and is available
#' automatically when the `tibble` package is loaded.
#'
#' @param x A `tallier_study` object.
#' @param ... Additional arguments passed to [scores_wide()] (e.g.
#'   `include_meta = FALSE`).
#'
#' @return A tibble; see [scores_wide()] for column details.
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#' tibble::as_tibble(study)
#' }
#'
#' @export
as_tibble.tallier_study <- function(x, ...) {
  if (!requireNamespace("tibble", quietly = TRUE)) {
    rlang::abort('Package "tibble" is required. Install it with install.packages("tibble").')
  }
  tibble::as_tibble(scores_wide(x, ...))
}
