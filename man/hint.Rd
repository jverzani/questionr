\name{hint}
\alias{hint}
\title{Function to add a tooltip hint to a problem.}
\usage{
  hint(hint = "", id, queue,
    selector = sprintf("#\%s", id), title = "hint")
}
\arguments{
  \item{hint}{text for hint}

  \item{id}{id of object}

  \item{queue}{optional Queue object to pass in}

  \item{selector}{used to bypass simple search for a DOM id
  (see radio)}

  \item{title}{title for hint}
}
\description{
  Function to add a tooltip hint to a problem.
}

