\name{Table}
\alias{Table}
\title{A table class}
\description{
  In development we want to have the convenience of a
  text-based data frame for stroing the tables, but also
  want the ability to easily transition to a data base.
  This class is meant to make that transition simple
  enough.
}
\details{
  The subclasses defines their fields using a Field
  subclass. The fields can not be named `id` or `drop`

  The main interface is get, filter and set along with
  new_record.
}

