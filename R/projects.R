##' @include tables.R
##' @include auth.R
NULL


Projects <- NULL                        # instance of this Table set in zzz.R
ProjectsTable <- setRefClass("ProjectsTable",
                            contains="Table",
                             fields=list(
                               name="CharField",
                               author="CharField",
                               date="DateField",
                               public="BooleanField",
                               keywords="ArrayField"
                               ),
                            methods=list(
                              initialize=function(...) {

                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "project_table.rds")
                                callSuper(file=nm, ...)
                              },
                              test = function(...) {
                                message("testing rpc")
                                print(list(...))
                              },
                              clone = function(project_id, owner, user_id) {
                                ## clone project (make new id, copy info) 
                                if(!valid_id(project_id))
                                  stop("Invalid project id")
                                if(! (get(project_id, "public") ||
                                      owner == get(project_id, "author"))
                                   )
                                  stop("No permission to clone project")

                                info <- get(project_id)
                                info$author <- user_id
                                info$date <- today()
                                info$id <- NULL # need a new record
                                new_id <- do.call(.self$new_record, info)
                                file.copy(id_to_filepath(project_id),
                                          id_to_filepath(new_id))
                                invisible(new_id) # return id
                              },
                              id_to_filepath=function(project_id) {
                                path <- sprintf("%s%s%s.Rmd", base_project_dir, .Platform$file.sep, project_id)
                                path

                              },
                              set_file=function(path, project_id) {
                                ## move path to that of file name
                                message("set file for project")
                                if(!file.exists(path))
                                  stop(sprintf("%s does not exist", path))
                                if(!valid_id(project_id))
                                  stop("Not a valid project id")
                                
                                file.copy(path, id_to_filepath(project_id), overwrite=TRUE)
                              },
                              view_project=function(project_id, seed=42, whisker_params=list()) {
                                "Create HTML for a project based on the project id"

                                set.seed(as.numeric(seed))
                                ## add necessary parameter
                                whisker_params$base_url <- getOption("questionr::base_url")
                                base_url <- getOption("questionr::base_url")

                                fname <- sprintf("%s%s%s.Rmd", base_project_dir, .Platform$file.sep, project_id)
                                tmp <- tempfile(fileext=".Rmd")
                                file.copy(fname, tmp)
                                
                                ## whisker, knit and markdown
                                base <- tools:::file_path_sans_ext(tmp)

                                message("knit")
                                knitr:::knit(str_c(base, ".Rmd"), str_c(base, ".mdw"))
                                message("whisker")
                                out <- whisker.render(file_to_string(str_c(base, ".mdw")),
                                                      whisker_params)
                                cat(out, file=str_c(base, ".md"))
                                message("markdown")
                                markdown:::markdownToHTML(str_c(base, ".md"), str_c(base, ".html"))
                                ## clean up
                                message("clean")
                                unlink(sprintf(str_c(base, c("Rmd", "mdw", "md"))))
                                
                                stringr:::str_c(base, ".html")
                              },
                              ## some rpc call
                              set_name=function(user_id, project_id, value) {
                                if(!Projects$valid_id(project_id))
                                  stop("Invalid project")
                                if(user_id!= Projects$get(project_id, "author"))
                                  stop("Invalid owner")
                                Projects$set(project_id, name=value)
                                return("")
                              },
                              set_public=function(user_id, project_id, value) {
                                if(!Projects$valid_id(project_id))
                                  stop("Invalid project")
                                if(user_id!= Projects$get(project_id, "author"))
                                  stop("Invalid owner")
                                
                                Projects$set(project_id, public=value)
                                return("")
                              },
                              set_keywords=function(user_id, project_id, value) {
                                if(!Projects$valid_id(project_id))
                                  stop("Invalid project")
                                if(user_id!= Projects$get(project_id, "author"))
                                  stop("Invalid owner")
                                
                                Projects$set(project_id, keywords=strsplit(value, ",")[[1]])
                                return("")
                              },
                              get_project_text=function(project_id) {
                                if(!Projects$valid_id(project_id))
                                  stop("Invalid project")
                                path <- id_to_filepath(project_id)
                                paste(readLines(path), collapse="\n")
                              },
                              update_project_text=function(user_id, project_id, new_text) {
                                message("Update projecct text")

                                if(!valid_id(project_id))
                                  stop("Invalid project id")
                                if(!user_id == Projects$get(project_id, "author"))
                                  stop("You don't own this resource")

                                path <- id_to_filepath(project_id)
                                cat(new_text, "\n", file=path)
                                ""                                
                              }

                              )
                            )
   

## get temp file with rendered project. Student id used to get random seed
make_project_html_student <- function(project_id, student_id) {
  ## use random seed from stud.id
  
  seed <- Students$get(student_id, "random_seed")
  whisker_params <- list(STUDENT_ID=student_id,
                         PAGE_ID=project_id)
  Projects$view_project(project_id, seed, whisker_params)

}

## compute grade for answers
## return list with graded and grade comment
compute_grade <- function(ans) {
  ## answer can be NULL or "", in which case it isn't answers

  answers <- pluck(ans, "answer")
  ind <- sapply(answers, function(x) is.null(x) || x=="")
  answers[ind] <- NA
  
  grade <- pluck(ans, "grade")
  ind <- sapply(grade, function(x) is.null(x) || x=="")
  grade[ind] <- NA
  grade <- unlist(grade)

  all_graded <- !any(is.na(grade))
  no_graded <- length(grade[!is.na(grade)])
  
  if(all_graded) {
    out <- list(
                all_graded=TRUE,
                grade=round(sum(unlist(grade), na.rm=TRUE)/length(grade), 1)
                )
  } else {
    out <- list(
                all_graded=FALSE,
                grade=sprintf("only %s of %s graded",
                  no_graded,
                  length(grade))
                )

  }

  out
}


## forms
download_project <- function(request, ...) {
 id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=id)) {
    return(login_form(request))
  }
 ## can edit name, date, public (yes, no) and keywords
 r <- request$GET()
 project_id <- r$project_id

 if(id != Projects$get(project_id, "author"))
   stop("Not the project owner")

 path <- sprintf("%s%s%s.Rmd", base_project_dir, .Platform$file.sep, project_id)
 if(!file.exists(path))
   stop("No such file?")
 
 fi <- file.info(path)
 headers <- list(
                 'Last-Modified' = Utils$rfc2822(fi$mtime),
                 'Content-Type' = Mime$mime_type(Mime$file_extname(basename(path))),
                 'Content-Length' = as.character(fi$size),
                 'Content-Disposition'= sprintf('attachment; filename="%s.Rmd"',
                    gsub("\\s+", "_", Projects$get(project_id,"name")))
                 )
 names(path) <- "file"
 response <- Response$new()
 response$headers <- headers
 response$body <- path
 response
 
}
 
## edit_project <- function(request, ...) {
##   ## need to be a teacher and own the project
##   id <- get_quizr_id(request)
##   if(!is_teacher(id=id)) {
##     return(login_form(request))
##   }

##   ## can edit name, date, public (yes, no) and keywords
##   r <- request$GET()
##   project_id <- r$project_id

  
##   if(!Projects$valid_id(id=project_id))
##     stop("Invalid project id")
  
##   author_id<-Projects$get(id=project_id, "author")
##   if(id != author_id) 
##     stop("You don't own the project")

##   ## XXX use generic form here!
##   tpl <-  system.file("templates", "teacher_edit_project", package="questionr")
##   show_form(tpl,
##             project_id=project_id,
##             name=name,
##             public=public,
##             keywords=keywords
##             )
## }

## Edit a project in a browser
teacher_edit_project_in_browser <- function(request) {
  ## need to be a teacher and own the project
  user_id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=user_id)) {
    return(login_form(request))
  }
  
  ## can edit name, date, public (yes, no) and keywords
  r <- request$GET()
  project_id <- r$project_id

  if(!Projects$valid_id(project_id))
    stop("Not a valid project")
  if(! user_id == Projects$get(project_id, "author"))
    stop("User does not own the resource")

  descr <- sprintf("Editing: %s", Projects$get(project_id, "name"))
  txt <- Projects$get_project_text(project_id)
  
  tpl <- system.file("templates", "ace_edit.html", package="questionr")
  show_form(tpl, user_id=user_id, project_id=project_id,
            text=txt, description=descr)
}
