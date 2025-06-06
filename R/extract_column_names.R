#' @title Find or get columns in a data frame based on search patterns
#' @name extract_column_names
#'
#' @description `extract_column_names()` returns column names from a data set that
#' match a certain search pattern, while `data_select()` returns the found data.
#'
#' @param data A data frame.
#' @param select Variables that will be included when performing the required
#'   tasks. Can be either
#'
#'   - a variable specified as a literal variable name (e.g., `column_name`),
#'   - a string with the variable name (e.g., `"column_name"`), a character
#'     vector of variable names (e.g., `c("col1", "col2", "col3")`), or a
#'     character vector of variable names including ranges specified via `:`
#'     (e.g., `c("col1:col3", "col5")`),
#'   - for some functions, like `data_select()` or `data_rename()`, `select` can
#'     be a named character vector. In this case, the names are used to rename
#'     the columns in the output data frame. See 'Details' in the related
#'     functions to see where this option applies.
#'   - a formula with variable names (e.g., `~column_1 + column_2`),
#'   - a vector of positive integers, giving the positions counting from the left
#'     (e.g. `1` or `c(1, 3, 5)`),
#'   - a vector of negative integers, giving the positions counting from the
#'     right (e.g., `-1` or `-1:-3`),
#'   - one of the following select-helpers: `starts_with()`, `ends_with()`,
#'     `contains()`, a range using `:`, or `regex()`. `starts_with()`,
#'     `ends_with()`, and  `contains()` accept several patterns, e.g
#'     `starts_with("Sep", "Petal")`. `regex()` can be used to define regular
#'     expression patterns.
#'   - a function testing for logical conditions, e.g. `is.numeric()` (or
#'     `is.numeric`), or any user-defined function that selects the variables
#'     for which the function returns `TRUE` (like: `foo <- function(x) mean(x) > 3`),
#'   - ranges specified via literal variable names, select-helpers (except
#'     `regex()`) and (user-defined) functions can be negated, i.e. return
#'     non-matching elements, when prefixed with a `-`, e.g. `-ends_with()`,
#'     `-is.numeric` or `-(Sepal.Width:Petal.Length)`. **Note:** Negation means
#'     that matches are _excluded_, and thus, the `exclude` argument can be
#'     used alternatively. For instance, `select=-ends_with("Length")` (with
#'     `-`) is equivalent to `exclude=ends_with("Length")` (no `-`). In case
#'     negation should not work as expected, use the `exclude` argument instead.
#'
#'   If `NULL`, selects all columns. Patterns that found no matches are silently
#'   ignored, e.g. `extract_column_names(iris, select = c("Species", "Test"))`
#'   will just return `"Species"`.
#' @param exclude See `select`, however, column names matched by the pattern
#'   from `exclude` will be excluded instead of selected. If `NULL` (the default),
#'   excludes no columns.
#' @param ignore_case Logical, if `TRUE` and when one of the select-helpers or
#'   a regular expression is used in `select`, ignores lower/upper case in the
#'   search pattern when matching against variable names.
#' @param regex Logical, if `TRUE`, the search pattern from `select` will be
#'   treated as regular expression. When `regex = TRUE`, select *must* be a
#'   character string (or a variable containing a character string) and is not
#'   allowed to be one of the supported select-helpers or a character vector
#'   of length > 1. `regex = TRUE` is comparable to using one of the two
#'   select-helpers, `select = contains()` or `select = regex()`, however,
#'   since the select-helpers may not work when called from inside other
#'   functions (see 'Details'), this argument may be used as workaround.
#' @param verbose Toggle warnings.
#' @param ... Arguments passed down to other functions. Mostly not used yet.
#'
#' @inherit data_rename seealso
#'
#' @return
#'
#' `extract_column_names()` returns a character vector with column names that
#' matched the pattern in `select` and `exclude`, or `NULL` if no matching
#' column name was found. `data_select()` returns a data frame with matching
#' columns.
#'
#' @details
#'
#' Specifically for `data_select()`, `select` can also be a named character
#' vector. In this case, the names are used to rename the columns in the
#' output data frame. See 'Examples'.
#'
#' Note that it is possible to either pass an entire select helper or only the
#' pattern inside a select helper as a function argument:
#'
#' ```r
#' foo <- function(data, pattern) {
#'   extract_column_names(data, select = starts_with(pattern))
#' }
#' foo(iris, pattern = "Sep")
#'
#' foo2 <- function(data, pattern) {
#'   extract_column_names(data, select = pattern)
#' }
#' foo2(iris, pattern = starts_with("Sep"))
#' ```
#'
#' This means that it is also possible to use loop values as arguments or patterns:
#'
#' ```r
#' for (i in c("Sepal", "Sp")) {
#'   head(iris) |>
#'     extract_column_names(select = starts_with(i)) |>
#'     print()
#' }
#' ```
#'
#' However, this behavior is limited to a "single-level function". It will not
#' work in nested functions, like below:
#'
#' ```r
#' inner <- function(data, arg) {
#'   extract_column_names(data, select = arg)
#' }
#' outer <- function(data, arg) {
#'   inner(data, starts_with(arg))
#' }
#' outer(iris, "Sep")
#' ```
#'
#' In this case, it is better to pass the whole select helper as the argument of
#' `outer()`:
#'
#' ```r
#' outer <- function(data, arg) {
#'   inner(data, arg)
#' }
#' outer(iris, starts_with("Sep"))
#' ```
#'
#' @examples
#' # Find column names by pattern
#' extract_column_names(iris, starts_with("Sepal"))
#' extract_column_names(iris, ends_with("Width"))
#' extract_column_names(iris, regex("\\."))
#' extract_column_names(iris, c("Petal.Width", "Sepal.Length"))
#'
#' # starts with "Sepal", but not allowed to end with "width"
#' extract_column_names(iris, starts_with("Sepal"), exclude = contains("Width"))
#'
#' # find numeric with mean > 3.5
#' numeric_mean_35 <- function(x) is.numeric(x) && mean(x, na.rm = TRUE) > 3.5
#' extract_column_names(iris, numeric_mean_35)
#'
#' # find column names, using range
#' extract_column_names(mtcars, c(cyl:hp, wt))
#'
#' # find range of column names by range, using character vector
#' extract_column_names(mtcars, c("cyl:hp", "wt"))
#'
#' # rename returned columns for "data_select()"
#' head(data_select(mtcars, c(`Miles per Gallon` = "mpg", Cylinders = "cyl")))
#' @export
extract_column_names <- function(data,
                                 select = NULL,
                                 exclude = NULL,
                                 ignore_case = FALSE,
                                 regex = FALSE,
                                 verbose = TRUE,
                                 ...) {
  columns <- .select_nse(
    select,
    data,
    exclude,
    ignore_case = ignore_case,
    regex = regex,
    verbose = FALSE
  )

  if (!length(columns) || is.null(columns)) {
    columns <- NULL
    if (isTRUE(verbose)) {
      insight::format_warning(
        "No column names that matched the required search pattern were found."
      )
    }
  }

  columns
}

#' @rdname extract_column_names
#' @export
find_columns <- extract_column_names
