\name{show_form}
\alias{show_form}
\title{show a form}
\usage{
  show_form(form, .l, ..., script, fragment = FALSE)
}
\arguments{
  \item{form}{is template}

  \item{.l}{if second argument is a list use that instead
  of ...}

  \item{...}{passed to \code{whisker.render} to populate
  template}

  \item{script}{optional javascript to add to form}

  \item{fragment}{if \code{TRUE} do not wrap in header and
  footer.}
}
\value{
  a character object with the form template sandwiched
  between the header and footer text.
}
\description{
  show a form
}

