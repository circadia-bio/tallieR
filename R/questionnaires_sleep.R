# R/questionnaires_sleep.R -- Sleep domain instruments
#
# ESS · ISI · DBAS-16 · MEQ · PSQI · RU-SATED · STOP-BANG · KSS · MCTQ
#
# Each instrument exposes:
#   .score_<id>(answers)     -> numeric (or named list for PSQI / MCTQ)
#   .interpret_<id>(score)   -> list(label, color, description)

# --- ESS ----------------------------------------------------------------------

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

# --- ISI ----------------------------------------------------------------------

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

# --- DBAS-16 ------------------------------------------------------------------

.score_dbas16 <- function(answers) {
  keys  <- paste0("dbas", 1:16)
  total <- sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
  round(total / 16, 1)
}

.interpret_dbas16 <- function(score) {
  if (score <= 4) return(list(label = "Within normal range",        color = "#2E7D32", description = "Beliefs and attitudes about sleep are broadly within the normal range."))
  list(label = "Clinically relevant beliefs", color = "#EA580C", description = "Dysfunctional beliefs about sleep that may be worth exploring in therapy.")
}

# --- MEQ ----------------------------------------------------------------------

.score_meq <- function(answers) {
  keys <- paste0("meq", 1:19)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_meq <- function(score) {
  if (score >= 70) return(list(label = "Definite morning type", color = "#F59E0B", description = "Definite morning type (early bird)."))
  if (score >= 59) return(list(label = "Moderate morning type", color = "#84CC16", description = "Moderate preference for mornings."))
  if (score >= 42) return(list(label = "Intermediate type",     color = "#2E7D32", description = "Intermediate chronotype -- neither strongly morning nor evening."))
  if (score >= 31) return(list(label = "Moderate evening type", color = "#6366F1", description = "Moderate preference for evenings."))
  list(label = "Definite evening type", color = "#7C3AED", description = "Definite evening type (night owl).")
}

# --- PSQI ---------------------------------------------------------------------
# Returns a named list of component scores C1-C7 and the global score.

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
  g <- if (is.list(score)) score[["global"]] else as.numeric(score)
  if (g <= 4)  return(list(label = "Good sleep quality",       color = "#2E7D32", description = "Good overall sleep quality."))
  if (g <= 10) return(list(label = "Poor sleep quality",       color = "#F59E0B", description = "Poor sleep quality. Consider sleep hygiene improvements."))
  list(label = "Severe sleep difficulties", color = "#DC2626", description = "Severe sleep difficulties. Recommend medical evaluation.")
}

# --- RU-SATED -----------------------------------------------------------------

.score_rusated <- function(answers) {
  keys <- paste0("rus", 1:6)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_rusated <- function(score) {
  if (score >= 17) return(list(label = "Good sleep health",     color = "#2E7D32", description = "Good multidimensional sleep health."))
  if (score >= 9)  return(list(label = "Moderate sleep health", color = "#F59E0B", description = "Moderate sleep health. There may be room for improvement."))
  list(label = "Poor sleep health", color = "#DC2626", description = "Poor sleep health across multiple dimensions.")
}

# --- STOP-BANG ----------------------------------------------------------------

.score_stopbang <- function(answers) {
  keys <- c("sb_s", "sb_t", "sb_o", "sb_p", "sb_b", "sb_a", "sb_n", "sb_g")
  sum(vapply(keys, function(k) if (identical(answers[[k]], "yes")) 1L else 0L, integer(1)))
}

.interpret_stopbang <- function(score) {
  if (score <= 2) return(list(label = "Low OSA risk",          color = "#2E7D32", description = "Low risk for obstructive sleep apnoea."))
  if (score <= 4) return(list(label = "Intermediate OSA risk", color = "#F59E0B", description = "Intermediate OSA risk. Consider further evaluation."))
  list(label = "High OSA risk", color = "#DC2626", description = "High OSA risk. Recommend medical evaluation.")
}

# --- KSS ----------------------------------------------------------------------

.score_kss <- function(answers) {
  as.numeric(answers[["kss1"]] %||% NA_real_)
}

.interpret_kss <- function(score) {
  if (is.na(score)) return(list(label = NA_character_, color = NA_character_, description = NA_character_))
  if (score <= 5)   return(list(label = "Alert",               color = "#2E7D32", description = "Adequately alert for most tasks."))
  if (score == 6)   return(list(label = "Onset of sleepiness", color = "#F59E0B", description = "Early signs of sleepiness. Caution for safety-critical tasks."))
  if (score <= 8)   return(list(label = "Moderate sleepiness", color = "#EA580C", description = "Moderate sleepiness -- performance impairment likely."))
  list(label = "Severe sleepiness", color = "#DC2626", description = "Severe sleepiness -- significant risk of performance failure.")
}

# --- MCTQ ---------------------------------------------------------------------

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
  sl_w <- as.numeric(answers[["sl_w"]] %||% 15) / 60
  wt_w <- .parse_hm(answers[["wt_w"]], 7)
  bt_f <- .parse_hm(answers[["bt_f"]], 23)
  sl_f <- as.numeric(answers[["sl_f"]] %||% 15) / 60
  wt_f <- .parse_hm(answers[["wt_f"]], 7)
  wd   <- as.numeric(answers[["wd"]]   %||% 5)
  fd   <- 7 - wd

  # Sleep onset and duration on workdays
  so_w <- bt_w + sl_w
  sd_w <- wt_w - so_w; if (sd_w <= 0) sd_w <- sd_w + 24
  # Mid-sleep on workdays (clock hours)
  msw  <- so_w + sd_w / 2

  # Sleep onset and duration on free days
  so_f <- bt_f + sl_f
  sd_f <- wt_f - so_f; if (sd_f <= 0) sd_f <- sd_f + 24
  # Mid-sleep on free days (clock hours, uncorrected)
  msf  <- so_f + sd_f / 2

  # Average sleep duration across the full week
  sd_week <- (sd_w * wd + sd_f * fd) / 7

  # MSFsc: MSF corrected for sleep debt accumulated over the workweek.
  # If free-day sleep is longer than workday sleep (positive deficit), the
  # excess is split equally across each free night and subtracted from MSF.
  deficit <- sd_week - sd_w
  msfsc   <- if (deficit > 0) msf - deficit / 2 else msf

  # SJL (absolute): unsigned difference between MSF and MSW.
  # Reflects the magnitude of circadian misalignment regardless of direction.
  sjl <- abs(msf - msw)

  # SJL_rel (relative / signed): MSFsc - MSW, both normalised to clock time.
  # Positive values indicate a later circadian phase on free days (the typical
  # direction); negative values indicate an earlier phase on free days.
  sjl_rel <- (msfsc %% 24) - (msw %% 24)

  # Alarm flags: optional items captured by ScoreMe (yes/no).
  # Returns NA if the item was not included in the export.
  alarm_w <- if (!is.null(answers[["alarm_w"]])) identical(answers[["alarm_w"]], "yes") else NA
  alarm_f <- if (!is.null(answers[["alarm_f"]])) identical(answers[["alarm_f"]], "yes") else NA

  list(
    msfsc   = round(msfsc %% 24, 2),   # Corrected mid-sleep on free days (h, clock time)
    sjl     = round(sjl, 2),            # Absolute social jetlag (h)
    sjl_rel = round(sjl_rel, 2),        # Relative (signed) social jetlag (h)
    msw     = round(msw %% 24, 2),      # Mid-sleep on workdays (h, clock time)
    msf     = round(msf %% 24, 2),      # Mid-sleep on free days (h, clock time)
    sd_w    = round(sd_w, 2),           # Sleep duration on workdays (h)
    sd_f    = round(sd_f, 2),           # Sleep duration on free days (h)
    sd_week = round(sd_week, 2),        # Average sleep duration across the week (h)
    alarm_w = alarm_w,                  # Alarm used on workdays (logical or NA)
    alarm_f = alarm_f                   # Alarm used on free days (logical or NA)
  )
}

.interpret_mctq <- function(score) {
  msfsc <- if (is.list(score)) score[["msfsc"]] else as.numeric(score)
  sjl   <- if (is.list(score)) score[["sjl"]]   else NA_real_

  chrono <- if (msfsc < 0.5)  list(label = "Extremely early chronotype", color = "#F59E0B")
  else if (msfsc < 2.5)       list(label = "Early chronotype",           color = "#84CC16")
  else if (msfsc < 3.5)       list(label = "Intermediate chronotype",    color = "#2E7D32")
  else if (msfsc < 5.5)       list(label = "Late chronotype",            color = "#6366F1")
  else                        list(label = "Extremely late chronotype",  color = "#7C3AED")

  sjl_desc <- if (is.na(sjl))  ""
  else if (sjl < 1)  " Low social jetlag (< 1 h)."
  else if (sjl < 2)  " Moderate social jetlag (1-2 h)."
  else               " High social jetlag (> 2 h)."

  list(label       = chrono$label,
       color       = chrono$color,
       description = paste0(chrono$label, ".", sjl_desc))
}

# --- Registry entry -----------------------------------------------------------

.SLEEP_INSTRUMENTS <- list(
  ess      = list(title = "Epworth Sleepiness Scale",                              score = .score_ess,      interpret = .interpret_ess,      domain = "Sleep",  max_score = 24,        beta = FALSE),
  isi      = list(title = "Insomnia Severity Index",                               score = .score_isi,      interpret = .interpret_isi,      domain = "Sleep",  max_score = 28,        beta = FALSE),
  dbas16   = list(title = "Dysfunctional Beliefs and Attitudes about Sleep (DBAS-16)", score = .score_dbas16, interpret = .interpret_dbas16, domain = "Sleep",  max_score = 10,        beta = FALSE),
  meq      = list(title = "Morningness-Eveningness Questionnaire",                 score = .score_meq,      interpret = .interpret_meq,      domain = "Sleep",  max_score = 86,        beta = FALSE),
  psqi     = list(title = "Pittsburgh Sleep Quality Index",                        score = .score_psqi,     interpret = .interpret_psqi,     domain = "Sleep",  max_score = 21,        beta = FALSE),
  rusated  = list(title = "RU-SATED Sleep Health Scale",                           score = .score_rusated,  interpret = .interpret_rusated,  domain = "Sleep",  max_score = 24,        beta = FALSE),
  stopbang = list(title = "STOP-BANG Questionnaire",                               score = .score_stopbang, interpret = .interpret_stopbang, domain = "Sleep",  max_score = 8,         beta = FALSE),
  kss      = list(title = "Karolinska Sleepiness Scale",                           score = .score_kss,      interpret = .interpret_kss,      domain = "Sleep",  max_score = 10,        beta = FALSE),
  mctq     = list(title = "Munich Chronotype Questionnaire",                       score = .score_mctq,     interpret = .interpret_mctq,     domain = "Sleep",  max_score = NA_real_,  beta = FALSE)
)
