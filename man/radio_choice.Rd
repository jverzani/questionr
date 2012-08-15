\name{radio_choice}
\alias{radio_choice}
\title{Create a radio choice}
\usage{
  radio_choice(page, x, value, inline = TRUE,
    linebreak = TRUE, comment, hint, ...)
}
\arguments{
  \item{page}{\code{Page} instance}

  \item{x}{list of items to choose from}

  \item{value}{one of the items}

  \item{inline}{logical. If \code{TRUE} horizontal, else
  vertical layout}

  \item{linebreak}{logical. Add new line at end (br tag)}

  \item{comment}{Optional. A named list with comments. The
  component names are chosen from among the wrong values.
  When matched, that is used a student comment.}

  \item{hint}{Optional. A hint (in HTML) to the user popped
  up when the mouse hovers on the problem}

  \item{...}{passed to \code{hint}}
}
\value{
  text to add to a page
}
\description{
  A radio choice allows the user to select one from a few
}

