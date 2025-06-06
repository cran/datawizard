#' Re-fit a model with standardized data
#'
#' Performs a standardization of data (z-scoring) using
#' [`standardize()`] and then re-fits the model to the standardized data.
#' \cr\cr
#' Standardization is done by completely refitting the model on the standardized
#' data. Hence, this approach is equal to standardizing the variables *before*
#' fitting the model and will return a new model object. This method is
#' particularly recommended for complex models that include interactions or
#' transformations (e.g., polynomial or spline terms). The `robust` (default to
#' `FALSE`) argument enables a robust standardization of data, based on the
#' `median` and the `MAD` instead of the `mean` and the `SD`.
#'
#' @param x A statistical model.
#' @param weights If `TRUE` (default), a weighted-standardization is carried out.
#' @param include_response If `TRUE` (default), the response value will also be
#'   standardized. If `FALSE`, only the predictors will be standardized.
#'   - Note that for GLMs and models with non-linear link functions, the
#'   response value will not be standardized, to make re-fitting the model work.
#'   - If the model contains an [stats::offset()], the offset variable(s) will
#'   be standardized only if the response is standardized. If `two_sd = TRUE`,
#'   offsets are standardized by one-sd (similar to the response).
#'   - (For `mediate` models, the `include_response` refers to the outcome in
#'   the y model; m model's response will always be standardized when possible).
#' @inheritParams standardize
#'
#' @return A statistical model fitted on standardized data
#'
#' @details
#'
#' # Generalized Linear Models
#' Standardization for generalized linear models (GLM, GLMM, etc) is done only
#' with respect to the predictors (while the outcome remains as-is,
#' unstandardized) - maintaining the interpretability of the coefficients (e.g.,
#' in a binomial model: the exponent of the standardized parameter is the OR of
#' a change of 1 SD in the predictor, etc.)
#'
#' # Dealing with Factors
#' `standardize(model)` or `standardize_parameters(model, method = "refit")` do
#' *not* standardize categorical predictors (i.e. factors) / their
#' dummy-variables, which may be a different behaviour compared to other R
#' packages (such as **lm.beta**) or other software packages (like SPSS). To
#' mimic such behaviours, either use `standardize_parameters(model, method =
#' "basic")` to obtain post-hoc standardized parameters, or standardize the data
#' with `standardize(data, force = TRUE)` *before* fitting the
#' model.
#'
#' # Transformed Variables
#' When the model's formula contains transformations (e.g. `y ~ exp(X)`) the
#' transformation effectively takes place after standardization (e.g.,
#' `exp(scale(X))`). Since some transformations are undefined for none positive
#' values, such as `log()` and `sqrt()`, the relevel variables are shifted (post
#' standardization) by `Z - min(Z) + 1` or `Z - min(Z)` (respectively).
#'
#'
#' @family standardize
#' @examples
#' model <- lm(Infant.Mortality ~ Education * Fertility, data = swiss)
#' coef(standardize(model))
#'
#' @export
#' @aliases standardize_models
standardize.default <- function(x,
                                robust = FALSE,
                                two_sd = FALSE,
                                weights = TRUE,
                                verbose = TRUE,
                                include_response = TRUE,
                                ...) {
  if (!insight::is_model(x)) {
    insight::format_warning(
      paste0(
        "Objects or variables of class '",
        class(x)[1],
        "' cannot be standardized."
      )
    )
    return(x)
  }

  # check model formula. Some notations don't work when standardizing data
  insight::formula_ok(
    x,
    action = "error",
    prefix_msg = "Model cannot be standardized.",
    verbose = verbose
  )

  data_std <- NULL # needed to avoid note
  .standardize_models(x,
    robust = robust, two_sd = two_sd,
    weights = weights,
    verbose = verbose,
    include_response = include_response,
    update_expr = stats::update(x, data = data_std),
    ...
  )
}


.standardize_models <- function(x,
                                robust = FALSE,
                                two_sd = FALSE,
                                weights = TRUE,
                                verbose = TRUE,
                                include_response = TRUE,
                                update_expr,
                                ...) {
  m_info <- .get_model_info(x, ...)
  model_data <- insight::get_data(x, source = "mf", verbose = FALSE)

  if (isTRUE(attr(model_data, "is_subset"))) {
    insight::format_error("Cannot standardize a model fit with a 'subset = '.")
  }

  if (m_info$is_bayesian && verbose) {
    insight::format_warning(
      "Standardizing variables without adjusting priors may lead to bogus results unless priors are auto-scaled."
    )
  }


  ## ---- Z the RESPONSE? ----
  # 1. Some models have special responses that should not be standardized. This
  # includes:
  # - generalized linear models (counts, binomial, etc...)
  # - Survival models
  # 2. We also don't want to standardize the response when `two_sd = TRUE` -
  # instead we will standardize the response separately.

  include_response <- include_response && .safe_to_standardize_response(m_info)

  resp <- NULL
  if (!include_response || (include_response && two_sd)) {
    resp <- c(insight::find_response(x), insight::find_response(x, combine = FALSE))
    resp <- insight::clean_names(resp)
    resp <- unique(resp)
  }

  # If there's an offset, don't standardize offset OR response
  offsets <- insight::find_offset(x)
  if (length(offsets)) {
    if (include_response) {
      if (verbose) {
        insight::format_warning("Offset detected and will be standardized.")
      }

      if (two_sd) {
        # Treat offsets like responses - only standardize by 1 SD
        resp <- c(resp, offsets)
        offsets <- NULL
      }
    } else if (!include_response) {
      # Don't standardize offsets if not standardizing the response
      offsets <- NULL
    }
  }


  ## ---- DO NOT Z: ----

  # 1. WEIGHTS:
  # because negative weights will cause errors in "update()"
  weight_variable <- insight::find_weights(x)

  if (!is.null(weight_variable) &&
    !weight_variable %in% colnames(model_data) &&
    "(weights)" %in% colnames(model_data)) {
    model_data$.missing_weight <- model_data[["(weights)"]]
    colnames(model_data)[ncol(model_data)] <- weight_variable
    weight_variable <- c(weight_variable, "(weights)")
  }

  # 2. RANDOM-GROUPS:
  random_group_factor <- insight::find_random(x, flatten = TRUE, split_nested = TRUE)


  ## ---- SUMMARY: TO Z OR NOT TO Z? ----

  dont_standardize <- c(resp, weight_variable, random_group_factor)
  do_standardize <- setdiff(colnames(model_data), dont_standardize)

  # can't std data$var variables
  doller_vars <- grepl("(.*)\\$(.*)", do_standardize)
  if (any(doller_vars)) {
    doller_vars <- colnames(model_data)[doller_vars]
    insight::format_warning(
      "Unable to standardize variables evaluated in the environment (i.e., not in `data`).",
      "The following variables will not be standardizd:",
      toString(doller_vars)
    )
    do_standardize <- setdiff(do_standardize, doller_vars)
    dont_standardize <- c(dont_standardize, doller_vars)
  }


  if (!length(do_standardize)) {
    insight::format_warning("No variables could be standardized.")
    return(x)
  }


  ## ---- STANDARDIZE! ----

  w <- insight::get_weights(x, remove_na = TRUE)

  data_std <- standardize(model_data[do_standardize],
    robust = robust,
    two_sd = two_sd,
    weights = if (weights) w,
    verbose = verbose
  )

  # if two_sd, it must not affect the response!
  if (include_response && two_sd) {
    data_std[resp] <- standardize(model_data[resp],
      robust = robust,
      two_sd = FALSE,
      weights = if (weights) w,
      verbose = verbose
    )

    dont_standardize <- setdiff(dont_standardize, resp)
  }

  # FIX LOG-SQRT VARS:
  # if we standardize log-terms, standardization will fail (because log of
  # negative value is NaN). Do some back-transformation here

  log_terms <- .log_terms(x, data_std)
  if (length(log_terms) > 0) {
    data_std[log_terms] <- lapply(
      data_std[log_terms],
      function(i) i - min(i, na.rm = TRUE) + 1
    )
  }

  # same for sqrt
  sqrt_terms <- .sqrt_terms(x, data_std)
  if (length(sqrt_terms) > 0) {
    data_std[sqrt_terms] <- lapply(
      data_std[sqrt_terms],
      function(i) i - min(i, na.rm = TRUE)
    )
  }

  if (verbose && length(c(log_terms, sqrt_terms))) {
    insight::format_alert(
      "Formula contains log- or sqrt-terms.",
      "See help(\"standardize\") for how such terms are standardized."
    )
  }


  ## ---- ADD BACK VARS THAT WHERE NOT Z ----
  if (length(dont_standardize)) {
    remaining_columns <- intersect(colnames(model_data), dont_standardize)
    data_std <- cbind(model_data[, remaining_columns, drop = FALSE], data_std)
  }


  ## ---- UPDATE MODEL WITH Z DATA ----
  on.exit(.update_failed())

  if (isTRUE(verbose)) {
    model_std <- eval(substitute(update_expr))
  } else {
    utils::capture.output({
      model_std <- eval(substitute(update_expr))
    })
  }

  on.exit() # undo previous on.exit()

  model_std
}


# Special methods ---------------------------------------------------------


#' @export
standardize.brmsfit <- function(x,
                                robust = FALSE,
                                two_sd = FALSE,
                                weights = TRUE,
                                verbose = TRUE,
                                include_response = TRUE,
                                ...) {
  data_std <- NULL # needed to avoid note
  if (insight::is_multivariate(x)) {
    insight::format_error(
      "Multivariate brmsfit models not supported.",
      "As an alternative: you may standardize your data (and adjust your priors), and re-fit the model."
    )
  }

  .standardize_models(x,
    robust = robust, two_sd = two_sd,
    weights = weights,
    verbose = verbose,
    include_response = include_response,
    update_expr = stats::update(x, newdata = data_std),
    ...
  )
}


#' @export
standardize.mixor <- function(x,
                              robust = FALSE,
                              two_sd = FALSE,
                              weights = TRUE,
                              verbose = TRUE,
                              include_response = TRUE,
                              ...) {
  data_std <- random_group_factor <- NULL # needed to avoid note
  .standardize_models(x,
    robust = robust, two_sd = two_sd,
    weights = weights,
    verbose = verbose,
    include_response = include_response,
    update_expr = {
      data_std <- data_std[order(data_std[, random_group_factor, drop = FALSE]), ]
      stats::update(x, data = data_std)
    },
    ...
  )
}


#' @export
standardize.mediate <- function(x,
                                robust = FALSE,
                                two_sd = FALSE,
                                weights = TRUE,
                                verbose = TRUE,
                                include_response = TRUE,
                                ...) {
  # models and data
  y <- x$model.y
  m <- x$model.m
  y_data <- insight::get_data(y, source = "mf", verbose = FALSE)
  m_data <- insight::get_data(m, source = "mf", verbose = FALSE)

  # std models and data
  y_std <- standardize(y,
    robust = robust, two_sd = two_sd,
    weights = weights, verbose = verbose,
    include_response = include_response, ...
  )
  m_std <- standardize(m,
    robust = robust, two_sd = two_sd,
    weights = weights, verbose = verbose,
    include_response = TRUE, ...
  )
  y_data_std <- insight::get_data(y_std, source = "mf", verbose = FALSE)
  m_data_std <- insight::get_data(m_std, source = "mf", verbose = FALSE)

  # fixed values
  covs <- x$covariates
  control.value <- x$control.value
  treat.value <- x$treat.value


  if (!is.null(covs)) {
    covs <- mapply(.rescale_fixed_values, covs, names(covs),
      SIMPLIFY = FALSE,
      MoreArgs = list(
        y_data = y_data, m_data = m_data,
        y_data_std = y_data_std, m_data_std = m_data_std
      )
    )
    if (verbose) {
      insight::format_alert(
        "Covariates' values have been rescaled to their standardized scales."
      )
    }
  }

  # if (is.numeric(y_data[[x$treat]]) || is.numeric(m_data[[x$treat]])) {
  #   if (!(is.numeric(y_data[[x$treat]]) && is.numeric(m_data[[x$treat]]))) {
  #     stop("'treat' variable is not of same type across both y and m models.",
  #          "\nCannot consistently standardize.", call. = FALSE)
  #   }
  #
  #   temp_vals <- .rescale_fixed_values(c(control.value, treat.value), x$treat,
  #                                      y_data = y_data, m_data = m_data,
  #                                      y_data_std = y_data_std, m_data_std = m_data_std)
  #
  #   control.value <- temp_vals[1]
  #   treat.value <- temp_vals[2]
  #   if (verbose) insight::format_alert("control and treatment values have been rescaled to their standardized scales.")
  # }

  if (verbose && !all(c(control.value, treat.value) %in% c(0, 1))) {
    insight::format_warning(
      "Control and treat values are not 0 and 1, and have not been re-scaled.",
      "Interpret results with caution."
    )
  }


  junk <- utils::capture.output({
    model_std <- stats::update(x,
      model.y = y_std, model.m = m_std,
      # control.value = control.value, treat.value = treat.value
      covariates = covs
    )
  })

  model_std
}


# Cannot ------------------------------------------------------------------


#' @export
standardize.wbm <- function(x, ...) {
  .update_failed(class(x))
}

#' @export
standardize.Surv <- standardize.wbm

#' @export
standardize.clm2 <- standardize.wbm

#' @export
standardize.bcplm <- standardize.wbm

#' @export
standardize.wbgee <- standardize.wbm

#' @export
standardize.biglm <- standardize.wbm
# biglm doesn't regit the model to new data - it ADDs MORE data to the model.


# helper ----------------------------

# Find log-terms inside model formula, and return "clean" term names
.log_terms <- function(model, data) {
  x <- insight::find_terms(model, flatten = TRUE)
  # log_pattern <- "^log\\((.*)\\)"
  log_pattern <- "(log\\(log|log|log1|log10|log1p|log2)\\(([^,\\+)]*).*"
  out <- insight::trim_ws(gsub(log_pattern, "\\2", grep(log_pattern, x, value = TRUE)))
  intersect(colnames(data), out)
}

# Find log-terms inside model formula, and return "clean" term names
.sqrt_terms <- function(model, data) {
  x <- insight::find_terms(model, flatten = TRUE)
  pattern <- "sqrt\\(([^,\\+)]*).*"
  out <- insight::trim_ws(gsub(pattern, "\\1", grep(pattern, x, value = TRUE)))
  intersect(colnames(data), out)
}


#' @keywords internal
.safe_to_standardize_response <- function(info, verbose = TRUE) {
  if (is.null(info)) {
    if (verbose) {
      insight::format_warning(
        "Unable to verify if response should not be standardized.",
        "Response will be standardized."
      )
    }
    return(TRUE)
  }

  # check if model has a response variable that should not be standardized.
  info$is_linear &&
    info$family != "inverse.gaussian" &&
    !info$is_survival &&
    !info$is_censored

  # # alternative would be to keep something like:
  # !info$is_count &&
  #   !info$is_ordinal &&
  #   !info$is_multinomial &&
  #   !info$is_beta &&
  #   !info$is_censored &&
  #   !info$is_binomial &&
  #   !info$is_survival
  # # And then treating response for "Gamma()" or "inverse.gaussian" similar to
  # # log-terms...
}

#' @keywords internal
.rescale_fixed_values <- function(val,
                                  cov_nm,
                                  y_data,
                                  m_data,
                                  y_data_std,
                                  m_data_std) {
  if (cov_nm %in% colnames(y_data)) {
    temp_data <- y_data
    temp_data_std <- y_data_std
  } else {
    temp_data <- m_data
    temp_data_std <- m_data_std
  }

  rescale(val,
    to = range(temp_data_std[[cov_nm]]),
    range = range(temp_data[[cov_nm]])
  )
}


#' @keywords internal
.update_failed <- function(class = NULL, ...) {
  if (is.null(class)) {
    msg1 <- "Unable to refit the model with standardized data."
  } else {
    msg1 <- sprintf("Standardization of parameters not possible for models of class '%s'.", class)
  }

  insight::format_error(
    msg1,
    "Try instead to standardize the data (standardize(data)) and refit the model manually."
  )
}
