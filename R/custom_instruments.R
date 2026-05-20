# R/custom_instruments.R -- Import custom instruments from ScoreMe JSON specs
#
# Allows researchers to load any questionnaire defined as a ScoreMe-compatible
# JSON file and use it immediately with score_questionnaire(), scores_wide(),
# scores_long(), and items_long() -- without modifying tallieR source code.
#
# Public API:
#   load_instrument(path)         -> named list (single registry entry)
#   load_instrument_dir(dir)      -> named list of registry entries
#
# The compiled registry entries are compatible with .INSTRUMENTS and can be
# passed to score_questionnaire() via its `instruments` argument, or merged
# into a user-managed registry.

# ─── Internal: compile a ScoreMe JSON spec into a registry entry ─────────────

#' @keywords internal
.compile_scoring_fn <- function(spec) {
  method <- spec[["scoringMethod"]]

  if (is.null(method)) {
    return(function(answers) NA_real_)
  }

  type       <- method[["type"]]   %||% "sum"
  item_ids   <- method[["items"]]  %||% vapply(spec[["items"]], `[[`, character(1), "id")
  yes_value  <- as.numeric(method[["yesValue"]]  %||% 1)
  multiplier <- as.numeric(method[["multiplier"]] %||% 1)

  # Build item lookup: id -> type (needed to handle yes_no correctly)
  item_types <- stats::setNames(
    vapply(spec[["items"]], function(it) it[["type"]] %||% "scale_0_3", character(1)),
    vapply(spec[["items"]], `[[`, character(1), "id")
  )

  .get_value <- function(answers, item_id) {
    raw <- answers[[item_id]]
    if (is.null(raw)) return(NA_real_)
    itype <- item_types[[item_id]] %||% ""
    if (identical(itype, "yes_no")) {
      return(if (identical(raw, "yes")) yes_value else 0)
    }
    as.numeric(raw)
  }

  if (type %in% c("sum", "weighted_sum")) {
    function(answers) {
      vals <- vapply(item_ids, .get_value, numeric(1), answers = answers)
      sum(vals, na.rm = TRUE) * multiplier
    }
  } else if (type == "mean") {
    function(answers) {
      vals <- vapply(item_ids, .get_value, numeric(1), answers = answers)
      round(mean(vals, na.rm = TRUE) * multiplier, 1)
    }
  } else {
    # "composite" or unknown -- scoring cannot be auto-compiled
    function(answers) {
      rlang::warn(paste0(
        "Instrument '", spec[["id"]], "' uses composite scoring that cannot ",
        "be auto-compiled from the JSON spec. Returning NA. ",
        "Supply a custom score() function via load_instrument() if needed."
      ))
      NA_real_
    }
  }
}

#' @keywords internal
.compile_interpret_fn <- function(spec) {
  bands     <- spec[["scoreBands"]]
  direction <- spec[["scoreBandDirection"]] %||% "asc"

  if (is.null(bands) || length(bands) == 0) {
    return(function(score) list(label = NA_character_, color = NA_character_, description = NA_character_))
  }

  function(score) {
    s <- if (is.list(score)) score[[1]] else as.numeric(score)
    if (is.na(s) || is.null(s)) {
      return(list(label = NA_character_, color = NA_character_, description = NA_character_))
    }
    for (band in bands) {
      lo <- as.numeric(band[["min"]])
      hi <- as.numeric(band[["max"]])
      if (s >= lo && s <= hi) {
        return(list(
          label       = band[["label"]]       %||% NA_character_,
          color       = band[["color"]]       %||% "#4A7BB5",
          description = band[["description"]] %||% NA_character_
        ))
      }
    }
    # Score outside all bands
    list(label = "Out of range", color = "#9E9E9E", description = paste0("Score ", s, " is outside the defined score bands."))
  }
}

#' @keywords internal
.compile_instrument <- function(spec) {
  required <- c("id", "title", "items")
  missing  <- required[!required %in% names(spec)]
  if (length(missing) > 0) {
    rlang::abort(paste0(
      "Invalid instrument spec: missing required field(s): ",
      paste(missing, collapse = ", "), "."
    ))
  }

  list(
    title       = spec[["title"]]      %||% spec[["id"]],
    domain      = spec[["domain"]]     %||% "Custom",
    max_score   = as.numeric(spec[["maxScore"]] %||% NA_real_),
    beta        = isTRUE(spec[["beta"]]),
    score       = .compile_scoring_fn(spec),
    interpret   = .compile_interpret_fn(spec),
    spec        = spec  # preserve original for documentation / display
  )
}

# ─── Public API ───────────────────────────────────────────────────────────────

#' Load a custom instrument from a ScoreMe JSON spec
#'
#' Reads a `.json` file produced for (or exported from) the ScoreMe app and
#' compiles it into a tallieR registry entry. The result can be passed to
#' [score_questionnaire()] via its `instruments` argument, combined with other
#' custom entries using [c()], or stored in a project-level list for reuse.
#'
#' **Supported scoring types:** `"sum"`, `"weighted_sum"`, `"mean"`. For
#' instruments with `"composite"` scoring (e.g. PSQI-style multi-component
#' algorithms) the returned entry will score as `NA` and a warning is emitted
#' each time scoring is attempted. You can override the compiled `score`
#' function by assigning a custom one after loading (see examples).
#'
#' @param path Path to a `.json` file containing a ScoreMe instrument spec.
#'   See `vignette("custom-instruments")` or
#'   `system.file("extdata", "example_instrument.json", package = "tallieR")`
#'   for the expected schema.
#'
#' @return A named list (a single tallieR registry), where the name is the
#'   instrument `id` from the spec. Invisibly also carries the original spec
#'   in `$<id>$spec`.
#'
#' @examples
#' \dontrun{
#' my_instr <- load_instrument("path/to/fss.json")
#'
#' # Score a single result
#' score_questionnaire("fss", answers, instruments = my_instr)
#'
#' # Combine with another custom instrument
#' registry <- c(load_instrument("fss.json"), load_instrument("vas_pain.json"))
#'
#' # Override scoring for a composite instrument
#' my_psqi <- load_instrument("psqi_custom.json")
#' my_psqi$psqi_custom$score <- function(answers) { ... }
#' }
#'
#' @seealso [load_instrument_dir()], [score_questionnaire()],
#'   [available_instruments()]
#'
#' @export
load_instrument <- function(path) {
  if (!file.exists(path)) {
    rlang::abort(paste0("File not found: ", path))
  }

  raw <- tryCatch(
    jsonlite::read_json(path, simplifyVector = FALSE),
    error = function(e) rlang::abort(paste0("Failed to parse JSON from '", path, "': ", e$message))
  )

  entry <- .compile_instrument(raw)
  id    <- raw[["id"]]

  registry <- stats::setNames(list(entry), id)

  cli::cli_alert_success(
    "Loaded instrument {.val {raw$title}} ({.val {id}}) from {.path {basename(path)}}"
  )

  registry
}

#' Load all custom instruments from a directory
#'
#' Reads every `.json` file in `dir`, compiles each as a tallieR registry
#' entry, and returns a combined named list suitable for passing to
#' [score_questionnaire()].
#'
#' @param dir Path to a directory containing ScoreMe instrument JSON files.
#' @param pattern Regular expression used to filter filenames. Defaults to
#'   `"\\.json$"`.
#'
#' @return A named list of registry entries (one per successfully loaded file).
#'
#' @examples
#' \dontrun{
#' custom <- load_instrument_dir("instruments/")
#' score_questionnaire("fss", answers, instruments = custom)
#' }
#'
#' @seealso [load_instrument()], [score_questionnaire()]
#'
#' @export
load_instrument_dir <- function(dir, pattern = "\\.json$") {
  if (!dir.exists(dir)) {
    rlang::abort(paste0("Directory not found: ", dir))
  }

  files <- list.files(dir, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) {
    rlang::warn(paste0("No JSON files found in: ", dir))
    return(list())
  }

  cli::cli_alert_info("Loading {length(files)} instrument spec{?s} from {.path {dir}}")

  results <- lapply(files, function(f) {
    tryCatch(load_instrument(f), error = function(e) {
      cli::cli_alert_warning("Skipping {.file {basename(f)}}: {e$message}")
      NULL
    })
  })
  results <- Filter(Negate(is.null), results)

  # Flatten list-of-registries into one registry
  do.call(c, results)
}
