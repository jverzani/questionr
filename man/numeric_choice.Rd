\name{numeric_choice}
\alias{numeric_choice}
\title{Allow a user to specify a numeric answer}
\usage{
  numeric_choice(page, x.lower, x.upper, digits, comment,
    hint, ...)
}
\arguments{
  \item{page}{\code{Page} instance}

  \item{x.lower}{lower value if \code{x.upper} given, else
  if \code{digits} given middle value.}

  \item{x.upper}{upper value of range}

  \item{digits}{if \code{x.upper} not given, specifies
  number of significant digits allowed.}

  \item{comment}{Optional. Named list with names drawn from
  "less" or "more" to customize comment when user answer is
  less or more.}

  \item{hint}{Optional. A hint (in HTML) to the user popped
  up when the user hovers}

  \item{...}{passed to \code{hint}}
}
\value{
  text to add to a page
}
\description{
  Numeric answers are specified within a range. The range
  can be given by a lower and upper bound or by number of
  significant digits.
}

