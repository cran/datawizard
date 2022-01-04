
# helper -----------------------------


## preparation for standardize and center ----

.process_std_center <- function(x,
                                weights,
                                robust,
                                verbose,
                                reference = NULL,
                                center = NULL,
                                scale = NULL) {
  # Warning if all NaNs
  if (all(is.na(x))) {
    return(NULL)
  }

  if (.are_weights(weights)) {
    valid_x <- !is.na(x) & !is.na(weights)
    vals <- x[valid_x]
    weights <- weights[valid_x]
  } else {
    valid_x <- !is.na(x)
    vals <- x[valid_x]
  }


  # Sanity checks
  check <- .check_standardize_numeric(x, name = NULL, verbose = verbose, reference = reference)

  if (is.factor(vals) || is.character(vals)) {
    vals <- .factor_to_numeric(vals)
  }

  # Get center and scale
  ref <- .get_center_scale(vals, robust, weights, reference, .center = center, .scale = scale)

  list(
    vals = vals,
    valid_x = valid_x,
    center = ref$center,
    scale = ref$scale,
    check = check
  )
}



## processing and checking of arguments ----

.process_std_args <- function(x,
                              select,
                              exclude,
                              weights,
                              append,
                              append_suffix = "_z",
                              force,
                              remove_na = "none",
                              reference = NULL,
                              .center = NULL,
                              .scale = NULL) {

  # check for formula notation, convert to character vector
  if (inherits(select, "formula")) {
    select <- all.vars(select)
  }
  if (inherits(exclude, "formula")) {
    exclude <- all.vars(exclude)
  }

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
      warning(insight::format_message("Could not find weighting column '", weights, "'. Weighting not carried out."))
      weights <- NULL
    }
  }

  select <- .select_variables(x, select, exclude, force)

  # check if selected variables are in reference
  if (!is.null(reference) && !all(select %in% names(reference))) {
    stop("The 'reference' must include all variables from 'select'.")
  }

  # drop NAs
  remove_na <- match.arg(remove_na, c("none", "selected", "all"))

  omit <- switch(remove_na,
    none = logical(nrow(x)),
    selected = rowSums(sapply(x[select], is.na)) > 0,
    all = rowSums(sapply(x, is.na)) > 0
  )
  x <- x[!omit, , drop = FALSE]

  if (!is.null(weights) && is.character(weights)) weights <- x[[weights]]

  # append standardized variables
  if (!is.null(append) && append != "") {
    new_variables <- x[select]
    colnames(new_variables) <- paste0(colnames(new_variables), append)
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
      stop("'center' and 'scale' must be of same length.")
    }

    # center and scale must either be of length 1 or of same length as selected variables
    if (length(.center) > 1 && length(.center) != length(select)) {
      stop(insight::format_message("'center' and 'scale' must have the same length as the selected variables for standardization or centering."))
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



## retrieve center and scale information ----

.get_center_scale <- function(x, robust = FALSE, weights = NULL, reference = NULL, .center = NULL, .scale = NULL) {
  if (is.null(reference)) reference <- x

  # for center(), we have no scale. default to 0
  if (is.null(.scale) || is.na(.scale)) {
    .scale <- 1
  }

  if (!is.null(.center) && !is.na(.center)) {
    center <- .center
    scale <- .scale
  } else if (robust) {
    center <- .median(reference, weights)
    scale <- .mad(reference, weights)
  } else {
    center <- .mean(reference, weights)
    scale <- .sd(reference, weights)
  }
  list(center = center, scale = scale)
}



## check range of input variables ----

#' @keywords internal
.check_standardize_numeric <- function(x,
                                       name = NULL,
                                       verbose = TRUE,
                                       reference = NULL) {
  # Warning if only one value
  if (length(unique(x)) == 1 && is.null(reference)) {
    if (verbose) {
      if (is.null(name)) {
        message(insight::format_message("The variable contains only one unique value and will be set to 0."))
      } else {
        message(insight::format_message(paste0("The variable `", name, "` contains only one unique value and will be set to 0.")))
      }
    }
    return(NULL)
  }

  # Warning if logical vector
  if (length(unique(x)) == 2 && !is.factor(x) && !is.character(x)) {
    if (verbose) {
      if (is.null(name)) {
        message(insight::format_message("The variable contains only two different values. Consider converting it to a factor."))
      } else {
        message(insight::format_message(paste0("Variable `", name, "` contains only two different values. Consider converting it to a factor.")))
      }
    }
  }
  x
}



## variables to standardize and center ----

.select_variables <- function(x, select, exclude, force) {
  if (is.null(select)) {
    select <- names(x)
  }

  if (!is.null(exclude)) {
    select <- setdiff(select, exclude)
  }

  if (!force) {
    factors <- sapply(x[select], function(i) is.factor(i) | is.character(i))
    select <- select[!factors]
  }

  select
}




.are_weights <- function(w) {
  !is.null(w) && length(w) && !all(w == 1) && !all(w == w[1])
}




.factor_to_numeric <- function(x) {
  # no need to change for numeric
  if (is.numeric(x)) {
    return(x)
  }

  # Dates can be coerced by as.numeric(), w/o as.character()
  if (inherits(x, "Date")) {
    return(as.numeric(x))
  }

  if (anyNA(suppressWarnings(as.numeric(as.character(stats::na.omit(x)))))) {
    if (is.character(x)) {
      x <- as.factor(x)
    }
    levels(x) <- 1:nlevels(x)
  }

  as.numeric(as.character(x))
}



## own implementation of mean/median/mad/sd ----

.mean <- function(x, weights = NULL, verbose = TRUE, ...) {
  if (!.are_weights(weights)) {
    return(mean(x, na.rm = TRUE))
  }

  if (!all(weights > 0, na.rm = TRUE)) {
    if (isTRUE(verbose)) {
      warning("Some weights were negative. Weighting not carried out.", call. = FALSE)
    }
    return(mean(x, na.rm = TRUE))
  }

  stats::weighted.mean(x, weights, na.rm = TRUE)
}


.median <- function(x, weights = NULL, verbose = TRUE, ...) {
  # From spatstat + wiki
  if (!.are_weights(weights)) {
    return(stats::median(x, na.rm = TRUE))
  }

  if (!all(weights > 0, na.rm = TRUE)) {
    if (isTRUE(verbose)) {
      warning("Some weights were negative. Weighting not carried out.", call. = FALSE)
    }
    return(stats::median(x, na.rm = TRUE))
  }

  oo <- order(x)
  x <- x[oo]
  weights <- weights[oo]
  Fx <- cumsum(weights) / sum(weights)

  lefties <- which(Fx <= 0.5)
  left <- max(lefties)
  if (length(lefties) == 0) {
    result <- x[1]
  } else if (left == length(x)) {
    result <- x[length(x)]
  } else {
    result <- x[left]

    if (!(Fx[left - 1] < 0.5 && 1 - Fx[left] < 0.5)) {
      right <- left + 1
      y <- x[left] * Fx[left] + x[right] * Fx[right]
      if (is.finite(y)) result <- y
    }
  }

  result
}

# For standardize_info ----------------------------------------------------

.sd <- function(x, weights = NULL) {
  # from cov.wt
  if (!.are_weights(weights)) {
    return(stats::sd(x, na.rm = TRUE))
  }

  stopifnot(all(weights > 0, na.rm = TRUE))

  weights1 <- weights / sum(weights)
  center <- sum(weights1 * x)
  xc <- sqrt(weights1) * (x - center)
  var <- (t(xc) %*% xc) / (1 - sum(weights1^2))
  sqrt(as.vector(var))
}


.mad <- function(x, weights = NULL, constant = 1.4826) {
  # From matrixStats
  if (!.are_weights(weights)) {
    return(stats::mad(x, na.rm = TRUE))
  }

  stopifnot(all(weights > 0, na.rm = TRUE))

  center <- .median(x, weights = weights)
  x <- abs(x - center)
  constant * .median(x, weights = weights)
}


# For standardize_parameters ----------------------------------------------

#' @keywords internal
.get_object <- function(x, attribute_name = "object_name") {
  obj_name <- attr(x, attribute_name, exact = TRUE)
  model <- NULL
  if (!is.null(obj_name)) {
    model <- tryCatch(
      {
        get(obj_name, envir = parent.frame())
      },
      error = function(e) {
        NULL
      }
    )
    if (is.null(model) ||
      # prevent self reference
      inherits(model, "parameters_model")) {
      model <- tryCatch(
        {
          get(obj_name, envir = globalenv())
        },
        error = function(e) {
          NULL
        }
      )
    }
  }
  model
}


# for grouped df ---------------------------

.process_grouped_df <- function(x,
                                select,
                                exclude,
                                append,
                                append_suffix = "_z",
                                reference,
                                weights,
                                force) {
  if (!is.null(reference)) {
    stop("The `reference` argument cannot be used with grouped standardization for now.")
  }

  # check append argument, and set default
  if (isFALSE(append)) {
    append <- NULL
  } else if (isTRUE(append)) {
    append <- append_suffix
  }

  info <- attributes(x)
  # dplyr >= 0.8.0 returns attribute "indices"
  grps <- attr(x, "groups", exact = TRUE)

  # check for formula notation, convert to character vector
  if (inherits(select, "formula")) {
    select <- all.vars(select)
  }
  if (inherits(exclude, "formula")) {
    exclude <- all.vars(exclude)
  }

  if (is.numeric(weights)) {
    warning(
      "For grouped data frames, 'weights' must be a character, not a numeric vector.\n",
      "Ignoring weightings."
    )
    weights <- NULL
  }


  # dplyr < 0.8.0?
  if (is.null(grps)) {
    grps <- attr(x, "indices", exact = TRUE)
    grps <- lapply(grps, function(x) x + 1)
  } else {
    grps <- grps[[".rows"]]
  }

  x <- as.data.frame(x)
  select <- .select_variables(x, select, exclude, force)

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