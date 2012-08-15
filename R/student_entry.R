##' @include students.R
NULL

##' Create entry page for students
##'
##' @param request request
##' @export
student <- function(request, ...) {
  ## should id in request
  
  user_id <- get_quizr_id(request)
  if(!Auth$is_student(user_id)) {
    return(login_form(request))
  }
  
  
  ## pick section if need be
  ## else view projects

  ## messages?
  msg_ids <- Students$get(user_id, "messages")
  if(length(msg_ids) == 0) {
    messages <- NULL
  } else {
    messages <- lapply(msg_ids, function(msg_id) {
      Messages$get(id=msg_id, "id", "date", "type", "title", "msg")
    })
  }

  ## sections
  secs <- Students$get_sections(user_id)$open
  sections <- Students$create_sections_list(user_id, secs)

  ## make form
  l <- list(sections=sections,
            messages=messages,
            LEFT_PANEL=student_left_panel(user_id),
            script=whisker.render('
  $("#student").tab("show");
  $(".alert").alert();
  $(".alert").bind("closed", function () {
    $.ajax({type:"post",url:"{{{base_url}}}/message", data:{id:this.id} });
  });
'
              
              )
            )
  
  tpl <- system.file("templates", "student_entry.html", package="questionr")
  show_form(form=tpl, l)

}

