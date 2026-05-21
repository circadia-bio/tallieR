# Load a custom instrument from a ScoreMe JSON spec

Reads a `.json` file produced for (or exported from) the ScoreMe app and
compiles it into a tallieR registry entry. The result can be passed to
[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md)
via its `instruments` argument, combined with other custom entries using
[`c()`](https://rdrr.io/r/base/c.html), or stored in a project-level
list for reuse.

## Usage

``` r
load_instrument(path)
```

## Arguments

- path:

  Path to a `.json` file containing a ScoreMe instrument spec. See
  `vignette("custom-instruments")` or
  `system.file("extdata", "example_instrument.json", package = "tallieR")`
  for the expected schema.

## Value

A named list (a single tallieR registry), where the name is the
instrument `id` from the spec. Invisibly also carries the original spec
in `$<id>$spec`.

## Details

**Supported scoring types:** `"sum"`, `"weighted_sum"`, `"mean"`. For
instruments with `"composite"` scoring (e.g. PSQI-style multi-component
algorithms) the returned entry will score as `NA` and a warning is
emitted each time scoring is attempted. You can override the compiled
`score` function by assigning a custom one after loading (see examples).

## See also

[`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md),
[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md),
[`available_instruments()`](https://tallier.circadia-lab.uk/reference/available_instruments.md)

## Examples

``` r
if (FALSE) { # \dontrun{
my_instr <- load_instrument("path/to/fss.json")

# Score a single result
score_questionnaire("fss", answers, instruments = my_instr)

# Combine with another custom instrument
registry <- c(load_instrument("fss.json"), load_instrument("vas_pain.json"))

# Override scoring for a composite instrument
my_psqi <- load_instrument("psqi_custom.json")
my_psqi$psqi_custom$score <- function(answers) { ... }
} # }
```
