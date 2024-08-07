# preparation for standardize and center ----
#
# Performs some preparation when standardizing or centering variables,
# like finding the center or scale, also in relation to some reference values.
# This function is applied to *vectors*.
#
#' @keywords internal
.process_std_center <- function(x,
                                weights,
                                robust,
                                verbose = TRUE,
                                reference = NULL,
                                center = NULL,
                                scale = NULL) {
  # Warning if all NaNs
  if (all(is.na(x) | is.infinite(x))) {
    return(NULL)
  }

  if (.are_weights(weights)) {
    valid_x <- !is.na(x) & !is.na(weights) & !is.infinite(x) & !is.infinite(weights)
    na_values <- is.na(x) | is.na(weights)
    inf_values <- is.infinite(x) | is.infinite(weights)
    vals <- x[valid_x]
    weights <- weights[valid_x]
  } else {
    valid_x <- !is.na(x) & !is.infinite(x)
    na_values <- is.na(x)
    inf_values <- is.infinite(x)
    vals <- x[valid_x]
  }

  # validation checks
  check <- .check_standardize_numeric(x, name = NULL, verbose = verbose, reference = reference, center = center)

  if (is.factor(vals) || is.character(vals)) {
    vals <- .factor_to_numeric(vals)
  }

  # Get center and scale
  ref <- .get_center_scale(vals, robust, weights, reference, .center = center, .scale = scale, verbose = verbose)

  list(
    vals = vals,
    valid_x = valid_x,
    center = ref$center,
    scale = ref$scale,
    check = check,
    na_values = na_values,
    inf_values = inf_values
  )
}


# processing and checking of arguments ----
#
# Performs some preparation when standardizing or centering variables,
# like finding the center or scale, also in relation to some reference values.
# This function is applied to the *data frame methods*.
#
#' @keywords internal
.process_std_args <- function(x,
                              select,
                              exclude,
                              weights,
                              append,
                              append_suffix = "_z",
                              keep_factors,
                              remove_na = "none",
                              reference = NULL,
                              .center = NULL,
                              .scale = NULL,
                              keep_character = FALSE,
                              preserve_value_labels = FALSE) {
  # check append argument, and set default
  if (isFALSE(append)) {
    append <- NULL
  } else if (isTRUE(append)) {
    append <- append_suffix
  }

  if (!is.null(weights) && is.character(weights)) {
    if (weights %in% colnames(x)) {
      exclude <- c(exclude, weights)
    } else {
      insight::format_warning(
        paste0("Could not find weighting column `", weights, "`. Weighting not carried out.")
      )
      weights <- NULL
    }
  }

  select <- .select_variables(x, select, exclude, keep_factors, keep_character)

  # check if selected variables are in reference
  if (!is.null(reference) && !all(select %in% names(reference))) {
    insight::format_error("The `reference` must include all variables from `select`.")
  }

  # copy label attributes
  variable_labels <- insight::compact_list(lapply(x, attr, "label", exact = TRUE))
  value_labels <- NULL
  if (preserve_value_labels) {
    value_labels <- insight::compact_list(lapply(x, attr, "labels", exact = TRUE))
  }

  # drop NAs
  remove_na <- match.arg(remove_na, c("none", "selected", "all"))

  omit <- switch(remove_na,
    none = logical(nrow(x)),
    selected = rowSums(vapply(x[select], is.na, FUN.VALUE = logical(nrow(x)))) > 0,
    all = rowSums(vapply(x, is.na, FUN.VALUE = logical(nrow(x)))) > 0
  )
  x <- x[!omit, , drop = FALSE]

  if (!is.null(weights) && is.character(weights)) weights <- x[[weights]]

  # append standardized variables
  if (!is.null(append) && append != "") {
    new_variables <- x[select]
    colnames(new_variables) <- paste0(colnames(new_variables), append)
    if (length(variable_labels)) {
      variable_labels <- c(variable_labels, stats::setNames(variable_labels[select], colnames(new_variables)))
    }
    if (length(value_labels)) {
      value_labels <- c(value_labels, stats::setNames(value_labels[select], colnames(new_variables)))
    }
    x <- cbind(x, new_variables)
    select <- colnames(new_variables)
  }


  # check for reference center and scale
  if (!is.null(.center)) {
    # for center(), we have no scale - set it to default value
    if (is.null(.scale)) {
      .scale <- rep(1, length(.center))
    }

    # center and scale must have same length
    if (length(.center) != length(.scale)) {
      insight::format_error("`center` and `scale` must be of same length.")
    }

    # center and scale must either be of length 1 or of same length as selected variables
    if (length(.center) > 1 && length(.center) != length(select)) {
      insight::format_error(
        "`center` and `scale` must have the same length as the selected variables for standardization or centering."
      )
    }

    # if of length 1, recycle
    if (length(.center) == 1) {
      .center <- rep(.center, length(select))
      .scale <- rep(.scale, length(select))
    }

    # set names
    if (is.null(names(.center))) {
      .center <- stats::setNames(.center, select)
    }
    if (is.null(names(.scale))) {
      .scale <- stats::setNames(.scale, select)
    }
  } else {
    # use NA if missing, so we can index these as vectors
    .center <- stats::setNames(rep(NA, length(select)), select)
    .scale <- stats::setNames(rep(NA, length(select)), select)
  }

  # add back variable labels
  if (length(variable_labels)) {
    for (i in names(variable_labels)) {
      attr(x[[i]], "label") <- variable_labels[[i]]
    }
  }

  if (preserve_value_labels && length(value_labels)) {
    for (i in names(value_labels)) {
      attr(x[[i]], "labels") <- value_labels[[i]]
    }
  }

  list(
    x = x,
    select = select,
    exclude = exclude,
    weights = weights,
    append = append,
    center = .center,
    scale = .scale
  )
}


# retrieve center and scale information ----
#' @keywords internal
.get_center_scale <- function(x,
                              robust = FALSE,
                              weights = NULL,
                              reference = NULL,
                              .center = NULL,
                              .scale = NULL,
                              verbose = TRUE) {
  if (is.null(reference)) reference <- x

  # for center(), we have no scale. default to 1
  if (is.null(.scale) || is.na(.scale) || isFALSE(.scale)) {
    scale <- 1
  } else if (isTRUE(.scale)) {
    if (robust) {
      scale <- weighted_mad(reference, weights)
    } else {
      scale <- weighted_sd(reference, weights)
    }
  } else {
    # we must have a numeric value here
    scale <- .scale
  }

  # process center
  if (is.null(.center) || is.na(.center) || isFALSE(.center)) {
    center <- 0
  } else if (isTRUE(.center)) {
    if (robust) {
      center <- weighted_median(reference, weights)
    } else {
      center <- weighted_mean(reference, weights)
    }
  } else {
    # we must have a numeric value here
    center <- .center
  }

  if (scale == 0) {
    scale <- 1
    if (verbose) {
      insight::format_warning(sprintf(
        "%s is 0 - variable not standardized (only scaled).",
        if (robust) "MAD" else "SD"
      ))
    }
  }

  list(center = center, scale = scale)
}


# check range of input variables ----
#' @keywords internal
.check_standardize_numeric <- function(x,
                                       name = NULL,
                                       verbose = TRUE,
                                       reference = NULL,
                                       center) {
  # Warning if only one value
  if (insight::has_single_value(x) && is.null(reference) && (is.null(center) || isTRUE(center))) {
    if (verbose) {
      if (is.null(name)) {
        insight::format_alert(
          "The variable contains only one unique value and will be set to 0."
        )
      } else {
        insight::format_alert(
          paste0("The variable `", name, "` contains only one unique value and will be set to 0.")
        )
      }
    }
    return(NULL)
  }

  # Warning if logical vector
  if (verbose && insight::n_unique(x) == 2 && !is.factor(x) && !is.character(x)) {
    if (is.null(name)) {
      insight::format_alert(
        "The variable contains only two different values. Consider converting it to a factor."
      )
    } else {
      insight::format_alert(
        paste0("Variable `", name, "` contains only two different values. Consider converting it to a factor.")
      )
    }
  }
  x
}


# process append argument ----
#' @keywords internal
.process_append <- function(x,
                            select,
                            append,
                            append_suffix = "_z",
                            preserve_value_labels = FALSE,
                            keep_factors = TRUE,
                            keep_character = FALSE) {
  # check append argument, and set default
  if (isFALSE(append)) {
    append <- NULL
  } else if (isTRUE(append)) {
    append <- append_suffix
  }

  # append recoded variables
  if (!is.null(append) && append != "") {
    # keep or drop factors and characters
    select <- .select_variables(
      x,
      select,
      exclude = NULL,
      keep_factors = keep_factors,
      keep_character = keep_character
    )

    # copy label attributes
    variable_labels <- insight::compact_list(lapply(x, attr, "label", exact = TRUE))
    value_labels <- NULL
    if (preserve_value_labels) {
      value_labels <- insight::compact_list(lapply(x, attr, "labels", exact = TRUE))
    }

    # add new variables that sould be appended
    new_variables <- x[select]
    colnames(new_variables) <- paste0(colnames(new_variables), append)
    if (length(variable_labels)) {
      variable_labels <- c(variable_labels, stats::setNames(variable_labels[select], colnames(new_variables)))
    }
    if (length(value_labels)) {
      value_labels <- c(value_labels, stats::setNames(value_labels[select], colnames(new_variables)))
    }
    x <- cbind(x, new_variables)
    select <- colnames(new_variables)

    # add back variable labels
    if (length(variable_labels)) {
      for (i in names(variable_labels)) {
        attr(x[[i]], "label") <- variable_labels[[i]]
      }
    }

    if (preserve_value_labels && length(value_labels)) {
      for (i in names(value_labels)) {
        attr(x[[i]], "labels") <- value_labels[[i]]
      }
    }
  }
  list(x = x, select = select)
}


# variables to standardize and center ----
#
# This function mainly serves the purpose to keep or drop factors and
# character vectors from transformation functions.
#
#' @keywords internal
.select_variables <- function(x, select, exclude, keep_factors, keep_character = FALSE) {
  if (is.null(select)) {
    select <- names(x)
  }

  if (!is.null(exclude)) {
    select <- setdiff(select, exclude)
  }

  if (!keep_factors) {
    if (!keep_character) {
      factors <- vapply(x[select], function(i) is.factor(i) | is.character(i), FUN.VALUE = logical(1L))
    } else {
      factors <- vapply(x[select], is.factor, FUN.VALUE = logical(1L))
    }
    select <- select[!factors]
  }

  select
}


# for grouped df ---------------------------
#' @keywords internal
.process_grouped_df <- function(x,
                                select,
                                exclude,
                                append,
                                append_suffix = "_z",
                                reference,
                                weights,
                                keep_factors) {
  if (!is.null(reference)) {
    insight::format_error("The `reference` argument cannot be used with grouped standardization for now.")
  }

  # check append argument, and set default
  if (isFALSE(append)) {
    append <- NULL
  } else if (isTRUE(append)) {
    append <- append_suffix
  }

  info <- attributes(x)

  grps <- attr(x, "groups", exact = TRUE)[[".rows"]]

  # for grouped data frames, we can decide to remove group variable from selection
  grp_vars <- setdiff(colnames(attr(x, "groups", exact = TRUE)), ".rows")

  if (is.numeric(weights)) {
    insight::format_warning(
      "For grouped data frames, `weights` must be a character, not a numeric vector.",
      "Ignoring weightings."
    )
    weights <- NULL
  }

  x <- as.data.frame(x)
  select <- .select_variables(x, select, exclude, keep_factors)
  select <- setdiff(select, grp_vars)

  # append standardized variables
  if (!is.null(append) && append != "") {
    new_variables <- x[select]
    colnames(new_variables) <- paste0(colnames(new_variables), append)
    x <- cbind(x, new_variables)
    select <- colnames(new_variables)
    info$names <- c(info$names, select)
  }

  list(x = x, info = info, select = select, grps = grps, weights = weights)
}
