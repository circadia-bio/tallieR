# Load all custom instruments from a directory

Reads every `.json` file in `dir`, compiles each as a tallieR registry
entry, and returns a combined named list suitable for passing to
[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md).

## Usage

``` r
load_instrument_dir(dir, pattern = "\\.json$")
```

## Arguments

- dir:

  Path to a directory containing ScoreMe instrument JSON files.

- pattern:

  Regular expression used to filter filenames. Defaults to `"\\.json$"`.

## Value

A named list of registry entries (one per successfully loaded file).

## See also

[`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md),
[`score_questionnaire()`](https://tallier.circadia-lab.uk/reference/score_questionnaire.md)

## Examples

``` r
if (FALSE) { # \dontrun{
custom <- load_instrument_dir("instruments/")
score_questionnaire("fss", answers, instruments = custom)
} # }
```
