##' @include teachers.R
NULL


## #### Grading functions

## ##
make_grade_choice <- function(prob_no, grade) {
  if(missing(grade) || is.null(grade) || is.na(grade) || length(grade) == 0) {
    radio(c(100, 80, 60, 40, 20, 0), horizontal=FALSE, selected=-1,
          id=sprintf("%s_grade_radio", prob_no),
          name=sprintf("%s_grade", prob_no)
          )
  } else {
    grade <- as.integer(grade)
    badge(str_pad(grade, 3), type=if(grade > 0) "info" else "warning")
  }
}

##################################################
## Grading forms

## different ways to write the answer
show_answer_comment <- function(prob, student_id, project_id) {
  ## dispatch on type
  prob$id <- sprintf("%s_comment", prob$problem)
  list(base_url=getOption("questionr::base_url"),
       student_id=student_id,
       project_id=project_id,
       prob_id=prob$problem)

  ## dispatch on type
  switch(prob$type,
         "free"=show_answer_free(prob),
         show_answer_default(prob)
         )
}

show_answer_default <- function(prob) {
  ## prob has type, answer, comment
  if(prob$type == "checkbox") {
    prob$answer <- paste(unlist(as.list(prob$answer)), collapse=", ")
  }

  ## debug
  if(prob$type == "free")
    return(show_answer_free(prob))
  
  tpl <- '
<form class="form-horizontal">
  <fieldset>
    <div class="control-group">
      <label class="control-label">Answer:</label>
      <div class="controls">{{{answer}}}</div>
    </div>
    <div class="control-group">
      <label class="control-label">Comment:</label>
      <div class="controls">{{{comment}}}</div>
    </div>
  </fieldset>
</form>
'

  tpl <- '
{{{answer}}}
<div class="alert">
  <button class="close" data-dismiss="alert">×</button>
  <strong>Comment:</strong> {{{comment}}}
</div>
'
  
  whisker.render(tpl, prob)
}

show_answer_free <- function(prob) {

  tpl <- '
<form class="form-horizontal">
  <fieldset>
    <div class="control-group">
      <label class="control-label">Answer:</label>
      <div class="controls">
      <div id="{{id}}_opencpu">
      <textarea class="input-xlarge" id="{{id}}_answer" cols=80, rows=3>{{{answer}}}</textarea>
     <a href="#{{problem}}" onclick="run_opencpu(\'{{id}}\');"><i class="icon-asterisk"></i>markdown</a>
      </div>

      </div>
    </div>
    <div class="control-group">
      <label class="control-label">Comment:</label>
      <div class="controls">
        <textarea class="comment_area input-xlarge" id="{{id}}" cols=80 rows=3>{{{comment}}}</textarea>
      </div>
    </div>
  </fieldset>
</form>
'
   whisker.render(tpl, prob)
}

teacher_grade_project <- function(request, ...) {


  id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=id)) 
    return(login_form(request))
  
  
  ## url is /teacher_grade_project/section_id/student_id/project_id
  pi <- strsplit( request$path_info(), "/")[[1]][-(1:2)]
  section_id <- pi[1]
  student_id <- pi[2]
  project_id <- pi[3]
  
  
  ## check if student in section class, project belong to student
  if(!Sections$valid_id(id=section_id))
    stop("Invalid section id")
  
  
  sections <- Teachers$get(id=id, "sections")
  sec_rec <- Sections$get(id=section_id, "students", "projects")

  if(!(section_id %in% sections))
    stop("Invalid section id")
  
  if(!(student_id %in% sec_rec$students))
    stop("Invalid student id")
  
  if(!(project_id %in% sec_rec$projects))
    stop("Invalid project id")
  
  ## okay, all okay. Now how to show?
  ans_id <- sprintf("%s:%s", student_id, project_id)
  stud_ans <- Answers$get(id=ans_id, "answers")
  stud_ans <- answers_sort(stud_ans)
  
  ## not all answers need grading.
  answers <- lapply(stud_ans, function(prob) {
    list(question_no=prob$problem,
         grade=make_grade_choice(prob$problem, as.numeric(prob$grade)),
         answer=show_answer_comment(prob, student_id, project_id)
         )
  })
  
  
  base_url <- getOption("questionr::base_url")
  context_url <- whisker.render("{{base_url}}/teacher_show_student_project/{{student_id}}/{{project_id}}")
  
  ## due date
  project_list <- Sections$list_projects(section_id)
  due_date <- Sections$get_due_date(section_id, project_id, id)

  
  submit_date <- Answers$get(id=ans_id, 'date')
  print(list("DEBUG", due_data=due_date, sub=submit_date))
  
  days_late <- NULL
  if(!is.null(due_date)) {
    delta <- as.numeric(submit_date - as.Date(due_date))
    days_late <- if(delta > 0) 
      badge(ngettext(delta, "1 day late", sprintf("%s days late",delta)), type="warning")
  }

  ## new grade
  tmp <- Filter(is.null, pluck(stud_ans, "grade"))
  if(length(tmp) == 0) {
    new_grade="{}"
  } else {
    new_grade=j(sapply(names(tmp), function(x) list(grade=NULL, comment=""), simplify=FALSE))$j
  }


  ## student_grade
  student_grade <- Answers$get(Answers$make_ans_id(student_id, project_id), "grade") %||% NULL

l <- list(context_url=context_url,
            student_photo=Auth$get(id=student_id, 'photo'),
            student_name=Auth$get(id=student_id, 'name'),
            project_name=Projects$get(id=project_id,'name'),
            section_name=Sections$get(section_id, "name"),
            submit_date=format(submit_date),
            due_date=due_date,
            days_late=days_late,
            answers=setNames(answers, NULL),
            student_grade=student_grade,
            new_grade=new_grade,
            student_id=student_id,
            project_id=project_id,
            section_id=section_id,
            LEFT_PANEL=teacher_left_panel(id),
            script='$("#teacher_grade_project").tab("show");',
            teacher_instructions="<strong>Grading a project:</strong> This form allows you to grade a project, should there be ungraded questions. Only the free response questions can be graded. For these one can run the student answer through knitr. For this, the student must use R-markdown syntax."
)
  tpl <-  system.file("templates", "teacher_grade_project.html", package="questionr")
 
}


teacher_save_grade <- function(request) {
  id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=id))
    return(login_form(request))


  post <- request$POST()
  student_id <- post$student_id
  project_id <- post$project_id
  section_id <- post$section_id
  new_grades <- fromj(post$new_grades)$x


  ## check if student in section class, project belong to student
  if(!Sections$valid_id(id=section_id))
    stop("Invalid section id")

  
  sections <-Teachers$get(id=id, "sections")

  if(!(section_id %in% sections))
    stop("Invalid section id")

  
  sec_rec <- Sections$get(id=section_id, "students", "projects")
  if(!(student_id %in% sec_rec$students))
    stop("Invalid student id")
  message("Student enrolled")
  
  if(!(project_id %in% sec_rec$projects))
    stop("Invalid project id")

  ## okay, all okay. no get answers
  ans_id <- sprintf("%s:%s", student_id, project_id)
  stud_ans <- Answers$get(id=ans_id, "answers")
  stud_ans <- answers_sort(stud_ans)

  ## merge in answers from new_grades
  for(i in names(new_grades)) {
    for(key in c("grade", "comment")) {
      stud_ans[[i]][[key]] <- new_grades[[i]][[key]]
    }
  }

  Answers$set(id=ans_id, answers=stud_ans, status="graded")
  
}



## SHow a student project. Doesn't include answers
teacher_show_student_project <- function(request, ...) {
  id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=id))
    return(login_form(request))
  

  ## url is /script/student_id/project_id
  pi <- strsplit( request$path_info(), "/")[[1]][-(1:2)]
  student_id <- pi[1]
  project_id <- pi[2]

  f <- make_project_html_student(project_id, student_id)
  return(file_to_string(f))

}

######################################################
