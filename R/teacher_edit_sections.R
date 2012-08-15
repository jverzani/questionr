##' @include teachers.R
NULL

##################################################
## edit sections

## process post, redirect to teacher_edit_sections
teacher_new_section <- function(request) {
  user_id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=user_id)) {
    return(login_form(request))
  }

  p <- get_post_from_raw(request)
  ## major fudge
  if(is.null(p$public))
    p$public <- FALSE
  if(is.null(p$closed))
    p$closed <- FALSE
  p$owner <- user_id
  
  ## make a new section
  ## need to have a name, semester, year, class, public optional
  section_id <- do.call(Sections$new_record, p)
  Teachers$push_j(user_id, "sections", section_id)
  if(!is.null(class_id <- p$class)) {
    if(! (Classes$get(class_id, "public") ||
          user_id == Classes$get(class_id, "owner"))
       )
      stop("Not able to copy class projects.")
           
    ## get projects from the class; set class field
    class_projects <- Classes$get(class_id, "projects")
    ## clone them if allowed (public or owner)
    new_project_ids <- sapply(class_projects, Projects$clone, owner=Classes$get(class_id, "owner"), user_id=user_id)
    Sections$set(section_id, projects=setNames(new_project_ids, NULL))
  }
  
  ## return url for redirect
  sprintf("%s/teacher_edit_sections", base_url)
}

## process post for editing of sections: new file, ...
edit_sections_process_post <- function(p, user_id) {
      ## handler post request, return JSON
    response <- Response$new()
    response$header("Content-Type", "application/json")

    
    filename <- p$`files[]`$filename
    path <- p$`files[]`$tempfile
    content_type <- p$`files[]`$content_type
    ## check for errors
    if(is.null(filename)) {
      error <- "No file uploaded"
      icon <- "icon-remove"
    } else if(!(file_extension <- tools:::file_ext(filename)
                %in% c("Rmd", "rmd", "md"))) {
      error_tpl <- "
Wrong file type. You needed to upload a R markdown file (Rmd, rmd, md). You
uploaded one of type {{file_extension}}."
      
      error <- whisker.render(error_tpl)
      icon <- "icon-remove"
    } else {
      ## create new project
      pid <- Projects$new_record(author=user_id,
                                 date=today(),
                                 name=p$description,
                                 public=p$public
                                 )
      Projects$set_file(path, pid)
      icon <- "icon-ok"
      error <- NULL

      ## push project id onto sections
      Sections$push_j(p$section_id, "projects", pid)
      
      l <- list(url="",
                thumbnail_url = icon,
                name=filename,
                type=content_type,
                size=file.info(filename)$size,
                delete_url="",
                delete_type="POST",
                valid=TRUE,
                error=error)
      
      response$body <- sprintf("[%s]",toJSON(l))
    }

    return(response)
}    

## generic form for gathering info to make a new section
edit_sections_make_new_section <- function(user_id, ...) {
  poss_classes <- Classes$possible_classes(user_id)
  
  l <- list(
            title="Add a new section",
            small_title="A section has collection of projects and students",
            well="well",                # form class
            form_id="new_section",
            submit_action=form_action("new_section", "teacher_new_section",
              success='
function(data) {
  $.gritter.add({title:"New class was created", text:" ", time:1000});
   setTimeout(function()  {window.location.replace(data)}, 1500);
}
'
              ),
            elements=list(
              list(id="name",
                   label="Name",
                   help="Name of the new section",
                   control=input_text(id="name",placeholder="")
                   ),
              list(id="semester",
                   label="Semester",
                   help="Semester of section",
                   control=input_text(id="semester", placeholder="")
                   ),
              list(id="year",
                   label="Year",
                   help="Year section to run",
                   control=input_text(id="year", placeholder=format(year(now())))
                   ),
              list(id="class",
                   label="Class",
                   help="Select a class to inherit projects from that class",
                   control=input_select(
                     id="class",
                     values=poss_classes[,'id'],
                     labels=poss_classes[,'name']
                     )
                   ),
              list(id="public",
                   label="Public",
                   help="A public section allows students to enroll without authorization",
                   control=input_checkbox(id="public", selected=FALSE)
                   ),
              list(id="submit",
                   label=NULL,
                   help=NULL,
                   control=input_button(
                     id="submit",
                     label="Submit",
                     type="primary",
                     submit=TRUE,
                     icon_class="ok"
                     )
                   )
              )
            )

  l$parent_selector <- "#new_section_tab "

  tpl <-system.file("templates", "generic_form.html", package="questionr")
  show_form(tpl, l, fragment=TRUE)

}

## return list for template for a class
## loop over for all sections
make_section_list <- function(id,          # section id
                            user_id
                            ) {
  info <- Sections$get(id)
  
  l <- list(active = FALSE,             # override tomake active
            section_id=id,
            label=info$name,
            semester=info$semester,
            year=info$year,
            public=info$public,
            rows=list()
            )

  due_dates <- Sections$get_due_dates(id)
  l$rows <- lapply(info$projects, function(project_id, section_id, user_id) {

    proj_info <- Projects$get(project_id)
    list(
         project_id=project_id,
         cells=list(
           list(label=input_text("name",
                  initial=proj_info$name,
                  onchange=whisker.render("call_rpc('project','set_name', {project_id:'{{project_id}}', value:$(this).val()})")
                  )
                ),
           ## due dates
           list(label=input_date("due_date",
                  initial=due_dates[[project_id]],
                  onchange=whisker.render("call_rpc('section','set_due_date', {section_id:'{{section_id}}',project_id:'{{project_id}}', value:$(this).val()})")
                  ))
           )
         )
  }, user_id=user_id, section_id=id)
  return(l)
} 

## Main form
## has means to
## a) select class to work on (tabs) or add a class
## b) for a class it
## i) lists projects allowing viewing/editing/deleting. Project order can be set via drag and dropping of the table rows.
## ii) button to add a new project
## iii) a form to edit basic class data
teacher_edit_sections <- function(request, ...) {
  user_id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=user_id)) {
    return(login_form(request))
  }

  ## This script handles post and non-post
  p <- request$POST()
  if(!is.null(p)) {
    return(edit_sections_process_post(p, user_id))
  } else {
    ## may have id passed in via get

    r <- request$GET()
    cur_section_id <- r$section_id
    if(is.null(cur_section_id))
      cur_section_id <- ""    
    if(!Sections$valid_id(cur_section_id))
      cur_section_id <- ""


    cur_sections <- Sections$filter(owner=user_id, closed=FALSE)
    
    section_ids <- names(cur_sections)
    if(length(section_ids) && !cur_section_id %in% section_ids )
      cur_section_id <- section_ids[1]
    sections <- lapply(section_ids, function(section_id) {
      message("make_section ", section_id)
      l <- make_section_list(section_id, user_id)
      l$active <- cur_section_id==section_id
      l
    })
    l <- list(sections=sections)


    l$owner <- user_id
    l$CSS <- lapply(paste(getOption("questionr::static_url"), "/blueimp/css/",
                          c("jquery.fileupload-ui"), ".css", sep=""),
                    function(i) list(url=i))
    l$LEFT_PANEL=teacher_left_panel(user_id)
    l$NEW_SECTION_FORM <- edit_sections_make_new_section(user_id)
    l$new_section_active <- length(section_ids) == 0
    l$READY_SCRIPT ='$("#teacher_edit_sections").tab("show");'
    l$teacher_instructions = "<strong>Edit sections:</strong> A section is primarily a collection of projects and students. This form allows you to edit a project, reorder a project (by drag and drop), remove a project, or add a project to a section. As well, you can create a new section or close an existing section."
    tpl <- system.file("templates", "teacher_edit_sections.html", package="questionr")
    ti_tpl <- system.file("templates", "teacher_instructions.html", package="questionr")
    show_form(c(tpl, ti_tpl),  l)

  }
}    

