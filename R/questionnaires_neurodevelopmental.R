# R/questionnaires_neurodevelopmental.R -- Neurodevelopmental domain instruments
#
# GSQ · AQ-10
#
# All instruments are beta = TRUE.

# --- GSQ ----------------------------------------------------------------------

.score_gsq <- function(answers) {
  keys <- paste0("gsq_", 1:28)
  sum(vapply(keys, function(k) as.numeric(answers[[k]] %||% 0), numeric(1)))
}

.interpret_gsq <- function(score) {
  if (score <= 28) return(list(label = "Low sensory sensitivity",      color = "#2E7D32", description = "Low level of sensory processing difficulties."))
  if (score <= 56) return(list(label = "Mild sensory sensitivity",     color = "#F59E0B", description = "Mild sensory processing difficulties."))
  if (score <= 84) return(list(label = "Moderate sensory sensitivity", color = "#EA580C", description = "Moderate sensory processing difficulties."))
  list(label = "High sensory sensitivity", color = "#DC2626", description = "High level of sensory processing difficulties.")
}

# --- AQ-10 --------------------------------------------------------------------
# Items 1,7,8,10 score 1 for "da" or "sa" (agree direction).
# Items 2,3,4,5,6,9 score 1 for "dd" or "sd" (disagree direction).

.score_aq10 <- function(answers) {
  agree_items    <- c(1L, 7L, 8L, 10L)
  disagree_items <- c(2L, 3L, 4L, 5L, 6L, 9L)
  total <- 0L
  for (i in seq_len(10)) {
    v <- answers[[paste0("aq10_", i)]]
    if (i %in% agree_items) {
      total <- total + if (identical(v, "da") || identical(v, "sa")) 1L else 0L
    } else {
      total <- total + if (identical(v, "dd") || identical(v, "sd")) 1L else 0L
    }
  }
  total
}

.interpret_aq10 <- function(score) {
  if (score <= 5) return(list(label = "Below threshold",                    color = "#2E7D32", description = "Score below the clinical referral threshold."))
  list(label = "Above threshold - consider referral", color = "#DC2626", description = "Score at or above the recommended referral threshold. Consider clinical assessment.")
}

# --- Registry entry -----------------------------------------------------------

.NEURODEVELOPMENTAL_INSTRUMENTS <- list(
  gsq   = list(title = "Glasgow Sensory Questionnaire",               score = .score_gsq,   interpret = .interpret_gsq,   domain = "Neurodevelopmental", max_score = 112, beta = TRUE),
  aq10  = list(title = "Autism Spectrum Quotient - 10 item screener", score = .score_aq10,  interpret = .interpret_aq10,  domain = "Neurodevelopmental", max_score = 10,  beta = TRUE)
)
