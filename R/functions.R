##' @include page.R
NULL


##' Function to add a tooltip hint to a problem.
##'
##' @param hint text for hint
##' @param id id of object
##' @param queue optional Queue object to pass in
##' @param selector used to bypass simple search for a DOM id (see radio)
##' @param title title for hint
##' @export
hint <- function(hint="", id, queue, selector=sprintf("#%s",id), title="hint") {
  hint <- gsub("\\n"," ",hint)
  ## use paste -- not whisker, else can't pass in HTML format
  txt <- paste(sprintf("\n<script>$('%s').popover(", selector),
               sprintf("{title:'%s',content:'%s'}", title, hint),
	       sprintf(");</script>\n"),
	       sep="")
  if(!missing(queue)) queue$push(txt) else txt
}
                      
## wrapper functions. Solely for familiarity and Rd generation.

##' Create a radio choice
##'
##' A radio choice allows the user to select one from a few
##' @param page \code{Page} instance
##' @param x list of items to choose from
##' @param value one of the items
##' @param inline logical. If \code{TRUE} horizontal, else vertical layout
##' @param linebreak logical. Add new line at end (br tag)
##' @param comment Optional. A named list with comments. The component names are chosen from among the wrong values. When matched, that is used a student comment.
##' @param hint Optional. A hint (in HTML) to the user popped up when
##' the mouse hovers on the problem
##' @param ... passed to \code{hint}
##' @return text to add to a page
##' @export
radio_choice <- function(page, x, value, inline=TRUE, linebreak=TRUE,  comment, hint, ...) {
  page$radio_choice(x, value, inline, linebreak,  comment, hint, ...)
}

##' Ask question with a checkbox group
##'
##' A checkbox group allows user to select one or more from a few
##' @param page \code{Page} instance
##' @param x list of items to choose from
##' @param value one of the items
##' @param inline logical. If \code{TRUE} horizontal, else vertical layout
##' @param linebreak  logical. Add new line at end (br tag)
##' @param comment Optional. A named list. The names correspond to the
##' student's choice. In this case, sorted then combined with "::". If
##' the student choice matches this, then that comment will be given
##' as to why the problem is wrong.
##' @param hint Optional. A hint (in HTML) to the user popped up when the user hovers
##' @param ... passed to \code{hint}
##' @return text to add to a page
##' @export
checkgroup_choice <- function(page, x, value, inline=TRUE, linebreak=TRUE,  comment, hint, ...) {
  page$checkgroup_choice(x, value, inline, linebreak,  comment, hint, ...)
}

##' Ask question with a combobox
##'
##' A combobox allows the user to select one from many using a
##' reasonable amount of vertical screen space
##' @param page \code{Page} instance
##' @param x list of items to choose from
##' @param value one of the items
##' @param comment Optional. Named list with names drawn from
##' incorrect answer. When specified these will be used in place of
##' default incorrect answer for comment.
##' @param hint Optional. A hint (in HTML) to the user popped up when
##' @param ... passed to \code{hint}
##' @return text to add to a page
##' @export
combobox_choice <- function(page, x, value, comment, hint, ...) {
  page$combobox_choice(x, value, comment, hint, ...)
}

##' Use an entry widget with typeahead feature
##'
##' Used to pick one from many like a comobobox. 
##' @param page \code{Page} instance
##' @param x list of items to choose from
##' @param value one of the items
##' @param comment Optional. Named list with names drawn from
##' incorrect answer. When specified these will be used in place of
##' default incorrect answer for comment.
##' @param hint Optional. A hint (in HTML) to the user popped up when the user hovers
##' @param ... passed to \code{hint}
##' @return text to add to a page
##' @export
typeahead_choice <- function(page, x, value, comment, hint, ...) {
  page$typeahead_choice(x, value, comment, hint, ...)
}

##' Allow a user to specify a numeric answer
##'
##' Numeric answers are specified within a range. The range can be
##' given by a lower and upper bound or by number of significant
##' digits.
##' @param page \code{Page} instance
##' @param x.lower lower value if \code{x.upper} given, else if \code{digits} given middle value.
##' @param x.upper upper value of range
##' @param digits if \code{x.upper} not given, specifies number of
##' significant digits allowed.
##' @param comment Optional. Named list with names drawn from "less"
##' or "more" to customize comment when user answer is less or more.
##' @param hint Optional. A hint (in HTML) to the user popped up when the user hovers
##' @param ... passed to \code{hint}
##' @return text to add to a page
##' @export
numeric_choice <- function(page, x.lower, x.upper, digits, comment, hint, ...) {
  page$numeric_choice(x.lower, x.upper, digits, comment, hint, ...)
}

