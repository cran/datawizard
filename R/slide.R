#' @title Shift numeric value range
#' @name slide
#'
#' @description
#' This functions shifts the value range of a numeric variable, so that the
#' new range starts at a given value.
#'
#' @param x A data frame or numeric vector.
#' @param verbose Toggle warnings.
#' @param ... not used.
#' @inheritParams to_numeric
#'
#' @return `x`, where the range of numeric variables starts at a new value.
#'
#' @inheritSection center Selection of variables - the `select` argument
#'
#' @inherit data_rename seealso
#'
#' @examples
#' # numeric
#' head(mtcars$gear)
#' head(slide(mtcars$gear))
#' head(slide(mtcars$gear, lowest = 10))
#'
#' # data frame
#' sapply(slide(mtcars, lowest = 1), min)
#' sapply(mtcars, min)
#' @export
slide <- function(x, ...) {
  UseMethod("slide")
}


#' @export
slide.default <- function(x, lowest = 0, verbose = TRUE, ...) {
  if (isTRUE(verbose)) {
    insight::format_alert(
      "Shifting non-numeric variables is not possible.",
      "Try using 'to_numeric()' and specify the 'lowest' argument."
    )
  }
  x
}


#' @rdname slide
#' @export
slide.numeric <- function(x, lowest = 0, ...) {
  original_x <- x
  minval <- min(x, na.rm = TRUE)
  difference <- minval - lowest
  x <- x - difference
  .set_back_labels(x, original_x, include_values = FALSE)
}


#' @rdname slide
#' @export
slide.data.frame <- function(x,
                             select = NULL,
                             exclude = NULL,
                             lowest = 0,
                             append = FALSE,
                             ignore_case = FALSE,
                             regex = FALSE,
                             verbose = TRUE,
                             ...) {
  # evaluate arguments
  select <- .select_nse(select,
    x,
    exclude,
    ignore_case,
    regex = regex,
    verbose = verbose
  )

  # when we append variables, we call ".process_append()", which will
  # create the new variables and updates "select", so new variables are processed
  if (!isFALSE(append)) {
    # process arguments
    my_args <- .process_append(
      x,
      select,
      append,
      append_suffix = "_s",
      keep_factors = FALSE
    )
    # update processed arguments
    x <- my_args$x
    select <- my_args$select
  }

  x[select] <- lapply(
    x[select],
    slide,
    lowest = lowest,
    verbose = verbose,
    ...
  )

  x
}
