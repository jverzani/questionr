##' @include zzz.R
## A number of simple classes and the Page class

## Some counter
Ctr <- setRefClass("Ctr",
                    fields=list(
                      ctr="integer"
                      ),
                    methods=list(
                      initialize=function(n=0L,...) {
                        ctr <<- 0L
                        callSuper(...)
                      },
                      inc=function() ctr <<- ctr  + 1L,
                      ct=function() ctr
                    ))


## A queue to add multiple output strings during a call
Queue <- setRefClass("Queue",
                     fields=list(out="character"),
                     methods=list(
                       initialize=function(...) callSuper(...),
                       push=function(x, static, data=list()) {
                         if(!missing(static)) {
                           tmp <- system.file("static", static, package="questionr")
                           tmp <- readLines(tmp)
                           tmp <- Filter(function(x) !grepl("^\\s*//", x), tmp)
                           x <- paste(tmp, collapse="\n")
                           ## add config values ...
                           base_url <- data$base_url <- getOption("questionr::base_url")
                           x <- whisker.render(x, data)
                         }
                           
                         out <<- c(out, x)
                         
                       },
                       push_whisker=function(tpl, ...) {
                         x <- whisker.render(tpl, list(...))
                         push(x)
                       },
                       flush=function(col="\n") {
                         "Flush values reset queue"
                         ret <- paste(out, collapse=col)
                         out <<- character(0)
                         ret
                       }
                       ))
