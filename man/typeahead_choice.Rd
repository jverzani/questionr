\name{typeahead_choice}
\alias{typeahead_choice}
\title{Use an entry widget with typeahead feature}
\usage{
  typeahead_choice(page, x, value, comment, hint, ...)
}
\arguments{
  \item{page}{\code{Page} instance}

  \item{x}{list of items to choose from}

  \item{value}{one of the items}

  \item{comment}{Optional. Named list with names drawn from
  incorrect answer. When specified these will be used in
  place of default incorrect answer for comment.}

  \item{hint}{Optional. A hint (in HTML) to the user popped
  up when the user hovers}

  \item{...}{passed to \code{hint}}
}
\value{
  text to add to a page
}
\description{
  Used to pick one from many like a comobobox.
}

