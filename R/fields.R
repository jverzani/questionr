
## A field is used to specify the type of variable in a record
## Here we store the model as a data frame of character values so
## that reading and writing is fast. The fields here have the
## to_string and from_string methods to speed that process.
##
## * A basic field holds scalar data. See ArrayField or ListField for
##   other
## * The classname  must end in "Field" as this is how we search amongst the
##   reference class fields
Field <- setRefClass("Field",
                     fields=list(
                       x="ANY"
                       ),
                     methods=list(
                       ## new must be able to take string argument
                       initialize=function(x, ...) {
                         if(!missing(x))
                           x <<- x
                         callSuper(...)
                       },
                       from_string=function(x) x,
                       to_string=function() as.character(x[1])
                       )
                     )

CharField <- setRefClass("CharField",
                         contains="Field",
                         fields=list(x="character"))


NumericField <- setRefClass("NumericField",
                            contains="Field",
                            fields=list(x="numeric"),
                            methods=list(
                              from_string=function(x) as.numeric(x)
                              ))

BooleanField <- setRefClass("BooleanField",
                            contains="Field",
                            fields=list(x="logical"),
                            method=list(
                              initialize=function(x=logical(0), ...) {
                                if(!missing(x) && is.character(x))
                                  callSuper(from_string(x), ...)
                                else
                                  callSuper(x, ...)
                           },
                              from_string=function(x) {
                                as.logical(x)[1]
                              }
                              ))

DateField <- setRefClass("DateField",
                         contains="Field",
                         fields=list(x="Date"),
                         methods=list(
                           initialize=function(x=today(), ...) {
                             if(!missing(x) && is.character(x))
                               callSuper(as.Date(x), ...)
                             else
                               callSuper(x, ...)
                           },
                           from_string=function(x) as.Date(x),
                           to_string=function() format(x)
                           ))

DateTimeField <- setRefClass("DateTimeField",
                         contains="Field",
                         fields=list(x="POSIXlt"),
                         methods=list(
                           initialize=function(x=now(), ...) {
                             if(!missing(x) && is.character(x))
                               callSuper(from_string(x), ...)
                             else
                               callSuper(x, ...)
                           },
                           from_string=function(x) as.POSIXlt(x[1]),
                           to_string=function(x) format(x)
                           ))

ArrayField <- setRefClass("ArrayField",
                          contains="Field",
                          methods=list(
                            initialize=function(x=NULL,...) {
                              if(!is.null(x) && is.character(x) && length(x) == 1 && x == "[ null ] ")
                                callSuper(NULL, ...)
                              else
                                callSuper(x, ...)
                            },
                            to_string=function() {
                              if(length(x) == 0)
                                toJSON(NULL)
                              else
                                toJSON(x)
                            },
                            from_string=function(x) {
                              out <- try(fromJSON(x), silent=TRUE)
                              if(inherits(out, "try-error"))
                                x
                              else if(is.list(out) &&
                                     length(out) == 1 &&
                                     is.null(out[[1]]))
                                return(character(0))
                              else
                                out
                            }
                            ))
                           
ListField <- setRefClass("ListField",
                         contains="Field",
                         methods=list(
                           initialize=function(x=list(), ...) {
                             if(is.character(x))
                               callSuper(from_string(x), ...)
                             else
                               callSuper(x, ...)
                           },
                           to_string=function() {
                             if(length(x) == 0)
                               toJSON(list(), collapse="\n")
                             else
                               toJSON(x, collapse="\n")
                           },
                           from_string=function(x) {
                             out <- try(fromJSON(x), silent=TRUE)
                             if(inherits(out, "try-error"))
                               out <- list()
                             else
                               out
                           }
                           ))
