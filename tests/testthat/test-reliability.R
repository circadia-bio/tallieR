# tests/testthat/test-reliability.R

# ─── Helpers ──────────────────────────────────────────────────────────────────

# Build a minimal tallier_export-like list from a named list of item matrices.
# Each name is a questionnaire_id; each value is a matrix (participants × items)
# with colnames as item_ids.
.make_export <- function(matrices) {
  participants <- lapply(seq_len(nrow(matrices[[1L]])), function(i) {
    results <- lapply(names(matrices), function(qid) {
      mat     <- matrices[[qid]]
      answers <- as.list(mat[i, ])
      list(
        questionnaire_id = qid,
        completed_at     = "2024-01-01T00:00:00Z",
        score            = NA,
        answers          = answers
      )
    })
    list(
      meta    = list(participant_id = paste0("p", i), code = paste0("P", i)),
      results = results
    )
  })
  structure(list(participants = participants), class = "tallier_export")
}

# ─── Unit tests for .alpha_from_matrix ────────────────────────────────────────

test_that(".alpha_from_matrix: known alpha value", {
  # Perfect parallel items: each item is constant + shared variance
  set.seed(42)
  shared <- rnorm(50)
  mat    <- cbind(shared + rnorm(50, sd = 0.1),
                  shared + rnorm(50, sd = 0.1),
                  shared + rnorm(50, sd = 0.1))
  res <- tallieR:::.alpha_from_matrix(mat)
  expect_gte(res$alpha, 0.95)
  expect_lte(res$alpha, 1.00)
  expect_true(res$ci_lower < res$alpha)
  expect_true(res$ci_upper > res$alpha)
  expect_equal(res$n_items, 3L)
  expect_equal(res$n_obs,  50L)
})

test_that(".alpha_from_matrix: exactly 2 items", {
  mat <- matrix(c(1,2,3,4, 1,2,3,4), nrow = 4L)
  res <- tallieR:::.alpha_from_matrix(mat)
  expect_equal(res$n_items, 2L)
  expect_true(is.numeric(res$alpha))
})

test_that(".alpha_from_matrix: fewer than 2 items returns NA", {
  mat <- matrix(1:5, ncol = 1L)
  res <- tallieR:::.alpha_from_matrix(mat)
  expect_true(is.na(res$alpha))
  expect_match(res$note, "2 numeric items")
})

test_that(".alpha_from_matrix: fewer than 2 obs returns NA", {
  mat <- matrix(1:3, nrow = 1L)
  res <- tallieR:::.alpha_from_matrix(mat)
  expect_true(is.na(res$alpha))
})

test_that(".alpha_from_matrix: zero total variance returns NA", {
  mat <- matrix(rep(1, 20), nrow = 10L, ncol = 2L)
  res <- tallieR:::.alpha_from_matrix(mat)
  expect_true(is.na(res$alpha))
  expect_match(res$note, "[Zz]ero variance")
})

# ─── Integration tests for cronbach_alpha() ───────────────────────────────────

test_that("cronbach_alpha: works on items_long() data frame", {
  # Simulate 30 participants × 8 ESS items with moderate internal consistency
  set.seed(7)
  n <- 30L
  shared <- round(runif(n, 0, 3))
  mat_ess <- matrix(
    pmin(3L, pmax(0L, outer(shared, rep(0L, 8L), "+") +
                        matrix(sample(-1L:1L, n * 8L, replace = TRUE), n, 8L))),
    nrow = n, ncol = 8L,
    dimnames = list(NULL, paste0("ess", 1:8))
  )

  export <- .make_export(list(ess = mat_ess))
  items  <- items_long(export)
  result <- cronbach_alpha(items)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$questionnaire_id, "ess")
  expect_true(is.numeric(result$alpha))
  expect_equal(result$n_items, 8L)
  expect_equal(result$n_obs,   n)
  expect_true(result$ci_lower < result$alpha)
  expect_true(result$ci_upper > result$alpha)
})

test_that("cronbach_alpha: works on tallier_export directly", {
  set.seed(11)
  n <- 20L
  shared <- runif(n)
  mat_isi <- matrix(
    pmin(4L, pmax(0L, round(outer(shared * 3, rep(1, 7)) +
                               matrix(rnorm(n * 7, sd = 0.5), n, 7L)))),
    nrow = n, ncol = 7L,
    dimnames = list(NULL, paste0("isi", 1:7))
  )
  export <- .make_export(list(isi = mat_isi))
  result <- cronbach_alpha(export)
  expect_equal(nrow(result), 1L)
  expect_equal(result$questionnaire_id, "isi")
  expect_true(is.numeric(result$alpha))
})

test_that("cronbach_alpha: multiple questionnaires", {
  set.seed(99)
  n <- 25L
  make_mat <- function(items, prefix) {
    s <- runif(n)
    m <- matrix(pmin(3, pmax(0, round(outer(s * 2, rep(1, items)) +
                                        matrix(rnorm(n * items, sd = 0.5), n, items)))),
                nrow = n, dimnames = list(NULL, paste0(prefix, seq_len(items))))
    m
  }
  export <- .make_export(list(
    ess   = make_mat(8L, "ess"),
    isi   = make_mat(7L, "isi"),
    meq   = make_mat(19L, "meq")
  ))
  result <- cronbach_alpha(export)
  expect_equal(nrow(result), 3L)
  expect_setequal(result$questionnaire_id, c("ess", "isi", "meq"))
  expect_true(all(is.numeric(result$alpha)))
})

test_that("cronbach_alpha: questionnaires filter works", {
  set.seed(3)
  n <- 15L
  s <- runif(n)
  make_m <- function(k, pfx) {
    matrix(pmin(3, pmax(0, round(outer(s * 2, rep(1, k)) +
                                   matrix(rnorm(n * k, sd = 0.4), n, k)))),
           nrow = n, dimnames = list(NULL, paste0(pfx, seq_len(k))))
  }
  export <- .make_export(list(ess = make_m(8L, "ess"), isi = make_m(7L, "isi")))
  result <- cronbach_alpha(export, questionnaires = "ess")
  expect_equal(nrow(result), 1L)
  expect_equal(result$questionnaire_id, "ess")
})

test_that("cronbach_alpha: unknown questionnaire in filter raises warning", {
  set.seed(5)
  n <- 10L
  s <- runif(n)
  mat <- matrix(pmin(3, pmax(0, round(outer(s * 2, rep(1, 8)) +
                                        matrix(rnorm(n * 8, sd = 0.4), n, 8)))),
                nrow = n, dimnames = list(NULL, paste0("ess", 1:8)))
  export <- .make_export(list(ess = mat))
  expect_warning(
    cronbach_alpha(export, questionnaires = c("ess", "nonexistent")),
    regexp = "nonexistent"
  )
})

test_that("cronbach_alpha: invalid conf_level raises error", {
  items_df <- data.frame(
    participant_id = "p1", questionnaire_id = "ess",
    item_id = "ess1", completed_at = "2024-01-01", response = "2",
    stringsAsFactors = FALSE
  )
  expect_error(cronbach_alpha(items_df, conf_level = 1.5), "`conf_level`")
  expect_error(cronbach_alpha(items_df, conf_level = 0),   "`conf_level`")
})

test_that("cronbach_alpha: data frame with missing required columns errors", {
  bad <- data.frame(a = 1, b = 2)
  expect_error(cronbach_alpha(bad), "Missing")
})

test_that("cronbach_alpha: CI respects conf_level", {
  set.seed(21)
  n <- 40L
  s <- rnorm(n)
  mat <- cbind(s + rnorm(n, sd = 0.3), s + rnorm(n, sd = 0.3),
               s + rnorm(n, sd = 0.3), s + rnorm(n, sd = 0.3))
  colnames(mat) <- paste0("q", 1:4)
  export <- .make_export(list(x = mat))

  r95 <- cronbach_alpha(export, conf_level = 0.95)
  r80 <- cronbach_alpha(export, conf_level = 0.80)
  width95 <- r95$ci_upper - r95$ci_lower
  width80 <- r80$ci_upper - r80$ci_lower
  expect_gt(width95, width80)
})

# ── omega_reliability() ────────────────────────────────────────────────────────

test_that(".omega_from_matrix: returns value in [0, 1] for well-conditioned data", {
  set.seed(42)
  shared <- rnorm(60)
  mat <- cbind(shared + rnorm(60, sd = 0.3),
               shared + rnorm(60, sd = 0.3),
               shared + rnorm(60, sd = 0.3),
               shared + rnorm(60, sd = 0.3))
  res <- tallieR:::.omega_from_matrix(mat)
  expect_true(is.numeric(res$omega))
  expect_gte(res$omega, 0)
  expect_lte(res$omega, 1)
  expect_true(is.na(res$note))
})

test_that(".omega_from_matrix: fewer than 2 items returns NA", {
  mat <- matrix(1:10, ncol = 1L)
  res <- tallieR:::.omega_from_matrix(mat)
  expect_true(is.na(res$omega))
  expect_match(res$note, "2 numeric items")
})

test_that(".omega_from_matrix: n <= k returns NA with informative note", {
  # 4 observations, 5 items: singular covariance
  mat <- matrix(rnorm(20), nrow = 4L, ncol = 5L)
  res <- tallieR:::.omega_from_matrix(mat)
  expect_true(is.na(res$omega))
  expect_match(res$note, "singular")
})

test_that("omega_reliability: correct shape and range", {
  set.seed(7)
  n <- 50L
  shared <- rnorm(n)
  mat_ess <- matrix(
    pmin(3L, pmax(0L, round(outer(shared * 0.8, rep(1, 8)) +
                               matrix(rnorm(n * 8, sd = 0.5), n, 8L)))),
    nrow = n, ncol = 8L,
    dimnames = list(NULL, paste0("ess", 1:8))
  )
  export <- .make_export(list(ess = mat_ess))
  result <- omega_reliability(export)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$questionnaire_id, "ess")
  expect_true(all(c("omega", "n_items", "n_obs", "note") %in% names(result)))
  expect_gte(result$omega, 0)
  expect_lte(result$omega, 1)
  expect_equal(result$n_items, 8L)
  expect_equal(result$n_obs,   n)
})

test_that("omega_reliability: accepts items_long() data frame", {
  set.seed(13)
  n <- 40L
  s <- rnorm(n)
  mat <- matrix(
    pmin(3, pmax(0, round(outer(s * 1.5, rep(1, 7)) +
                             matrix(rnorm(n * 7, sd = 0.4), n, 7L)))),
    nrow = n, dimnames = list(NULL, paste0("isi", 1:7))
  )
  export <- .make_export(list(isi = mat))
  items  <- items_long(export)
  result <- omega_reliability(items)
  expect_equal(nrow(result), 1L)
  expect_equal(result$questionnaire_id, "isi")
  expect_true(is.numeric(result$omega))
})

test_that("omega_reliability: n <= k produces NA with note", {
  # 3 participants, 8 items: factanal will fail
  set.seed(1)
  mat <- matrix(round(runif(24, 0, 3)), nrow = 3L, ncol = 8L,
                dimnames = list(NULL, paste0("ess", 1:8)))
  export <- .make_export(list(ess = mat))
  result <- omega_reliability(export)
  expect_true(is.na(result$omega))
  expect_false(is.na(result$note))
})

test_that("omega_reliability: questionnaires filter works", {
  set.seed(77)
  n <- 30L
  s <- rnorm(n)
  make_m <- function(k, pfx) {
    matrix(pmin(3, pmax(0, round(outer(s, rep(1, k)) +
                                   matrix(rnorm(n * k, sd = 0.5), n, k)))),
           nrow = n, dimnames = list(NULL, paste0(pfx, seq_len(k))))
  }
  export <- .make_export(list(ess = make_m(8L, "ess"), isi = make_m(7L, "isi")))
  result <- omega_reliability(export, questionnaires = "ess")
  expect_equal(nrow(result), 1L)
  expect_equal(result$questionnaire_id, "ess")
})

test_that("omega_reliability: omega >= alpha for congeneric items", {
  # For congeneric items (unequal loadings), omega >= alpha is expected
  set.seed(55)
  n <- 80L
  # Deliberately unequal loadings
  loadings <- c(0.9, 0.7, 0.5, 0.3, 0.8, 0.6, 0.4, 0.2)
  shared   <- rnorm(n)
  mat <- sapply(loadings, function(l) l * shared + sqrt(1 - l^2) * rnorm(n))
  colnames(mat) <- paste0("q", seq_along(loadings))
  export <- .make_export(list(q = mat))

  alpha_res <- cronbach_alpha(export)
  omega_res <- omega_reliability(export)
  expect_gte(omega_res$omega, alpha_res$alpha - 0.01)  # allow tiny numerical tolerance
})

test_that("cronbach_alpha: empty items data returns empty df with warning", {
  # Construct an export with no results
  empty_export <- structure(
    list(participants = list(
      list(meta = list(participant_id = "p1", code = "P001"), results = list())
    )),
    class = "tallier_export"
  )
  expect_warning(
    result <- cronbach_alpha(empty_export),
    "No item-level data"
  )
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("omega_reliability: empty items data returns empty df with warning", {
  empty_export <- structure(
    list(participants = list(
      list(meta = list(participant_id = "p1", code = "P001"), results = list())
    )),
    class = "tallier_export"
  )
  expect_warning(
    result <- omega_reliability(empty_export),
    "No item-level data"
  )
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("omega_reliability: min_items binding produces NA with note", {
  # A questionnaire with only 1 numeric item: should fail min_items check
  set.seed(9)
  n <- 20L
  mat <- matrix(round(runif(n, 0, 3)), nrow = n, ncol = 1L,
                dimnames = list(NULL, "q1"))
  export <- .make_export(list(solo = mat))
  result <- omega_reliability(export, min_items = 2L)
  expect_true(is.na(result$omega))
  expect_match(result$note, "min_items")
})

test_that("omega_reliability: data frame with missing columns errors", {
  bad <- data.frame(a = 1, b = 2)
  expect_error(omega_reliability(bad), "Missing")
})
