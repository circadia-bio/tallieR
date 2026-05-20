# R/questionnaires_wellbeing.R -- Wellbeing domain instruments
#
# WHOQOL-BREF · MacArthur SSS
#
# All instruments are beta = TRUE.

# --- WHOQOL-BREF --------------------------------------------------------------
# Returns list(total, physical, psychological, social, environment).
# Items 3, 4 are reverse-scored via the options encoding in ScoreMe
# (value already encodes the reversal); item 26 uses descending values (5=Never).
# Domain scores are scaled 0-100.

.score_whoqol_bref <- function(answers) {
  .r <- function(k) as.numeric(answers[[k]] %||% 0)
  physical      <- round((.r("whoqol_3") + .r("whoqol_4") + .r("whoqol_10") +
                          .r("whoqol_15") + .r("whoqol_16") + .r("whoqol_17") +
                          .r("whoqol_18")) / 35 * 100)
  psychological <- round((.r("whoqol_5") + .r("whoqol_6") + .r("whoqol_7") +
                          .r("whoqol_11") + .r("whoqol_19") + .r("whoqol_26")) / 30 * 100)
  social        <- round((.r("whoqol_20") + .r("whoqol_21") + .r("whoqol_22")) / 15 * 100)
  environment   <- round((.r("whoqol_8") + .r("whoqol_9") + .r("whoqol_12") +
                          .r("whoqol_13") + .r("whoqol_14") + .r("whoqol_23") +
                          .r("whoqol_24") + .r("whoqol_25")) / 40 * 100)
  total <- round((physical + psychological + social + environment) / 4)
  list(total = total, physical = physical, psychological = psychological,
       social = social, environment = environment)
}

.interpret_whoqol_bref <- function(score) {
  s <- if (is.list(score)) score[["total"]] else as.numeric(score)
  if (s <= 40) return(list(label = "Poor QoL",      color = "#DC2626", description = "Poor quality of life."))
  if (s <= 60) return(list(label = "Moderate QoL",  color = "#EA580C", description = "Moderate quality of life."))
  if (s <= 80) return(list(label = "Good QoL",      color = "#F59E0B", description = "Good quality of life."))
  list(label = "Very good QoL", color = "#2E7D32", description = "Very good quality of life.")
}

# --- MacArthur SSS ------------------------------------------------------------

.score_macarthur_sss <- function(answers) {
  as.numeric(answers[["mac_sss_society"]] %||% 0) +
    as.numeric(answers[["mac_sss_community"]] %||% 0)
}

.interpret_macarthur_sss <- function(score) {
  if (score <= 8)  return(list(label = "Low social status",      color = "#EA580C", description = "Low perceived social status."))
  if (score <= 14) return(list(label = "Moderate social status", color = "#F59E0B", description = "Moderate perceived social status."))
  list(label = "High social status", color = "#2E7D32", description = "High perceived social status.")
}

# --- Registry entry -----------------------------------------------------------

.WELLBEING_INSTRUMENTS <- list(
  whoqol_bref   = list(title = "World Health Organization Quality of Life - Brief version", score = .score_whoqol_bref,   interpret = .interpret_whoqol_bref,   domain = "Wellbeing", max_score = 100,      beta = TRUE),
  macarthur_sss = list(title = "MacArthur Scale of Subjective Social Status",               score = .score_macarthur_sss, interpret = .interpret_macarthur_sss, domain = "Wellbeing", max_score = 20,       beta = TRUE)
)
