# R/questionnaires.R — Scoring functions for all built-in ScoreMe instruments
#
# Each instrument has:
#   .score_<id>(answers)     → numeric (or named list for PSQI components)
#   .interpret_<id>(score)   → list(label, color, description)
#
# The public API routes through score_questionnaire() and interpret_score().

# ─── ESS ──────────────────────────────────────────────────────────────────────

.score_ess <- function(answers) {
  keys <- paste0("ess", 1:8)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_ess <- function(score) {
  if (score <= 7)  return(list(label = "Normal",     color = "#2E7D32", description = "Daytime sleepiness is within the normal range."))
  if (score <= 9)  return(list(label = "Borderline", color = "#F59E0B", description = "Borderline score. Consider monitoring sleep habits."))
  if (score <= 15) return(list(label = "Excessive",  color = "#EA580C", description = "Excessive daytime sleepiness. Consider clinical review."))
  list(label = "Severe", color = "#DC2626", description = "Severe excessive daytime sleepiness. Recommend medical advice.")
}

# ─── ISI ──────────────────────────────────────────────────────────────────────

.score_isi <- function(answers) {
  keys <- paste0("isi", 1:7)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_isi <- function(score) {
  if (score <= 7)  return(list(label = "No clinically significant insomnia", color = "#2E7D32", description = "No clinically significant insomnia."))
  if (score <= 14) return(list(label = "Subthreshold insomnia",              color = "#F59E0B", description = "Subthreshold insomnia. Consider sleep hygiene education."))
  if (score <= 21) return(list(label = "Clinical insomnia (moderate)",        color = "#EA580C", description = "Moderate clinical insomnia. Consider professional support."))
  list(label = "Clinical insomnia (severe)", color = "#DC2626", description = "Severe clinical insomnia. Recommend medical evaluation.")
}

# ─── DBAS-16 ──────────────────────────────────────────────────────────────────

.score_dbas16 <- function(answers) {
  keys  <- paste0("dbas", 1:16)
  total <- sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
  round(total / 16, 1)
}

.interpret_dbas16 <- function(score) {
  if (score <= 4) return(list(label = "Within normal range",        color = "#2E7D32", description = "Beliefs and attitudes about sleep are broadly within the normal range."))
  list(label = "Clinically relevant beliefs", color = "#EA580C", description = "Dysfunctional beliefs about sleep that may be worth exploring in therapy.")
}

# ─── MEQ ──────────────────────────────────────────────────────────────────────

.score_meq <- function(answers) {
  keys <- paste0("meq", 1:19)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_meq <- function(score) {
  if (score >= 70) return(list(label = "Definite morning type", color = "#F59E0B", description = "Definite morning type (early bird)."))
  if (score >= 59) return(list(label = "Moderate morning type", color = "#84CC16", description = "Moderate preference for mornings."))
  if (score >= 42) return(list(label = "Intermediate type",     color = "#2E7D32", description = "Intermediate chronotype — neither strongly morning nor evening."))
  if (score >= 31) return(list(label = "Moderate evening type", color = "#6366F1", description = "Moderate preference for evenings."))
  list(label = "Definite evening type", color = "#7C3AED", description = "Definite evening type (night owl).")
}

# ─── PSQI ─────────────────────────────────────────────────────────────────────
# Returns a named list of component scores C1–C7 and the global score.

.score_psqi <- function(answers) {
  .a <- function(k, default = 0) as.numeric(answers[[k]] %||% default)
  .time_hm <- function(k, default_h, default_m) {
    v <- answers[[k]]
    if (is.null(v) || !is.list(v)) return(default_h + default_m / 60)
    h <- as.numeric(v[["hour"]] %||% default_h)
    m <- as.numeric(v[["minute"]] %||% default_m)
    h + m / 60
  }

  c1 <- .a("psqi9")

  sol      <- .a("psqi2", 20)
  sol_sc   <- if (sol <= 15) 0L else if (sol <= 30) 1L else if (sol <= 60) 2L else 3L
  c2_raw   <- sol_sc + .a("psqi5a")
  c2       <- if (c2_raw == 0) 0L else if (c2_raw <= 2) 1L else if (c2_raw <= 4) 2L else 3L

  sd       <- .a("psqi4", 7)
  c3       <- if (sd >= 7) 0L else if (sd >= 6) 1L else if (sd >= 5) 2L else 3L

  bt_h     <- .time_hm("psqi1", 23, 0)
  wt_h     <- .time_hm("psqi3",  7, 0)
  tib_h    <- wt_h - bt_h
  if (tib_h <= 0) tib_h <- tib_h + 24
  hse      <- if (tib_h > 0) (sd / tib_h) * 100 else 0
  c4       <- if (hse >= 85) 0L else if (hse >= 75) 1L else if (hse >= 65) 2L else 3L

  dist_keys <- paste0("psqi5", letters[2:9])
  dist_sum  <- sum(vapply(dist_keys, .a, numeric(1)))
  c5        <- if (dist_sum == 0) 0L else if (dist_sum <= 9) 1L else if (dist_sum <= 18) 2L else 3L

  c6 <- .a("psqi6")

  c7_raw <- .a("psqi7") + .a("psqi8")
  c7     <- if (c7_raw == 0) 0L else if (c7_raw <= 2) 1L else if (c7_raw <= 4) 2L else 3L

  global <- c1 + c2 + c3 + c4 + c5 + c6 + c7

  list(global = global, C1 = c1, C2 = c2, C3 = c3, C4 = c4, C5 = c5, C6 = c6, C7 = c7)
}

.interpret_psqi <- function(score) {
  # score may be the global number or the list returned above
  g <- if (is.list(score)) score[["global"]] else as.numeric(score)
  if (g <= 4)  return(list(label = "Good sleep quality",       color = "#2E7D32", description = "Good overall sleep quality."))
  if (g <= 10) return(list(label = "Poor sleep quality",       color = "#F59E0B", description = "Poor sleep quality. Consider sleep hygiene improvements."))
  list(label = "Severe sleep difficulties", color = "#DC2626", description = "Severe sleep difficulties. Recommend medical evaluation.")
}

# ─── RU-SATED ─────────────────────────────────────────────────────────────────

.score_rusated <- function(answers) {
  keys <- paste0("rus", 1:6)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_rusated <- function(score) {
  if (score >= 17) return(list(label = "Good sleep health",     color = "#2E7D32", description = "Good multidimensional sleep health."))
  if (score >= 9)  return(list(label = "Moderate sleep health", color = "#F59E0B", description = "Moderate sleep health. There may be room for improvement."))
  list(label = "Poor sleep health", color = "#DC2626", description = "Poor sleep health across multiple dimensions.")
}

# ─── STOP-BANG ────────────────────────────────────────────────────────────────

.score_stopbang <- function(answers) {
  keys <- c("sb_s", "sb_t", "sb_o", "sb_p", "sb_b", "sb_a", "sb_n", "sb_g")
  sum(vapply(keys, function(k) if (identical(answers[[k]], "yes")) 1L else 0L, integer(1)))
}

.interpret_stopbang <- function(score) {
  if (score <= 2) return(list(label = "Low OSA risk",          color = "#2E7D32", description = "Low risk for obstructive sleep apnoea."))
  if (score <= 4) return(list(label = "Intermediate OSA risk", color = "#F59E0B", description = "Intermediate OSA risk. Consider further evaluation."))
  list(label = "High OSA risk", color = "#DC2626", description = "High OSA risk. Recommend medical evaluation.")
}

# ─── KSS ──────────────────────────────────────────────────────────────────────

.score_kss <- function(answers) {
  as.numeric(answers[["kss1"]] %||% NA_real_)
}

.interpret_kss <- function(score) {
  if (is.na(score)) return(list(label = NA_character_, color = NA_character_, description = NA_character_))
  if (score <= 5)   return(list(label = "Alert",               color = "#2E7D32", description = "Adequately alert for most tasks."))
  if (score == 6)   return(list(label = "Onset of sleepiness", color = "#F59E0B", description = "Early signs of sleepiness. Caution for safety-critical tasks."))
  if (score <= 8)   return(list(label = "Moderate sleepiness", color = "#EA580C", description = "Moderate sleepiness — performance impairment likely."))
  list(label = "Severe sleepiness", color = "#DC2626", description = "Severe sleepiness — significant risk of performance failure.")
}

# ─── MCTQ ─────────────────────────────────────────────────────────────────────
# Answers expected:
#   bt_w, sl_w, wt_w  — bed time, sleep latency (min), wake time on workdays
#   bt_f, sl_f, wt_f  — same for free days
#   wd                — number of workdays per week (integer, 0–7)
# Times are lists {hour, minute} or decimal hours; latency is numeric minutes.

.parse_hm <- function(x, default = 0) {
  if (is.null(x)) return(as.numeric(default))
  if (is.list(x)) {
    h <- as.numeric(x[["hour"]]   %||% x[["hours"]]   %||% 0)
    m <- as.numeric(x[["minute"]] %||% x[["minutes"]] %||% 0)
    return(h + m / 60)
  }
  as.numeric(x)
}

.score_mctq <- function(answers) {
  bt_w <- .parse_hm(answers[["bt_w"]], 23)
  sl_w <- as.numeric(answers[["sl_w"]] %||% 15) / 60   # minutes → hours
  wt_w <- .parse_hm(answers[["wt_w"]], 7)
  bt_f <- .parse_hm(answers[["bt_f"]], 23)
  sl_f <- as.numeric(answers[["sl_f"]] %||% 15) / 60
  wt_f <- .parse_hm(answers[["wt_f"]], 7)
  wd   <- as.numeric(answers[["wd"]]   %||% 5)
  fd   <- 7 - wd

  # Handle overnight: if wake < bed, wake is next day
  so_w <- bt_w + sl_w
  sd_w <- wt_w - so_w; if (sd_w <= 0) sd_w <- sd_w + 24
  msw  <- so_w + sd_w / 2

  so_f <- bt_f + sl_f
  sd_f <- wt_f - so_f; if (sd_f <= 0) sd_f <- sd_f + 24
  msf  <- so_f + sd_f / 2

  # MSFsc: correct for sleep debt on workdays
  sd_week  <- (sd_w * wd + sd_f * fd) / 7
  deficit  <- sd_week - sd_w
  msfsc    <- if (deficit > 0) msf - deficit / 2 else msf

  # Social jetlag
  sjl <- abs(msf - msw)

  list(msfsc = round(msfsc %% 24, 2), sjl = round(sjl, 2),
       msw = round(msw %% 24, 2), msf = round(msf %% 24, 2),
       sd_w = round(sd_w, 2), sd_f = round(sd_f, 2))
}

.interpret_mctq <- function(score) {
  msfsc <- if (is.list(score)) score[["msfsc"]] else as.numeric(score)
  sjl   <- if (is.list(score)) score[["sjl"]]   else NA_real_

  chrono <- if (msfsc < 0.5)       list(label = "Extremely early chronotype", color = "#F59E0B")
  else if (msfsc < 2.5)            list(label = "Early chronotype",           color = "#84CC16")
  else if (msfsc < 3.5)            list(label = "Intermediate chronotype",    color = "#2E7D32")
  else if (msfsc < 5.5)            list(label = "Late chronotype",            color = "#6366F1")
  else                             list(label = "Extremely late chronotype",  color = "#7C3AED")

  sjl_desc <- if (is.na(sjl))  ""
  else if (sjl < 1)  " Low social jetlag (< 1 h)."
  else if (sjl < 2)  " Moderate social jetlag (1–2 h)."
  else               " High social jetlag (> 2 h)."

  list(label       = chrono$label,
       color       = chrono$color,
       description = paste0(chrono$label, ".", sjl_desc))
}

# ─── Registry ─────────────────────────────────────────────────────────────────

.INSTRUMENTS <- list(
  ess      = list(title = "Epworth Sleepiness Scale",                    score = .score_ess,      interpret = .interpret_ess,      domain = "Sleep",  max_score = 24),
  isi      = list(title = "Insomnia Severity Index",                     score = .score_isi,      interpret = .interpret_isi,      domain = "Sleep",  max_score = 28),
  dbas16   = list(title = "Dysfunctional Beliefs and Attitudes about Sleep (DBAS-16)", score = .score_dbas16, interpret = .interpret_dbas16, domain = "Sleep", max_score = 10),
  meq      = list(title = "Morningness-Eveningness Questionnaire",       score = .score_meq,      interpret = .interpret_meq,      domain = "Sleep",  max_score = 86),
  psqi     = list(title = "Pittsburgh Sleep Quality Index",              score = .score_psqi,     interpret = .interpret_psqi,     domain = "Sleep",  max_score = 21),
  rusated  = list(title = "RU-SATED Sleep Health Scale",                 score = .score_rusated,  interpret = .interpret_rusated,  domain = "Sleep",  max_score = 24),
  stopbang = list(title = "STOP-BANG Questionnaire",                     score = .score_stopbang, interpret = .interpret_stopbang, domain = "Sleep",  max_score = 8),
  kss      = list(title = "Karolinska Sleepiness Scale",                 score = .score_kss,      interpret = .interpret_kss,      domain = "Sleep",  max_score = 10),
  mctq     = list(title = "Munich Chronotype Questionnaire",              score = .score_mctq,     interpret = .interpret_mctq,     domain = "Sleep",  max_score = NA_real_)
)

# ─── Public API ───────────────────────────────────────────────────────────────

#' List available instruments
#'
#' Returns a data frame listing all built-in questionnaires supported by
#' tallieR, with their IDs, full titles, clinical domain, and maximum score.
#'
#' @return A `data.frame` with columns `id`, `title`, `domain`, `max_score`.
#'
#' @examples
#' available_instruments()
#'
#' @export
available_instruments <- function() {
  data.frame(
    id        = names(.INSTRUMENTS),
    title     = vapply(.INSTRUMENTS, `[[`, character(1), "title"),
    domain    = vapply(.INSTRUMENTS, `[[`, character(1), "domain"),
    max_score = vapply(.INSTRUMENTS, `[[`, numeric(1),   "max_score"),
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
#' @return For most instruments: a single numeric score. For PSQI: a named
#'   list with the global score and component scores C1–C7.
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
        score_questionnaire(r$questionnaire_id, r$answers),
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
#' @param score Numeric score (or named list for PSQI).
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
