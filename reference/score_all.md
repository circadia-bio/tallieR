# Score all questionnaires in an export

Convenience wrapper that rescores every result entry in a
`tallier_export` or `tallier_study` object. This is called automatically
when `rescore = TRUE` in
[`read_scoreme()`](https://tallier.circadia-lab.uk/reference/read_scoreme.md).

## Usage

``` r
score_all(obj)
```

## Arguments

- obj:

  A `tallier_export` or `tallier_study` object.

## Value

The same object with scores updated in-place.
