# R/import.R — Read ScoreMe JSON exports
#
# ScoreMe exports a single JSON file with the shape produced by
# participantsToJSON() in storage/storage.js:
#
#   {
#     "exportedAt":       "2026-05-14T10:00:00.000Z",
#     "exportVersion":    "1.0",
#     "participantCount": 12,
#     "participants": [
#       {
#         "id":        "1715680000000",
#         "code":      "P001",
#         "name":      "Alice Smith",
#         "age":       "28",
#         "sex":       "female",
#         "bmi":       "22.4",
#         "group":     "control",
#         "site":      "Newcastle",
#         "session":   "baseline",
#         "diagnosis": "",
#         "medication": "",
#         "referral":  "",
#         "customFields": [{ "label": "shift_worker", "value": "yes" }],
#         "notes":     "",
#         "createdAt": "2026-01-10T09:00:00.000Z",
#         "results": {
#           "ess": [
#             {
#               "questionnaireId": "ess",
#               "completedAt":     "2026-01-10T09:05:00.000Z",
#               "answers":         { "ess1": 2, "ess2": 1, ... },
#               "score":           12
#             }
#           ],
#           "isi": [ ... ]
#         }
#       }
#     ]
#   }
#
# A single-participant export (legacy or one-shot) may also be just the
# participant object directly, or the full envelope above with one entry.

# ─── Internal helpers ─────────────────────────────────────────────────────────

.scalar <- function(x, default = NA_character_) {
  if (is.null(x) || length(x) == 0) return(default)
  as.character(x[[1]])
}

#' @keywords internal
.parse_participant_meta <- function(p) {
  custom <- p[["customFields"]] %||% list()
  custom_df <- if (length(custom) > 0) {
    labels <- vapply(custom, function(cf) cf[["label"]] %||% "", character(1))
    values <- vapply(custom, function(cf) cf[["value"]] %||% "", character(1))
    stats::setNames(as.list(values), labels)
  } else {
    list()
  }

  base <- list(
    participant_id = .scalar(p[["id"]]),
    code           = .scalar(p[["code"]]),
    name           = .scalar(p[["name"]]),
    age            = .scalar(p[["age"]]),
    sex            = .scalar(p[["sex"]]),
    bmi            = .scalar(p[["bmi"]]),
    group          = .scalar(p[["group"]]),
    site           = .scalar(p[["site"]]),
    session        = .scalar(p[["session"]]),
    diagnosis      = .scalar(p[["diagnosis"]]),
    medication     = .scalar(p[["medication"]]),
    referral       = .scalar(p[["referral"]]),
    notes          = .scalar(p[["notes"]]),
    created_at     = .scalar(p[["createdAt"]])
  )

  c(base, custom_df)
}

#' @keywords internal
.parse_result <- function(r, questionnaire_id) {
  list(
    questionnaire_id = questionnaire_id,
    completed_at     = .scalar(r[["completedAt"]]),
    score            = r[["score"]],
    answers          = r[["answers"]] %||% list()
  )
}

#' @keywords internal
.parse_participant <- function(p) {
  meta    <- .parse_participant_meta(p)
  results <- p[["results"]] %||% list()

  # Each key is a questionnaire id; value is a list of result objects (history)
  result_list <- lapply(names(results), function(qid) {
    entries <- results[[qid]]
    # Normalise: can be a single object (legacy) or a list of objects
    if (is.list(entries) && !is.null(entries[["completedAt"]])) {
      entries <- list(entries)
    }
    lapply(entries, .parse_result, questionnaire_id = qid)
  })
  result_list <- unlist(result_list, recursive = FALSE)

  list(meta = meta, results = result_list)
}

# ─── Public API ───────────────────────────────────────────────────────────────

#' Read a ScoreMe JSON export
#'
#' Reads a single JSON file exported from the ScoreMe app and returns a
#' `tallier_export` object containing participant metadata and all
#' questionnaire results.
#'
#' @param path Path to a `.json` file exported from ScoreMe.
#' @param rescore Logical. If `TRUE` (default), scores are recomputed from
#'   item-level answers using the built-in tallieR scoring functions. If
#'   `FALSE`, the scores stored in the export file are used as-is.
#' @param instruments An optional named list of custom instrument registry
#'   entries created by [load_instrument()] or [load_instrument_dir()].
#'   When `rescore = TRUE`, these are merged with the built-in registry so
#'   that custom questionnaires in the export can be scored. Entries in
#'   `instruments` take precedence over built-ins with the same id.
#'
#' @return A `tallier_export` object: a list with elements:
#'   \describe{
#'     \item{`exported_at`}{Timestamp of the export (character).}
#'     \item{`export_version`}{Schema version string.}
#'     \item{`participants`}{A list of parsed participant records.}
#'     \item{`n_participants`}{Number of participants.}
#'   }
#'
#' @examples
#' \dontrun{
#' exp <- read_scoreme("my_study_export.json")
#' print(exp)
#' wide <- scores_wide(exp)
#'
#' # With custom instruments
#' custom <- load_instrument("fss.json")
#' exp    <- read_scoreme("export.json", instruments = custom)
#' wide   <- scores_wide(exp)
#' }
#'
#' @seealso [load_instrument()], [load_instrument_dir()]
#'
#' @export
read_scoreme <- function(path, rescore = TRUE, instruments = NULL) {
  if (!file.exists(path)) {
    rlang::abort(paste0("File not found: ", path))
  }

  raw <- jsonlite::read_json(path, simplifyVector = FALSE)

  # Support both envelope format and bare participant list
  if (!is.null(raw[["participants"]])) {
    participant_list <- raw[["participants"]]
    exported_at      <- raw[["exportedAt"]]      %||% NA_character_
    export_version   <- raw[["exportVersion"]]   %||% "unknown"
  } else if (is.list(raw) && !is.null(raw[[1]][["id"]])) {
    # Bare list of participant objects
    participant_list <- raw
    exported_at      <- NA_character_
    export_version   <- "unknown"
  } else {
    rlang::abort("Unrecognised ScoreMe export format.")
  }

  participants <- lapply(participant_list, .parse_participant)

  if (rescore) {
    participants <- lapply(participants, function(p) {
      p$results <- lapply(p$results, function(r) {
        rescored <- tryCatch(
          score_questionnaire(r$questionnaire_id, r$answers, instruments = instruments),
          error = function(e) NULL
        )
        if (!is.null(rescored)) r$score <- rescored
        r
      })
      p
    })
  }

  structure(
    list(
      exported_at    = exported_at,
      export_version = export_version,
      participants   = participants,
      n_participants = length(participants)
    ),
    class = "tallier_export"
  )
}

#' Read a directory of ScoreMe JSON exports
#'
#' Reads all `.json` files in a directory and combines them into a single
#' `tallier_study` object. Useful when each participant's data was exported
#' as a separate file, or when multiple batch exports need to be merged.
#'
#' @param dir Path to a directory containing `.json` export files.
#' @param rescore Logical. Passed to [read_scoreme()].
#' @param pattern Regular expression used to filter filenames. Defaults to
#'   `"\\.json$"` (all JSON files).
#' @param instruments An optional named list of custom instrument registry
#'   entries, passed through to [read_scoreme()]. See [load_instrument()].
#'
#' @return A `tallier_study` object: a list with elements:
#'   \describe{
#'     \item{`files`}{Character vector of files read.}
#'     \item{`participants`}{Combined list of all participant records.}
#'     \item{`n_participants`}{Total number of participants.}
#'   }
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#' wide  <- scores_wide(study)
#' }
#'
#' @export
read_scoreme_dir <- function(dir, rescore = TRUE, pattern = "\\.json$", instruments = NULL) {
  if (!dir.exists(dir)) {
    rlang::abort(paste0("Directory not found: ", dir))
  }

  files <- list.files(dir, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) {
    rlang::warn(paste0("No JSON files found in: ", dir))
    return(structure(list(files = character(), participants = list(), n_participants = 0L),
                     class = "tallier_study"))
  }

  cli::cli_alert_info("Reading {length(files)} file{?s} from {.path {dir}}")

  exports <- lapply(files, function(f) {
    tryCatch(read_scoreme(f, rescore = rescore, instruments = instruments), error = function(e) {
      cli::cli_alert_warning("Skipping {.file {basename(f)}}: {e$message}")
      NULL
    })
  })
  exports  <- Filter(Negate(is.null), exports)
  all_ppts <- unlist(lapply(exports, `[[`, "participants"), recursive = FALSE)

  cli::cli_alert_success("Loaded {length(all_ppts)} participant{?s}")

  structure(
    list(
      files          = files,
      participants   = all_ppts,
      n_participants = length(all_ppts)
    ),
    class = "tallier_study"
  )
}

#' @export
print.tallier_export <- function(x, ...) {
  instruments <- sort(unique(unlist(lapply(x$participants, function(p) {
    vapply(p$results, `[[`, character(1), "questionnaire_id")
  }))))
  if (length(instruments) > 0L) {
    cli::cli_alert_info(
      "tallier_export: {x$n_participants} participant{?s} | exported {x$exported_at}"
    )
    cli::cli_bullets(c(" " = "Instruments ({length(instruments)}): {paste(instruments, collapse = ', ')}"))
  } else {
    cli::cli_alert_info(
      "tallier_export: {x$n_participants} participant{?s} | exported {x$exported_at} | no results"
    )
  }
  invisible(x)
}

#' @export
print.tallier_study <- function(x, ...) {
  instruments <- sort(unique(unlist(lapply(x$participants, function(p) {
    vapply(p$results, `[[`, character(1), "questionnaire_id")
  }))))
  if (length(instruments) > 0L) {
    cli::cli_alert_info(
      "tallier_study: {x$n_participants} participant{?s} from {length(x$files)} file{?s}"
    )
    cli::cli_bullets(c(" " = "Instruments ({length(instruments)}): {paste(instruments, collapse = ', ')}"))
  } else {
    cli::cli_alert_info(
      "tallier_study: {x$n_participants} participant{?s} from {length(x$files)} file{?s} | no results"
    )
  }
  invisible(x)
}

# ─── Summary helpers ──────────────────────────────────────────────────────────

#' @keywords internal
.summary_stats <- function(participants) {
  n <- length(participants)

  # Collect all result entries across participants
  all_results <- unlist(lapply(participants, `[[`, "results"), recursive = FALSE)

  if (length(all_results) == 0L) {
    return(list(
      n_participants    = n,
      instruments       = character(0),
      completion        = data.frame(questionnaire_id = character(0),
                                     n = integer(0),
                                     pct = numeric(0),
                                     stringsAsFactors = FALSE),
      date_range        = c(min = NA_character_, max = NA_character_)
    ))
  }

  # Unique instruments and per-instrument participant counts
  q_ids <- vapply(all_results, `[[`, character(1), "questionnaire_id")
  p_ids <- unlist(lapply(seq_along(participants), function(i) {
    rep(participants[[i]]$meta$participant_id %||% as.character(i),
        length(participants[[i]]$results))
  }))

  instruments <- sort(unique(q_ids))

  completion <- do.call(rbind, lapply(instruments, function(qid) {
    n_with <- length(unique(p_ids[q_ids == qid]))
    data.frame(
      questionnaire_id = qid,
      n   = n_with,
      pct = round(n_with / max(n, 1L) * 100, 1),
      stringsAsFactors = FALSE
    )
  }))

  # Date range from completed_at timestamps
  dates <- vapply(all_results, function(r) r$completed_at %||% NA_character_, character(1))
  dates <- dates[!is.na(dates)]
  date_range <- if (length(dates) > 0L) {
    c(min = min(dates), max = max(dates))
  } else {
    c(min = NA_character_, max = NA_character_)
  }

  list(
    n_participants = n,
    instruments    = instruments,
    completion     = completion,
    date_range     = date_range
  )
}

#' Summarise a tallier_export object
#'
#' Prints a structured overview of a `tallier_export`, including participant
#' count, instruments present, per-instrument completion rates, and the date
#' range of administrations. The summary statistics are also returned
#' invisibly as a list for programmatic use.
#'
#' @param object A `tallier_export` object.
#' @param ... Ignored.
#'
#' @return Invisibly, a list with elements `n_participants`, `instruments`,
#'   `completion` (a data frame), and `date_range`.
#'
#' @examples
#' \dontrun{
#' exp <- read_scoreme("export.json")
#' summary(exp)
#'
#' # Access stats programmatically
#' s <- summary(exp)
#' s$completion
#' }
#'
#' @export
summary.tallier_export <- function(object, ...) {
  s <- .summary_stats(object$participants)

  cli::cli_h1("tallier_export")
  cli::cli_bullets(c(
    "*" = "Participants: {s$n_participants}",
    "*" = "Exported:     {object$exported_at %||% 'unknown'}",
    "*" = "Instruments:  {length(s$instruments)}"
  ))

  if (length(s$instruments) > 0L) {
    cli::cli_h2("Completion")
    for (i in seq_len(nrow(s$completion))) {
      r <- s$completion[i, ]
      cli::cli_bullets(c(" " = "{r$questionnaire_id}: {r$n}/{s$n_participants} ({r$pct}%)"))
    }
    cli::cli_h2("Date range")
    cli::cli_bullets(c(
      " " = "First: {s$date_range['min']}",
      " " = "Last:  {s$date_range['max']}"
    ))
  }

  invisible(s)
}

#' Summarise a tallier_study object
#'
#' Prints a structured overview of a `tallier_study`, including participant
#' count, number of source files, instruments present, per-instrument
#' completion rates, and the date range of administrations. The summary
#' statistics are also returned invisibly as a list for programmatic use.
#'
#' @param object A `tallier_study` object.
#' @param ... Ignored.
#'
#' @return Invisibly, a list with elements `n_participants`, `n_files`,
#'   `instruments`, `completion` (a data frame), and `date_range`.
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#' summary(study)
#'
#' # Access stats programmatically
#' s <- summary(study)
#' s$completion
#' }
#'
#' @export
summary.tallier_study <- function(object, ...) {
  s <- .summary_stats(object$participants)
  s$n_files <- length(object$files)

  cli::cli_h1("tallier_study")
  cli::cli_bullets(c(
    "*" = "Participants: {s$n_participants}",
    "*" = "Source files: {s$n_files}",
    "*" = "Instruments:  {length(s$instruments)}"
  ))

  if (length(s$instruments) > 0L) {
    cli::cli_h2("Completion")
    for (i in seq_len(nrow(s$completion))) {
      r <- s$completion[i, ]
      cli::cli_bullets(c(" " = "{r$questionnaire_id}: {r$n}/{s$n_participants} ({r$pct}%)"))
    }
    cli::cli_h2("Date range")
    cli::cli_bullets(c(
      " " = "First: {s$date_range['min']}",
      " " = "Last:  {s$date_range['max']}"
    ))
  }

  invisible(s)
}
