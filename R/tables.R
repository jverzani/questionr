##' @include fields.R
NULL

##' A table class
##'
##' In development we want to have the convenience of a text-based
##' data frame for stroing the tables, but also want the ability to
##' easily transition to a data base. This class is meant to make that
##' transition simple enough.
##'
##' The subclasses defines their fields using a Field subclass.
##' The fields can not be named `id` or `drop`
##' 
##' The main interface is get, filter and set along with new_record.
Table <- setRefClass("Table",
                      fields=list(
                        ..df="data.frame", # character data frame
                        ..file="character",
                        lock_file="character",
                        file=function(val) {
                          if(missing(val)) {
                            ..file
                          } else {
                            ..file <<- val
                            lock_file <<- str_c(val, ".lock")
                            .self$read_file()
                          }
                        },
                        last_access="POSIXct"
                        ),
                      methods=list(
                        initialize=function(file, ...) {
                          last_access <<- origin

                          if(!missing(file)) {
                            file <<- file
                          }
                          callSuper(...)
                        },
                        ## work with fields
                        get_fields=function() {
                          "return named list of field types"
                          tmp <- .refClassDef@fieldClasses
                          out <- Filter(function(nm) grep("Field$", nm), tmp)
                          out$id <- "CharField"
                          out
                        },
                        list_to_char=function(l) {
                          "List is list (or data frame) of values, char list of characterized values"
                          fields <- get_fields()
                          mapply(function(key, value) {
                            gen <- base::get(fields[[key]])
                            gen$new(value)$to_string()
                          }, names(l), l, SIMPLIFY=FALSE)
                        },
                        char_to_list=function(r) {
                          "Char is data frame row, treated like a list. List is list of values"
                          fields <- get_fields()
                           mapply(function(key, value) {
                             base::get(fields[[key]])$new()$from_string(value)
                          }, names(r), r, SIMPLIFY=FALSE)


                        },
                        lock = function() {
                          cat("", file=lock_file)
                        },
                        unlock=function() {
                          unlink(lock_file)
                        },
                        is_locked=function() {
                          file.exists(lock_file)
                        },
                        get_lock=function() {
                          "get lock or stop"
                          if(is_locked()) {
                            ## ignore lock if old
                            old <- seconds(5)
                            if((last_access + old) < now()) {
                              unlink(lock_file)
                            }
                            ## ## still locked?
                            ## if(is_locked()) {
                            ##   ## now we wait
                            ##   MAX_CTR <- 1000; ctr <- 1
                            ##   while(is_locked() && ctr < MAX_CTR) {
                            ##     print(list("is_locked", is_locked(), ctr))
                            ##     ctr <- ctr + 1
                            ##   }
                            ##   if(ctr >= MAX_CTR)
                            ##     stop("Couldn't get lock()")
                            ## }
                          }
                          lock()
                        },
                        read_file=function() {
                          "Read file, though we don't if mtime after last access"
                          if(file == "")
                            stop("Need to set a file name")

                          if(!file.exists(file)) {
                            create_table()
                            return()
                          }

                          fi <- file.info(file)
                          if(last_access >= fi$mtime)
                            return()
                          
                          get_lock(); on.exit(unlock())
                          ..df <<- read.table(file, header=TRUE, row.names=NULL,
                                              colClasses="character")
                          
                        },
                        write_file=function() {
                          if(!is_locked()) {
                            ## XXX this is wrong, will write if we are locked?
                            get_lock(); on.exit(unlock())
                          }


                          
                          write.table(..df, col.names=TRUE, row.names=FALSE, file=file)
                          last_access <<- now()
                        },
                        new_id=function() {
                          "Create a new Unique ID for this table"
                          id_maker <- function() paste(sample(LETTERS, 10, TRUE), collapse="")
                          if(nrow(..df) == 0 || ncol(..df) == 0) return(id_maker())
                          
                          cur <- ..df[, "id", drop=TRUE]
                          while((ID <- id_maker()) %in% cur) {}
                          ID
                        },
                        valid_id=function(id) {
                          read_file()
                          id %in% ..df[,"id", drop=TRUE]
                        },
                        index_of=function(id) {
                          match(id, ..df[, "id", drop=TRUE])
                        },
                        merge_list=function(l, l1) {
                          for(key in names(l1)) l[[key]] <- l1[[key]]
                          l
                        },
                        create_table = function() {
                          "Make initial table"
                          
                          out <- data.frame(default_record(),
                                            stringsAsFactors=FALSE)[integer(0),, drop=FALSE]
                          ..df <<- out
                            write_file()
                        },
                        default_record=function() {
                          ## create default record using keys
                          l <- list(id=new_id())
                          fields <- get_fields()
                          defs <- mapply(function(nm, type) {
                            base::get(type)$new()$to_string()
                          }, names(fields), fields, SIMPLIFY=FALSE)
                          merge_list(defs, l)
                        },
                        new_record=function(...) {
                          lock(); on.exit(unlock())
                          message("new_record")
                          read_file()
                          l <- merge_list( default_record(), list(...))
                          l <- list_to_char(l)
                          i <- nrow(..df) + 1
                          mapply(function(key, value) ..df[i, key] <<- value,
                                 names(l), l)
                          write_file()
                          last_access <<- now()
                          ## return id
                          l$id
                        },
                        get=function(id=NULL, ..., drop=TRUE) {
                          ## Return list of list of lists
                          ## if drop=TRUE *and* list of length 1, then drop
                          ## each record is a list, with JSON object expand
                          if(is.null(id)) stop("need an ID to return values from a record")

                          read_file()
                          idx <- index_of(id)
                          rec <- ..df[idx, , drop=FALSE]
                          ## narrow
                          nms <- unlist(list(...))

                          if(length(nms) > 0)
                            rec <- rec[, match(nms, names(..df)), drop=FALSE]
                          ## coerce json
                          out <- char_to_list(rec)
                          if(drop==TRUE && length(out) == 1)
                            out[[1]]
                          else
                            out
                        },
                        filter=function(...) {
                          "Return list of records, keyed by id that match search"
                          if(length(list(...)) == 0) {
                            ## return the whole lot
                            return(split(..df, ..df$id))
                          }
                          if(nrow(..df) == 0)
                            return(list())
                          
                          l <- list_to_char(list(...))
                          ind <- mapply(function(key, value) ..df[[key]] %in% value,
                                 names(l), l)
                          if(is.matrix(ind))
                            ind <- apply(ind, 1, all)

                          rec <- ..df[ind, , drop=FALSE]
                          out <- split(rec, rec[,'id'])
                          out <- sapply(out, .self$char_to_list, simplify=FALSE)
                          out
                        },
                        set=function(id=NULL, ...) {
                          if(is.null(id) || !valid_id(id))
                            stop(sprintf("Can not set: invalid id %s", id))

                          read_file()
                          get_lock(); on.exit(unlock())
                          l <- list(...)
                          l <- list_to_char(l)
                          idx <- index_of(id)
                          mapply(function(key, value) ..df[idx, key] <<- value,
                                 names(l), l)
                          write_file()
                        },
                        remove=function(id) {
                          "Remove field"
                          if(!valid_id(id)) stop("Can't remove invalid id")
                          idx <- index_of(id)
                          read_file()
                          ..df <<- ..df[-idx, ,drop=FALSE]
                          write_file()
                        },
                        ## json helpers
                        push_j=function(id, key, value) {
                          fields <- get_fields()
                          if(!fields[[key]] == "ArrayField")
                            stop("Key is not a json field")
                          vals <- get(id, key)
                          l <- setNames(list(unique(c(vals, value))), key)
                          l$id <- id
                          do.call(.self$set, l)
                        },
                        pop_j=function(id, key, value) {
                          "Remove value if present from list"
                          fields <- get_fields()
                          if(!fields[[key]] == "ArrayField")
                            stop("Key is not a json field")
                          vals <- get(id, key)
                          vals <- Filter(function(i) !identical(i, value), vals)
                          l <- setNames(list(vals), key)
                          l$id <- id
                          do.call(.self$set, l)
                        }
                        ))
        
