test_that("text formatting helpers work as expected", {
  expect_snapshot(text_format(
    c(
      "A very long First",
      "Some similar long Second",
      "Shorter Third",
      "More or less long Fourth",
      "And finally the Last"
    ),
    width = 20
  ))

  expect_snapshot(text_format(
    c(
      "A very long First",
      "Some similar long Second",
      "Shorter Third",
      "More or less long Fourth",
      "And finally the Last"
    ),
    last = " or ",
    enclose = "`",
    width = 20
  ))

  expect_identical(
    text_fullstop(c("something", "something else.")),
    c("something.", "something else.")
  )

  expect_identical(
    text_lastchar(c("ABC", "DEF"), n = 2),
    c("BC", "EF"),
    ignore_attr = TRUE
  )

  expect_identical(
    text_concatenate(c("First", "Second")),
    "First and Second"
  )

  expect_identical(
    text_concatenate("First"),
    "First"
  )

  expect_identical(
    text_concatenate(c("First", "Second", "Last")),
    "First, Second and Last"
  )

  expect_identical(
    text_concatenate(c("First", "Second", "Last"), last = " or ", enclose = "`"),
    "`First`, `Second` or `Last`"
  )

  expect_identical(
    text_remove(c("one!", "two", "three!"), "!"),
    c("one", "two", "three")
  )

  expect_identical(
    text_paste(c("A", "", "B"), c("42", "42", "42")),
    c("A, 42", "42", "B, 42")
  )

  expect_identical(
    text_paste(c("A", "", "B"), c("42", "42", "42"), enclose = "`"),
    c("`A`, `42`", "`42`", "`B`, `42`")
  )
})

test_that("text formatters respect `width` argument", {
  expect_snapshot({
    long_text <- strrep("abc ", 100)
    cat(text_format(long_text, width = 50))
    cat(text_format(long_text, width = 80))

    withr::with_options(list(width = 50), code = {
      cat(text_format(long_text))
    })
  })
})
