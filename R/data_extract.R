#' Extract one or more columns or elements from an object
#'
#' `data_extract()` (or its alias `extract()`) is similar to `$`. It extracts
#' either a single column or element from an object (e.g., a data frame, list),
#' or multiple columns resp. elements.
#'
#' @param data The object to subset. Methods are currently available for data frames
#'   and data frame extensions (e.g., tibbles).
#' @param name An optional argument that specifies the column to be used as
#'   names for the vector elements after extraction. Must be specified either
#'   as literal variable name (e.g., `column_name`) or as string
#'   (`"column_name"`). `name` will be ignored when a data frame is returned.
#' @param extract String, indicating which element will be extracted when `select`
#'   matches multiple variables. Can be `"all"` (the default) to return all
#'   matched variables, `"first"` or `"last"` to return the first or last match,
#'   or `"odd"` and `"even"` to return all odd-numbered or even-numbered
#'   matches. Note that `"first"` or `"last"` return a vector (unless
#'   `as_data_frame = TRUE`), while `"all"` can return a vector (if only one
#'   match was found) *or* a data frame (for more than one match). Type safe
#'   return values are only possible when `extract` is `"first"` or `"last"` (will
#'   always return a vector) or when `as_data_frame = TRUE` (always returns a
#'   data frame).
#' @param as_data_frame Logical, if `TRUE`, will always return a data frame,
#'   even if only one variable was matched. If `FALSE`, either returns a vector
#'   or a data frame. See `extract` for details.
#' @param verbose Toggle warnings.
#' @param ... For use by future methods.
#'
#' @inheritParams extract_column_names
#'
#' @details `data_extract()` can be used to select multiple variables or pull a
#' single variable from a data frame. Thus, the return value is by default not
#' type safe - `data_extract()` either returns a vector or a data frame.
#' \subsection{Extracting single variables (vectors)}{
#' When `select` is the name of a single column, or when select only matches
#' one column, a vector is returned. A single variable is also returned when
#' `extract` is either `"first` or `"last"`. Setting `as_data_frame` to `TRUE`
#' overrides this behaviour and *always* returns a data frame.
#' }
#' \subsection{Extracting a data frame of variables}{
#' When `select` is a character vector containing more than one column name (or
#' a numeric vector with more than one valid column indices), or when `select`
#' uses one of the supported select-helpers that match multiple columns, a
#' data frame is returned. Setting `as_data_frame` to `TRUE` *always* returns
#' a data frame.
#' }
#'
#' @return A vector (or a data frame) containing the extracted element, or
#'   `NULL` if no matching variable was found.
#' @export
#'
#' @examples
#' # single variable
#' data_extract(mtcars, cyl, name = gear)
#' data_extract(mtcars, "cyl", name = gear)
#' data_extract(mtcars, -1, name = gear)
#' data_extract(mtcars, cyl, name = 0)
#' data_extract(mtcars, cyl, name = "row.names")
#'
#' # selecting multiple variables
#' head(data_extract(iris, starts_with("Sepal")))
#' head(data_extract(iris, ends_with("Width")))
#' head(data_extract(iris, 2:4))
#'
#' # select first of multiple variables
#' data_extract(iris, starts_with("Sepal"), extract = "first")
#'
#' # select first of multiple variables, return as data frame
#' head(data_extract(iris, starts_with("Sepal"), extract = "first", as_data_frame = TRUE))
data_extract <- function(data, select, ...) {
  UseMethod("data_extract")
}

#' @rdname data_extract
#' @export
data_extract.data.frame <- function(data,
                                    select,
                                    name = NULL,
                                    extract = "all",
                                    as_data_frame = FALSE,
                                    ignore_case = FALSE,
                                    regex = FALSE,
                                    verbose = TRUE,
                                    ...) {
  extract <- match.arg(tolower(extract), choices = c("all", "first", "last", "odd", "even"))

  # evaluate arguments
  select <- .select_nse(select,
    data,
    exclude = NULL,
    ignore_case,
    regex = regex,
    verbose = verbose
  )

  # nothing to select?
  if (!length(select)) {
    return(NULL)
  }

  nl <- as.list(seq_along(data))
  names(nl) <- names(data)
  name <- eval(substitute(name), nl, parent.frame())

  if (is.numeric(name) && length(name) == 1L) {
    if (name < 0L) {
      name <- ncol(data) + name + 1L
    } else if (name == 0L) {
      name <- rownames(data)
    }
  } else if (is.character(name) && identical(name, "row.names")) {
    name <- rownames(data)
  }

  # chose which matched variables to extract
  select <- switch(extract,
    first = select[1L],
    last = select[length(select)],
    odd = select[seq(1L, length(select), 2L)],
    even = select[seq(2L, length(select), 2L)],
    select
  )

  # "name" only used for naming elements in a vector, not data frame
  needs_no_names <- isTRUE(as_data_frame) ||
    # more than one variable means data frame, so no name
    length(select) > 1L ||
    # if we have only one variable, but number of observations not equal to
    # length of names, we have no proper match, so no naming, too.
    (length(select) == 1L && length(name) > 1L && length(data[[select]]) != length(name))

  if (needs_no_names) {
    name <- NULL
  }

  # we definitely should have a vector here when name not NULL
  if (is.null(name)) {
    data[, select, drop = !as_data_frame]
  } else {
    # if name indicates a variable, extract values for naming now
    if (length(name) == 1L) {
      name <- data[[name]]
    }
    stats::setNames(data[[select]], name)
  }
}
