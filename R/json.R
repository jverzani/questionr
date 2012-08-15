## class for working with JSON objects
## for some reason, i want to use JSON to serialize values to character
## so that they can fit into a cell of a data frame

require(RJSONIO)
## we want dates as characters. Doesn't do fromJSON(toJSON(x)) = x
setMethod("toJSON", signature=signature(x="Date"), function(x, ...) {
 toJSON(format(x), ...)
})

setMethod("toJSON", signature=signature(x="POSIXct"), function(x, ...) {
 toJSON(format(x), ...)
})


JSON <- setRefClass("JSON",
                    fields=list(
                      "j"="character",   # asJSON
                      ".x"="ANY",
                      x=function(val) {
                        if(missing(val)) {
                          .x
                        } else {
                          if(is.character(val) && length(val) == 0) {
                            .x <<- val
                            j <<- "[null]"
                          } else {
                            .x <<- val
                            ## really don't want new lines here, they mess up write table
                            j <<- gsub("\\n", " ", toJSON(.x, collapse=""))
                          }
                        }
                      }
                      ),
                    methods=list(
                      initialize=function(x, ...) {
                        if(!missing(x))
                          initFields(x=x)
                        callSuper(...)
                      },
                      push=function(value, key) {
                        "Push value onto object with optional key"
                      },
                      remove=function(value, key) {
                        "Remove by value or key"
                      },
                      update=function(key, value) {
                        "Update value at key, which may be an index or name"
                      },
                      index_of=function(value) {
                        "Find index of item"
                      }
                      ))

JSONarray <- setRefClass("JSONarray",
                         contains="JSON",
                         methods=list(
                           push=function(value, ...) {
                             if(length(x) == 1 && x == "")
                               x <<- value
                             else
                               x <<- unique(c(x, value))
                             .self
                           },
                           remove=function(value, key) {
                             if(!missing(key)) {
                               x <<- x[-key]
                             } else {
                               x <<- Filter(function(y) !identical(y,value), x)
                             }
                             .self
                           },
                           update=function(key, value) {
                             x[key] <<- value
                             .self
                           },
                           index_of=function(value) {
                             match(value, x)
                           }
                           ))

                    
JSONobject <- setRefClass("JSONobject",
                          contains="JSON",
                          methods=list(
                            push=function(value, key) {
                              if(missing(key)) 
                                key <- "missing_X"
                              x[[key]] <<- value
                              .self
                            },
                            remove=function(value, key) {
                              if(!missing(key)) {
                                x[[key]] <<- NULL
                              } else {
                                ind <- index_of(value)
                                if(!is.na(ind))
                                  x[[ind]] <<- value
                              }
                              .self
                            },
                            update=function(key, value) {
                              x[[key]] <<- value
                              .self                              
                            },
                            index_of=function(value) {
                              vals <- sapply(x, function(i) identical(i,value))
                              if(!any(vals)) return(NA)
                              ind <- which(vals)
                              return(min(ind))
                            }
                            ))



j <- function(x, ...) UseMethod("j")
j.list <- function(x, ...) JSONobject$new(x)
j.logical <- j.character <- j.numeric <- function(x, ...) JSONarray$new(x)
j.AsIs <- function(x, ...) JSONobject$new(character(0))

fromj <- function(x, ...) {
  tmp <- fromJSON(x)
  if(is.list(tmp) && length(tmp) == 1 && is.null(tmp[[1]])) 
    tmp <- character(0)
  j(tmp)
}



## Now we can do things like this to update the obj
## # obj = "[1,2,3]" as JSON array
## obj <- j(fromJSON(obj))$push(4)$remove(3)$j


##' Get post from the Rook request object
##'
##' Sometimes the Rook post parsing stuff chokes. The safest
##' way is to pass in JSON via an ajax post call with contentType:"application/json"
##' and parse the data this way (see \code{form_action} in markup.R)
##'  $.ajax({url:"http://localhost:9000/custom/quizr/request_teacher_status",
##'         type:"POST",
##' 	    contentType:"application/json",
##'         data:JSON.stringify({a:1, b:2, c:{d:"ab;c"}}),
##'         success:function(data) {tmp=data;window.location.replace(data)}
##'        });
get_post_from_raw <- function(request) {
  as.list(fromJSON(rawToChar(request$env$rook.input$postBody)))
}


## some JSON like things:
pluck <- function(x, key) sapply(x, "[[", key)

extapply <- function(receiver, sender, defaults)  {
  ## return a list with sender, deafults, receiver priority. Treat unamed as special
  out <- as.list(receiver)

  if(!missing(defaults)) {
    if(is.null(names(defaults))) {
      out <- c(out, defaults)
    } else {
      nms <- names(defaults)
      ind <- which(nms == "")
      sapply(nms[-ind], function(key) out[[key]] <<- defaults[[key]])
      out <- c(out, defaults[ind])
    }
  }
  
  if(is.null(names(sender))) {
    out <- c(out, sender)
  } else {
    nms <- names(sender)
    ind <- which(nms == "")
    sapply(nms[-ind], function(key) out[[key]] <<- sender[[key]])
    out <- c(out, sender[ind])
  }
  
  out
}

  
merge_list <- function(l, l1) {
  for(i in names(l1))
    l[[i]] <- l1[[i]]
  l
}
