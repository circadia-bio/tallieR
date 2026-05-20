fixture_path <- system.file("extdata", "example_instrument.json", package = "tallieR")

# ─── load_instrument() ────────────────────────────────────────────────────────

test_that("load_instrument returns a named list keyed by instrument id", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg <- load_instrument(fixture_path)
  expect_type(reg, "list")
  expect_true("fss" %in% names(reg))
})

test_that("loaded instrument has required registry fields", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg  <- load_instrument(fixture_path)
  inst <- reg[["fss"]]
  expect_true(all(c("title", "domain", "max_score", "beta", "score", "interpret") %in% names(inst)))
  expect_equal(inst$title,     "Fatigue Severity Scale")
  expect_equal(inst$domain,    "Fatigue")
  expect_equal(inst$max_score, 63)
  expect_false(inst$beta)
})

test_that("loaded instrument preserves original spec", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg <- load_instrument(fixture_path)
  expect_false(is.null(reg[["fss"]][["spec"]]))
  expect_equal(reg[["fss"]][["spec"]][["shortTitle"]], "FSS")
})

test_that("load_instrument errors on non-existent file", {
  expect_error(load_instrument("does_not_exist.json"), "File not found")
})

test_that("load_instrument errors when required fields are missing", {
  tmp <- tempfile(fileext = ".json")
  writeLines('{"title": "No ID here", "items": []}', tmp)
  expect_error(load_instrument(tmp), "missing required field")
  unlink(tmp)
})

# ─── Scoring via compiled function ────────────────────────────────────────────

test_that("compiled mean scoring returns correct value", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg  <- load_instrument(fixture_path)
  # 9 items all rated 5 -> mean = 5.0
  answers <- stats::setNames(
    as.list(rep(5, 9)),
    paste0("fss", 1:9)
  )
  score <- reg[["fss"]]$score(answers)
  expect_equal(score, 5.0)
})

test_that("compiled scoring handles missing items gracefully (NA excluded)", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg     <- load_instrument(fixture_path)
  answers <- list(fss1 = 6, fss2 = 4)   # only 2 of 9 items
  score   <- reg[["fss"]]$score(answers)
  # mean(6, 4, NA, NA, ...) with na.rm = TRUE -> mean(c(6,4)) = 5.0
  expect_equal(score, 5.0)
})

# ─── Interpretation ───────────────────────────────────────────────────────────

test_that("compiled interpretation returns correct band", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg    <- load_instrument(fixture_path)
  interp <- reg[["fss"]]$interpret(2.0)
  expect_equal(interp$label, "No significant fatigue")
  expect_equal(interp$color, "#2E7D32")

  interp2 <- reg[["fss"]]$interpret(4.5)
  expect_equal(interp2$label, "Moderate fatigue")

  interp3 <- reg[["fss"]]$interpret(6.0)
  expect_equal(interp3$label, "Severe fatigue")
})

test_that("out-of-range score returns 'Out of range' entry", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg    <- load_instrument(fixture_path)
  interp <- reg[["fss"]]$interpret(99)
  expect_equal(interp$label, "Out of range")
})

# ─── Integration with score_questionnaire() ───────────────────────────────────

test_that("score_questionnaire accepts instruments argument", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg     <- load_instrument(fixture_path)
  answers <- stats::setNames(as.list(rep(4, 9)), paste0("fss", 1:9))
  score   <- score_questionnaire("fss", answers, instruments = reg)
  expect_equal(score, 4.0)
})

test_that("score_questionnaire errors for unknown id even with instruments arg", {
  expect_error(
    score_questionnaire("no_such_q", list(), instruments = list()),
    "Unknown questionnaire id"
  )
})

test_that("custom instrument takes precedence over built-in with same id", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  # Build a trivial override for ESS that always returns 99
  override <- list(ess = list(
    title     = "ESS override",
    domain    = "Test",
    max_score = 99,
    beta      = FALSE,
    score     = function(answers) 99,
    interpret = function(score) list(label = "override", color = "#000000", description = "")
  ))
  score <- score_questionnaire("ess", list(), instruments = override)
  expect_equal(score, 99)
})

# ─── Integration with interpret_score() ───────────────────────────────────────

test_that("interpret_score accepts instruments argument", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  reg    <- load_instrument(fixture_path)
  interp <- interpret_score("fss", 5.0, instruments = reg)
  expect_equal(interp$label, "Moderate fatigue")
})

# ─── load_instrument_dir() ────────────────────────────────────────────────────

test_that("load_instrument_dir loads all JSON files in a directory", {
  skip_if_not(file.exists(fixture_path), "fixture not installed")
  dir <- dirname(fixture_path)
  reg <- load_instrument_dir(dir)
  expect_type(reg, "list")
  expect_true("fss" %in% names(reg))
})

test_that("load_instrument_dir errors on missing directory", {
  expect_error(load_instrument_dir("/no/such/dir"), "Directory not found")
})

test_that("load_instrument_dir returns empty list for directory with no JSON files", {
  tmp_dir <- tempdir()
  # Temporarily move to a clean subdirectory
  clean <- file.path(tmp_dir, "tallieR_empty_test")
  dir.create(clean, showWarnings = FALSE)
  expect_warning(reg <- load_instrument_dir(clean), "No JSON files found")
  expect_equal(length(reg), 0L)
  unlink(clean, recursive = TRUE)
})

# ─── Composite scoring type ───────────────────────────────────────────────────

test_that("composite scoring type emits a warning and returns NA", {
  tmp <- tempfile(fileext = ".json")
  spec <- list(
    id    = "test_composite",
    title = "Composite Test",
    items = list(list(id = "c1", number = 1, text = "Q1", type = "scale_0_3")),
    scoringMethod = list(type = "composite", items = list("c1"))
  )
  writeLines(jsonlite::toJSON(spec, auto_unbox = TRUE), tmp)
  reg <- load_instrument(tmp)
  expect_warning(score <- reg[["test_composite"]]$score(list(c1 = 2)), "composite scoring")
  expect_true(is.na(score))
  unlink(tmp)
})
