# tests/testthat/test-questionnaires.R

# ── Sleep ─────────────────────────────────────────────────────────────────────

test_that("score_questionnaire: ESS", {
  answers <- list(ess1=2, ess2=1, ess3=0, ess4=3, ess5=1, ess6=0, ess7=2, ess8=1)
  expect_equal(score_questionnaire("ess", answers), 10)
  expect_equal(interpret_score("ess", 10)$label, "Excessive")
  expect_equal(interpret_score("ess",  7)$label, "Normal")
  expect_equal(interpret_score("ess",  8)$label, "Borderline")
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
  answers <- list(
    meq1=5, meq2=5, meq3=4, meq4=4, meq5=4, meq6=4, meq7=4, meq8=4, meq9=4, meq10=5,
    meq11=6, meq12=5, meq13=4, meq14=4, meq15=4, meq16=4, meq17=5, meq18=5, meq19=6
  )
  score <- score_questionnaire("meq", answers)
  expect_gte(score, 42)
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
  expect_equal(interpret_score("rusated",  5)$label, "Poor sleep health")
})

test_that("score_questionnaire: PSQI", {
  answers <- list(
    psqi9 = 1, psqi2 = 20, psqi5a = 1, psqi4 = 6.5,
    psqi1 = list(hour = 23, minute = 0),
    psqi3 = list(hour =  7, minute = 0),
    psqi5b=1, psqi5c=0, psqi5d=0, psqi5e=0, psqi5f=0, psqi5g=0, psqi5h=0, psqi5i=0,
    psqi6 = 0, psqi7 = 1, psqi8 = 1
  )
  result <- score_questionnaire("psqi", answers)
  expect_true(is.list(result))
  expect_true("global" %in% names(result))
  expect_gte(result$global, 0)
  expect_lte(result$global, 21)
  expect_equal(interpret_score("psqi", result$global)$label, interpret_score("psqi", result)$label)
})

test_that("score_questionnaire: MCTQ", {
  answers <- list(
    bt_w = list(hour = 23, minute = 0), sl_w = 15,
    wt_w = list(hour =  7, minute = 0),
    bt_f = list(hour =  0, minute = 30), sl_f = 10,
    wt_f = list(hour =  9, minute = 0),
    wd   = 5
  )
  result <- score_questionnaire("mctq", answers)
  expect_true(is.list(result))

  # All expected fields present
  expect_true(all(c("msfsc", "sjl", "sjl_rel", "msw", "msf",
                    "sd_w", "sd_f", "sd_week",
                    "alarm_w", "alarm_f") %in% names(result)))

  # sjl is absolute (non-negative)
  expect_gte(result$sjl, 0)

  # sd_week is a weighted average of sd_w and sd_f (5 workdays, 2 free days)
  # sd_w: 07:00 - (23:00 + 15/60) = 7.75h; sd_f: 09:00 - (00:30 + 10/60) = 8.33h
  expected_sd_week <- round((result$sd_w * 5 + result$sd_f * 2) / 7, 2)
  expect_equal(result$sd_week, expected_sd_week)

  # sjl_rel is signed: MSFsc - MSW, both as normalised clock times.
  # Check sign and that it is consistent with the stored msfsc/msw to within
  # rounding tolerance (independent rounding of each field can cause 0.01 drift).
  expect_true(is.numeric(result$sjl_rel))
  expect_equal(result$sjl_rel, round(result$msfsc - result$msw, 2),
               tolerance = 0.02)

  # alarm flags absent from answers -> NA
  expect_true(is.na(result$alarm_w))
  expect_true(is.na(result$alarm_f))

  # interpret still works
  interp <- interpret_score("mctq", result)
  expect_true(nchar(interp$label) > 0)
})

test_that("MCTQ alarm flags parsed correctly when present", {
  answers_alarm <- list(
    bt_w = list(hour = 23, minute = 0), sl_w = 15,
    wt_w = list(hour =  7, minute = 0),
    bt_f = list(hour =  0, minute = 0),  sl_f = 10,
    wt_f = list(hour =  9, minute = 0),
    wd   = 5,
    alarm_w = "yes",
    alarm_f = "no"
  )
  result <- score_questionnaire("mctq", answers_alarm)
  expect_true(isTRUE(result$alarm_w))
  expect_true(isFALSE(result$alarm_f))
})

# ── Mental Health ─────────────────────────────────────────────────────────────

test_that("score_questionnaire: PHQ-2", {
  answers <- list(phq2_1 = 3, phq2_2 = 2)
  expect_equal(suppressWarnings(score_questionnaire("phq2", answers)), 5)
  expect_equal(interpret_score("phq2", 5)$label, "Positive screen")
  expect_equal(interpret_score("phq2", 2)$label, "Negative screen")
})

test_that("score_questionnaire: PHQ-9", {
  answers <- as.list(stats::setNames(rep(2, 9), paste0("phq9_", 1:9)))
  expect_equal(suppressWarnings(score_questionnaire("phq9", answers)), 18)
  expect_equal(interpret_score("phq9", 18)$label, "Moderately severe")
  expect_equal(interpret_score("phq9",  3)$label, "Minimal depression")
  expect_equal(interpret_score("phq9", 25)$label, "Severe depression")
})

test_that("score_questionnaire: PHQ-15", {
  answers <- as.list(stats::setNames(rep(2, 15), paste0("phq15_", 1:15)))
  expect_equal(suppressWarnings(score_questionnaire("phq15", answers)), 30)
  expect_equal(interpret_score("phq15", 30)$label, "High somatic symptoms")
  expect_equal(interpret_score("phq15",  3)$label, "Minimal somatic symptoms")
})

test_that("score_questionnaire: GAD-7", {
  answers <- as.list(stats::setNames(rep(3, 7), paste0("gad7_", 1:7)))
  expect_equal(suppressWarnings(score_questionnaire("gad7", answers)), 21)
  expect_equal(interpret_score("gad7", 21)$label, "Severe anxiety")
  expect_equal(interpret_score("gad7",  3)$label, "Minimal anxiety")
  expect_equal(interpret_score("gad7",  7)$label, "Mild anxiety")
})

test_that("score_questionnaire: GAD-2", {
  answers <- list(gad2_1 = 3, gad2_2 = 3)
  expect_equal(suppressWarnings(score_questionnaire("gad2", answers)), 6)
  expect_equal(interpret_score("gad2", 6)$label, "Positive screen")
  expect_equal(interpret_score("gad2", 1)$label, "Negative screen")
})

test_that("score_questionnaire: BDI-II", {
  answers <- as.list(stats::setNames(rep(2, 21), paste0("bdi2_", 1:21)))
  expect_equal(suppressWarnings(score_questionnaire("bdi2", answers)), 42)
  expect_equal(interpret_score("bdi2", 42)$label, "Severe depression")
  expect_equal(interpret_score("bdi2",  5)$label, "Minimal depression")
  expect_equal(interpret_score("bdi2", 16)$label, "Mild depression")
  expect_equal(interpret_score("bdi2", 24)$label, "Moderate depression")
})

test_that("score_questionnaire: BAI", {
  answers <- as.list(stats::setNames(rep(3, 21), paste0("bai", 1:21)))
  expect_equal(suppressWarnings(score_questionnaire("bai", answers)), 63)
  expect_equal(interpret_score("bai", 63)$label, "Severe anxiety")
  expect_equal(interpret_score("bai",  4)$label, "Minimal anxiety")
  expect_equal(interpret_score("bai", 10)$label, "Mild anxiety")
  expect_equal(interpret_score("bai", 20)$label, "Moderate anxiety")
})

test_that("score_questionnaire: DASS-21", {
  # All 3s -> depression = 42, anxiety = 42, stress = 42, total = 126 (all *2)
  answers <- as.list(stats::setNames(rep(3, 21), paste0("dass21_", 1:21)))
  result  <- suppressWarnings(score_questionnaire("dass21", answers))
  expect_true(is.list(result))
  expect_true(all(c("total", "depression", "anxiety", "stress") %in% names(result)))
  expect_equal(result$depression + result$anxiety + result$stress, result$total)
  expect_equal(interpret_score("dass21", result)$label, "Severe-Extreme")
  expect_equal(interpret_score("dass21", list(total = 5))$label, "Normal-Mild")
})

test_that("score_questionnaire: PANSS", {
  # Minimum: all absent (1 per item) -> positive=7, negative=7, general=16, total=30
  min_answers <- as.list(c(
    stats::setNames(rep(1, 7),  paste0("panss_p", 1:7)),
    stats::setNames(rep(1, 7),  paste0("panss_n", 1:7)),
    stats::setNames(rep(1, 16), paste0("panss_g", 1:16))
  ))
  result <- suppressWarnings(score_questionnaire("panss", min_answers))
  expect_true(is.list(result))
  expect_equal(result$total, 30)
  expect_equal(interpret_score("panss", result)$label, "Minimal psychopathology")

  # High: all 7
  max_answers <- as.list(c(
    stats::setNames(rep(7, 7),  paste0("panss_p", 1:7)),
    stats::setNames(rep(7, 7),  paste0("panss_n", 1:7)),
    stats::setNames(rep(7, 16), paste0("panss_g", 1:16))
  ))
  result_max <- suppressWarnings(score_questionnaire("panss", max_answers))
  expect_equal(result_max$total, 210)
  expect_equal(interpret_score("panss", result_max)$label, "Severe-Extreme")
})

test_that("score_questionnaire: STAI-S", {
  # All 4s: forward items = 4, reverse items = 5-4 = 1
  # 10 forward items x 4 = 40; 10 reverse items x 1 = 10 -> total = 50
  answers <- as.list(stats::setNames(rep(4, 20), paste0("stais_", 1:20)))
  expect_equal(suppressWarnings(score_questionnaire("stai_s", answers)), 50)
  expect_equal(interpret_score("stai_s", 50)$label, "High state anxiety")
  expect_equal(interpret_score("stai_s", 30)$label, "Low state anxiety")
  expect_equal(interpret_score("stai_s", 40)$label, "Moderate state anxiety")
})

test_that("score_questionnaire: STAI-T", {
  # All 4s: 12 forward items x 4 = 48; 8 reverse items x 1 = 8 -> total = 56
  answers <- as.list(stats::setNames(rep(4, 20), paste0("stait_", 21:40)))
  expect_equal(suppressWarnings(score_questionnaire("stai_t", answers)), 56)
  expect_equal(interpret_score("stai_t", 56)$label, "High trait anxiety")
  expect_equal(interpret_score("stai_t", 25)$label, "Low trait anxiety")
})

# ── Wellbeing ─────────────────────────────────────────────────────────────────

test_that("score_questionnaire: WHOQOL-BREF", {
  # All 5s (maximum on all items)
  answers <- as.list(stats::setNames(rep(5, 26), paste0("whoqol_", 1:26)))
  result  <- suppressWarnings(score_questionnaire("whoqol_bref", answers))
  expect_true(is.list(result))
  expect_true(all(c("total", "physical", "psychological", "social", "environment") %in% names(result)))
  expect_equal(result$total, 100)
  expect_equal(interpret_score("whoqol_bref", result)$label, "Very good QoL")
  expect_equal(interpret_score("whoqol_bref", list(total = 30))$label, "Poor QoL")
})

test_that("score_questionnaire: MacArthur SSS", {
  answers <- list(mac_sss_society = 8, mac_sss_community = 7)
  expect_equal(suppressWarnings(score_questionnaire("macarthur_sss", answers)), 15)
  expect_equal(interpret_score("macarthur_sss", 15)$label, "High social status")
  expect_equal(interpret_score("macarthur_sss",  5)$label, "Low social status")
  expect_equal(interpret_score("macarthur_sss", 11)$label, "Moderate social status")
})

# ── Physical Activity ─────────────────────────────────────────────────────────

test_that("score_questionnaire: IPAQ-S", {
  # 3 vigorous days x 60 min x 8.0 = 1440
  # 2 moderate  days x 30 min x 4.0 = 240
  # 5 walking   days x 20 min x 3.3 = 330
  # total = 2010
  answers <- list(ipaq_vigd=3, ipaq_vigm=60, ipaq_modd=2, ipaq_modm=30,
                  ipaq_walkd=5, ipaq_walkm=20, ipaq_sitm=480)
  expect_equal(suppressWarnings(score_questionnaire("ipaq_short", answers)), 2010)
  expect_equal(interpret_score("ipaq_short", 2010)$label, "Minimally active (Moderate)")
  expect_equal(interpret_score("ipaq_short",  200)$label, "Inactive (Low)")
  expect_equal(interpret_score("ipaq_short", 4000)$label, "HEPA Active (High)")
})

test_that("score_questionnaire: GPAQ", {
  # Work vigorous: yes, 3 days, 60 min -> 3*60*8 = 1440
  # Transport:     yes, 5 days, 30 min -> 5*30*4 = 600
  # total = 2040
  answers <- list(
    gpaq_p1="yes",  gpaq_p2=3,  gpaq_p3=60,
    gpaq_p4="no",   gpaq_p5=0,  gpaq_p6=0,
    gpaq_p7="yes",  gpaq_p8=5,  gpaq_p9=30,
    gpaq_p10="no",  gpaq_p11=0, gpaq_p12=0,
    gpaq_p13="no",  gpaq_p14=0, gpaq_p15=0,
    gpaq_p16=480
  )
  expect_equal(suppressWarnings(score_questionnaire("gpaq", answers)), 2040)
  expect_equal(interpret_score("gpaq", 2040)$label, "Sufficiently active")
  expect_equal(interpret_score("gpaq",  300)$label, "Insufficiently active")
})

# ── Neurodevelopmental ────────────────────────────────────────────────────────

test_that("score_questionnaire: GSQ", {
  # All 4s -> 28 * 4 = 112
  answers <- as.list(stats::setNames(rep(4, 28), paste0("gsq_", 1:28)))
  expect_equal(suppressWarnings(score_questionnaire("gsq", answers)), 112)
  expect_equal(interpret_score("gsq", 112)$label, "High sensory sensitivity")
  expect_equal(interpret_score("gsq",  10)$label, "Low sensory sensitivity")
  expect_equal(interpret_score("gsq",  40)$label, "Mild sensory sensitivity")
  expect_equal(interpret_score("gsq",  70)$label, "Moderate sensory sensitivity")
})

test_that("score_questionnaire: AQ-10", {
  # Agree-direction items 1,7,8,10 = "da"; disagree-direction 2,3,4,5,6,9 = "dd" -> score 10
  answers <- list(
    aq10_1="da", aq10_2="dd", aq10_3="dd", aq10_4="dd", aq10_5="dd",
    aq10_6="dd", aq10_7="da", aq10_8="da", aq10_9="dd", aq10_10="da"
  )
  expect_equal(suppressWarnings(score_questionnaire("aq10", answers)), 10)
  expect_equal(interpret_score("aq10", 10)$label, "Above threshold - consider referral")
  expect_equal(interpret_score("aq10",  3)$label, "Below threshold")

  # All in wrong direction -> score 0
  answers_0 <- list(
    aq10_1="dd", aq10_2="da", aq10_3="da", aq10_4="da", aq10_5="da",
    aq10_6="da", aq10_7="dd", aq10_8="dd", aq10_9="da", aq10_10="dd"
  )
  expect_equal(suppressWarnings(score_questionnaire("aq10", answers_0)), 0)
})

# ── Registry & error handling ─────────────────────────────────────────────────

test_that("available_instruments returns expected columns and IDs", {
  inst <- available_instruments()
  expect_true(is.data.frame(inst))
  expect_true(all(c("id", "title", "domain", "max_score", "beta") %in% names(inst)))

  # All original sleep instruments still present and non-beta
  sleep_ids <- c("ess", "isi", "dbas16", "meq", "psqi", "rusated", "stopbang", "kss", "mctq")
  expect_true(all(sleep_ids %in% inst$id))
  expect_true(all(!inst$beta[inst$id %in% sleep_ids]))

  # All new instruments present and beta
  new_ids <- c("phq2", "phq9", "phq15", "gad7", "gad2", "bdi2", "bai", "dass21",
               "panss", "stai_s", "stai_t", "whoqol_bref", "macarthur_sss",
               "ipaq_short", "gpaq", "gsq", "aq10")
  expect_true(all(new_ids %in% inst$id))
  expect_true(all(inst$beta[inst$id %in% new_ids]))
})

test_that("score_questionnaire emits warning for beta instruments", {
  expect_warning(score_questionnaire("phq2", list(phq2_1 = 1, phq2_2 = 1)), "beta")
})

test_that("score_questionnaire does not warn for stable instruments", {
  expect_no_warning(score_questionnaire("ess", list(ess1=1, ess2=1, ess3=1,
                                                    ess4=1, ess5=1, ess6=1,
                                                    ess7=1, ess8=1)))
})

test_that("unknown questionnaire id gives informative error", {
  expect_error(score_questionnaire("xyz", list()), "Unknown questionnaire id")
})

# ── interpret_all() ───────────────────────────────────────────────────────────

.make_minimal_export <- function() {
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
            list(questionnaire_id = "ess",
                 completed_at     = "2026-01-01T09:00:00.000Z",
                 score            = 12,
                 answers          = list(ess1=2,ess2=1,ess3=0,ess4=3,
                                        ess5=1,ess6=0,ess7=2,ess8=3)),
            list(questionnaire_id = "isi",
                 completed_at     = "2026-01-01T09:05:00.000Z",
                 score            = 8,
                 answers          = list(isi1=1,isi2=1,isi3=1,isi4=1,
                                        isi5=1,isi6=1,isi7=2))
          )
        )
      )
    ),
    class = "tallier_export"
  )
}

test_that("interpret_all() returns correct shape", {
  obj <- .make_minimal_export()
  out <- interpret_all(obj)

  expect_true(is.data.frame(out))
  expected_cols <- c("participant_id", "code", "questionnaire_id",
                     "completed_at", "score", "label", "color", "description")
  expect_true(all(expected_cols %in% names(out)))
  expect_equal(nrow(out), 2L)  # one row per result
})

test_that("interpret_all() returns correct interpretation values", {
  obj <- .make_minimal_export()
  out <- interpret_all(obj)

  ess_row <- out[out$questionnaire_id == "ess", ]
  expect_equal(ess_row$label, "Excessive")   # ESS 12 -> Excessive sleepiness
  expect_false(is.na(ess_row$color))
  expect_false(is.na(ess_row$description))
})

test_that("interpret_all() handles unknown instrument gracefully", {
  obj <- .make_minimal_export()
  # Inject a result with an unrecognised questionnaire id
  obj$participants[[1]]$results[[3]] <- list(
    questionnaire_id = "unknown_q",
    completed_at     = "2026-01-01T09:10:00.000Z",
    score            = 5,
    answers          = list()
  )
  out <- suppressWarnings(interpret_all(obj))

  unknown_row <- out[out$questionnaire_id == "unknown_q", ]
  expect_equal(nrow(unknown_row), 1L)
  expect_true(is.na(unknown_row$label))
})

test_that("interpret_all() include_meta = FALSE drops metadata columns", {
  obj <- .make_minimal_export()
  out <- interpret_all(obj, include_meta = FALSE)

  expect_false("name" %in% names(out))
  expect_false("age"  %in% names(out))
  expect_true("participant_id" %in% names(out))
})

test_that("interpret_all() returns empty data frame for empty export", {
  empty <- structure(
    list(exported_at = NA, export_version = "1.0",
         participants = list(), n_participants = 0L),
    class = "tallier_export"
  )
  out <- interpret_all(empty)
  expect_true(is.data.frame(out))
  expect_equal(nrow(out), 0L)
})
