% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/assign_labels.R
\name{assign_labels}
\alias{assign_labels}
\alias{assign_labels.numeric}
\alias{assign_labels.data.frame}
\title{Assign variable and value labels}
\usage{
assign_labels(x, ...)

\method{assign_labels}{numeric}(x, variable = NULL, values = NULL, ...)

\method{assign_labels}{data.frame}(
  x,
  select = NULL,
  exclude = NULL,
  values = NULL,
  ignore_case = FALSE,
  regex = FALSE,
  verbose = TRUE,
  ...
)
}
\arguments{
\item{x}{A data frame, factor or vector.}

\item{...}{Currently not used.}

\item{variable}{The variable label as string.}

\item{values}{The value labels as (named) character vector. If \code{values} is
\emph{not} a named vector, the length of labels must be equal to the length of
unique values. For a named vector, the left-hand side (LHS) is the value in
\code{x}, the right-hand side (RHS) the associated value label. Non-matching
labels are omitted.}

\item{select}{Variables that will be included when performing the required
tasks. Can be either
\itemize{
\item a variable specified as a literal variable name (e.g., \code{column_name}),
\item a string with the variable name (e.g., \code{"column_name"}), a character
vector of variable names (e.g., \code{c("col1", "col2", "col3")}), or a
character vector of variable names including ranges specified via \code{:}
(e.g., \code{c("col1:col3", "col5")}),
\item for some functions, like \code{data_select()} or \code{data_rename()}, \code{select} can
be a named character vector. In this case, the names are used to rename
the columns in the output data frame. See 'Details' in the related
functions to see where this option applies.
\item a formula with variable names (e.g., \code{~column_1 + column_2}),
\item a vector of positive integers, giving the positions counting from the left
(e.g. \code{1} or \code{c(1, 3, 5)}),
\item a vector of negative integers, giving the positions counting from the
right (e.g., \code{-1} or \code{-1:-3}),
\item one of the following select-helpers: \code{starts_with()}, \code{ends_with()},
\code{contains()}, a range using \code{:}, or \code{regex()}. \code{starts_with()},
\code{ends_with()}, and  \code{contains()} accept several patterns, e.g
\code{starts_with("Sep", "Petal")}. \code{regex()} can be used to define regular
expression patterns.
\item a function testing for logical conditions, e.g. \code{is.numeric()} (or
\code{is.numeric}), or any user-defined function that selects the variables
for which the function returns \code{TRUE} (like: \code{foo <- function(x) mean(x) > 3}),
\item ranges specified via literal variable names, select-helpers (except
\code{regex()}) and (user-defined) functions can be negated, i.e. return
non-matching elements, when prefixed with a \code{-}, e.g. \code{-ends_with()},
\code{-is.numeric} or \code{-(Sepal.Width:Petal.Length)}. \strong{Note:} Negation means
that matches are \emph{excluded}, and thus, the \code{exclude} argument can be
used alternatively. For instance, \code{select=-ends_with("Length")} (with
\code{-}) is equivalent to \code{exclude=ends_with("Length")} (no \code{-}). In case
negation should not work as expected, use the \code{exclude} argument instead.
}

If \code{NULL}, selects all columns. Patterns that found no matches are silently
ignored, e.g. \code{extract_column_names(iris, select = c("Species", "Test"))}
will just return \code{"Species"}.}

\item{exclude}{See \code{select}, however, column names matched by the pattern
from \code{exclude} will be excluded instead of selected. If \code{NULL} (the default),
excludes no columns.}

\item{ignore_case}{Logical, if \code{TRUE} and when one of the select-helpers or
a regular expression is used in \code{select}, ignores lower/upper case in the
search pattern when matching against variable names.}

\item{regex}{Logical, if \code{TRUE}, the search pattern from \code{select} will be
treated as regular expression. When \code{regex = TRUE}, select \emph{must} be a
character string (or a variable containing a character string) and is not
allowed to be one of the supported select-helpers or a character vector
of length > 1. \code{regex = TRUE} is comparable to using one of the two
select-helpers, \code{select = contains()} or \code{select = regex()}, however,
since the select-helpers may not work when called from inside other
functions (see 'Details'), this argument may be used as workaround.}

\item{verbose}{Toggle warnings.}
}
\value{
A labelled variable, or a data frame of labelled variables.
}
\description{
Assign variable and values labels to a variable or variables in a data frame.
Labels are stored as attributes (\code{"label"} for variable labels and \code{"labels"})
for value labels.
}
\section{Selection of variables - the \code{select} argument}{

For most functions that have a \code{select} argument (including this function),
the complete input data frame is returned, even when \code{select} only selects
a range of variables. That is, the function is only applied to those variables
that have a match in \code{select}, while all other variables remain unchanged.
In other words: for this function, \code{select} will not omit any non-included
variables, so that the returned data frame will include all variables
from the input data frame.
}

\examples{
x <- 1:3
# labelling by providing required number of labels
assign_labels(
  x,
  variable = "My x",
  values = c("one", "two", "three")
)

# labelling using named vectors
data(iris)
out <- assign_labels(
  iris$Species,
  variable = "Labelled Species",
  values = c(`setosa` = "Spec1", `versicolor` = "Spec2", `virginica` = "Spec3")
)
str(out)

# data frame example
out <- assign_labels(
  iris,
  select = "Species",
  variable = "Labelled Species",
  values = c(`setosa` = "Spec1", `versicolor` = "Spec2", `virginica` = "Spec3")
)
str(out$Species)

# Partial labelling
x <- 1:5
assign_labels(
  x,
  variable = "My x",
  values = c(`1` = "lowest", `5` = "highest")
)
}
