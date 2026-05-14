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
