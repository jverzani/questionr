\name{checkgroup_choice}
\alias{checkgroup_choice}
\title{Ask question with a checkbox group}
\usage{
  checkgroup_choice(page, x, value, inline = TRUE,
    linebreak = TRUE, comment, hint, ...)
}
\arguments{
  \item{page}{\code{Page} instance}

  \item{x}{list of items to choose from}

  \item{value}{one of the items}

  \item{inline}{logical. If \code{TRUE} horizontal, else
  vertical layout}

  \item{linebreak}{logical. Add new line at end (br tag)}

  \item{comment}{Optional. A named list. The names
  correspond to the student's choice. In this case, sorted
  then combined with "::". If the student choice matches
  this, then that comment will be given as to why the
  problem is wrong.}

  \item{hint}{Optional. A hint (in HTML) to the user popped
  up when the user hovers}

  \item{...}{passed to \code{hint}}
}
\value{
  text to add to a page
}
\description{
  A checkbox group allows user to select one or more from a
  few
}

