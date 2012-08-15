##' @include tables.R
##' @include auth.R
##' @include markup.R
NULL

## table for requests to be a teacher
## goto url {{base_url}}/request_teacher_status to make a request
## admins are needed to approve

TeacherRequestTable <- setRefClass("TeacherRequestTable",
                                   contains="Table",
                                   fields=list(
                                     user_id="CharField",
                                     message="CharField",
                                     date="DateField"
                                     ),
                                   methods=list(
                                     initialize=function( ...) {

                                       nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "teacher_request_table.rds")
                                       callSuper(file=nm, ...)
                                     },
                                     has_requests=function() {
                                       nrow(..df) > 0
                                     },
                                     list_requests=function(id) {
                                       ## return list of requests
                                       ## suitable for use in template
                                       pluck(filter(), "user_id")
                                     },
                                     approve_request=function(id, user_id) {
                                       ## approve a request
                                       if(!Auth$is_admin(id))
                                         stop("Not an admin")

                                       if(!Auth$valid_id(user_id))
                                         stop("invalid user id")
                                       
                                       rec <- filter(user_id=user_id)
                                       if(rec$date + day(7) < today())
                                         stop("Not a timely request")

                                       ## all okay, add to auth table
                                       ## then leave a message
                                       remove(id)
                                       Auth$push_j(user_id, "roles")
                                       Messages$add_teacher_message(user_id,
                                                                    title="Welcome.",
                                                                    msg="Your request to be a teacher has been approved.",
                                                                    type="info")
                                       invisible()
                                     },
                                     deny_request=function(id, user_id) {
                                       ## deny a request
                                       if(!Auth$is_admin(id))
                                         stop("Not an admin")
                                       
                                       if(!Auth$valid_id(user_id))
                                         stop("invalid user id")
                                       
                                       rec <- filter(user_id=user_id)
                                       if(rec$date + day(7) < today())
                                         stop("Not a timely request")
                                       
                                       ## all okay, add to auth table
                                       ## then leave a message
                                       remove(id)
                                       Messages$add_student_message(user_id,
                                                                    title="Denied.",
                                                                    msg="Your request to be a teacher has been denied.",
                                                                    type="error")
                                     }
                                     
                                                                    
                                     ))


## forms

## simple form to request to be a teacher
request_teacher_status <- function(request, ...) {
  user_id <- get_quizr_id(request)
  if(!Auth$valid_id(user_id))
    stop("Invalid id")
  
  if(Auth$is_teacher(id=user_id)) {
##    stop("Already a teacher")
  }

  ## this does get and post
  p <- request$POST()
  if(!is.null(p)) {
    post <- get_post_from_raw(request)

    
    request_table <-  TeacherRequestTable$new()
    id <- request_table$new_record(user_id=user_id, message=post$msg)

    ## redirect to base by passing in URL
    return(sprintf("%s", base_url))
  } else {
    ## display form
    l <- list(
              set_value=FALSE,          # no JS written
              form_id="form",
              submit_action=form_action("form", "request_teacher_status"),
              title="Request to be a teacher",
              instructs="<p>To become a teacher, simply request it here. You will be notified by a message if your request is approved.</p>",
              elements=list(
                list(id="msg",
                     label="Message",
                     control=input_textarea(id="msg", rows=5)
                     ),
                list(id="submit_btn",
                     label=NULL, help=NULL,
                     control=input_button(id="submit_btn",
                       label="submit",
                       submit=TRUE,
                       icon_class="play"
                       )
                     )
                )
              )

#    l$LEFT_PANEL=teacher_left_panel(user_id)
    tpl <-  system.file("templates", "generic_form.html", package="questionr")
    show_form(tpl, l)
                     
  }

}

## form for approving teacher requests
approve_teacher_request <- function(request) {
  user_id <- get_quizr_id(request)
  if(!Auth$valid_id(user_id))
    stop("Invalid id")
  
  if(!Auth$is_admin(id=user_id)) {
    print("Not an admin")
   stop("You are not an admin")
  }

  request_table <- TeacherRequestTable$new()

  p <- request$POST()
  if(!is.null(p)) {
    post <- get_post_from_raw(request)

    
    ## we pass in an action and an id
    req_id <- post$request_id
    
    if(!request_table$valid_id(req_id))
      stop("Invalid request id")
    ## if(request_table$get(req_id, "date") + day(30) < today()) {
    ##   request_table$remove(req_id)
    ##   stop("Old request, denied")
    ## }
    
    id <- request_table$get(req_id, "user_id")
    if(!Auth$valid_id(id))
      stop("Invalid user id")
    if(!Auth$is_teacher(id))
      stop("Already a teacher")
    
    if(post$action == "deny") {
      ## deny
      msg <- "Your request to be a teacher was denied"
      type <- "error"
    } else {
      ## accept
      msg <- "Your request to be a teacher has been approved."
      type <- "info"
      Auth$push_j(id, "roles", "teacher")
      Teachers$new_record(id=id)
    }
    ## remove from request table
    request_table$remove(req_id)
    ## add message
    Messages$add_teacher_message(id,
                                 msg=msg,
                                 type=type)

    ## reload page
    return("#")
  } else {
    ## make a form
    reqs <- request_table$filter()
    make_row <- function(req_id) {
      user_id <- request_table$get(req_id, "user_id")
      msg <- request_table$get(req_id, "message")
      user_info <- Auth$get(user_id)
      l <- list(list(label=whisker.render("{{{photo}}} {{{name}}}", user_info)),
           list(label=msg),
           list(label=whisker.render('
<a class="btn" href="#" onclick="process_request(\'{{req_id}}\', \'deny\');false">
<i class="icon-remove"></i> deny</a>
&nbsp;
<a class="btn" href="#" onclick="process_request(\'{{req_id}}\', \'approve\');false">
<i class="icon-ok"></i> approve</a>
'))
           )
      list(cells=l)
    }
    
    l <- list(headers=list(
                list(label="User"),
                list(label="Request"),
                list(label="Action")
                ),
              rows=lapply(names(reqs), make_row)
              )

    l$script <- whisker.render('
var process_request = function(req_id, action) {
  $.ajax({url:"{{{base_url}}}/approve_teacher_request",
          type:"POST",
          contentType:"application/json",
          processData:false,
          data:JSON.stringify({action:action, request_id:req_id}),
          success:function(data) {window.location.reload()}
         });
  return(false);
};
', list(base_url=getOption("questionr::base_url")))

    
    l$LEFT_PANEL=teacher_left_panel(user_id)
    tpl <-  system.file("templates", "draggable-table.html", package="questionr")
    show_form(tpl, l)
  }
}
