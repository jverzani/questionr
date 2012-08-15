##' Make this a rook app
##'
##' To use this on Rhttpd$new(app_name="this", filename="that")
##' @param env env passed in by Rook
##' @return a list with components status, headers, body
##' 
app <- function(env) {

  request <- Request$new(env)
  status <- 200L

  ## Login is a bit convoluted.
  ##
  ## once authenticated, a cookie "quizr_id" is set, though this is checked
  ## to see if it is still valid. If authenticated, the requested script
  ## is served, or the default script for the users role.
  ## 
  ## If authenticating, then this script processes a POST requistion with a
  ## `token`. This is sent to janrain for confirmation. If that is successful, then
  ## the script redirects
  ##
  ## If unauthenticated, a user gets the welcome page.

  ## this is a ID (Possibly invalid), "", "null", or NULL
  quizr_id <- request$cookies()$quizr_id

  if(is.null(quizr_id) || quizr_id == "null" ||
     nchar(quizr_id) == 0
     ) {
    ## Not logged in, but we could be in the process. We are if
    ## we have a login token and it is apost
    if(request$post() && !is.null(token <- request$POST()$token)) {
      out <- login_janrain(request, token)
      ## out has status, msg, quizr_id and redirect
      if(out$status == 200) {
        ## all good, set cookie for next time and redirect. Use Utils to set path
        response <- Response$new()
        Rook:::Utils$set_cookie_header(response$headers,"quizr_id", out$quizr_id,
                                       path="/")
        response$redirect(sprintf("%s/%s", questionr:::base_url, out$redirect))
        return(response$finish())
      } else {
        ## show message, redirect... XXX What to do here
        print(list("Houston...", out=out))
        response <- Response$new(status=200L)
        response$write("XXX replace me, couldn't log on")
        return(response$finish())
      }
    } else {
      ## Show unauthenticated pages:
      ## welcome_form
      ## login_form
      if(grepl("login_form", request$path_info()))
        out <- login_form(request)
      else
        out <- welcome_form(request)
      response <- Response$new(status=status)
      response$write(out)
      return(response$finish())
    }

    
  }


  if(!questionr:::Auth$valid_id(quizr_id))
    return(logout_form(request)$finish())


  ## are we running rapache?
  if(exists("POST")) {
#    message("POST")
#    print(POST)
#    saveRDS(POST(), "/tmp/post.rds")
    saveRDS(request, "/tmp/request.rds")
  }


  
  
  ## Okay, now we do things base on path.info
  path <- request$path_info()
  router <- list("test"="testing_123",
                 "generic"="generic_example",
                 "generic_tabbable"="generic_tabbable_example",
                 "draggable_table"="draggable_table",
                 
                 "login_form"="login_form",
                 "login"="login_janrain",
                 "logout"="logout_form",
                 "show_project"="show_project",
                 "show_basic"="show_basic",
                 "rpc"="rpc",
                 ## admin
                 
                 "approve_teacher_request"="approve_teacher_request",
                 ## professor
                 "teacher"="teacher",
                 "teacher_save_grade"="teacher_save_grade",
                 "teacher_grade_project"="teacher_grade_project",
                 "teacher_show_student_project"="teacher_show_student_project",
                 "teacher_add_project"="teacher_add_project",
                 "teacher_view_project"="teacher_view_project",
                 "teacher_edit_project"="teacher_edit_project_in_browser",
                 "teacher_download_project"="download_project",
                 "teacher_edit_sections"="teacher_edit_sections",
                 "teacher_new_section"="teacher_new_section",
                 "edit_classes"="edit_classes",
                 "teacher_add_students"= "teacher_add_students",
                 "teacher_leave_message"="teacher_leave_message",
                 "teacher_preferences"="teacher_preferences",
                 ## student
                 "student"="student",
                 "set_answers"="student_set_answers",
                 "get_answers"="student_get_answers", # AJAX
                 "delete_message"="delete_message",
                 "enroll"="enroll_in_section",
                 "request_teacher_status"="request_teacher_status",
                 "section_enroll"="section_enroll" # process request
                 )
                    
  ## find the url or do default. Should do lookup hash, but hey
  i <- 1
  while(i <= length(router)) {
    nm <- names(router)[i]
    if(grepl(sprintf("^/%s/", nm), paste(path,"/", sep=""))) {
      f <- getFromNamespace(router[[i]], ns="questionr")
      ##
      out <- try(f(request), silent=TRUE)
      break()
    }
    i <- i + 1
  }
  if(i > length(router)) {
    ## do the default base on role
    if(questionr:::Auth$is_teacher(quizr_id))
      out <- try(getFromNamespace("teacher", ns="questionr")(request), silent=TRUE)
    else if(questionr:::Auth$is_student(quizr_id))
      out <- try(getFromNamespace("student", ns="questionr")(request), silent=TRUE)
    else
      out <- try(getFromNamespace("welcome_form", ns="questionr")(request), silent=TRUE)
  } 

  ## response of a form can be a Rook "Response" object, try-error or character string

  if(is(out, "Response")) {
    out$finish()
  } else if(inherits(out, "try-error")) {
    err_msg <- attr(out, "condition")$message
    response <- Response$new(status=400L)
    response$write(whisker.render("Error: {{{err_msg}}}"))
    response$finish()
    
  } else {
    response <- Response$new(status=status)
    response$write(out)
    response$finish()
  }
}


