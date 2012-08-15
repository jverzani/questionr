\name{combobox_choice}
\alias{combobox_choice}
\title{Ask question with a combobox}
\usage{
  combobox_choice(page, x, value, comment, hint, ...)
}
\arguments{
  \item{page}{\code{Page} instance}

  \item{x}{list of items to choose from}

  \item{value}{one of the items}

  \item{comment}{Optional. Named list with names drawn from
  incorrect answer. When specified these will be used in
  place of default incorrect answer for comment.}

  \item{hint}{Optional. A hint (in HTML) to the user popped
  up when}

  \item{...}{passed to \code{hint}}
}
\value{
  text to add to a page
}
\description{
  A combobox allows the user to select one from many using
  a reasonable amount of vertical screen space
}

