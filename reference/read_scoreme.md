# Read a ScoreMe JSON export

Reads a single JSON file exported from the ScoreMe app and returns a
`tallier_export` object containing participant metadata and all
questionnaire results.

## Usage

``` r
read_scoreme(path, rescore = TRUE)
```

## Arguments

- path:

  Path to a `.json` file exported from ScoreMe.

- rescore:

  Logical. If `TRUE` (default), scores are recomputed from item-level
  answers using the built-in tallieR scoring functions. If `FALSE`, the
  scores stored in the export file are used as-is.

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

## Examples

``` r
if (FALSE) { # \dontrun{
exp <- read_scoreme("my_study_export.json")
print(exp)
wide <- scores_wide(exp)
} # }
```
