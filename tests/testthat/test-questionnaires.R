test_that("score_questionnaire: ESS", {
  answers <- list(ess1=2, ess2=1, ess3=0, ess4=3, ess5=1, ess6=0, ess7=2, ess8=1)
  expect_equal(score_questionnaire("ess", answers), 10)
  expect_equal(interpret_score("ess", 10)$label, "Excessive")
  expect_equal(interpret_score("ess", 7)$label,  "Normal")
  expect_equal(interpret_score("ess", 8)$label,  "Borderline")
  expect_equal(interpret_score("ess", 16)$label, "Severe")
})

test_that("score_questionnaire: ISI", {
  answers <- list(isi1=3, isi2=2, isi3=1, isi4=3, isi5=2, isi6=1, isi7=2)
  expect_equal(score_questionnaire("isi", answers), 14)
  expect_equal(interpret_score("isi", 14)$label, "Subthreshold insomnia")
  expect_equal(interpret_score("isi", 22)$label, "Clinical insomnia (severe)")
})

test_that("score_questionnaire: DBAS-16", {
  answers <- as.list(stats::setNames(rep(6, 16), paste0("dbas", 1:16)))
  expect_equal(score_questionnaire("dbas16", answers), 6.0)
  expect_equal(interpret_score("dbas16", 6.0)$label, "Clinically relevant beliefs")
  expect_equal(interpret_score("dbas16", 3.0)$label, "Within normal range")
})

test_that("score_questionnaire: MEQ", {
  # All maximum-morningness options
  answers <- list(
    meq1=5, meq2=5, meq3=4, meq4=4, meq5=4, meq6=4, meq7=4, meq8=4, meq9=4, meq10=5,
    meq11=6, meq12=5, meq13=4, meq14=4, meq15=4, meq16=4, meq17=5, meq18=5, meq19=6
  )
  score <- score_questionnaire("meq", answers)
  expect_gte(score, 42) # at least intermediate
  expect_equal(interpret_score("meq", 75)$label, "Definite morning type")
  expect_equal(interpret_score("meq", 28)$label, "Definite evening type")
})

test_that("score_questionnaire: STOP-BANG", {
  high <- list(sb_s="yes", sb_t="yes", sb_o="yes", sb_p="yes",
               sb_b="yes", sb_a="yes", sb_n="yes", sb_g="yes")
  expect_equal(score_questionnaire("stopbang", high), 8L)
  expect_equal(interpret_score("stopbang", 8)$label, "High OSA risk")

  low <- list(sb_s="no", sb_t="no", sb_o="no", sb_p="no",
              sb_b="no", sb_a="no", sb_n="no", sb_g="no")
  expect_equal(score_questionnaire("stopbang", low), 0L)
  expect_equal(interpret_score("stopbang", 0)$label, "Low OSA risk")
})

test_that("score_questionnaire: KSS", {
  expect_equal(score_questionnaire("kss", list(kss1 = 9)), 9)
  expect_equal(interpret_score("kss", 9)$label, "Severe sleepiness")
  expect_equal(interpret_score("kss", 3)$label, "Alert")
})

test_that("score_questionnaire: RU-SATED", {
  good <- as.list(stats::setNames(rep(4, 6), paste0("rus", 1:6)))
  expect_equal(score_questionnaire("rusated", good), 24)
  expect_equal(interpret_score("rusated", 24)$label, "Good sleep health")
  expect_equal(interpret_score("rusated", 5)$label,  "Poor sleep health")
})

test_that("score_questionnaire: PSQI", {
  answers <- list(
    psqi9 = 1,
    psqi2 = 20,
    psqi5a = 1,
    psqi4 = 6.5,
    psqi1 = list(hour = 23, minute = 0),
    psqi3 = list(hour = 7,  minute = 0),
    psqi5b=1, psqi5c=0, psqi5d=0, psqi5e=0, psqi5f=0, psqi5g=0, psqi5h=0, psqi5i=0,
    psqi6 = 0,
    psqi7 = 1,
    psqi8 = 1
  )
  result <- score_questionnaire("psqi", answers)
  expect_true(is.list(result))
  expect_true("global" %in% names(result))
  expect_gte(result$global, 0)
  expect_lte(result$global, 21)
})

test_that("available_instruments returns expected IDs", {
  inst <- available_instruments()
  expect_true(is.data.frame(inst))
  expect_true(all(c("ess","isi","dbas16","meq","psqi","rusated","stopbang","kss","mctq") %in% inst$id))
})

test_that("score_questionnaire: MCTQ", {
  answers <- list(
    bt_w = list(hour = 23, minute = 0),
    sl_w = 15,
    wt_w = list(hour = 7,  minute = 0),
    bt_f = list(hour = 0,  minute = 30),
    sl_f = 10,
    wt_f = list(hour = 9,  minute = 0),
    wd   = 5
  )
  result <- score_questionnaire("mctq", answers)
  expect_true(is.list(result))
  expect_true(all(c("msfsc", "sjl", "msw", "msf", "sd_w", "sd_f") %in% names(result)))
  expect_gte(result$sjl, 0)
  interp <- interpret_score("mctq", result)
  expect_true(nchar(interp$label) > 0)
})

test_that("unknown questionnaire id gives informative error", {
  expect_error(score_questionnaire("xyz", list()), "Unknown questionnaire id")
})
