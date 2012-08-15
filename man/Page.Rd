\name{Page}
\alias{Page}
\title{Main class for a page}
\description{
  A page is setup by first defining the instance of this
  class. The methods \code{write_header} and
  \code{write_footer} are the bookends for a page. Within
  these, there are several methods for specifying problem
  types:
}
\details{
  \code{new_problem} If \code{add_badge} is \code{TRUE}
  will place a badge indicating the number of tries for a
  problem and a comment area, otherwise places an icon.

  \code{radio_choice} To allow a selection of one from a
  few using radio buttons

  \code{checkgroup_choice} To allow a selection of one or
  more from a few using checkbox buttons

  \code{combobox_choice} To allow a selection of one from
  many using a combobox

  \code{typeahead_choice} To allow a selection of one from
  many using a entry box with typeahead enabled.

  \code{numeric_choice} To allow single numeric value to be
  selected, from within a range.

  These methods all have arguments:

  \code{comment} to leave a comment when the student is
  wrong. Comments are specified using lists. For numeric
  values, the components "less" and "more" are used to give
  a comment when the student is below the range or above.
  For others, the components are named to match the
  possible wrong answers. A default is given, so you need
  not specify all of them.

  \code{hint} To have a hint popup when the user hovers
  near the problem. The \code{...} argument allows one to
  pass a title to the hint.

  The methods also have wrapper functions which are
  documented.

  The \code{grade_button} is used to allow the student to
  see their current grade along with comments.

  The \code{grade_server_button} is used to send grades
  back to a server
}

