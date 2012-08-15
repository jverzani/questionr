##' @include tables.R
##' @include auth.R
##' @include class.R
NULL


Sections <- NULL                        # instance of this Table set in zzz.R
SectionsTable <- setRefClass("SectionsTable",
                            contains="Table",
                             fields=list(
                               owner="CharField", # auth table
                               name="CharField",
                               semester="CharField",
                               year="CharField",
                               class="CharField", # class id
                               public="BooleanField",   # logical: "yes" || "no"
                               closed="BooleanField",  # logical: "yes" || "no"
                               projects="ArrayField", # project IDs, json
                               due_dates="ListField", # due dates, "YYYY-mm-dd" keyed by project name
                               students="ArrayField", # student IDs, json
                               pending="ArrayField"
                               ),
                             methods=list(
                              initialize=function(...) {

                            
                                
                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "section_table.rds")
                                callSuper(file=nm, ...)
                              },
                              is_closed=function(id) {
                                get(id, "closed")
                              },
                              is_current = function(id) {
                                "Is this a current section?"
                                if(!valid_id(id))
                                  stop("Invalid id")
  
                                sem <- lookup_semester()
                                yr <- lookup_year()
  
                                rec <- get(id=id, "semester", "year")

                                rec$semester == sem && rec$year == yr

                              },
                               check_permissions=function(section_id, owner) {
                                  if(!valid_id(section_id))
                                    stop("Invalid id")
                                  if(!Auth$is_teacher(owner))
                                    stop("Invalid teacher id")
                                  if(owner != get(section_id, "owner"))
                                    stop("Invalid owner")
                                },
                               ## basic properties, called via rpc
                               set_name=function(section_id, user_id, value) {
                                 check_permissions(section_id, user_id)
                                 set(section_id, name=value)
                               },
                               set_year=function(section_id, user_id, value) {
                                 check_permissions(section_id, user_id)
                                 set(section_id, year= as.numeric(value))
                               },
                               set_semester=function(section_id, user_id, value) {
                                 check_permissions(section_id, user_id)
                                 set(section_id, semester=value)
                               },
                               ## Projects
                              list_projects=function(id) {
                                "list projects in sectino along with due dates"
                                if(!valid_id(id))
                                  stop("Invalid id")

                               
                                projs <- get(id=id, 'projects')
                                due <- get(id=id, 'due_dates')
  
                                ## are due same length as projects? If not, we pad by "None"
                                if(length(due) < length(projs))
                                  due <- c(due, rep("None",length(projs) - length(due) ))
                                
                                list(projects=projs, due_dates=due)
                              },
                               new_project=function(user_id, section_id) {
                                 check_permissions(section_id, user_id)

                                message("new project")
                                ## make anew project, then push onto projects
                                project_id <- Projects$new_record(name="Fill me in",
                                                                  author=user_id,
                                                                  public=FALSE,
                                                                  keywords="")
                                push_j(section_id, "projects", project_id)
                                return(project_id)
                               },
                               upload_project=function(user_id, section_id, project_id) {
                                 check_permissions(section_id, user_id)
                               
                                 
                                if(missing(project_id) || is.null(project_id)) {
                                  ## new add to class, make new project
                                  message("new project")
                                  project_id <- new_project(user_id, section_id)
                                }
                                
                                message("replace project via upload")
                                p <- request$POST()
                                path <- p$`files[]`$tempfile
                                fname <- p$`files[]`$filename
                                content_type <- p$`files[]`$content_type
                                
                                ## check if fname matches Rmd, md, ...
                                
                                Projects$set_file(path, project_id)
                              },
                               delete_project=function(section_id, project_id, user_id) {
                                 check_permissions(section_id, user_id)
                                 pop_j(section_id, "projects", project_id)
                               },
                               rearrange_project_order=function(section_id, new_order, user_id) {
                                 "rearrange order if the all match"
                                 message("Rerrange order")
                                 
                                 ## XXX should check that owner has permissions...
                                 check_permissions(section_id, user_id)
                                 old_order <- get(section_id, "projects")
                                 if(length(old_order) == length(new_order) &&
                                    all(sort(old_order) == sort(new_order))) {
                                   set(section_id, projects=new_order)
                                   return("")
                                 } else {
                                   stop("Unable to rearrange order")
                                 }
                              },
                               ## Students
                              enroll_student_in_section = function(student_id, section_id) {
                                "Enroll student if public or place in queue for approval. Add message"

                                msg <- ""
                                if(!Sections$valid_id(section_id)) {
                                  ## valid section?
                                  msg <- "<h4>Enrollment request denied.</h4> Invalid section id"
                                } else {
                                  rec <- Sections$get(id=section_id, "students", "name", "class", "public", "pending")
                                  cur_students <- rec$students

                                  if(student_id %in% cur_students) {
                                    msg <- sprintf("<h4>Enrollment request denied.</h4> You are already enrolled in  section %s",
                                                   rec$name)

                                  } else if(rec$public) {
                                    Students$student_add_section(id=student_id, section_id=section_id)
                                    msg <- sprintf("You were enrolled in %s section %s",
                                                   rec$name)
                                  } else {
                                    msg <- sprintf("Enrollment request for section %s has been made.",
                                                   rec$name)
                                    
                                    
                                    pend <- unique(c(rec$pending, student_id))
                                    Sections$set(id=section_id, pending=pend)
                                  }
                                }

                              
                                Messages$add_student_message(student_id,
                                                             title="Attention",
                                                             msg=msg,
                                                             type="info")
                                
                              },
                               enroll_student=function(section_id, user_id, student_id, action=c("accept","deny")) {
                                 message("enroll student")
                                         
                                 check_permissions(section_id, user_id)
                                 action <- match.arg(action);
                                 
                                 pop_j(section_id, "pending", student_id)

                                 if(action == "deny") {
                                   msg <- sprintf("Your request to enroll in section %s has been denied", get(section_id, "name"))
                                 } else {
                                   msg <- sprintf("Your request to enroll in section %s has been approved", get(section_id, "name"))
                                   ## add to list of students in sectin
                                   push_j(section_id, "students", student_id)
                                   ## add to student list
                                   Students$push_j(student_id, "sections", section_id)
                                 }
                                 Messages$add_student_message(student_id,
                                                              msg = msg,
                                                              type=if(action == "deny") "error" else "success")
                                 
                                 
                                 
                               },
                               ## due dates
                               get_due_dates=function(section_id) {
                                 ## coerce to Date class
                                 dates <- get(section_id, "due_dates")
                                 sapply(dates, as.Date, simplify=FALSE) # as.list
                               },
                               set_due_dates=function(section_id, dates) {
                                 dates <- sapply(dates, format, simplify=FALSE)
                                 print(list("set dates", dates))
                                 set(section_id, due_dates=dates)
                               },
                               get_due_date = function(section_id, project_id, user_id) {
                                 "Return Date object or NULL"
                                 check_permissions(section_id, user_id)
                                 get_due_dates(section_id)[[project_id]]
                               },
                               set_due_date = function(section_id, project_id, user_id, value) {
                                 check_permissions(section_id, user_id)
                                 dates <- get_due_dates(section_id)
                                 print(list(old_dates=dates))
                                 dates[[project_id]] <- as.Date(value)
                                 print(list(new_dates=dates))
                                 
                                 set_due_dates(section_id, dates)
                               },
                               ## sections
                              close_section=function(section_id, user_id) {
                                check_permissions(section_id, user_id)
                                set(section_id, closed=TRUE)
                              }



                              )
                            )
                            


lookup_semester <- function() {
  mo <- month(now())
  if(mo < 6)
    "Spring"
  else if(mo < 8)
    "Summer"
  else
    "Fall"
}
lookup_year <- function() {
  format(year(now()))
}
  
