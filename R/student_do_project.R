##' @include students.R
NULL

##' Show a project
##'
##' @param request Used to fish out student_ID;  page_ID in path info
##' @return web page
##' @export
show_project <- function(request, ...) {
  user_id <- get_quizr_id(request)
  
  if(!Auth$is_student(id=user_id)) {
    return(login_form(request))
  }

  
  student_id <- user_id
  project_id <- strsplit(request$path_info(), "/")[[1]][3] ## /, show_project, ID

  ## need to check if we can view project: public or in section
  if(Students$can_see_project(student_id, project_id)) {
    f <- make_project_html_student(project_id, student_id)
    return(file_to_string(f))
  } else {
    msg <- sprintf("You can't see this project %s", project_id)
  }
}



##' receive student answers
##'
##' AJAX callback
##' @param request
##' @param ...
##' @export
student_set_answers <- function(request, ...) {
  user_id <- get_quizr_id(request)
  
  if(!Auth$is_student(id=user_id)) {
    return(login_form(request))
  }

  ## $.post("http://localhost:9000/custom/quizr/set_answers", {answers:JSON.stringify(student_answers,status:"save|submit"), project_id:page_id});
  p <- request$POST()

  project_id <- p$project_id
  status <- p$status
  grade <- ""        # fill in if graded

  print(list("set_answers",
             p = p,
             can_see=Students$can_see_project(user_id, project_id)
             ))


  ## now check if this is a valid project, then set
  if(Students$can_see_project(user_id, project_id)) {
    answers <- fromj(p$answers)$x                  # as JSON, using JSON.stringify

    
    ## compute status and grade if a submit
    if(status == "submitted") {
      grades <- compute_grade(answers)
      if(grades$all_graded) {
        status <- "graded"
      } 
      grade <- as.character(grades$grade)
    }
    
    ans_id <- Answers$make_ans_id(user_id, project_id)
    if(Answers$valid_id(ans_id)) {
      message("update record")
      Answers$set(id=ans_id,
                  status=status,
                  date=format(today()),
                  grade=grade,
                  answers=answers)
    } else {
      ## new answer
      message("new answer record")
      Answers$new_record(
                         student_id=user_id,
                         project_id=project_id,
                         date=format(today()),
                         status=status,
                         grade=grade,
                         answers=answers
                         )
    }
  }

  message("all done")

  
  response <- Rook:::Response$new()
  response

}



##' receive student answers
##'
##' AJAX callback
##' @param request
##' @param ...
##' @export
student_get_answers <- function(request, ...) {
  user_id <- get_quizr_id(request)
  
  if(!Auth$is_student(id=user_id)) {
    return(login_form(request))
  }

  ## $.post({url:"http://localhost:9000/custom/quizr/get_answers", data:{project_id:page_id}, success=function(data) {}});
  p <- request$POST()

  project_id <- p$project_id

  
  ## now check if this is a valid project, if so return
  if(Students$can_see_project(user_id, project_id) &&
     Answers$valid_id2(user_id, project_id)) {
    ans_id <- Answers$make_ans_id(user_id, project_id)
    rec <- Answers$get(ans_id, "answers", "status", "grade")
    
    answers <- rec$answers
    status <- rec$status
    grade <- rec$grade
    
    ## pass back object with status and answers 
    out <- list(status=status, grade=grade, answers=answers)
    
  } else {
    out <- list(status="error", answers=NULL)
  }

  response <- Rook:::Response$new()
  response$header("Content-Type", "application/json")
  response$write(j(out)$j)
  return(response)
}

