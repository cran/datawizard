#' @title Read (import) data files from various sources
#' @name data_read
#'
#' @description
#' This functions imports data from various file types. It is a small wrapper
#' around `haven::read_spss()`, `haven::read_stata()`, `haven::read_sas()`,
#' `readxl::read_excel()` and `data.table::fread()` resp. `readr::read_delim()`
#' (the latter if package **data.table** is not installed). Thus, supported file
#' types for importing data are data files from SPSS, SAS or Stata, Excel files
#' or text files (like '.csv' files). All other file types are passed to
#' `rio::import()`. `data_write()` works in a similar way.
#'
#' @param path Character string, the file path to the data file.
#' @param path_catalog Character string, path to the catalog file. Only relevant
#' for SAS data files.
#' @param encoding The character encoding used for the file. Usually not needed.
#' @param convert_factors If `TRUE` (default), numeric variables, where all
#' values have a value label, are assumed to be categorical and converted into
#' factors. If `FALSE`, no variable types are guessed and no conversion of
#' numeric variables into factors will be performed. For `data_read()`, this
#' argument only applies to file types with *labelled data*, e.g. files from
#' SPSS, SAS or Stata. See also section 'Differences to other packages'. For
#' `data_write()`, this argument only applies to the text (e.g. `.txt` or
#' `.csv`) or spreadsheet file formats (like `.xlsx`). Converting to factors
#' might be useful for these formats because labelled numeric variables are then
#' converted into factors and exported as character columns - else, value labels
#' would be lost and only numeric values are written to the file.
#' @param verbose Toggle warnings and messages.
#' @param ... Arguments passed to the related `read_*()` or `write_*()` functions.
#'
#' @return A data frame.
#'
#' @section Supported file types:
#' - `data_read()` is a wrapper around the **haven**, **data.table**, **readr**
#'   **readxl**, **nanoparquet** and **rio** packages. Currently supported file
#'   types are `.txt`, `.csv`, `.xls`, `.xlsx`, `.sav`, `.por`, `.dta`, `.sas`,
#'   `.rda`, `.parquet`, `.rdata`, and `.rds` (and related files). All other file
#'   types are passed to `rio::import()`.
#' - `data_write()` is a wrapper around **haven**, **readr**, **nanoparquet**,
#'   and **rio** packages, and supports writing files into all formats supported
#'   by these packages.
#'
#' @section Compressed files (zip) and URLs:
#' `data_read()` can also read the above mentioned files from URLs or from
#' inside zip-compressed files. Thus, `path` can also be a URL to a file like
#' `"http://www.url.com/file.csv"`. When `path` points to a zip-compressed file,
#' and there are multiple files inside the zip-archive, then the first supported
#' file is extracted and loaded.
#'
#' @section General behaviour:
#' `data_read()` detects the appropriate `read_*()` function based on the
#' file-extension of the data file. Thus, in most cases it should be enough to
#' only specify the `path` argument. However, if more control is needed, all
#' arguments in `...` are passed down to the related `read_*()` function. The
#' same applies to `data_write()`, i.e. based on the file extension provided in
#' `path`, the appropriate `write_*()` function is used automatically.
#'
#' @section SPSS specific behaviour:
#' `data_read()` does *not* import user-defined ("tagged") `NA` values from
#' SPSS, i.e. argument `user_na` is always set to `FALSE` when importing SPSS
#' data with the **haven** package. Use `convert_to_na()` to define missing
#' values in the imported data, if necessary. Furthermore, `data_write()`
#' compresses SPSS files by default. If this causes problems with (older) SPSS
#' versions, use `compress = "none"`, for example
#' `data_write(data, "myfile.sav", compress = "none")`.
#'
#' @section Differences to other packages that read foreign data formats:
#' `data_read()` is most comparable to `rio::import()`. For data files from
#' SPSS, SAS or Stata, which support labelled data, variables are converted into
#' their most appropriate type. The major difference to `rio::import()` is for
#' data files from SPSS, SAS, or Stata, i.e. file types that support
#' *labelled data*. `data_read()` automatically converts fully labelled numeric
#' variables into factors, where imported value labels will be set as factor
#' levels. If a numeric variable has _no_ value labels or less value labels than
#' values, it is not converted to factor. In this case, value labels are
#' preserved as `"labels"` attribute. Character vectors are preserved. Use
#' `convert_factors = FALSE` to remove the automatic conversion of numeric
#' variables to factors.
#'
#' @export
data_read <- function(path,
                      path_catalog = NULL,
                      encoding = NULL,
                      convert_factors = TRUE,
                      verbose = TRUE,
                      ...) {
  # extract first valid file from zip-file
  if (identical(.file_ext(path), "zip")) {
    path <- .extract_zip(path)
  }

  # check for valid file type
  file_type <- .file_ext(path)
  if (!is.character(file_type) || file_type == "") {
    insight::format_error(
      "Could not detect file type. The `path` argument has no file extension.",
      "Please provide a file path including extension, like \"myfile.csv\" or \"c:/Users/Default/myfile.sav\"."
    )
  }

  # read data
  out <- switch(file_type,
    txt = ,
    csv = .read_text(path, encoding, verbose, ...),
    rda = ,
    rdata = .read_base_rda(path, file_type, verbose, ...),
    rds = .read_base_rds(path, verbose, ...),
    xls = ,
    xlsx = .read_excel(path, encoding, verbose, ...),
    sav = ,
    por = .read_spss(path, encoding, convert_factors, verbose, ...),
    dta = .read_stata(path, encoding, convert_factors, verbose, ...),
    sas7bdat = .read_sas(path, path_catalog, encoding, convert_factors, verbose, ...),
    parquet = .read_parquet(path, verbose, ...),
    .read_unknown(path, file_type, verbose, ...)
  )

  # tell user about empty columns
  if (verbose) {
    empty_cols <- empty_columns(out)
    # only message if we actually have empty columns
    if (length(empty_cols)) {
      insight::format_alert(
        sprintf("Following %i variables are empty:", length(empty_cols)),
        text_concatenate(names(empty_cols)),
        "\nUse `remove_empty_columns()` to remove them from the data frame."
      )
    }
  }

  out
}


# helper -----------------------

.file_ext <- function(x) {
  pos <- regexpr("\\.([[:alnum:]]+)$", x)
  ifelse(pos > -1L, tolower(substring(x, pos + 1L)), "")
}


.extract_zip <- function(path) {
  files <- utils::unzip(path, list = TRUE)
  files_ext <- vapply(files$Name, .file_ext, FUN.VALUE = character(1L))

  supported_filetypes <- c("txt", "csv", "xls", "xlsx", "sav", "por", "dta")
  dest <- files$Name[which(files_ext %in% supported_filetypes)]

  if (length(dest) > 0) {
    d <- tempfile()
    dir.create(d)
    utils::unzip(path, exdir = d)
    path <- file.path(d, dest[1])
  } else {
    insight::format_error("The zip-file does not contain any supported file types.")
  }

  path
}


# process imported data from SPSS, SAS or Stata -----------------------

.post_process_imported_data <- function(x, convert_factors, verbose) {
  # user may decide whether we automatically detect variable type or not
  if (isTRUE(convert_factors)) {
    if (verbose) {
      msg <- "Variables where all values have associated labels are now converted into factors. If this is not intended, use `convert_factors = FALSE`." # nolint
      insight::format_alert(msg)
    }
    x[] <- lapply(x, function(i) {
      # only proceed if not all missing
      if (!all(is.na(i))) {
        # save labels
        value_labels <- attr(i, "labels", exact = TRUE)
        variable_labels <- attr(i, "label", exact = TRUE)

        # filter, so only matching value labels remain
        value_labels <- value_labels[value_labels %in% unique(i)]

        # guess variable type
        if (is.character(i)) {
          # we need this to drop haven-specific class attributes
          i <- as.character(i)
        } else if (!is.null(value_labels) && length(value_labels) == insight::n_unique(i)) {
          # if all values are labelled, we assume factor. Use labels as levels
          if (is.numeric(i)) {
            i <- factor(i, labels = names(value_labels))
          } else {
            i <- factor(as.character(i), labels = names(value_labels))
          }
          value_labels <- NULL
          attr(i, "converted_to_factor") <- TRUE
        } else {
          # else, fall back to numeric or factor
          i <- as.numeric(i)
        }

        # drop unused value labels
        value_labels <- value_labels[value_labels %in% unique(i)]
        if (length(value_labels) > 0L) {
          attr(i, "labels") <- value_labels
        }

        # add back variable label
        attr(i, "label") <- variable_labels
      }
      i
    })
    # tell user how many variables were converted
    if (verbose) {
      cnt <- sum(vapply(x, function(i) isTRUE(attributes(i)$converted_to_factor), TRUE))
      msg <- sprintf("%i out of %i variables were fully labelled and converted into factors.", cnt, ncol(x))
      insight::format_alert(msg)
    }
  } else {
    # drop haven class attributes
    x[] <- lapply(x, function(i) {
      # save labels
      class(i) <- setdiff(class(i), c("haven_labelled", "vctrs_vctr"))
      i
    })
  }

  class(x) <- "data.frame"
  x
}


# read functions -----------------------

.read_spss <- function(path, encoding, convert_factors, verbose, ...) {
  insight::check_if_installed("haven", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    insight::format_alert("Reading data...")
  }
  out <- haven::read_sav(file = path, encoding = encoding, user_na = FALSE, ...)
  .post_process_imported_data(out, convert_factors, verbose)
}


.read_stata <- function(path, encoding, convert_factors, verbose, ...) {
  insight::check_if_installed("haven", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    insight::format_alert("Reading data...")
  }
  out <- haven::read_dta(file = path, encoding = encoding, ...)
  .post_process_imported_data(out, convert_factors, verbose)
}


.read_sas <- function(path, path_catalog, encoding, convert_factors, verbose, ...) {
  insight::check_if_installed("haven", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    insight::format_alert("Reading data...")
  }
  out <- haven::read_sas(data_file = path, catalog_file = path_catalog, encoding = encoding, ...)
  .post_process_imported_data(out, convert_factors, verbose)
}


.read_excel <- function(path, encoding, verbose, ...) {
  insight::check_if_installed("readxl", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    insight::format_alert("Reading data...")
  }
  out <- readxl::read_excel(path, ...)
  class(out) <- "data.frame"
  out
}


.read_text <- function(path, encoding, verbose, ...) {
  if (insight::check_if_installed("data.table", quietly = TRUE)) {
    # set proper default encoding-value for fread
    if (is.null(encoding)) {
      encoding <- "unknown"
    }
    out <- data.table::fread(input = path, encoding = encoding, ...)
    return(as.data.frame(out))
  }

  insight::check_if_installed("readr", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    insight::format_alert("Reading data...")
  }
  out <- readr::read_delim(path, ...)
  as.data.frame(out)
}


.read_unknown <- function(path, file_type, verbose, ...) {
  insight::check_if_installed("rio", reason = paste0("to read files of type '", file_type, "'"))
  if (verbose) {
    insight::format_alert("Reading data...")
  }
  # set up arguments. for RDS, we set trust = TRUE, to avoid warnings
  rio_args <- list(file = path)
  # check if we have RDS, and if so, add trust = TRUE
  if (file_type %in% c("rds", "rdata", "rda")) {
    rio_args$trust <- TRUE
  }
  out <- do.call(rio::import, c(rio_args, list(...)))

  # check if loaded file is a data frame, or not (e.g. model objects)
  # it returns `NULL` if the file is no valid data file that contains a data
  # frame.frame, or cannot be coerced to a data frame. Else, if it was a data
  # frame or could be coerced into one, the (new) data frame is returned. In
  # this case, we overwrite "out", else we keep its original object.
  valid_data_object <- .get_data_from_loaded_file(out, verbose)
  # if file could be coerced to a data frame, overwrite out
  if (!is.null(valid_data_object)) {
    out <- valid_data_object
  }

  out
}


.read_base_rda <- function(path, file_type, verbose = TRUE, ...) {
  if (verbose) {
    insight::format_alert("Reading data...")
  }

  # check URLs
  path <- .check_path_url(path, file_type)

  # since RData and rda can keep multiple files, we load them into a
  # new environment and return them as list object then
  env <- new.env()
  load(file = path, envir = env)

  # if the RData file contains more than one object, we don't check the output
  # but just return everything
  if (length(ls(env)) > 1) {
    if (verbose) {
      insight::format_alert("File contained more than one object, returning all objects.")
    }
    return(as.list(env))
  }

  # else, retrieve loaded object
  out <- get(ls(env)[1], env)

  # check if loaded file is a data frame, or not (e.g. model objects)
  # it returns `NULL` if the file is no valid data file that contains a data
  # frame.frame, or cannot be coerced to a data frame. Else, if it was a data
  # frame or could be coerced into one, the (new) data frame is returned. In
  # this case, we overwrite "out", else we keep its original object.
  valid_data_object <- .get_data_from_loaded_file(out, verbose)
  # if file could be coerced to a data frame, overwrite out
  if (!is.null(valid_data_object)) {
    out <- valid_data_object
  }

  out
}


.read_base_rds <- function(path, verbose = TRUE, ...) {
  if (verbose) {
    insight::format_alert("Reading data...")
  }

  # check URLs
  path <- .check_path_url(path, file_type = "rds")
  out <- readRDS(file = path)

  # check if loaded file is a data frame, or not (e.g. model objects)
  # it returns `NULL` if the file is no valid data file that contains a data
  # frame.frame, or cannot be coerced to a data frame. Else, if it was a data
  # frame or could be coerced into one, the (new) data frame is returned. In
  # this case, we overwrite "out", else we keep its original object.
  valid_data_object <- .get_data_from_loaded_file(out, verbose)
  # if file could be coerced to a data frame, overwrite out
  if (!is.null(valid_data_object)) {
    out <- valid_data_object
  }

  out
}


.read_parquet <- function(path, verbose = TRUE, ...) {
  # requires nanoparquet package
  insight::check_if_installed("nanoparquet")

  if (verbose) {
    insight::format_alert("Reading data...")
  }

  # check URLs
  path <- .check_path_url(path, file_type = "parquet")
  out <- nanoparquet::read_parquet(file = path, ...)

  as.data.frame(out)
}


# check input helper --------------------------------------------------------

# for URLs, we need to download the file and save it locally
.check_path_url <- function(path, file_type) {
  url_pattern <- "^(https?|ftp)://(.*)"
  # check if file path is an URL
  if (grepl(url_pattern, path)) {
    insight::check_if_installed("curl")
    if (curl::has_internet()) {
      # if yes, create temp file and save file locally
      temp_file <- tempfile(fileext = paste0(".", file_type))
      download <- curl::curl_fetch_memory(path)
      writeBin(object = download$content, con = temp_file)
      # return path to temp file
      path <- temp_file
    } else {
      insight::format_error(
        "No internet connection detected. Could not download file from URL."
      )
    }
  }
  path
}


.get_data_from_loaded_file <- function(out, verbose = TRUE) {
  # it is also possible to read in pre-compiled model objects with data_read()
  # in this case, just return as is. We do this check before we check with
  # "is.data.frame()", because some models (like brmsfit) have an `as.data.frame()`
  # method, which coerces the model object into a data frame, which is likely to
  # be not intentional
  if (insight::is_model(out)) {
    if (verbose) {
      insight::format_alert(
        paste0("Imported file is a regression model object of class \"", class(out)[1], "\"."),
        "Returning file as is."
      )
    }
    return(NULL)
  }

  # for "unknown" data formats (like .RDS), which still can be imported via
  # "rio::import()", we must check whether we actually have a data frame or
  # not. Else, tell user.
  if (!is.data.frame(out)) {
    tmp <- tryCatch(as.data.frame(out, stringsAsFactors = FALSE), error = function(e) NULL)
    if (is.null(tmp)) {
      if (verbose) {
        insight::format_warning(
          paste0("Imported file is no data frame, but of class \"", class(out)[1], "\"."),
          "Returning file as is. Please check if importing this file was intended."
        )
      }
      return(NULL)
    }
    out <- tmp
  }
  out
}
