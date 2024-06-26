test_that("demean works", {
  df <- iris

  set.seed(123)
  df$ID <- sample.int(4, nrow(df), replace = TRUE) # fake-ID

  set.seed(123)
  df$binary <- as.factor(rbinom(150, 1, 0.35)) # binary variable

  set.seed(123)
  x <- demean(df, select = c("Sepal.Length", "Petal.Length"), by = "ID")
  expect_snapshot(head(x))

  set.seed(123)
  expect_message(
    {
      x <- demean(df, select = c("Sepal.Length", "binary", "Species"), by = "ID")
    },
    "have been coerced to numeric"
  )
  expect_snapshot(head(x))

  set.seed(123)
  expect_message(
    {
      y <- demean(df, select = ~ Sepal.Length + binary + Species, by = ~ID)
    },
    "have been coerced to numeric"
  )
  expect_message(
    {
      z <- demean(df, select = c("Sepal.Length", "binary", "Species"), by = "ID")
    },
    "have been coerced to numeric"
  )
  expect_identical(y, z)
})

test_that("demean interaction term", {
  dat <- data.frame(
    a = c(1, 2, 3, 4, 1, 2, 3, 4),
    x = c(4, 3, 3, 4, 1, 2, 1, 2),
    y = c(1, 2, 1, 2, 4, 3, 2, 1),
    ID = c(1, 2, 3, 1, 2, 3, 1, 2)
  )

  set.seed(123)
  expect_snapshot(demean(dat, select = c("a", "x*y"), by = "ID"))
})

test_that("demean shows message if some vars don't exist", {
  dat <- data.frame(
    a = c(1, 2, 3, 4, 1, 2, 3, 4),
    x = c(4, 3, 3, 4, 1, 2, 1, 2),
    y = c(1, 2, 1, 2, 4, 3, 2, 1),
    ID = c(1, 2, 3, 1, 2, 3, 1, 2)
  )

  set.seed(123)
  expect_message(
    demean(dat, select = "foo", by = "ID"),
    regexp = "not found"
  )
})
