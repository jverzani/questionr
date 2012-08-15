##' @include teachers.R
NULL

## leave section(s) a message
teacher_leave_message <- function(request, ...) {
  id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=id)) {
    return(login_form(request))
  }

  p <- request$POST()
  if(!is.null(p)) {
    post <- get_post_from_raw(request)
    message("Leave message")
    
    ids <- Messages$add_student_message(post$users,
                                 title=post$message_title,
                                 type=post$message_type,
                                 msg=post$message
                                 )

    
    ## redirect to base
    message("redirect")
    getOption("questionr::base_url")
  } else {

    ## need to loop over sections, students in sections. Give means to select
    ## students to get the message or all
    message("make message form")

    ## this function makes the message instructions and form
    make_instructs <- function() {
      l <- list(form_id="submit_message_request",
                elements=list(
                  list(label="Message type",
                       control=input_select(id="message_type",
                         values=c("info", "success", "error"),
                         initial=1)
                       ),
                  list(label="Message title",
                       control=input_text(id="message_title",
                         placeholder="e.g. Attention:")
                       ),
                  list(label="Message",
                       help="The message to leave. Select recipients below.",
                       control=input_textarea(id="message")
                       ),
                  list(label=NULL, help=NULL,
                       control=input_button(submit=TRUE, label="Submit")
                       )
                  ),
                submit_action=whisker.render('
function() {
var users = []
$("td [type=\'checkbox\']").each(function() {if(this.checked) users.push(this.name)});
if(users.length == 0) {
  alert("Nobody is selected")
  return(false);
}
var data={users:users,
          message_title:$("#message_title").val(),
          message_type:$("#message_type").val(),
          message:$("#message").val()
          };
var success=function(data) {$.gritter.add({title:"Message sent", text:" ", time:1000});setTimeout(function() {window.location.replace(data)}, 1500);};


$.ajax({url:"{{{base_url}}}/teacher_leave_message",
          type:"POST",
          contentType:"application/json",
          data:JSON.stringify(data),
          success:success,
          error:function(data) {console.log(data)}
         });
 return(false);
}
', list(base_url=getOption("questionr::base_url")))
                )

      tpl <- system.file("templates", "generic_form.html", package="questionr")
      show_form(tpl, l, fragment=TRUE)
    }

    ## Now we make a list of all students by section
    make_section_list=function(sec_id) {
      make_tab_content <- function(sec_id) {
        if(!Sections$valid_id(sec_id))
          stop("Not a valid section id")

        ## headers
        l <- list(headers=list(
                    list(label=input_checkbox(id="select_all", selected=FALSE,
                           onchange="toggle_all(this);false")),
                    list(label="Name")
                    ))
        ## rows
        l$rows <- lapply(Sections$get(sec_id, "students"), function(stud_id) {
          if(!Auth$valid_id(stud_id))
            stop("Not a valid stduent id")

          student_name <- Auth$get(stud_id, "name")
          list(cells=list(
                 list(label=input_checkbox(selected=FALSE, name=stud_id)),
                 list(label=student_name)
                 )
               )
        })
        tpl <-  system.file("templates", "table.html", package="questionr")
        show_form(tpl, l, fragment=TRUE)
      }
    
      
      l <- list(tab_id=sec_id,
                label=Sections$get(sec_id, "name"),
                tab_content=make_tab_content(sec_id))
      l
    }

    
    cur_secs <- Teachers$get_sections(id=id)$open ## XXX not old

    l <- list(title="Send selected students a message",
              instructs=make_instructs())
    if(length(cur_secs)) {
      l$tabs <- lapply(cur_secs, make_section_list)
      l$tabs[[1]]$active=TRUE             # first tab
    }
              
  l$script <- '
var toggle_all = function(self) {
  var value = self.checked;
  $(self).parents("table").find("[type=\'checkbox\']").each(function() {this.checked=value})
};
'
  
    l$LEFT_PANEL <- teacher_left_panel(id)
    l$teacher_instructions="<strong>Leave messages for your students:</strong> This pages allows you to leave a section or students within a message that appears when they log on."

    tpl <- system.file("templates", "generic_tabbable.html", package="questionr")
    ti_tpl <- system.file("templates", "teacher_instructions.html", package="questionr")
    show_form(c(tpl, ti_tpl),  l)
  }

}

