#' Compute Skewness and (Excess) Kurtosis
#'
#' @param x A numeric vector or data.frame.
#' @param type Type of algorithm for computing skewness. May be one of `1`
#'   (or `"1"`, `"I"` or `"classic"`), `2` (or `"2"`,
#'   `"II"` or `"SPSS"` or `"SAS"`) or `3` (or  `"3"`,
#'   `"III"` or `"Minitab"`). See 'Details'.
#' @param iterations The number of bootstrap replicates for computing standard
#'   errors. If `NULL` (default), parametric standard errors are computed.
#' @param test Logical, if `TRUE`, tests if skewness or kurtosis is
#'   significantly different from zero.
#' @param digits Number of decimal places.
#' @param object An object returned by `skewness()` or `kurtosis()`.
#' @param verbose Toggle warnings and messages.
#' @param ... Arguments passed to or from other methods.
#' @inheritParams coef_var
#'
#' @details
#'
#' \subsection{Skewness}{
#' Symmetric distributions have a `skewness` around zero, while
#' a negative skewness values indicates a "left-skewed" distribution, and a
#' positive skewness values indicates a "right-skewed" distribution. Examples
#' for the relationship of skewness and distributions are:
#'
#'   - Normal distribution (and other symmetric distribution) has a skewness
#'   of 0
#'   - Half-normal distribution has a skewness just below 1
#'   - Exponential distribution has a skewness of 2
#'   - Lognormal distribution can have a skewness of any positive value,
#'   depending on its parameters
#'
#' (\cite{https://en.wikipedia.org/wiki/Skewness})
#' }
#'
#' \subsection{Types of Skewness}{
#' `skewness()` supports three different methods for estimating skewness,
#' as discussed in \cite{Joanes and Gill (1988)}:
#'
#' - Type "1" is the "classical" method, which is `g1 = (sum((x -
#' mean(x))^3) / n) / (sum((x - mean(x))^2) / n)^1.5`
#'
#' - Type "2" first calculates the type-1 skewness, then adjusts the result:
#' `G1 = g1 * sqrt(n * (n - 1)) / (n - 2)`. This is what SAS and SPSS
#' usually return.
#'
#' - Type "3" first calculates the type-1 skewness, then adjusts the result:
#' `b1 = g1 * ((1 - 1 / n))^1.5`. This is what Minitab usually returns.
#' }
#'
#' \subsection{Kurtosis}{
#' The `kurtosis` is a measure of "tailedness" of a distribution. A
#' distribution with a kurtosis values of about zero is called "mesokurtic". A
#' kurtosis value larger than zero indicates a "leptokurtic" distribution with
#' *fatter* tails. A kurtosis value below zero indicates a "platykurtic"
#' distribution with *thinner* tails
#' (\cite{https://en.wikipedia.org/wiki/Kurtosis}).
#' }
#'
#' \subsection{Types of Kurtosis}{
#' `kurtosis()` supports three different methods for estimating kurtosis,
#' as discussed in \cite{Joanes and Gill (1988)}:
#'
#' - Type "1" is the "classical" method, which is `g2 = n * sum((x -
#' mean(x))^4) / (sum((x - mean(x))^2)^2) - 3`.
#'
#' - Type "2" first calculates the type-1 kurtosis, then adjusts the result:
#' `G2 = ((n + 1) * g2 + 6) * (n - 1)/((n - 2) * (n - 3))`. This is what
#' SAS and SPSS usually return
#'
#' - Type "3" first calculates the type-1 kurtosis, then adjusts the result:
#' `b2 = (g2 + 3) * (1 - 1 / n)^2 - 3`. This is what Minitab usually
#' returns.
#'
#' }
#'
#' \subsection{Standard Errors}{
#' It is recommended to compute empirical (bootstrapped) standard errors (via
#' the `iterations` argument) than relying on analytic standard errors
#' (\cite{Wright & Herrington, 2011}).
#' }
#'
#' @references
#'
#' - D. N. Joanes and C. A. Gill (1998). Comparing measures of sample
#'   skewness and kurtosis. The Statistician, 47, 183–189.
#'
#' - Wright, D. B., & Herrington, J. A. (2011). Problematic standard
#'   errors and confidence intervals for skewness and kurtosis. Behavior
#'   research methods, 43(1), 8-17.
#'
#' @return Values of skewness or kurtosis.
#'
#' @examples
#' skewness(rnorm(1000))
#' kurtosis(rnorm(1000))
#' @export
skewness <- function(x, ...) {
  UseMethod("skewness")
}


# skewness -----------------------------------------


#' @rdname skewness
#' @export
skewness.numeric <- function(x,
                             remove_na = TRUE,
                             type = "2",
                             iterations = NULL,
                             verbose = TRUE,
                             ...) {
  if (remove_na) x <- x[!is.na(x)]
  n <- length(x)
  out <- (sum((x - mean(x))^3) / n) / (sum((x - mean(x))^2) / n)^1.5

  type <- .check_skewness_type(type)

  if (type == "2" && n < 3) {
    if (verbose) {
      insight::format_warning(
        "Need at least 3 complete observations for type-2-skewness. Using 'type=\"1\"' now."
      )
    }
    type <- "1"
  }

  .skewness <- switch(type,
    "1" = out,
    "2" = out * sqrt(n * (n - 1)) / (n - 2),
    "3" = out * ((1 - 1 / n))^1.5
  )

  out_se <- sqrt((6 * (n - 2)) / ((n + 1) * (n + 3)))

  .skewness_se <- switch(type,
    "1" = out_se,
    "2" = out_se * ((sqrt(n * (n - 1))) / (n - 2)),
    "3" = out_se * (((n - 1) / n)^1.5),
  )

  if (!is.null(iterations)) {
    if (requireNamespace("boot", quietly = TRUE)) {
      results <- boot::boot(
        data = x,
        statistic = .boot_skewness,
        R = iterations,
        remove_na = remove_na,
        type = type
      )
      out_se <- stats::sd(results$t, na.rm = TRUE)
    } else {
      insight::format_warning("Package 'boot' needed for bootstrapping SEs.")
    }
  }

  .skewness <- data.frame(
    Skewness = .skewness,
    SE = out_se
  )
  class(.skewness) <- unique(c("parameters_skewness", class(.skewness)))
  .skewness
}


#' @export
skewness.matrix <- function(x,
                            remove_na = TRUE,
                            type = "2",
                            iterations = NULL,
                            ...) {
  .skewness <- apply(
    x,
    2,
    skewness,
    remove_na = remove_na,
    type = type,
    iterations = iterations
  )

  .names <- colnames(x)

  if (length(.names) == 0) {
    .names <- paste0("X", seq_len(ncol(x)))
  }

  .skewness <- cbind(Parameter = .names, do.call(rbind, .skewness))

  class(.skewness) <- unique(c("parameters_skewness", class(.skewness)))
  .skewness
}


#' @export
skewness.data.frame <- function(x,
                                remove_na = TRUE,
                                type = "2",
                                iterations = NULL,
                                ...) {
  .skewness <- lapply(x,
    skewness,
    remove_na = remove_na,
    type = type,
    iterations = iterations
  )

  .skewness <- cbind(Parameter = names(.skewness), do.call(rbind, .skewness))

  class(.skewness) <- unique(c("parameters_skewness", class(.skewness)))
  .skewness
}


#' @export
skewness.default <- function(x,
                             remove_na = TRUE,
                             type = "2",
                             iterations = NULL,
                             ...) {
  skewness(
    .factor_to_numeric(x),
    remove_na = remove_na,
    type = type,
    iterations = iterations
  )
}


# Kurtosis -----------------------------------


#' @rdname skewness
#' @export
kurtosis <- function(x, ...) {
  UseMethod("kurtosis")
}


#' @rdname skewness
#' @export
kurtosis.numeric <- function(x,
                             remove_na = TRUE,
                             type = "2",
                             iterations = NULL,
                             verbose = TRUE,
                             ...) {
  if (remove_na) x <- x[!is.na(x)]
  n <- length(x)
  out <- n * sum((x - mean(x))^4) / (sum((x - mean(x))^2)^2)

  type <- .check_skewness_type(type)

  if (type == "2" && n < 4) {
    if (verbose) {
      insight::format_warning(
        "Need at least 4 complete observations for type-2-kurtosis Using 'type=\"1\"' now."
      )
    }
    type <- "1"
  }

  .kurtosis <- switch(type,
    "1" = out - 3,
    "2" = ((n + 1) * (out - 3) + 6) * (n - 1) / ((n - 2) * (n - 3)),
    "3" = out * (1 - 1 / n)^2 - 3
  )

  out_se <- sqrt((24 * n * (n - 2) * (n - 3)) / (((n + 1)^2) * (n + 3) * (n + 5)))

  .kurtosis_se <- switch(type,
    "1" = out_se,
    "2" = out_se * (((n - 1) * (n + 1)) / ((n - 2) * (n - 3))),
    "3" = out_se * ((n - 1) / n)^2
  )

  if (!is.null(iterations)) {
    insight::check_if_installed("boot")

    results <- boot::boot(
      data = x,
      statistic = .boot_kurtosis,
      R = iterations,
      remove_na = remove_na,
      type = type
    )
    out_se <- stats::sd(results$t, na.rm = TRUE)
  }

  .kurtosis <- data.frame(
    Kurtosis = .kurtosis,
    SE = out_se
  )
  class(.kurtosis) <- unique(c("parameters_kurtosis", class(.kurtosis)))
  .kurtosis
}


#' @export
kurtosis.matrix <- function(x,
                            remove_na = TRUE,
                            type = "2",
                            iterations = NULL,
                            ...) {
  .kurtosis <- apply(
    x,
    2,
    kurtosis,
    remove_na = remove_na,
    type = type,
    iterations = iterations
  )
  .names <- colnames(x)
  if (length(.names) == 0) {
    .names <- paste0("X", seq_len(ncol(x)))
  }
  .kurtosis <- cbind(Parameter = .names, do.call(rbind, .kurtosis))
  class(.kurtosis) <- unique(c("parameters_kurtosis", class(.kurtosis)))
  .kurtosis
}


#' @export
kurtosis.data.frame <- function(x,
                                remove_na = TRUE,
                                type = "2",
                                iterations = NULL,
                                ...) {
  .kurtosis <- lapply(x,
    kurtosis,
    remove_na = remove_na,
    type = type,
    iterations = iterations
  )
  .kurtosis <- cbind(Parameter = names(.kurtosis), do.call(rbind, .kurtosis))
  class(.kurtosis) <- unique(c("parameters_kurtosis", class(.kurtosis)))
  .kurtosis
}


#' @export
kurtosis.default <- function(x,
                             remove_na = TRUE,
                             type = "2",
                             iterations = NULL,
                             ...) {
  kurtosis(
    .factor_to_numeric(x),
    remove_na = remove_na,
    type = type,
    iterations = iterations
  )
}


# methods -----------------------------------------

#' @export
as.numeric.parameters_kurtosis <- function(x, ...) {
  x$Kurtosis
}

#' @export
as.numeric.parameters_skewness <- function(x, ...) {
  x$Skewness
}

#' @export
as.double.parameters_kurtosis <- as.numeric.parameters_kurtosis

#' @export
as.double.parameters_skewness <- as.numeric.parameters_skewness

#' @rdname skewness
#' @export
print.parameters_kurtosis <- function(x, digits = 3, test = FALSE, ...) {
  out <- summary(x, test = test)
  cat(insight::export_table(out, digits = digits))
  invisible(x)
}

#' @rdname skewness
#' @export
print.parameters_skewness <- print.parameters_kurtosis

#' @rdname skewness
#' @export
summary.parameters_skewness <- function(object, test = FALSE, ...) {
  if (test) {
    object$z <- object$Skewness / object$SE
    object$p <- 2 * (1 - stats::pnorm(abs(object$z)))
  }
  object
}

#' @rdname skewness
#' @export
summary.parameters_kurtosis <- function(object, test = FALSE, ...) {
  if (test) {
    object$z <- object$Kurtosis / object$SE
    object$p <- 2 * (1 - stats::pnorm(abs(object$z)))
  }
  object
}

# helper ------------------------------------------

.check_skewness_type <- function(type) {
  # convenience
  if (is.numeric(type)) type <- as.character(type)
  skewness_types <- c("1", "2", "3", "I", "II", "III", "classic", "SPSS", "SAS", "Minitab")
  is_skewness_type_invalid <- is.null(type) || is.na(type) || !(type %in% skewness_types)

  if (is_skewness_type_invalid) {
    insight::format_warning("'type' must be a character value from \"1\" to \"3\". Using 'type=\"2\"' now.")
    type <- "2"
  }

  switch(type,
    `1` = ,
    I = ,
    classic = "1",
    `2` = ,
    II = ,
    SPSS = ,
    SAS = "2",
    `3` = ,
    III = ,
    Minitab = "3"
  )
}


# bootstrapping -----------------------------------

.boot_skewness <- function(data, indices, remove_na, type) {
  datawizard::skewness(data[indices],
    remove_na = remove_na,
    type = type,
    iterations = NULL
  )$Skewness
}


.boot_kurtosis <- function(data, indices, remove_na, type) {
  datawizard::kurtosis(data[indices],
    remove_na = remove_na,
    type = type,
    iterations = NULL
  )$Kurtosis
}
