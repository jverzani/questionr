\name{write_table}
\alias{write_table}
\alias{write_table.data.frame}
\title{Use Bootstrap's pretty print of tables}
\usage{
  write_table(x, opts, ...)

  \method{write_table}{data.frame}(x,
    opts = c("striped", "bordered", "condensed"), ...)
}
\arguments{
  \item{x}{object to dispatch on}

  \item{opts}{options from "striped", "bordered", and
  "condensed".}

  \item{...}{ignored for now}
}
\description{
  S3 generic to write a pretty table. At this point only a
  method for data frames is written.

  S3 method for data frames
}

