#' @title Create a grouped data frame
#' @name data_group
#'
#' @description This function is comparable to `dplyr::group_by()`, but just
#' following the **datawizard** function design. `data_ungroup()` removes the
#' grouping information from a grouped data frame.
#'
#' @param data A data frame
#' @inheritParams extract_column_names
#'
#' @return A grouped data frame, i.e. a data frame with additional information
#' about the grouping structure saved as attributes.
#'
#' @examplesIf requireNamespace("poorman")
#' data(efc)
#' suppressPackageStartupMessages(library(poorman, quietly = TRUE))
#'
#' # total mean
#' efc %>%
#'   summarize(mean_hours = mean(c12hour, na.rm = TRUE))
#'
#' # mean by educational level
#' efc %>%
#'   data_group(c172code) %>%
#'   summarize(mean_hours = mean(c12hour, na.rm = TRUE))
#' @export
data_group <- function(data,
                       select = NULL,
                       exclude = NULL,
                       ignore_case = FALSE,
                       regex = FALSE,
                       verbose = TRUE,
                       ...) {
  # variables for grouping
  select <- .select_nse(
    select,
    data,
    exclude,
    ignore_case = ignore_case,
    regex = regex,
    verbose = verbose
  )
  # create grid with combinations of all levels
  my_grid <- as.data.frame(expand.grid(lapply(data[select], unique)))
  # sort grid
  my_grid <- my_grid[do.call(order, my_grid), , drop = FALSE]

  .rows <- lapply(seq_len(nrow(my_grid)), function(i) {
    as.integer(data_match(
      data,
      to = my_grid[i, , drop = FALSE],
      match = "and",
      return_indices = TRUE,
      remove_na = FALSE
    ))
  })
  my_grid[[".rows"]] <- .rows

  # remove data_match attributes
  attr(my_grid, "out.attrs") <- NULL
  attr(my_grid, ".drop") <- TRUE

  attr(data, "groups") <- my_grid
  class(data) <- unique(c("grouped_df", "data.frame"), class(data))

  data
}


#' @rdname data_group
#' @export
data_ungroup <- function(data,
                         verbose = TRUE,
                         ...) {
  attr(data, "groups") <- NULL
  class(data) <- unique(setdiff(class(data), "grouped_df"))

  data
}
