# R/questionnaires_mental_health.R -- Mental Health domain instruments
#
# PHQ-2 · PHQ-9 · PHQ-15 · GAD-7 · GAD-2 · BDI-II · BAI · DASS-21 · PANSS · STAI-S · STAI-T
#
# All instruments are beta = TRUE.

# --- PHQ-2 --------------------------------------------------------------------

.score_phq2 <- function(answers) {
  keys <- c("phq2_1", "phq2_2")
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_phq2 <- function(score) {
  if (score <= 2) return(list(label = "Negative screen", color = "#2E7D32", description = "Negative screen for depression."))
  list(label = "Positive screen", color = "#DC2626", description = "Positive screen. Consider follow-up with PHQ-9 or clinical evaluation.")
}

# --- PHQ-9 --------------------------------------------------------------------

.score_phq9 <- function(answers) {
  keys <- paste0("phq9_", 1:9)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_phq9 <- function(score) {
  if (score <= 4)  return(list(label = "Minimal depression",      color = "#2E7D32", description = "Minimal or no depressive symptoms."))
  if (score <= 9)  return(list(label = "Mild depression",         color = "#F59E0B", description = "Mild depression. Watchful waiting recommended."))
  if (score <= 14) return(list(label = "Moderate depression",     color = "#EA580C", description = "Moderate depression. Consider treatment plan."))
  if (score <= 19) return(list(label = "Moderately severe",       color = "#DC2626", description = "Moderately severe depression. Active treatment warranted."))
  list(label = "Severe depression", color = "#7C2D12", description = "Severe depression. Immediate treatment or referral indicated.")
}

# --- PHQ-15 -------------------------------------------------------------------

.score_phq15 <- function(answers) {
  keys <- paste0("phq15_", 1:15)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_phq15 <- function(score) {
  if (score <= 4)  return(list(label = "Minimal somatic symptoms", color = "#2E7D32", description = "Minimal somatic symptom burden."))
  if (score <= 9)  return(list(label = "Low somatic symptoms",     color = "#F59E0B", description = "Low somatic symptom severity."))
  if (score <= 14) return(list(label = "Medium somatic symptoms",  color = "#EA580C", description = "Medium somatic symptom severity. Consider clinical review."))
  list(label = "High somatic symptoms", color = "#DC2626", description = "High somatic symptom burden. Clinical attention warranted.")
}

# --- GAD-7 --------------------------------------------------------------------

.score_gad7 <- function(answers) {
  keys <- paste0("gad7_", 1:7)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_gad7 <- function(score) {
  if (score <= 4)  return(list(label = "Minimal anxiety",  color = "#2E7D32", description = "Minimal anxiety symptoms."))
  if (score <= 9)  return(list(label = "Mild anxiety",     color = "#F59E0B", description = "Mild anxiety. Consider watchful waiting."))
  if (score <= 14) return(list(label = "Moderate anxiety", color = "#EA580C", description = "Moderate anxiety. Consider further assessment."))
  list(label = "Severe anxiety", color = "#DC2626", description = "Severe anxiety. Active treatment indicated.")
}

# --- GAD-2 --------------------------------------------------------------------

.score_gad2 <- function(answers) {
  keys <- c("gad2_1", "gad2_2")
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_gad2 <- function(score) {
  if (score <= 2) return(list(label = "Negative screen", color = "#2E7D32", description = "Negative screen for generalised anxiety."))
  list(label = "Positive screen", color = "#DC2626", description = "Positive screen. Consider follow-up with GAD-7 or clinical evaluation.")
}

# --- BDI-II -------------------------------------------------------------------

.score_bdi2 <- function(answers) {
  keys <- paste0("bdi2_", 1:21)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_bdi2 <- function(score) {
  if (score <= 13) return(list(label = "Minimal depression",  color = "#2E7D32", description = "Minimal depression."))
  if (score <= 19) return(list(label = "Mild depression",     color = "#F59E0B", description = "Mild depression."))
  if (score <= 28) return(list(label = "Moderate depression", color = "#EA580C", description = "Moderate depression."))
  list(label = "Severe depression", color = "#DC2626", description = "Severe depression.")
}

# --- BAI ----------------------------------------------------------------------

.score_bai <- function(answers) {
  keys <- paste0("bai", 1:21)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_bai <- function(score) {
  if (score <= 7)  return(list(label = "Minimal anxiety",  color = "#2E7D32", description = "Minimal anxiety."))
  if (score <= 15) return(list(label = "Mild anxiety",     color = "#F59E0B", description = "Mild anxiety."))
  if (score <= 25) return(list(label = "Moderate anxiety", color = "#EA580C", description = "Moderate anxiety."))
  list(label = "Severe anxiety", color = "#DC2626", description = "Severe anxiety.")
}

# --- DASS-21 ------------------------------------------------------------------
# Returns list(total, depression, anxiety, stress); each subscale is doubled
# to align with DASS-42 norms.

.score_dass21 <- function(answers) {
  .s <- function(keys) sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
  dep    <- .s(paste0("dass21_", c(3, 5, 10, 13, 16, 17, 21))) * 2L
  anx    <- .s(paste0("dass21_", c(2, 4, 7, 9, 15, 19, 20)))   * 2L
  stress <- .s(paste0("dass21_", c(1, 6, 8, 11, 12, 14, 18)))  * 2L
  list(total = dep + anx + stress, depression = dep, anxiety = anx, stress = stress)
}

.interpret_dass21 <- function(score) {
  s <- if (is.list(score)) score[["total"]] else as.numeric(score)
  if (s <= 13) return(list(label = "Normal-Mild",    color = "#2E7D32", description = "Total score in the normal to mild range. Refer to subscale breakdown."))
  if (s <= 28) return(list(label = "Moderate",       color = "#F59E0B", description = "Moderate overall distress. Refer to subscale breakdown."))
  list(label = "Severe-Extreme", color = "#DC2626", description = "Severe to extreme distress. Clinical evaluation recommended.")
}

# --- PANSS --------------------------------------------------------------------
# Returns list(total, positive, negative, general). Items default to 1 (Absent).

.score_panss <- function(answers) {
  .s <- function(keys) sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 1), numeric(1)))
  p_items <- paste0("panss_p", 1:7)
  n_items <- paste0("panss_n", 1:7)
  g_items <- paste0("panss_g", 1:16)
  positive <- .s(p_items)
  negative <- .s(n_items)
  general  <- .s(g_items)
  list(total = positive + negative + general, positive = positive, negative = negative, general = general)
}

.interpret_panss <- function(score) {
  s <- if (is.list(score)) score[["total"]] else as.numeric(score)
  if (s <= 58) return(list(label = "Minimal psychopathology", color = "#2E7D32", description = "Minimal symptom burden."))
  if (s <= 75) return(list(label = "Mild",                    color = "#F59E0B", description = "Mild psychopathology."))
  if (s <= 95) return(list(label = "Moderate",                color = "#EA580C", description = "Moderate psychopathology."))
  list(label = "Severe-Extreme", color = "#DC2626", description = "Severe to extreme psychopathology.")
}

# --- STAI-S -------------------------------------------------------------------
# Items 1,2,5,8,10,11,15,16,19,20 are reverse-scored (value -> 5 - value).

.score_stai_s <- function(answers) {
  reverse <- c(1L, 2L, 5L, 8L, 10L, 11L, 15L, 16L, 19L, 20L)
  total <- 0L
  for (i in seq_len(20)) {
    raw <- as.numeric(answers[[paste0("stais_", i)]] %||% 0)
    total <- total + if (i %in% reverse) (5L - raw) else raw
  }
  total
}

.interpret_stai_s <- function(score) {
  if (score <= 37) return(list(label = "Low state anxiety",      color = "#2E7D32", description = "Low anxiety at this moment."))
  if (score <= 44) return(list(label = "Moderate state anxiety", color = "#F59E0B", description = "Moderate state anxiety."))
  list(label = "High state anxiety", color = "#DC2626", description = "High state anxiety.")
}

# --- STAI-T -------------------------------------------------------------------
# Items 21,26,27,30,33,34,36,39 are reverse-scored.

.score_stai_t <- function(answers) {
  reverse <- c(21L, 26L, 27L, 30L, 33L, 34L, 36L, 39L)
  total <- 0L
  for (i in seq(21L, 40L)) {
    raw <- as.numeric(answers[[paste0("stait_", i)]] %||% 0)
    total <- total + if (i %in% reverse) (5L - raw) else raw
  }
  total
}

.interpret_stai_t <- function(score) {
  if (score <= 37) return(list(label = "Low trait anxiety",      color = "#2E7D32", description = "Low anxiety proneness."))
  if (score <= 44) return(list(label = "Moderate trait anxiety", color = "#F59E0B", description = "Moderate trait anxiety."))
  list(label = "High trait anxiety", color = "#DC2626", description = "High trait anxiety.")
}

# --- Registry entry -----------------------------------------------------------

.MENTAL_HEALTH_INSTRUMENTS <- list(
  phq2    = list(title = "Patient Health Questionnaire - 2 items",                    score = .score_phq2,    interpret = .interpret_phq2,    domain = "Mental Health", max_score = 6,         beta = TRUE),
  phq9    = list(title = "Patient Health Questionnaire - 9 items",                    score = .score_phq9,    interpret = .interpret_phq9,    domain = "Mental Health", max_score = 27,        beta = TRUE),
  phq15   = list(title = "Patient Health Questionnaire - 15 items (Somatic Symptoms)",score = .score_phq15,   interpret = .interpret_phq15,   domain = "Mental Health", max_score = 30,        beta = TRUE),
  gad7    = list(title = "Generalised Anxiety Disorder - 7 items",                    score = .score_gad7,    interpret = .interpret_gad7,    domain = "Mental Health", max_score = 21,        beta = TRUE),
  gad2    = list(title = "Generalised Anxiety Disorder - 2 items",                    score = .score_gad2,    interpret = .interpret_gad2,    domain = "Mental Health", max_score = 6,         beta = TRUE),
  bdi2    = list(title = "Beck Depression Inventory - Second Edition",                score = .score_bdi2,    interpret = .interpret_bdi2,    domain = "Mental Health", max_score = 63,        beta = TRUE),
  bai     = list(title = "Beck Anxiety Inventory",                                    score = .score_bai,     interpret = .interpret_bai,     domain = "Mental Health", max_score = 63,        beta = TRUE),
  dass21  = list(title = "Depression Anxiety Stress Scales - 21 items",               score = .score_dass21,  interpret = .interpret_dass21,  domain = "Mental Health", max_score = 42,        beta = TRUE),
  panss   = list(title = "Positive and Negative Syndrome Scale",                      score = .score_panss,   interpret = .interpret_panss,   domain = "Mental Health", max_score = 210,       beta = TRUE),
  stai_s  = list(title = "State-Trait Anxiety Inventory - State subscale",            score = .score_stai_s,  interpret = .interpret_stai_s,  domain = "Mental Health", max_score = 80,        beta = TRUE),
  stai_t  = list(title = "State-Trait Anxiety Inventory - Trait subscale",            score = .score_stai_t,  interpret = .interpret_stai_t,  domain = "Mental Health", max_score = 80,        beta = TRUE)
)
