% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/standardize.R, R/unstandardize.R
\name{standardize}
\alias{standardize}
\alias{standardise}
\alias{standardize.numeric}
\alias{standardize.factor}
\alias{standardize.data.frame}
\alias{unstandardize}
\alias{unstandardise}
\alias{unstandardize.numeric}
\alias{unstandardize.data.frame}
\title{Standardization (Z-scoring)}
\usage{
standardize(x, ...)

standardise(x, ...)

\method{standardize}{numeric}(
  x,
  robust = FALSE,
  two_sd = FALSE,
  weights = NULL,
  reference = NULL,
  center = NULL,
  scale = NULL,
  verbose = TRUE,
  ...
)

\method{standardize}{factor}(
  x,
  robust = FALSE,
  two_sd = FALSE,
  weights = NULL,
  force = FALSE,
  verbose = TRUE,
  ...
)

\method{standardize}{data.frame}(
  x,
  select = NULL,
  exclude = NULL,
  robust = FALSE,
  two_sd = FALSE,
  weights = NULL,
  reference = NULL,
  center = NULL,
  scale = NULL,
  remove_na = c("none", "selected", "all"),
  force = FALSE,
  append = FALSE,
  ignore_case = FALSE,
  regex = FALSE,
  verbose = TRUE,
  ...
)

unstandardize(x, ...)

unstandardise(x, ...)

\method{unstandardize}{numeric}(
  x,
  center = NULL,
  scale = NULL,
  reference = NULL,
  robust = FALSE,
  two_sd = FALSE,
  ...
)

\method{unstandardize}{data.frame}(
  x,
  center = NULL,
  scale = NULL,
  reference = NULL,
  robust = FALSE,
  two_sd = FALSE,
  select = NULL,
  exclude = NULL,
  ignore_case = FALSE,
  regex = FALSE,
  verbose = TRUE,
  ...
)
}
\arguments{
\item{x}{A (grouped) data frame, a vector or a statistical model (for
\code{unstandardize()} cannot be a model).}

\item{...}{Arguments passed to or from other methods.}

\item{robust}{Logical, if \code{TRUE}, centering is done by subtracting the
median from the variables and dividing it by the median absolute deviation
(MAD). If \code{FALSE}, variables are standardized by subtracting the
mean and dividing it by the standard deviation (SD).}

\item{two_sd}{If \code{TRUE}, the variables are scaled by two times the deviation
(SD or MAD depending on \code{robust}). This method can be useful to obtain
model coefficients of continuous parameters comparable to coefficients
related to binary predictors, when applied to \strong{the predictors} (not the
outcome) (Gelman, 2008).}

\item{weights}{Can be \code{NULL} (for no weighting), or:
\itemize{
\item For model: if \code{TRUE} (default), a weighted-standardization is carried out.
\item For \code{data.frame}s: a numeric vector of weights, or a character of the
name of a column in the \code{data.frame} that contains the weights.
\item For numeric vectors: a numeric vector of weights.
}}

\item{reference}{A data frame or variable from which the centrality and
deviation will be computed instead of from the input variable. Useful for
standardizing a subset or new data according to another data frame.}

\item{center, scale}{\itemize{
\item For \code{standardize()}: \cr
Numeric values, which can be used as alternative to \code{reference} to define
a reference centrality and deviation. If \code{scale} and \code{center} are of
length 1, they will be recycled to match the length of selected variables
for standardization. Else, \code{center} and \code{scale} must be of same length as
the number of selected variables. Values in \code{center} and \code{scale} will be
matched to selected variables in the provided order, unless a named vector
is given. In this case, names are matched against the names of the selected
variables.
\item For \code{unstandardize()}: \cr
\code{center} and \code{scale} correspond to the center (the mean / median) and the scale (SD / MAD) of
the original non-standardized data (for data frames, should be named, or
have column order correspond to the numeric column). However, one can also
directly provide the original data through \code{reference}, from which the
center and the scale will be computed (according to \code{robust} and \code{two_sd}).
Alternatively, if the input contains the attributes \code{center} and \code{scale}
(as does the output of \code{standardize()}), it will take it from there if the
rest of the arguments are absent.
}}

\item{verbose}{Toggle warnings and messages on or off.}

\item{force}{Logical, if \code{TRUE}, forces recoding of factors and character
vectors as well.}

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

\item{remove_na}{How should missing values (\code{NA}) be treated: if \code{"none"}
(default): each column's standardization is done separately, ignoring
\code{NA}s. Else, rows with \code{NA} in the columns selected with \code{select} /
\code{exclude} (\code{"selected"}) or in all columns (\code{"all"}) are dropped before
standardization, and the resulting data frame does not include these cases.}

\item{append}{Logical or string. If \code{TRUE}, standardized variables get new
column names (with the suffix \code{"_z"}) and are appended (column bind) to \code{x},
thus returning both the original and the standardized variables. If \code{FALSE},
original variables in \code{x} will be overwritten by their standardized versions.
If a character value, standardized variables are appended with new column
names (using the defined suffix) to the original data frame.}

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
The standardized object (either a standardize data frame or a
statistical model fitted on standardized data).
}
\description{
Performs a standardization of data (z-scoring), i.e., centering and scaling,
so that the data is expressed in terms of standard deviation (i.e., mean = 0,
SD = 1) or Median Absolute Deviance (median = 0, MAD = 1). When applied to a
statistical model, this function extracts the dataset, standardizes it, and
refits the model with this standardized version of the dataset. The
\code{\link[=normalize]{normalize()}} function can also be used to scale all numeric variables within
the 0 - 1 range.
\cr\cr
For model standardization, see \code{\link[=standardize.default]{standardize.default()}}.
}
\note{
When \code{x} is a vector or a data frame with \verb{remove_na = "none")},
missing values are preserved, so the return value has the same length /
number of rows as the original input.
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
d <- iris[1:4, ]

# vectors
standardise(d$Petal.Length)

# Data frames
# overwrite
standardise(d, select = c("Sepal.Length", "Sepal.Width"))

# append
standardise(d, select = c("Sepal.Length", "Sepal.Width"), append = TRUE)

# append, suffix
standardise(d, select = c("Sepal.Length", "Sepal.Width"), append = "_std")

# standardizing with reference center and scale
d <- data.frame(
  a = c(-2, -1, 0, 1, 2),
  b = c(3, 4, 5, 6, 7)
)

# default standardization, based on mean and sd of each variable
standardize(d) # means are 0 and 5, sd ~ 1.581139

# standardization, based on mean and sd set to the same values
standardize(d, center = c(0, 5), scale = c(1.581, 1.581))

# standardization, mean and sd for each variable newly defined
standardize(d, center = c(3, 4), scale = c(2, 4))

# standardization, taking same mean and sd for each variable
standardize(d, center = 1, scale = 3)
}
\seealso{
See \code{\link[=center]{center()}} for grand-mean centering of variables, and
\code{\link[=makepredictcall.dw_transformer]{makepredictcall.dw_transformer()}} for use in model formulas.

Other transform utilities: 
\code{\link{normalize}()},
\code{\link{ranktransform}()},
\code{\link{rescale}()},
\code{\link{reverse}()}

Other standardize: 
\code{\link{standardize.default}()}
}
\concept{standardize}
\concept{transform utilities}
