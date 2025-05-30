% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/row_count.R
\name{row_count}
\alias{row_count}
\title{Count specific values row-wise}
\usage{
row_count(
  data,
  select = NULL,
  exclude = NULL,
  count = NULL,
  allow_coercion = TRUE,
  ignore_case = FALSE,
  regex = FALSE,
  verbose = TRUE
)
}
\arguments{
\item{data}{A data frame with at least two columns, where number of specific
values are counted row-wise.}

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

\item{count}{The value for which the row sum should be computed. May be a
numeric value, a character string (for factors or character vectors), \code{NA} or
\code{Inf}.}

\item{allow_coercion}{Logical. If \code{FALSE}, \code{count} matches only values of same
class (i.e. when \code{count = 2}, the value \code{"2"} is not counted and vice versa).
By default, when \code{allow_coercion = TRUE}, \code{count = 2} also matches \code{"2"}. In
order to count factor levels in the data, use \code{count = factor("level")}. See
'Examples'.}

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
A vector with row-wise counts of values specified in \code{count}.
}
\description{
\code{row_count()} mimics base R's \code{rowSums()}, with sums for a
specific value indicated by \code{count}. Hence, it is similar to
\code{rowSums(x == count, na.rm = TRUE)}, but offers some more options, including
strict comparisons. Comparisons using \code{==} coerce values to atomic vectors,
thus both \code{2 == 2} and \code{"2" == 2} are \code{TRUE}. In \code{row_count()}, it is also
possible to make "type safe" comparisons using the \code{allow_coercion} argument,
where \code{"2" == 2} is not true.
}
\examples{
dat <- data.frame(
  c1 = c(1, 2, NA, 4),
  c2 = c(NA, 2, NA, 5),
  c3 = c(NA, 4, NA, NA),
  c4 = c(2, 3, 7, 8)
)

# count all 4s per row
row_count(dat, count = 4)
# count all missing values per row
row_count(dat, count = NA)

dat <- data.frame(
  c1 = c("1", "2", NA, "3"),
  c2 = c(NA, "2", NA, "3"),
  c3 = c(NA, 4, NA, NA),
  c4 = c(2, 3, 7, Inf)
)
# count all 2s and "2"s per row
row_count(dat, count = 2)
# only count 2s, but not "2"s
row_count(dat, count = 2, allow_coercion = FALSE)

dat <- data.frame(
  c1 = factor(c("1", "2", NA, "3")),
  c2 = c("2", "1", NA, "3"),
  c3 = c(NA, 4, NA, NA),
  c4 = c(2, 3, 7, Inf)
)
# find only character "2"s
row_count(dat, count = "2", allow_coercion = FALSE)
# find only factor level "2"s
row_count(dat, count = factor("2"), allow_coercion = FALSE)

}
