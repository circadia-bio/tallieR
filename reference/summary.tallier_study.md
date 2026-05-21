# Summarise a tallier_study object

Prints a structured overview of a `tallier_study`, including participant
count, number of source files, instruments present, per-instrument
completion rates, and the date range of administrations. The summary
statistics are also returned invisibly as a list for programmatic use.

## Usage

``` r
# S3 method for class 'tallier_study'
summary(object, ...)
```

## Arguments

- object:

  A `tallier_study` object.

- ...:

  Ignored.

## Value

Invisibly, a list with elements `n_participants`, `n_files`,
`instruments`, `completion` (a data frame), and `date_range`.

## Examples

``` r
if (FALSE) { # \dontrun{
study <- read_scoreme_dir("exports/")
summary(study)

# Access stats programmatically
s <- summary(study)
s$completion
} # }
```
