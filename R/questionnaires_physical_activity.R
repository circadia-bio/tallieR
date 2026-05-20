# R/questionnaires_physical_activity.R -- Physical Activity domain instruments
#
# IPAQ-S · GPAQ
#
# Both instruments score in MET-minutes/week (unbounded upper end).
# All instruments are beta = TRUE.

# --- IPAQ-S -------------------------------------------------------------------

.score_ipaq_short <- function(answers) {
  .n <- function(k) as.numeric(answers[[k]] %||% 0)
  vig  <- .n("ipaq_vigd")  * .n("ipaq_vigm")  * 8.0
  mod  <- .n("ipaq_modd")  * .n("ipaq_modm")  * 4.0
  walk <- .n("ipaq_walkd") * .n("ipaq_walkm") * 3.3
  round(vig + mod + walk)
}

.interpret_ipaq_short <- function(score) {
  if (score < 600)  return(list(label = "Inactive (Low)",              color = "#DC2626", description = "Low physical activity level. Does not meet recommended activity guidelines."))
  if (score < 3000) return(list(label = "Minimally active (Moderate)", color = "#F59E0B", description = "Minimally active. Meets some but not all activity guidelines."))
  list(label = "HEPA Active (High)", color = "#2E7D32", description = "Health-enhancing physical activity level.")
}

# --- GPAQ ---------------------------------------------------------------------

.score_gpaq <- function(answers) {
  .n  <- function(k) as.numeric(answers[[k]] %||% 0)
  .yn <- function(k) if (identical(answers[[k]], "yes")) 1L else 0L
  met <- .yn("gpaq_p1")  * .n("gpaq_p2")  * .n("gpaq_p3")  * 8.0 +
         .yn("gpaq_p4")  * .n("gpaq_p5")  * .n("gpaq_p6")  * 4.0 +
         .yn("gpaq_p7")  * .n("gpaq_p8")  * .n("gpaq_p9")  * 4.0 +
         .yn("gpaq_p10") * .n("gpaq_p11") * .n("gpaq_p12") * 8.0 +
         .yn("gpaq_p13") * .n("gpaq_p14") * .n("gpaq_p15") * 4.0
  round(met)
}

.interpret_gpaq <- function(score) {
  if (score < 600) return(list(label = "Insufficiently active", color = "#DC2626", description = "Insufficient physical activity. Below WHO minimum recommendations."))
  list(label = "Sufficiently active", color = "#2E7D32", description = "Sufficient physical activity. Meets WHO minimum recommendations.")
}

# --- Registry entry -----------------------------------------------------------

.PHYSICAL_ACTIVITY_INSTRUMENTS <- list(
  ipaq_short = list(title = "International Physical Activity Questionnaire - Short Form", score = .score_ipaq_short, interpret = .interpret_ipaq_short, domain = "Physical Activity", max_score = NA_real_, beta = TRUE),
  gpaq       = list(title = "Global Physical Activity Questionnaire",                    score = .score_gpaq,       interpret = .interpret_gpaq,       domain = "Physical Activity", max_score = NA_real_, beta = TRUE)
)
