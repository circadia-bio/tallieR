# Score a questionnaire from item-level answers

Computes the score for a single questionnaire using the official scoring
algorithm embedded in tallieR, or a custom scoring function compiled
from a ScoreMe JSON spec via
[`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md).

## Usage

``` r
score_questionnaire(id, answers, instruments = NULL)
```

## Arguments

- id:

  Character. Questionnaire identifier (e.g. `"ess"`, `"psqi"`). See
  [`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)
  for valid IDs. For custom instruments, this must match the `id` field
  in the spec passed to `instruments`.

- answers:

  A named list of item responses, as exported by ScoreMe. Keys are item
  IDs (e.g. `"ess1"`, `"psqi2"`); values are the raw responses (numeric,
  character `"yes"`/`"no"`, or clock-time list).

- instruments:

  An optional named list of additional instrument registry entries, as
  returned by
  [`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)
  or
  [`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md).
  These are searched first, before the built-in registry, so a custom
  entry can override a built-in if needed.

## Value

For most instruments: a single numeric score. For composite instruments
(PSQI, MCTQ, DASS-21, PANSS, WHOQOL-BREF): a named list of subscale and
total scores.

## Details

Instruments marked `beta = TRUE` in
[`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)
are newer additions whose scoring has been ported from ScoreMe but has
not yet been independently validated in tallieR. A warning is emitted
for these instruments; suppress with
[`suppressWarnings()`](https://rdrr.io/r/base/warning.html) if needed.

## See also

[`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md),
[`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md)

## Examples

``` r
score_questionnaire("ess", list(ess1 = 2, ess2 = 1, ess3 = 0,
                                ess4 = 3, ess5 = 1, ess6 = 0,
                                ess7 = 2, ess8 = 1))
#> [1] 10

if (FALSE) { # \dontrun{
# Score using a custom instrument loaded from a JSON spec
my_instr <- load_instrument("path/to/fss.json")
score_questionnaire("fss", answers, instruments = my_instr)
} # }
```
