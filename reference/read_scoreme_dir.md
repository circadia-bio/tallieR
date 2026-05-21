# Read a directory of ScoreMe JSON exports

Reads all `.json` files in a directory and combines them into a single
`tallier_study` object. Useful when each participant's data was exported
as a separate file, or when multiple batch exports need to be merged.

## Usage

``` r
read_scoreme_dir(
  dir,
  rescore = TRUE,
  pattern = "\\.json$",
  instruments = NULL
)
```

## Arguments

- dir:

  Path to a directory containing `.json` export files.

- rescore:

  Logical. Passed to
  [`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md).

- pattern:

  Regular expression used to filter filenames. Defaults to `"\\.json$"`
  (all JSON files).

- instruments:

  An optional named list of custom instrument registry entries, passed
  through to
  [`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md).
  See
  [`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md).

## Value

A `tallier_study` object: a list with elements:

- `files`:

  Character vector of files read.

- `participants`:

  Combined list of all participant records.

- `n_participants`:

  Total number of participants.

## Examples

``` r
if (FALSE) { # \dontrun{
study <- read_scoreme_dir("exports/")
wide  <- scores_wide(study)
} # }
```
