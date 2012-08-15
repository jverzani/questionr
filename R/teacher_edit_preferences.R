##' @include teachers.R
NULL

##################################################

teacher_preferences <- function(request, ...) {
 user_id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=user_id)) {
    return(login_form(request))
  }

 l <- list(
            title="Edit preferences",
            well="well",                # form class
            form_id="edit_preferences",
            elements=list(
              ## For variety, we use local storage for storing whether
              ## help blurbs should be shown
              list(id="show_help",
                   label="Show help",
                   help="Toggle the display of help blurbs",
                   control=input_checkbox(id="show_help",
                     onchange="localStorage.show_teacher_instructions=this.checked;")
                   )
              )
            )


 ## add in code to check help preference as appropriate
 l$READY_SCRIPT <- '
var tmp = localStorage.getItem("show_teacher_instructions");
$("#show_help")[0].checked = typeof(tmp) == "undefined" || tmp == "true";
$("#teacher_preferences").tab("show");
'
 l$LEFT_PANEL=teacher_left_panel(user_id)
 

 
  tpl <-system.file("templates", "generic_form.html", package="questionr")
  show_form(tpl, l)

}
