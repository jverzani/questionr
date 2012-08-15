##' @include teachers.R
NULL

##' Create entry page for teachers
##'
##' @param request request
##' @export
teacher <- function(request, ...) {

  user_id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=user_id)) 
    return(login_form(request))

  ## any messages
  msgs <- Teachers$get(id=user_id, "messages")
  messages <- sapply(msgs, function(msg_id) {
    Messages$get(id=msg_id, "id", "type", "title", "msg")
  }, simplify=FALSE, USE.NAMES=FALSE)


  
  ## make sections list
  cur_secs <- Teachers$get_sections(user_id)$open
  sections <- lapply(cur_secs, function(section_id) {
    rec <- Sections$get(id=section_id, "class", "name")
    names(rec)[2] <- "section_name"
    rec$section_id <- section_id
    rec$stuff <- write_table(Teachers$student_by_project(section_id))
    rec
  })

  if(length(sections)) {
    sections[[1]]$active <- TRUE
  }

l <- list(
          sections=sections,
          messages=messages,
          has_pending= Teachers$has_pending(user_id),
          more_than_one_section=ifelse(length(cur_secs) > 1, "s", ""),
          TITLE="Our title",
          LEFT_PANEL=teacher_left_panel(user_id),
          READY_SCRIPT ='
$("#teacher").tab("show");
$(".alert-block").bind("closed", function () {
  call_rpc("message", "remove_teacher_message",
           {msg_id: $(this).attr("data-alertid")});
})
'
          )
  l$teacher_instructions <- "<strong>View a section:</strong> This page shows your open sections and the students in them for grading. Pages open in a new tab."

  tpl <- system.file("templates", "teacher_entry.html", package="questionr")
  ti_tpl <- system.file("templates", "teacher_instructions.html", package="questionr")
  show_form(c(tpl, ti_tpl),  l)
}
