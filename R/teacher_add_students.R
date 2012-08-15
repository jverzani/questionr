##' @include teachers.R
NULL


## add students to course that have a request
teacher_add_students <- function(request, ...) {
  id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=id)) {
    return(login_form(request))
  }

  make_student_table <- function(sec_id) {
    force(sec_id)
    studs <- Sections$get(sec_id, "pending")
    sec_name <- Sections$get(sec_id, "name")
    
    l <- list(headers=list(
                list(label="Name"),
                list(label="Section"),
                list(label="Action")
                )
              )
    l$rows <- lapply(studs, function(stud_id, sec_id) {
      l <- list(row_id=NULL,
                cells=list(
                  list(label=Auth$get(stud_id, "name")),
                  list(label=sec_name),
                  list(label=whisker.render('
<a href="#" class="btn btn-success" onclick="enroll_student(this,\'{{sec_id}}\', \'{{stud_id}}\', \'accept\')"><i class="icon-ok icon-white"></i> accept</a>
&nbsp;
<a href="#" class="btn btn-warning" onclick="enroll_student(this,\'{{sec_id}}\', \'{{stud_id}}\', \'deny\')"><i class="icon-remove icon-white"></i> deny</a>
'))
                )
                )
      l
    }, sec_id=sec_id)

    tpl <-  system.file("templates", "table.html", package="questionr")
    show_form(tpl, l, fragment=TRUE)
  }
  
  list_students <- function(sec_id) {
    l <- list(tab_id=sec_id,
              label=Sections$get(sec_id, "name"),
              tab_content=make_student_table(sec_id)
              )
    

  }



  
  l <- list(title="Enroll students into a section")
  pending <- Teachers$get_pending_sections(id)


  if(length(pending) == 0) {
    l$small_title="You have no pending student requests"
  } else {
  
    l$tabs <- lapply(pending, list_students)
    ## l$js_files <- whisker.render('<script src="{{{static_url}}}/jquery-cookie/jquery.cookie.js"></script>', list(static_url=getOption("questionr::static_url")))
    l$script <- whisker.render('
var enroll_student=function(self, sec_id, stud_id, action) {
  var params = {section_id:sec_id, student_id:stud_id, action:action};
  var success = function() {$(self).parent().parent().remove();return(false)};
  call_rpc("section", "enroll_student", params, success);
  return(false);
}
', list(base_url=getOption("questionr::base_url")))
    if(length(l))
      l$tabs[[1]]$active=TRUE
    else
      print(list("HUH", l=l))
  }

  
  tpl <-system.file("templates", "generic_tabbable.html", package="questionr")
  
  l$LEFT_PANEL <- teacher_left_panel(id)
  l$READY_SCRIPT <- '$("#teacher_add_students").tab("show");'
  
  show_form(tpl,  l)
  
  
  
}

