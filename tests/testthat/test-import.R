fixture_path <- system.file("extdata", "example_export.json", package = "tallieR")

test_that("read_scoreme parses participants and results", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  exp <- read_scoreme(fixture_path)
  expect_s3_class(exp, "tallier_export")
  expect_equal(exp$n_participants, 2L)
  expect_equal(exp$participants[[1]]$meta$code, "P001")
  expect_equal(length(exp$participants[[1]]$results), 3L)
})

test_that("scores_wide returns one row per participant", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  exp  <- read_scoreme(fixture_path)
  wide <- scores_wide(exp)
  expect_equal(nrow(wide), 2L)
  expect_true("ess" %in% names(wide))
  expect_true("isi" %in% names(wide))
})

test_that("scores_long returns one row per participant × questionnaire", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  exp  <- read_scoreme(fixture_path)
  long <- scores_long(exp)
  # P001 has 3 Qs, P002 has 3 Qs → 6 rows
  expect_equal(nrow(long), 6L)
  expect_true("questionnaire_id" %in% names(long))
  expect_true("score" %in% names(long))
})

test_that("items_long returns one row per item response", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  exp   <- read_scoreme(fixture_path)
  items <- items_long(exp)
  expect_true("item_id" %in% names(items))
  expect_true("response" %in% names(items))
  expect_gt(nrow(items), 0L)
})

test_that("read_scoreme rescores correctly", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  exp <- read_scoreme(fixture_path, rescore = TRUE)
  ess_result <- exp$participants[[1]]$results[[which(
    vapply(exp$participants[[1]]$results, `[[`, character(1), "questionnaire_id") == "ess"
  )]]
  # 2+1+0+3+1+0+2+1 = 10
  expect_equal(ess_result$score, 10)
})

# ── summary() ─────────────────────────────────────────────────────────────

.make_export_for_summary <- function() {
  structure(
    list(
      exported_at    = "2026-01-10T12:00:00.000Z",
      export_version = "1.0",
      n_participants = 2L,
      participants   = list(
        list(
          meta    = list(participant_id = "p1", code = "P001", name = "Alice",
                         age = "28", sex = "female", bmi = "", group = "",
                         site = "", session = "", diagnosis = "",
                         medication = "", referral = "", notes = "",
                         created_at = "2026-01-01T00:00:00.000Z"),
          results = list(
            list(questionnaire_id = "ess",
                 completed_at     = "2026-01-05T09:00:00.000Z",
                 score = 10, answers = list()),
            list(questionnaire_id = "isi",
                 completed_at     = "2026-01-05T09:10:00.000Z",
                 score = 8,  answers = list())
          )
        ),
        list(
          meta    = list(participant_id = "p2", code = "P002", name = "Bob",
                         age = "35", sex = "male", bmi = "", group = "",
                         site = "", session = "", diagnosis = "",
                         medication = "", referral = "", notes = "",
                         created_at = "2026-01-02T00:00:00.000Z"),
          results = list(
            list(questionnaire_id = "ess",
                 completed_at     = "2026-01-08T09:00:00.000Z",
                 score = 14, answers = list())
            # Note: p2 has no ISI — tests partial completion
          )
        )
      )
    ),
    class = "tallier_export"
  )
}

test_that("summary.tallier_export returns correct structure", {
  obj <- .make_export_for_summary()
  s   <- summary(obj)

  expect_equal(s$n_participants, 2L)
  expect_true(all(c("ess", "isi") %in% s$instruments))
  expect_true(is.data.frame(s$completion))
  expect_true(all(c("questionnaire_id", "n", "pct") %in% names(s$completion)))
})

test_that("summary.tallier_export completion rates are correct", {
  obj <- .make_export_for_summary()
  s   <- summary(obj)

  ess_row <- s$completion[s$completion$questionnaire_id == "ess", ]
  isi_row <- s$completion[s$completion$questionnaire_id == "isi", ]

  # Both participants completed ESS
  expect_equal(ess_row$n,   2L)
  expect_equal(ess_row$pct, 100)

  # Only p1 completed ISI
  expect_equal(isi_row$n,   1L)
  expect_equal(isi_row$pct, 50)
})

test_that("summary.tallier_export date range is correct", {
  obj <- .make_export_for_summary()
  s   <- summary(obj)

  expect_equal(s$date_range["min"], c(min = "2026-01-05T09:00:00.000Z"))
  expect_equal(s$date_range["max"], c(max = "2026-01-08T09:00:00.000Z"))
})

test_that("summary.tallier_export handles empty export gracefully", {
  empty <- structure(
    list(exported_at = NA, export_version = "1.0",
         participants = list(), n_participants = 0L),
    class = "tallier_export"
  )
  s <- summary(empty)
  expect_equal(s$n_participants, 0L)
  expect_equal(length(s$instruments), 0L)
  expect_true(is.na(s$date_range["min"]))
})

test_that("summary.tallier_study includes n_files", {
  study <- structure(
    list(
      files          = c("a.json", "b.json"),
      n_participants = 2L,
      participants   = .make_export_for_summary()$participants
    ),
    class = "tallier_study"
  )
  s <- summary(study)
  expect_equal(s$n_files, 2L)
  expect_equal(s$n_participants, 2L)
  expect_true(all(c("ess", "isi") %in% s$instruments))
})

# ── completion_summary() ─────────────────────────────────────────────────────

test_that("completion_summary() long format has correct shape", {
  obj <- .make_export_for_summary()
  out <- completion_summary(obj)

  # 2 participants x 2 questionnaires = 4 rows
  expect_equal(nrow(out), 4L)
  expect_true(all(c("participant_id", "questionnaire_id", "completed",
                    "completed_at") %in% names(out)))
  expect_type(out$completed, "logical")
})

test_that("completion_summary() completed column is correct", {
  obj <- .make_export_for_summary()
  out <- completion_summary(obj)

  # p1 completed both ESS and ISI
  p1 <- out[out$participant_id == "p1", ]
  expect_true(all(p1$completed))

  # p2 completed ESS only
  p2 <- out[out$participant_id == "p2", ]
  expect_true(p2$completed[p2$questionnaire_id == "ess"])
  expect_false(p2$completed[p2$questionnaire_id == "isi"])
})

test_that("completion_summary() most recent date is retained for repeated admins", {
  # Give p1 two ESS administrations
  obj <- .make_export_for_summary()
  obj$participants[[1]]$results[[3]] <- list(
    questionnaire_id = "ess",
    completed_at     = "2026-01-09T10:00:00.000Z",
    score = 8, answers = list()
  )
  out <- completion_summary(obj)

  p1_ess <- out[out$participant_id == "p1" & out$questionnaire_id == "ess", ]
  expect_equal(p1_ess$completed_at, "2026-01-09T10:00:00.000Z")
})

test_that("completion_summary() wide format has one row per participant", {
  obj  <- .make_export_for_summary()
  wide <- completion_summary(obj, wide = TRUE)

  expect_equal(nrow(wide), 2L)
  expect_true(all(c("ess", "isi") %in% names(wide)))
  expect_type(wide$ess, "logical")

  # p2's ISI column should be FALSE (not NA)
  p2_row <- wide[wide$participant_id == "p2", ]
  expect_false(p2_row$isi)
})

test_that("completion_summary() include_date = FALSE drops completed_at", {
  obj <- .make_export_for_summary()
  out <- completion_summary(obj, include_date = FALSE)
  expect_false("completed_at" %in% names(out))
})

test_that("completion_summary() include_meta = FALSE drops metadata columns", {
  obj <- .make_export_for_summary()
  out <- completion_summary(obj, include_meta = FALSE)
  expect_false("name" %in% names(out))
  expect_true("participant_id" %in% names(out))
})

test_that("completion_summary() returns empty data frame for empty export", {
  empty <- structure(
    list(exported_at = NA, export_version = "1.0",
         participants = list(), n_participants = 0L),
    class = "tallier_export"
  )
  out <- completion_summary(empty)
  expect_true(is.data.frame(out))
  expect_equal(nrow(out), 0L)
})

# ── items_long(scored_items = TRUE) ─────────────────────────────────────────────

.make_stai_export <- function() {
  # STAI-S: 20 items rated 1-4
  # Reverse items: 1,2,5,8,10,11,15,16,19,20 -> scored as 5 - raw
  stai_s_answers <- as.list(stats::setNames(rep(3L, 20L), paste0("stais_", 1:20)))

  structure(
    list(
      exported_at    = "2026-01-01T00:00:00.000Z",
      export_version = "1.0",
      n_participants = 1L,
      participants   = list(
        list(
          meta    = list(participant_id = "p1", code = "P001", name = "Test",
                         age = "30", sex = "female", bmi = "", group = "",
                         site = "", session = "", diagnosis = "",
                         medication = "", referral = "", notes = "",
                         created_at = "2026-01-01T00:00:00.000Z"),
          results = list(
            list(questionnaire_id = "stai_s",
                 completed_at     = "2026-01-01T09:00:00.000Z",
                 score            = 50L,
                 answers          = stai_s_answers)
          )
        )
      )
    ),
    class = "tallier_export"
  )
}

test_that("items_long scored_items = FALSE returns no response_scored column", {
  obj <- .make_stai_export()
  out <- suppressWarnings(items_long(obj, scored_items = FALSE))
  expect_false("response_scored" %in% names(out))
})

test_that("items_long scored_items = TRUE adds response_scored column", {
  obj <- .make_stai_export()
  out <- suppressWarnings(items_long(obj, scored_items = TRUE))
  expect_true("response_scored" %in% names(out))
})

test_that("items_long scored_items = TRUE reverses STAI-S items correctly", {
  obj <- .make_stai_export()
  out <- suppressWarnings(items_long(obj, scored_items = TRUE))

  reverse_ids <- paste0("stais_", c(1, 2, 5, 8, 10, 11, 15, 16, 19, 20))
  forward_ids <- paste0("stais_", c(3, 4, 6, 7, 9, 12, 13, 14, 17, 18))

  rev_rows <- out[out$item_id %in% reverse_ids, ]
  fwd_rows <- out[out$item_id %in% forward_ids, ]

  # All raw responses are 3; reversed should be 5 - 3 = 2
  expect_true(all(rev_rows$response == "3"))
  expect_true(all(rev_rows$response_scored == "2"))

  # Forward items unchanged
  expect_true(all(fwd_rows$response_scored == fwd_rows$response))
})

test_that("items_long scored_items = TRUE leaves non-reverse instruments unchanged", {
  # Build an export with ESS answers (no reverse items defined)
  ess_answers <- as.list(stats::setNames(rep(2L, 8L), paste0("ess", 1:8)))
  obj <- structure(
    list(
      exported_at = NA, export_version = "1.0", n_participants = 1L,
      participants = list(list(
        meta    = list(participant_id = "p1", code = "P001", name = "Test",
                       age = "30", sex = "female", bmi = "", group = "",
                       site = "", session = "", diagnosis = "",
                       medication = "", referral = "", notes = "",
                       created_at = "2026-01-01T00:00:00.000Z"),
        results = list(list(questionnaire_id = "ess",
                            completed_at     = "2026-01-01T09:00:00.000Z",
                            score = 16L, answers = ess_answers))
      ))
    ),
    class = "tallier_export"
  )
  out <- items_long(obj, scored_items = TRUE)
  expect_true("response_scored" %in% names(out))
  # ESS has no reverse items: response_scored should equal response for all rows
  expect_true(all(out$response_scored == out$response))
})
