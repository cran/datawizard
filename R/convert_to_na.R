#' @title Convert non-missing values in a variable into missing values.
#' @name convert_to_na
#'
#' @description
#' Convert non-missing values in a variable into missing values.
#'
#' @param x A vector, factor or a data frame.
#' @param na Numeric or character vector (or a list of numeric and character
#'   vectors) with values that should be converted to `NA`.
#' @inheritParams standardize
#' @param verbose Toggle warnings.
#' @param ... Not used.
#'
#' @return
#' `x`, where all values in `na` are converted to `NA`.
#'
#' @examples
#' x <- sample(1:6, size = 30, replace = TRUE)
#' x
#' # values 4 and 5 to NA
#' convert_to_na(x, na = 4:5)
#'
#' # data frames
#' set.seed(123)
#' x <- data.frame(
#'   a = sample(1:6, size = 20, replace = TRUE),
#'   b = sample(letters[1:6], size = 20, replace = TRUE),
#'   c = sample(c(30:33, 99), size = 20, replace = TRUE)
#' )
#' # for all numerics, convert 5 to NA. Character/factor will be ignored.
#' convert_to_na(x, na = 5)
#'
#' # for numerics, 5 to NA, for character/factor, "f" to NA
#' convert_to_na(x, na = list(6, "f"))
#'
#' # select specific variables
#' convert_to_na(x, select = c("a", "b"), na = list(6, "f"))
#' @export
convert_to_na <- function(x, ...) {
  UseMethod("convert_to_na")
}


#' @rdname convert_to_na
#' @export
convert_to_na.numeric <- function(x, na = NULL, verbose = TRUE, ...) {
  # if we have a list, use first valid element
  if (is.list(na)) {
    na <- unlist(na[sapply(na, is.numeric)])
  }

  if (is_empty_object(na) || !is.numeric(na)) {
    if (isTRUE(verbose)) {
      warning(insight::format_message("`na` needs to be a numeric vector."), call. = FALSE)
    }
  } else {
    matches <- which(x %in% na)
    x[matches] <- NA
  }
  x
}


#' @export
convert_to_na.factor <- function(x, na = NULL, verbose = TRUE, ...) {
  # if we have a list, use first valid element
  if (is.list(na)) {
    na <- unlist(na[sapply(na, is.character)])
  }

  if (is_empty_object(na) || (!is.factor(na) && !is.character(na))) {
    if (isTRUE(verbose)) {
      warning(insight::format_message("`na` needs to be a character vector."), call. = FALSE)
    }
  } else {
    matches <- which(x %in% na)
    x[matches] <- NA
  }
  x
}


#' @export
convert_to_na.character <- convert_to_na.factor


#' @rdname convert_to_na
#' @export
convert_to_na.data.frame <- function(x, na = NULL, select = NULL, exclude = NULL, verbose = TRUE, ...) {
  # check for formula notation, convert to character vector
  if (inherits(select, "formula")) {
    select <- all.vars(select)
  }
  if (inherits(exclude, "formula")) {
    exclude <- all.vars(exclude)
  }

  select <- .select_variables(x, select, exclude, force = TRUE)

  x[select] <- lapply(x[select], convert_to_na, na = na, verbose = FALSE, ...)
  x
}