# R/zzz.R -- Package load hook
#
# Assembles .INSTRUMENTS from the domain registries. This file is sourced
# last (alphabetically "zzz" > all other R/ files), ensuring all
# questionnaires_*.R files have been evaluated before the merge runs.

.onLoad <- function(libname, pkgname) {
  .INSTRUMENTS <<- c(
    .SLEEP_INSTRUMENTS,
    .MENTAL_HEALTH_INSTRUMENTS,
    .WELLBEING_INSTRUMENTS,
    .PHYSICAL_ACTIVITY_INSTRUMENTS,
    .NEURODEVELOPMENTAL_INSTRUMENTS
  )
}
