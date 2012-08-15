##' @include tables.R
##' @include auth.R
##' @include projects.R
NULL


Classes <- NULL                        # instance of this Table set in zzz.R
ClassTable <- setRefClass("ClassTable",
                            contains="Table",
                          fields=list(
                            school="CharField",
                            name="CharField",
                            owner="CharField",
                            public="BooleanField",
                            projects="ArrayField"
                          ),
                            methods=list(
                              initialize=function(...) {

                                
                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "class_table.rds")
                                callSuper(file=nm, ...)
                              },
                              new_record=function(user_id, school, name, owner, public) {
                                if(!Auth$is_teacher(user_id)) stop("Not a teacher")
                                callSuper(school=school, name=name, owner=owner, public=public)
                              },
                              
                              rearrange_project_order=function(class_id, new_order, user_id) {
                               "rearrange order if the all match"
                               message("Rerrange order")
                               ## XXX should check that owner has permissions...
                               
                                old_order <- get(class_id, "projects")
                                if(length(old_order) == length(new_order) &&
                                   all(sort(old_order) == sort(new_order))) {
                                  set(class_id, projects=new_order)
                                  return("")
                                } else {
                                  stop("Unable to rearrange order")
                                }
                              },
                              delete_project=function(class_id, project_id, user_id) {
                                "delete project from class, if owner"
                                message("delete_project")
                                if(!Classes$valid_id(class_id)) stop("Invalid class")
                                if(!Auth$is_teacher(user_id)) stop("Not a teacher")
                                if(!Projects$valid_id(project_id)) stop("Invalid project id")
                                if(user_id!= Projects$get(project_id, "author"))
                                  stop("You don't own this project")

                                ## remove in two places
                                Classes$pop_j(class_id, "projects", project_id)
                                Projects$remove(project_id)
                                
                              },
                              new_project=function(user_id, class_id) {
                                ## add new project to class. return new id
                                if(!Classes$valid_id(class_id))
                                  stop("Not a valid class")
                                if(user_id != Classes$get(class_id, "owner"))
                                  stop("Not the owner of the class")

                                message("new project")
                                ## make anew project, then push onto projects
                                project_id <- Projects$new_record(name="Fill me in",
                                                                  author=user_id,
                                                                  public=FALSE,
                                                                  keywords="")
                                push_j(class_id, "projects", project_id)
                                return(project_id)
                              },
                              upload_project=function(user_id, class_id, project_id) {
                                if(user_id != Classes$get(class_id, "owner"))
                                  stop("Not the owner of the class")


                                
                                if(missing(project_id) || is.null(project_id)) {
                                  ## new add to class, make new project
                                  message("new project")
                                  project_id <- new_project(user_id, class_id)
                                }
                                
                                 ## replace. Make sure owner is correct m
                                message("replace project via upload")
                                p <- request$POST()
                                path <- p$`files[]`$tempfile
                                fname <- p$`files[]`$filename
                                content_type <- p$`files[]`$content_type
                                
                                ## check if fname matches Rmd, md, ...
                                
                                Projects$set_file(path, project_id)
                              },
                              possible_classes=function(user_id) {
                                ## List public or privately owned classes
                                ## return data frame with id, name
                                is_public <- filter(public=TRUE)
                                is_private <- filter(owner=user_id, public=FALSE)
                                all <- c(is_private, is_public)
                                out <- mapply(function(id, l) list(id=id,
                                                                   name=whisker.render("{{{name}}} at {{{school}}}", l)),
                                              names(all), all, SIMPLIFY=FALSE)
                                do.call(rbind, out)

                              },
                              set_name=function(user_id, class_id, value) {
                                if(!valid_id(class_id))
                                  stop("Invalid class id")
                                if(user_id != Classes$get(class_id, "owner"))
                                  stop("Not the owner of the class")
                                set(class_id, name=value)
                              },
                              set_school=function(user_id, class_id, value) {
                                if(!valid_id(class_id))
                                  stop("Invalid class id")
                                if(user_id != Classes$get(class_id, "owner"))
                                  stop("Not the owner of the class")
                                set(class_id, school=value)
                              },
                              set_public=function(user_id, class_id, value) {
                                if(!valid_id(class_id))
                                  stop("Invalid class id")
                                if(user_id != Classes$get(class_id, "owner"))
                                  stop("Not the owner of the class")
                                set(class_id, public=as.logical(value))
                              },
                              delete_class=function(user_id, class_id) {
                                ## check owner, then call remove
                                if(!valid_id(class_id))
                                  stop("Invalid class id")
                                if(user_id != Classes$get(class_id, "owner"))
                                  stop("Not the owner of the class")
                                remove(class_id)
                              }
                              )
                            )
                            
