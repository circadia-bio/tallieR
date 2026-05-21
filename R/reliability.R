# R/reliability.R -- Internal consistency / reliability utilities
#
# cronbach_alpha()  -- Cronbach's alpha for one or more questionnaires
# omega_reliability() -- McDonald's omega (total) for one or more questionnaires

# ─── Internal helpers ─────────────────────────────────────────────────────────

#' Compute Cronbach's alpha from a numeric item matrix
#'
#' @param mat A numeric matrix (participants × items) with no missing columns
#'   left after `na_action`.
#' @param conf_level Confidence level for the CI.
#'
#' @return Named list with `alpha`, `n_items`, `n_obs`, `ci_lower`, `ci_upper`.
#' @keywords internal
.alpha_from_matrix <- function(mat, conf_level = 0.95) {
  k   <- ncol(mat)
  n   <- nrow(mat)

  if (k < 2L)  return(list(alpha = NA_real_, n_items = k, n_obs = n,
                            ci_lower = NA_real_, ci_upper = NA_real_,
                            note = "Need at least 2 numeric items."))
  if (n < 2L)  return(list(alpha = NA_real_, n_items = k, n_obs = n,
                            ci_lower = NA_real_, ci_upper = NA_real_,
                            note = "Need at least 2 complete observations."))

  var_items <- sum(apply(mat, 2L, stats::var))
  var_total <- stats::var(rowSums(mat))

  if (var_total == 0) return(list(alpha = NA_real_, n_items = k, n_obs = n,
                                  ci_lower = NA_real_, ci_upper = NA_real_,
                                  note = "Zero variance in row totals."))

  alpha <- (k / (k - 1L)) * (1 - var_items / var_total)

  # Exact CI via F-distribution (Feldt et al., 1987)
  # Reference: Feldt, L.S., Woodruff, D.J., Salih, F.A. (1987).
  #   Statistical inference for coefficient alpha. Applied Psychological
  #   Measurement, 11(1), 93-103.
  p       <- (1 - conf_level) / 2
  f_lower <- stats::qf(    p, df1 = n - 1L, df2 = (n - 1L) * (k - 1L))
  f_upper <- stats::qf(1 - p, df1 = n - 1L, df2 = (n - 1L) * (k - 1L))
  ci_lower <- 1 - (1 - alpha) * f_upper
  ci_upper <- 1 - (1 - alpha) * f_lower

  list(alpha    = alpha,
       n_items  = k,
       n_obs    = n,
       ci_lower = ci_lower,
       ci_upper = ci_upper,
       note     = NA_character_)
}

#' Pivot items for one questionnaire into a participant x item matrix
#'
#' Extracts numeric items from a filtered `items_long()` slice, drops
#' items that cannot be coerced to numeric (e.g. MCTQ time lists,
#' STOP-BANG yes/no), and keeps only complete cases.
#'
#' @param df A data frame as produced by [items_long()] filtered to one
#'   `questionnaire_id`.
#' @param min_numeric Minimum fraction of items that must be numeric to
#'   proceed (default 0.5). If fewer items survive, returns `NULL`.
#' @keywords internal
.items_to_matrix <- function(df, min_numeric = 0.5) {
  # Use the most recent administration per participant
  df <- df[order(df$completed_at, decreasing = TRUE), ]
  df <- df[!duplicated(paste(df$participant_id, df$item_id)), ]

  # Wide pivot: participants (rows) x items (columns)
  wide <- tryCatch(
    tidyr::pivot_wider(
      df[, c("participant_id", "item_id", "response")],
      id_cols     = "participant_id",
      names_from  = "item_id",
      values_from = "response"
    ),
    error = function(e) NULL
  )
  if (is.null(wide) || nrow(wide) == 0L) return(NULL)

  # Coerce to numeric; columns that are all NA are non-numeric items
  item_cols <- setdiff(names(wide), "participant_id")
  num_mat   <- suppressWarnings(
    vapply(item_cols, function(col) as.numeric(wide[[col]]), numeric(nrow(wide)))
  )
  if (is.null(dim(num_mat))) num_mat <- matrix(num_mat, ncol = 1L,
                                               dimnames = list(NULL, item_cols))

  # Drop items that are entirely NA (non-numeric) or constant
  keep <- apply(num_mat, 2L, function(x) !all(is.na(x)))
  num_mat <- num_mat[, keep, drop = FALSE]

  if (ncol(num_mat) < min_numeric * length(item_cols)) return(NULL)

  # Keep only complete cases
  complete <- stats::complete.cases(num_mat)
  num_mat  <- num_mat[complete, , drop = FALSE]

  num_mat
}

# ─── Public API ───────────────────────────────────────────────────────────────

#' Validate and prepare item-level data for reliability functions
#'
#' Shared internal helper used by [cronbach_alpha()] and [omega_reliability()].
#' Accepts either a tallier object or a pre-built `items_long()` data frame,
#' validates required columns, optionally filters to a subset of questionnaires,
#' and warns about unknown IDs.
#'
#' @return A list with `items` (data frame) and `all_qs` (character vector of
#'   questionnaire IDs to process), or calls `rlang::warn`/`rlang::abort` and
#'   returns `NULL` when the input is invalid or empty.
#' @keywords internal
.prepare_items <- function(obj, questionnaires, empty_fn) {
  required <- c("participant_id", "questionnaire_id", "item_id",
                "completed_at", "response")

  if (is.data.frame(obj)) {
    items   <- obj
    missing <- setdiff(required, names(items))
    if (length(missing) > 0L) {
      rlang::abort(paste0(
        "When passing a data frame, it must have columns: ",
        paste(required, collapse = ", "), ". Missing: ",
        paste(missing, collapse = ", "), "."
      ))
    }
  } else {
    items <- items_long(obj)
  }

  if (nrow(items) == 0L) {
    rlang::warn("No item-level data found in `obj`. Returning empty data frame.")
    return(NULL)
  }

  all_qs <- unique(items$questionnaire_id)

  if (!is.null(questionnaires)) {
    unknown <- setdiff(questionnaires, all_qs)
    if (length(unknown) > 0L) {
      rlang::warn(paste0(
        "Questionnaire(s) not found in data and will be skipped: ",
        paste(unknown, collapse = ", ")
      ))
    }
    all_qs <- intersect(questionnaires, all_qs)
  }

  if (length(all_qs) == 0L) {
    rlang::warn("No matching questionnaires found. Returning empty data frame.")
    return(NULL)
  }

  list(items = items, all_qs = all_qs)
}

#' Cronbach's alpha for one or more questionnaires
#'
#' Computes Cronbach's alpha (a measure of internal consistency) for each
#' questionnaire present in a `tallier_export` or `tallier_study` object.
#' Item-level responses are extracted via [items_long()], coerced to numeric,
#' and a participant × item matrix is constructed per questionnaire.
#'
#' Non-numeric items (e.g. MCTQ clock times, STOP-BANG yes/no) are silently
#' dropped before estimation. Questionnaires with fewer than 2 numeric items
#' or fewer than 2 complete observations return `NA` with an explanatory note.
#'
#' @param obj A `tallier_export` or `tallier_study` object, or a data frame
#'   as returned by [items_long()] (must contain columns `participant_id`,
#'   `questionnaire_id`, `item_id`, `completed_at`, `response`).
#' @param questionnaires Character vector of questionnaire IDs to include.
#'   Defaults to all questionnaires present in `obj`.
#' @param conf_level Numeric. Confidence level for the CI (default `0.95`).
#'   Uses the exact F-distribution method of Feldt et al. (1987).
#' @param min_items Integer. Minimum number of numeric items required to
#'   attempt estimation (default `2`).
#'
#' @return A `data.frame` with one row per questionnaire and columns:
#'   \describe{
#'     \item{questionnaire_id}{Questionnaire identifier.}
#'     \item{alpha}{Cronbach's alpha (standardised scale: −∞ to 1).}
#'     \item{ci_lower}{Lower bound of the `conf_level` CI.}
#'     \item{ci_upper}{Upper bound of the `conf_level` CI.}
#'     \item{n_items}{Number of numeric items used.}
#'     \item{n_obs}{Number of complete observations (participants).}
#'     \item{note}{`NA` on success, or a short message explaining why
#'       estimation failed.}
#'   }
#'
#' @references
#' Cronbach, L. J. (1951). Coefficient alpha and the internal structure of
#' tests. *Psychometrika*, 16(3), 297–334.
#' \doi{10.1007/BF02310555}
#'
#' Feldt, L. S., Woodruff, D. J., & Salih, F. A. (1987). Statistical
#' inference for coefficient alpha. *Applied Psychological Measurement*,
#' 11(1), 93–103. \doi{10.1177/014662168701100107}
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#'
#' # All questionnaires
#' cronbach_alpha(study)
#'
#' # Specific subset
#' cronbach_alpha(study, questionnaires = c("ess", "isi", "phq9"))
#'
#' # From an items_long() data frame (e.g. already filtered)
#' items <- items_long(study)
#' cronbach_alpha(items)
#' }
#'
#' @export
cronbach_alpha <- function(obj,
                           questionnaires = NULL,
                           conf_level     = 0.95,
                           min_items      = 2L) {

  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    rlang::abort("`conf_level` must be a number strictly between 0 and 1.")
  }
  min_items <- as.integer(min_items)

  prepared <- .prepare_items(obj, questionnaires, .empty_alpha_df)
  if (is.null(prepared)) return(.empty_alpha_df())
  items  <- prepared$items
  all_qs <- prepared$all_qs

  rows <- lapply(all_qs, function(qid) {
    slice  <- items[items$questionnaire_id == qid, ]
    mat    <- .items_to_matrix(slice)

    if (is.null(mat)) {
      return(data.frame(
        questionnaire_id = qid,
        alpha    = NA_real_,
        ci_lower = NA_real_,
        ci_upper = NA_real_,
        n_items  = 0L,
        n_obs    = 0L,
        note     = "No numeric items or no complete observations.",
        stringsAsFactors = FALSE
      ))
    }

    if (ncol(mat) < min_items) {
      return(data.frame(
        questionnaire_id = qid,
        alpha    = NA_real_,
        ci_lower = NA_real_,
        ci_upper = NA_real_,
        n_items  = ncol(mat),
        n_obs    = nrow(mat),
        note     = paste0("Fewer than min_items (", min_items, ") numeric items."),
        stringsAsFactors = FALSE
      ))
    }

    res <- .alpha_from_matrix(mat, conf_level = conf_level)
    data.frame(
      questionnaire_id = qid,
      alpha    = res$alpha,
      ci_lower = res$ci_lower,
      ci_upper = res$ci_upper,
      n_items  = res$n_items,
      n_obs    = res$n_obs,
      note     = res$note,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' @keywords internal
.empty_alpha_df <- function() {
  data.frame(
    questionnaire_id = character(0),
    alpha            = numeric(0),
    ci_lower         = numeric(0),
    ci_upper         = numeric(0),
    n_items          = integer(0),
    n_obs            = integer(0),
    note             = character(0),
    stringsAsFactors = FALSE
  )
}

# ─── omega_reliability() ───────────────────────────────────────────────────────

#' Compute McDonald's omega (total) from a numeric item matrix
#'
#' Uses a single-factor EFA via `stats::factanal()` to extract factor loadings,
#' then applies the omega_t formula:
#' `omega = (sum(lambda))^2 / ((sum(lambda))^2 + sum(1 - lambda^2))`
#' where `lambda` are the standardised factor loadings.
#'
#' @param mat A numeric matrix (participants x items), complete cases only.
#' @return Named list with `omega`, `n_items`, `n_obs`, `note`.
#' @keywords internal
.omega_from_matrix <- function(mat) {
  k <- ncol(mat)
  n <- nrow(mat)

  if (k < 2L) return(list(omega = NA_real_, n_items = k, n_obs = n,
                           note = "Need at least 2 numeric items."))
  if (n < 2L) return(list(omega = NA_real_, n_items = k, n_obs = n,
                           note = "Need at least 2 complete observations."))
  if (n <= k) return(list(omega = NA_real_, n_items = k, n_obs = n,
                           note = "More items than observations; covariance matrix is singular."))

  fa <- tryCatch(
    stats::factanal(mat, factors = 1L, rotation = "none"),
    error   = function(e) NULL,
    warning = function(w) {
      # factanal warns (not errors) on non-convergence; treat as failure
      tryCatch(stats::factanal(mat, factors = 1L, rotation = "none"),
               error = function(e) NULL)
    }
  )

  if (is.null(fa)) return(list(omega = NA_real_, n_items = k, n_obs = n,
                                note = "Factor analysis did not converge."))

  loadings <- as.numeric(fa$loadings)

  # McDonald's omega_t
  sum_lambda  <- sum(loadings)
  sum_err_var <- sum(1 - loadings^2)
  omega       <- sum_lambda^2 / (sum_lambda^2 + sum_err_var)

  list(omega   = omega,
       n_items = k,
       n_obs   = n,
       note    = NA_character_)
}

#' @keywords internal
.empty_omega_df <- function() {
  data.frame(
    questionnaire_id = character(0),
    omega            = numeric(0),
    n_items          = integer(0),
    n_obs            = integer(0),
    note             = character(0),
    stringsAsFactors = FALSE
  )
}

#' McDonald's omega for one or more questionnaires
#'
#' Computes McDonald's omega (\eqn{\omega_t}, total omega) as a measure of
#' internal consistency for each questionnaire present in a `tallier_export`
#' or `tallier_study` object. Omega is generally preferred over Cronbach's
#' alpha for non-tau-equivalent items (i.e. items with unequal factor
#' loadings), which is the norm in most psychological questionnaires.
#'
#' Estimation uses a single-factor EFA via [stats::factanal()]. The formula
#' applied is:
#' \deqn{\omega_t = \frac{(\sum \lambda_i)^2}{(\sum \lambda_i)^2 + \sum(1 - \lambda_i^2)}}
#' where \eqn{\lambda_i} are the standardised factor loadings.
#'
#' Non-numeric items (e.g. MCTQ clock times, STOP-BANG yes/no) are silently
#' dropped before estimation. Questionnaires with fewer items than observations,
#' fewer than 2 numeric items, or non-convergent factor solutions return `NA`
#' with an explanatory note.
#'
#' @param obj A `tallier_export` or `tallier_study` object, or a data frame
#'   as returned by [items_long()] (must contain columns `participant_id`,
#'   `questionnaire_id`, `item_id`, `completed_at`, `response`).
#' @param questionnaires Character vector of questionnaire IDs to include.
#'   Defaults to all questionnaires present in `obj`.
#' @param min_items Integer. Minimum number of numeric items required to
#'   attempt estimation (default `2`).
#'
#' @return A `data.frame` with one row per questionnaire and columns:
#'   \describe{
#'     \item{questionnaire_id}{Questionnaire identifier.}
#'     \item{omega}{McDonald's omega_t. Range: 0 to 1.}
#'     \item{n_items}{Number of numeric items used.}
#'     \item{n_obs}{Number of complete observations (participants).}
#'     \item{note}{`NA` on success, or a short message explaining why
#'       estimation failed.}
#'   }
#'
#' @references
#' McDonald, R. P. (1999). *Test theory: A unified treatment*.
#' Lawrence Erlbaum Associates.
#'
#' Revelle, W., & Zinbarg, R. E. (2009). Coefficients alpha, beta, omega,
#' and the glb: Comments on Sijtsma. *Psychometrika*, 74(1), 145–154.
#' \doi{10.1007/s11336-008-9102-z}
#'
#' @examples
#' \dontrun{
#' study <- read_scoreme_dir("exports/")
#'
#' # All questionnaires
#' omega_reliability(study)
#'
#' # Compare alpha and omega side by side
#' alpha <- cronbach_alpha(study, questionnaires = c("ess", "isi"))
#' omega <- omega_reliability(study, questionnaires = c("ess", "isi"))
#' merge(alpha[, c("questionnaire_id", "alpha", "n_obs")],
#'       omega[, c("questionnaire_id", "omega")],
#'       by = "questionnaire_id")
#' }
#'
#' @seealso [cronbach_alpha()]
#'
#' @export
omega_reliability <- function(obj,
                              questionnaires = NULL,
                              min_items      = 2L) {
  min_items <- as.integer(min_items)

  prepared <- .prepare_items(obj, questionnaires, .empty_omega_df)
  if (is.null(prepared)) return(.empty_omega_df())
  items  <- prepared$items
  all_qs <- prepared$all_qs

  rows <- lapply(all_qs, function(qid) {
    slice <- items[items$questionnaire_id == qid, ]
    mat   <- .items_to_matrix(slice)

    if (is.null(mat)) {
      return(data.frame(
        questionnaire_id = qid,
        omega   = NA_real_,
        n_items = 0L,
        n_obs   = 0L,
        note    = "No numeric items or no complete observations.",
        stringsAsFactors = FALSE
      ))
    }

    if (ncol(mat) < min_items) {
      return(data.frame(
        questionnaire_id = qid,
        omega   = NA_real_,
        n_items = ncol(mat),
        n_obs   = nrow(mat),
        note    = paste0("Fewer than min_items (", min_items, ") numeric items."),
        stringsAsFactors = FALSE
      ))
    }

    res <- .omega_from_matrix(mat)
    data.frame(
      questionnaire_id = qid,
      omega   = res$omega,
      n_items = res$n_items,
      n_obs   = res$n_obs,
      note    = res$note,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
