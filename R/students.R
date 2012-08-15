##' @include tables.R
##' @include auth.R
##' @include sections.R
##' @include forms.R
##' @include projects.R
##' @include utils.R
NULL

Students <- NULL                        # instance of this Table set in zzz.R
StudentsTable <- setRefClass("StudentsTable",
                            contains="Table",
                             fields=list(
                               random_seed="NumericField",
                               sections="ArrayField",
                               messages="ArrayField"
                               ),
                            methods=list(
                              initialize=function(...) {
                             
                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "student_table.rds")
                                callSuper(file=nm, ...)
                              },
                              ## list sections, return list of current, old
                              get_sections=function(user_id) {
                                if(!Auth$is_student(user_id))
                                  stop("Invalid id")

                                secs <- get(user_id, 'sections')
                                if(length(secs) == 0)
                                  return(list())

                                ans <- sapply(secs, Sections$is_closed) #Sections$is_current)
                                ans <- c("open", "closed")[1 + ans]
                                split(secs, ans)
                              },
                              ## to add/remove a section:
                              ## * add/remove section here, add/remove student to students entry in section table
                              student_add_section = function(id, section_id) {
                                if(!Auth$is_student(id) ||
                                   !Sections$valid_id(section_id))
                                  stop("one of the IDs is wrong")

                                push_j(id=id, "sections", section_id)
                                Sections$push_j(section_id, "students", id)
                              },
                              student_remove_section = function(id, section_id) {
                                 if(!Auth$is_student(id) ||
                                   !Sections$valid_id(section_id))
                                  stop("one of the IDs is wrong")

                                 pop_j(id=id, "sections", section_id)
                                 Sections$pop_j(section_id, "students", id)
                                 
                               },

                              ## Return a link to view project
                              ## adjust icons below. Used to list projects
                              student_project_status = function(student_id, project_id) {
                                ans_id <- Answers$make_ans_id(student_id, project_id)
                                
                                ## had this, but took out onclick='window.open(this.href); return false;'
                                f <- function(msg, icon="icon-leaf") 
                                  sprintf("<i class='%s'></i>&nbsp;<a href='%s/show_project/%s'>%s</a>",
                                          icon,
                                          getOption("questionr::base_url"),
                                          project_id,
                                          msg)
  
                                if(!Answers$valid_id(ans_id)) {
                                  ## not done
                                  f("Not started", icon=answer_icon("not-started"))
                                } else {
                                  rec <- Answers$get(ans_id, "status", "grade")
                                  if(rec$status == "graded") {
                                    f(sprintf("%s", rec$grade), icon=answer_icon("graded"))
                                  } else if(rec$status == "saved") {
                                    f("saved", icon=answer_icon("file"))
                                  } else {
                                    f("Submitted for grading", answer_icon("submitted"))
                                  }
                                }
                              },
                              create_sections_list = function(id, secs) {
                                ## build up sections list list with components:
                                ## section_id, section_name,
                                ## section_data: LoL with project_name, project_due, project_status

                                message("create_sections_list. For ", secs)

                                l <- lapply(secs, function(section_id) {
                                  sec_rec <- Sections$get(id=section_id, "closed", "class", "name")
                                  
                                  out <- list(section_id=section_id,
                                              section_name=sec_rec$name,
                                              active= section_id == secs[1]
                                              )

                                  

                                  projects <- Sections$get(section_id, "projects")
                                  due_dates <- Sections$get(section_id, "due_dates")

                                  
                                  out$section_data <- lapply(projects, function(project_id) {
                                    
                                    due <- due_dates[[project_id]] %||% ""
                                    proj_name <- Projects$get(id=project_id, "name")

                                    out <- list(project_name=proj_name,
                                                project_due=due,
                                                project_status=student_project_status(id, project_id)
                                                )
                                  })
                                  out
                                })
                                l
                              },
                              ## return logical if student can see project
                              can_see_project=function(student_id, project_id) {
                                if(!Projects$valid_id(project_id)) {
                                  message("no valid project by this id", project_id)
                                  return(FALSE)
                                }

                                public <- Projects$get(project_id, "public")
                                if(public) {
                                  return(TRUE)
                                } else {
                                  ## does this project belong to a student section
                                  secs <- get_sections(student_id)$open
                                  out <- any(sapply(secs, function(sec) {
                                    project_id %in% Sections$get(sec, "projects")
                                  }))
                                  return(out)
                                }

                              }




                              )
                            )
                            


##################################################
## Forms

##' return HTML formatted text for left panel of form
student_left_panel <- function(id) {

  options <- rbind(c("student", gettext("View work...")),
                   c("enroll", gettext("Enroll in section...")),
                   c("logout", gettext("Logout..."))
                   )
  
  options <- data.frame(url=options[,1],
                        label=options[,2],
                        stringsAsFactors=FALSE)
  options <- df_to_list(options)


  l <- merge_list(Auth$get(id=id),
                  list(options=options))

  tpl <- system.file("templates", "left_panel.html", package="questionr")
  show_form(tpl, l, fragment=TRUE)
}
