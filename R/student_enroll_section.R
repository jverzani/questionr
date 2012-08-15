##' @include students.R
NULL

## XXX DELET ME AND HTML template
## Basic form to enroll in a section
enroll_in_section <- function(request, ...) {
  message("enroll in section")
  
  user_id <- get_quizr_id(request)
  if(!Auth$is_student(id=user_id)) {
    return(login_form(request))
  }
  
  
  if(!is.null(request$POST())) {
    ## process post
    post <- get_post_from_raw(request)

    section_id <- post$section_id %||% post$public_section %||% NULL

    print(list("enroll in setion",
               post=post,
               section=section_id))
    
    if(is.null(section_id)) {
      stop("No section chosen!")
    }
    
    Sections$enroll_student_in_section(user_id, section_id)

    ## redirect by giving url
    return(getOption("questionr::base_url"))
    
    
  } else {
    ## make form
    public_sections <- Sections$filter(public=TRUE)
    l <- list(
              title="Enroll in a section",
              instructs="
<p>
  Use this form to enroll in a section. You can select a public section,
  or enter in a section ID that is given to you by a teacher. The teacher
  will need to authorize you to join the section.
</p>
",
              form_id="enroll_form",
              submit_action=form_action("enroll_form", "enroll"),
              LEFT_PANEL=student_left_panel(user_id),
              script='$("#enroll").tab("show");',
              
              ## form elements
              elements=list(
                list(id="section_id",
                     label="ID",
                     help="ID of the section",
                     control=input_text(id="section_id",placeholder="")
                     ),
                list(id="public_section",
                     label="Public sections",
                     help="Public sections allow anyone to enroll",
                     control=input_select("public_section",
                       values=names(public_sections),
                       labels=pluck(public_sections, "name")
                       )
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
    
    tpl <-system.file("templates", "generic_form.html", package="questionr")
    show_form(tpl, l)
  }
}


## Make form to enroll into a section
enroll_in_section1 <- function(request, ...) {
 user_id <- get_quizr_id(request)
  
 if(!Auth$is_student(id=user_id)) {
   return(login_form(request))
 }
 student_id <- user_id

 

 ## make sections list to populate comboboxes
 public <- Sections$filter(public=TRUE, closed=FALSE)
 private <- Sections$filter(public=FALSE, closed=FALSE)

 make_options <- function(rec) {
   l <- lapply(seq_along(rec$id), function(i) {
     list(value=as.character(rec$id[i]),
          label=sprintf("%s section %s, %s %s",
            rec$class[i],
            rec$name[i],
            rec$semester[i],
            rec$year[i]
            )
          )
   })
   if(length(l) == 0) {
     l <- list(value="XXX", label="No such sections")
   } else {
     l <- c(list(list(value="XXX", label="Select a section...")), l)
   }
   
   return(l)
 }
                
 
 sections <- list(list(id="section_public",
                       label="Public sections:",
                       options=make_options(public)
                       ),
                  list(id="section_private",
                       label="Private sections:",
                       options=make_options(private)
                       )
                  )

  tpl <- system.file("templates", "student_enroll_section.html", package="questionr")
  show_form(form=tpl,
            sections=sections)

}

section_enroll <- function(request, ...) {
  ## get info, then redirect
  user_id <- get_quizr_id(request)
  
  if(!Auth$is_student(id=user_id)) {
    return(login_form(request))
  }

  student_id <- user_id

  p <- request$POST()

  ## fish out of three places: section_direct, public, private
  section_id <- p$section_direct
        
  if(is.null(section_id) || nchar(section_id) == 0) {
    section_id <- p$section_public
    if(is.null(section_id) || section_id == "XXX") {
      section_id <- p$section_private
      if(is.null(section_id) || section_id == "XXX") {
        ## Nothing here!
        section_id <- "XXX"
      }
    }
  }

  Sections$enroll_student_in_section(student_id, section_id)
  
  response <- Rook:::Response$new()
  response$header("Content-Type", "application/json")
  response$write(toJSON(base_url))
  return(response)
}

