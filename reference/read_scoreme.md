# Read a ScoreMe JSON export

Reads a single JSON file exported from the ScoreMe app and returns a
`tallier_export` object containing participant metadata and all
questionnaire results.

## Usage

``` r
read_scoreme(path, rescore = TRUE, instruments = NULL)
```

## Arguments

- path:

  Path to a `.json` file exported from ScoreMe.

- rescore:

  Logical. If `TRUE` (default), scores are recomputed from item-level
  answers using the built-in tallieR scoring functions. If `FALSE`, the
  scores stored in the export file are used as-is.

- instruments:

  An optional named list of custom instrument registry entries created
  by
  [`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)
  or
  [`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md).
  When `rescore = TRUE`, these are merged with the built-in registry so
  that custom questionnaires in the export can be scored. Entries in
  `instruments` take precedence over built-ins with the same id.

## Value

A `tallier_export` object: a list with elements:

- `exported_at`:

  Timestamp of the export (character).

- `export_version`:

  Schema version string.

- `participants`:

  A list of parsed participant records.

- `n_participants`:

  Number of participants.

## See also

[`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md),
[`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md)

## Examples

``` r
if (FALSE) { # \dontrun{
exp <- read_scoreme("my_study_export.json")
print(exp)
wide <- scores_wide(exp)

# With custom instruments
custom <- load_instrument("fss.json")
exp    <- read_scoreme("export.json", instruments = custom)
wide   <- scores_wide(exp)
} # }
```
