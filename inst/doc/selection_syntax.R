## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

pkgs <- c(
  "datawizard",
  "dplyr"
)

if (!all(vapply(pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1L)))) {
  knitr::opts_chunk$set(eval = FALSE)
}

## ----load, echo=FALSE, message=FALSE------------------------------------------
library(datawizard)
library(dplyr)

set.seed(123)
iris <- iris[sample(nrow(iris), 10), ]
row.names(iris) <- NULL

## -----------------------------------------------------------------------------
data_select(iris, c("Sepal.Length", "Petal.Width"))

## -----------------------------------------------------------------------------
iris %>%
  group_by(Species) %>%
  standardise(Petal.Length) %>%
  ungroup()

## -----------------------------------------------------------------------------
data_select(iris, c(1, 2, 5))

## -----------------------------------------------------------------------------
data_select(iris, is.numeric)

## -----------------------------------------------------------------------------
my_function <- function(i) {
  is.numeric(i) && mean(i, na.rm = TRUE) > 3.5
}

data_select(iris, my_function)

## -----------------------------------------------------------------------------
data_select(iris, starts_with("Sep", "Peta"))

data_select(iris, ends_with("dth", "ies"))

data_select(iris, contains("pal", "ec"))

data_select(iris, regex("^Sep|ies"))

## -----------------------------------------------------------------------------
data_select(iris, -c("Sepal.Length", "Petal.Width"))

data_select(iris, -starts_with("Sep", "Peta"))

data_select(iris, -is.numeric)

## -----------------------------------------------------------------------------
data_select(iris, -(1:2))

## -----------------------------------------------------------------------------
data_select(iris, -(Petal.Length:Species))

## -----------------------------------------------------------------------------
data_select(iris, exclude = c("Sepal.Length", "Petal.Width"))

data_select(iris, exclude = starts_with("Sep", "Peta"))

## -----------------------------------------------------------------------------
my_function <- function(data, selection) {
  extract_column_names(data, select = selection)
}
my_function(iris, "Sepal.Length")
my_function(iris, starts_with("Sep"))

my_function_2 <- function(data, pattern) {
  extract_column_names(data, select = starts_with(pattern))
}
my_function_2(iris, "Sep")

## -----------------------------------------------------------------------------
new_iris <- iris
for (i in c("Sep", "Pet")) {
  new_iris <- new_iris %>%
    data_relocate(select = starts_with(i), after = -1)
}
new_iris

## -----------------------------------------------------------------------------
data_select(iris, c("sepal.length", "petal.width"), ignore_case = TRUE)

data_select(iris, ~ Sepal.length + petal.Width, ignore_case = TRUE)

data_select(iris, starts_with("sep", "peta"), ignore_case = TRUE)

## -----------------------------------------------------------------------------
data_select(iris, ~ Sepal.Length + Petal.Width)

