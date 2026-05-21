# Score all questionnaires in an export

Convenience wrapper that rescores every result entry in a
`tallier_export` or `tallier_study` object. This is called automatically
when `rescore = TRUE` in
[`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md).

## Usage

``` r
score_all(obj, instruments = NULL)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

- instruments:

  An optional named list of additional registry entries from
  [`load_instrument()`](https://tallier.circadia-lab.uk/reference/load_instrument.md)
  or
  [`load_instrument_dir()`](https://tallier.circadia-lab.uk/reference/load_instrument_dir.md),
  merged with the built-in registry before scoring. Entries in
  `instruments` take precedence over built-ins with the same id.

## Value

The same object with scores updated in-place.
