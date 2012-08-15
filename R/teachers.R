##' @include tables.R
##' @include auth.R
##' @include markup.R
NULL

Teachers <- NULL                        # instance of this Table set in zzz.R
TeachersTable <- setRefClass("TeachersTable",
                            contains="Table",
                             fields=list(
                               sections="ArrayField",
                               messages="ArrayField"
                               ),
                            methods=list(
                              initialize=function(...) {

                               
                                
                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "teacher_table.rds")
                                callSuper(file=nm, ...)
                              },
                              ##
                              get_sectionsXXX=function(id) {
                                "Get list os section split by old and current"
                                if(!Auth$is_teacher(id))
                                  stop("Invalid id")

                                secs <- get(id, "sections")
                                ans <- sapply(secs, function(sec) {
                                  Sections$is_current(sec)
                                })
                                ans <- c("old", "current")[1 + ans]
                                l <- split(secs, ans)
                              },
                              get_sections=function(id) {
                                "Get list of sections split by closed, not"
                                secs <- get(id, "sections")
                                if(length(secs) == 0)
                                  return(list(closed=character(0),
                                                open=character(0)))
                                
                                out <- lapply(secs, function(section_id) {
                                  Sections$get(section_id, "id", "closed")
                                })
                                ids <- pluck(out, "id")
                                closed <- pluck(out, "closed")
                                list(closed=ids[closed],
                                     open=ids[!closed])

                              },
                              student_by_project = function(sec_id) {
                                "make a data frame of students in row, project in column"

                                
                                if(!Sections$valid_id(sec_id)) 
                                  stop(sprintf("Invalid section %s", sec_id))
                                
                                sec_rec <- Sections$get(id=sec_id, "projects", "students")
                                projects <- sec_rec$projects
                                students <- sec_rec$students

                                
                                ## piece together column by column
                                student_names <- sapply(students, function(student_id) {
                                  Auth$get(id=student_id, "name")
                                })
                                
                                project_values <- lapply(projects, function(project_id) {
                                  sapply(students, function(student_id) {
                                    pid <- project_id                 # force pid for whisker.render scope
                                    base_url <- getOption(questionr:::base_url)
                                    answer_id <- sprintf("%s:%s", student_id, project_id)
                                    if(!Answers$valid_id(answer_id))
                                      return("Not started")
                                    
                                    status <- Answers$get(id=answer_id, "status")
                                    grade <- compute_grade(Answers$get(id=answer_id, "answers"))$grade
                                    icon <- answer_icon(status)
                                    if(grade != "")
                                      whisker.render("<a href='{{{base_url}}}/teacher_grade_project/{{section_id}}/{{student_id}}/{{pid}}/' onclick='window.open(this.href); return false;'>{{grade}}</a>",
                                                     list(base_url=getOption("questionr::base_url"),
                                                          section_id=sec_id,
                                                          pid=project_id,
                                                          student_id=student_id,
                                                          grade=grade)
                                                     )
                                    else if(status == "submitted")
                                      whisker.render("<a href='{{{base_url}}}/teacher_grade_project/{{section_id}}/{{student_id}}/{{pid}}/'><i class='{{icon}}'></i></a>",
                                                     list(base_url=base_url,
                                                          section_id=sec_id,                            
                                                          pid=project_id,
                                                          student_id=student_id)
                                                     )
                                    else
                                      whisker.render("<i class='{{icon}}'></i>")
                                  })
                                })
                                
                                m <- cbind(student_names, do.call(cbind, project_values))
                                df <- data.frame(m, stringsAsFactors=FALSE)
                                nms <- sprintf("<a href=fillMeIn?%s>P. %s</a>", seq_along(project_values),seq_along(project_values))
                                setNames(df, c("Student", nms))
                              },
                              new_section=function(user_id,
                                name="",
                                semester=lookup_semester(),
                                year=lookup_year(),
                                class=NULL,
                                public=FALSE) {
                                "Create a new section, return the id"

                                if(!Auth$is_teacher(user_id))
                                  stop("Not authorized")
                                message("new section")
                                print(list(closed=closed, public=public))
                                
                                if(!is.null(class) && nchar(class) == 0)
                                  class=""

                                sec_id <- Sections$new_record(owner=user_id,
                                                              name=name,
                                                              semester=semester,
                                                              year=year,
                                                              class=class,
                                                              public=public,
                                                              closed=FALSE)
                                ## return new section id
                                return(sec_id)
                              },
                              has_pending=function(id) {
                                ## return TRUE if there are pending students
                                length(get_pending_sections(id)) > 0
                              },
                              get_pending_sections=function(id) {
                                ## return section ids of sections with pending students
                                secs <- get_sections(id)
#                                cur_secs <- secs$current
                                ## XXX
 #                               cur_secs <- secs$old
                                cur_secs <- secs$open
                                has_pending <- function(section_id)
                                  length(Sections$get(section_id, "pending")) > 0
                                
                                Filter(has_pending, cur_secs)
                              }                              
                              )
                             )

  
##################################################
##
## Forms


##' return HTML formatted text for left panel of form
teacher_left_panel <- function(user_id) {
  if(!Auth$is_teacher(user_id))
    stop("Not a teacher")
  
  ## teacher options
  options <- rbind(c("teacher", gettext("View sections...")),
                   c("teacher_edit_sections", gettext("Edit sections..."))
                   )
  if(Teachers$has_pending(user_id)) 
    options <- rbind(options,
                     c("teacher_add_students", gettext("Enroll students..."))
                     )
  options <- rbind(options,
                   c("edit_classes", gettext("Edit classes...")),
                   c("teacher_leave_message", gettext("Leave messages...")),
                   c("teacher_preferences", gettext("Edit preferences...")),
                   c("logout", gettext("Logout..."))
                   )
  ## admin requests
  if(Auth$is_admin(user_id)) {
    if(TeacherRequestTable$new()$has_requests())
      options <- rbind(options, c("approve_teacher_request", gettext("Approve teachers")))
  }
                           
  
  options <- data.frame(url=options[,1],
                        label=options[,2],
                        stringsAsFactors=FALSE)
  options <- lapply(seq_len(nrow(options)), function(i) options[i,])
  l <- merge_list(Auth$get(id=user_id),
                  list(options=options))

  tpl <- system.file("templates", "left_panel.html", package="questionr")
  show_form(tpl, l, fragment=TRUE)
}

## teacher_select_section <- function(request, ...) {
##   user_id <- get_quizr_id(request)
##   if(!Auth$is_teacher(user_id))
##     return(login_form(request))

##   if(request$section) {
##     cur_secs <- request$section ## really from a post request
##   } else {
##     secs <- Teachers$get_sections(id=user_id)
##     cur_secs <- secs$current
##   }
  
##   ## make a list avail_sections with class, section_id, section_name
##   avail_sections <- sapply(cur_secs, function(sec) {
##     rec <- Sections$get(id=sec, "class", "name")
    
##     list(class=Classes$get(id=rec$class,'name'),
##          section_id=sec,
##          section_name=rec$name
##          )
##   }, simplify=FALSE)
  
  
##   tpl <-  system.file("templates", "teacher_select_section.html", package="questionr")
##   whisker.render(tpl, 
##                  avail_section=avail_sections,
##                  base_url=base_url
##                  )

## }


teacher_view_project <- function(request, ...) {
  id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=id)) {
    return(login_form(request))
  }

  r <- request$GET()
  project_id <- r$project_id
  fname <- Projects$view_project(project_id)
  file_to_string(fname)
}


