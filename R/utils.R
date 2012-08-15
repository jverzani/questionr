## utility functions

##' turn file(s) into character string (scalar)
file_to_string <- function(...) {
  l <- lapply(unlist(list(...)), readLines, warn=FALSE)
  paste(unlist(l), collapse="\n")
  ##  paste(readLines(f, warn=FALSE), collapse="\n")
}

## || for NULL
"%||%" <- function(x, y) {
  if(missing(x) ||
     is.null(x) ||
     (is.character(x) && nchar(x) == 0)
     ) {
    y
  } else {
    x
  }
}

##' df_to_list
##'
##' Convert a data frame to alist along its rows
df_to_list <- function(df, USE.NAMES=TRUE) {
  sapply(seq_len(nrow(df)), function(i) df[i,],
         simplify=FALSE, USE.NAMES=USE.NAMES)
}
  
