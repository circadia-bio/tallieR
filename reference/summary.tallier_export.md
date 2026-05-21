# Summarise a tallier_export object

Prints a structured overview of a `tallier_export`, including
participant count, instruments present, per-instrument completion rates,
and the date range of administrations. The summary statistics are also
returned invisibly as a list for programmatic use.

## Usage

``` r
# S3 method for class 'tallier_export'
summary(object, ...)
```

## Arguments

- object:

  A `tallier_export` object.

- ...:

  Ignored.

## Value

Invisibly, a list with elements `n_participants`, `instruments`,
`completion` (a data frame), and `date_range`.

## Examples

``` r
if (FALSE) { # \dontrun{
exp <- read_scoreme("export.json")
summary(exp)

# Access stats programmatically
s <- summary(exp)
s$completion
} # }
```
