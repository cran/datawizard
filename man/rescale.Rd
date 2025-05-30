% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_rescale.R
\name{rescale}
\alias{rescale}
\alias{change_scale}
\alias{rescale.numeric}
\alias{rescale.data.frame}
\title{Rescale Variables to a New Range}
\usage{
rescale(x, ...)

change_scale(x, ...)

\method{rescale}{numeric}(
  x,
  to = c(0, 100),
  multiply = NULL,
  add = NULL,
  range = NULL,
  verbose = TRUE,
  ...
)

\method{rescale}{data.frame}(
  x,
  select = NULL,
  exclude = NULL,
  to = c(0, 100),
  multiply = NULL,
  add = NULL,
  range = NULL,
  append = FALSE,
  ignore_case = FALSE,
  regex = FALSE,
  verbose = FALSE,
  ...
)
}
\arguments{
\item{x}{A (grouped) data frame, numeric vector or factor.}

\item{...}{Arguments passed to or from other methods.}

\item{to}{Numeric vector of length 2 giving the new range that the variable
will have after rescaling. To reverse-score a variable, the range should
be given with the maximum value first. See examples.}

\item{multiply}{If not \code{NULL}, \code{to} is ignored and \code{multiply} will be used,
giving the factor by which the actual range of \code{x} should be expanded.
For example, if a vector ranges from 5 to 15 and \code{multiply = 1.1}, the current
range of 10 will be expanded by the factor of 1.1, giving a new range of
11. Thus, the rescaled vector would range from 4.5 to 15.5.}

\item{add}{A vector of length 1 or 2. If not \code{NULL}, \code{to} is ignored and \code{add}
will be used, giving the amount by which the minimum and maximum of the
actual range of \code{x} should be expanded. For example, if a vector ranges from
5 to 15 and \code{add = 1}, the range will be expanded from 4 to 16. If \code{add} is
of length 2, then the first value is used for the lower bound and the second
value for the upper bound.}

\item{range}{Initial (old) range of values. If \code{NULL}, will take the range of
the input vector (\code{range(x)}).}

\item{verbose}{Toggle warnings.}

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

\item{append}{Logical or string. If \code{TRUE}, recoded or converted variables
get new column names and are appended (column bind) to \code{x}, thus returning
both the original and the recoded variables. The new columns get a suffix,
based on the calling function: \code{"_r"} for recode functions, \code{"_n"} for
\code{to_numeric()}, \code{"_f"} for \code{to_factor()}, or \code{"_s"} for
\code{slide()}. If \code{append=FALSE}, original variables in \code{x} will be
overwritten by their recoded versions. If a character value, recoded
variables are appended with new column names (using the defined suffix) to
the original data frame.}

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
}
\value{
A rescaled object.
}
\description{
Rescale variables to a new range. Can also be used to reverse-score variables
(change the keying/scoring direction), or to expand a range.
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
rescale(c(0, 1, 5, -5, -2))
rescale(c(0, 1, 5, -5, -2), to = c(-5, 5))
rescale(c(1, 2, 3, 4, 5), to = c(-2, 2))

# Specify the "theoretical" range of the input vector
rescale(c(1, 3, 4), to = c(0, 40), range = c(0, 4))

# Reverse-score a variable
rescale(c(1, 2, 3, 4, 5), to = c(5, 1))
rescale(c(1, 2, 3, 4, 5), to = c(2, -2))

# Data frames
head(rescale(iris, to = c(0, 1)))
head(rescale(iris, to = c(0, 1), select = "Sepal.Length"))

# One can specify a list of ranges
head(rescale(iris, to = list(
  "Sepal.Length" = c(0, 1),
  "Petal.Length" = c(-1, 0)
)))

# "expand" ranges by a factor or a given value
x <- 5:15
x
# both will expand the range by 10\%
rescale(x, multiply = 1.1)
rescale(x, add = 0.5)

# expand range by different values
rescale(x, add = c(1, 3))

# Specify list of multipliers
d <- data.frame(x = 5:15, y = 5:15)
rescale(d, multiply = list(x = 1.1, y = 0.5))
}
\seealso{
See \code{\link[=makepredictcall.dw_transformer]{makepredictcall.dw_transformer()}} for use in model formulas.

Other transform utilities: 
\code{\link{normalize}()},
\code{\link{ranktransform}()},
\code{\link{reverse}()},
\code{\link{standardize}()}
}
\concept{transform utilities}
