##' @include tables.R
NULL

Messages <- NULL                        # instance of this Table set in zzz.R
MessagesTable <- setRefClass("MessagesTable",
                            contains="Table",
                             fields=list(
                               date="DateField",
                               type="CharField", # " alert-[info, success, error]"
                               title="CharField",
                               msg="CharField",
                               users="ArrayField"
                               ),
                             
                             methods=list(
                               initialize=function(...) {
                                
                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "message_table.rds")
                                callSuper(file=nm, ...)
                              },
                               add_student_message=function(user_id,
                                msg,
                                title="Attention:",
                                type=c("info", "success", "error")
                                ) {
                                if(!Auth$valid_id(user_id))
                                  stop("Invalid user id")
                                if(!Auth$is_student(user_id))
                                  stop("Not a student")

                                msg_id <- new_record(type=match.arg(type),
                                                     title=title,
                                                     msg=msg,
                                                     users=user_id)
                                add_students(msg_id, user_id)
                                msg_id
                              },
                              add_students=function(msg_id,  users) {
                                ## for students we keep message info in two places
                                ## add message to each student
                                sapply(users, function(student_id) {
                                  if(!Auth$is_student(student_id))
                                    stop("Not a student")
                                  Students$push_j(student_id, "messages", msg_id)
                                })

                                ## add student to message
                                Messages$push_j(msg_id, "users", users)
                              },
                              ## remove a student from the list
                              ## must also remove message id from user
                              remove_students=function(id, users) {
                                sapply(users, function(student_id) {
                                  Students$pop_j(student_id, "messages", id)
                                })

                                sapply(users, function(user) Messages$pop_j(id, "users", user))
                                if(length(get(id, "users")) == 0)
                                  remove(id)
                              },
                              add_teacher_message=function(
                                user_id,
                                msg,
                                title="Attention:",
                                type=c("info", "success", "error")
                                ) {
                                if(!Auth$valid_id(user_id))
                                  stop("Invalid user id")
                                if(!Auth$is_teacher(user_id))
                                  stop("Not a teacher")

                                msg_id <- new_record(type=match.arg(type),
                                                     title=title,
                                                     msg=msg,
                                                     users=user_id)
                                Teachers$push_j(user_id, "messages", msg_id)
                                msg_id
                              },
                               remove_teacher_message=function(msg_id) {
                                 if(!valid_id(msg_id))
                                   stop("Not a valid message id")
                                 
                                 user_id <- get(msg_id, "users")
                                 if(!Auth$is_teacher(user_id[1]))
                                   stop("Not a teacher's message")

                                 remove(msg_id)
                                 Teachers$pop_j(user_id, "messages", msg_id)
                                 invisible()
                               }
                                
                                
                                



                              )
                            )
       

##' AJAX function to delete message
##'
##' @param request request
##' @param ... dots
##' @export
delete_message <- function(request, ...) {
  quizr_id <- get_quizr_id(request)
  
  if(!Auth$is_student(id=quizr_id)) {
    return(login_form(request))
  }
  
  p <- request$POST()
  message_id <- p$id
  
  Messages$remove_students(id=message_id, users=quizr_id)

}
