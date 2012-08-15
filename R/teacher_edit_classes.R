##' @include class.R
##' @include teachers.R
NULL


## this takes care of the post uploads
edit_classes_process_post <- function(p, user_id) {
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

      ## push project id onto classes
      Classes$push_j(p$class_id, "projects", pid)
      
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

## create new page using generic form
edit_classes_make_new_class <- function(...) {
  l <- list(
            title="Add a new class",
            small_title="A class defines a collection of projects",
            well="well",                # form class
            ## default handler needs ID and OBJ, calls rpc on edit
            ## can set a handler too, just define a set_value function
#            handler="var set_value=function(key, value) {alert(key + \":\" + value)};",
            ## keep track of what you have
            set_value=TRUE,
            handler="
items={}; // global?
var set_value = function(key, value) {
  console.log('set ' + key);
  items[key] = value;
};
",
            
            elements=list(
              list(id="name_new",
                   label="Name",
                   help="Name of the new class",
                   control=input_text(id="name_new",placeholder="")
                   ),
              list(id="school_new",
                   label="School",
                   help="Name of school",
                   control=input_text(id="school_new", placeholder="")
                   ),
              list(id="public_new",
                   label="Public",
                   help="A public class allows others to copy it to make sections",
                   control=input_checkbox(id="public_new", selected=FALSE)
                   ),
              list(id="new_submit",
                   label=NULL,
                   help=NULL,
                   control=input_button(id="button",
                     label="Submit",
                     type="primary",
                     icon_class="ok",
                     action=whisker.render('
function() {
if(typeof(items.name_new) == "undefined") {
   alert("We need a name for the class");
   return(false);
}
var name = items.name_new;
var school = items.school_new || "";
var public = items.public_new || false;
var owner = $.cookie("quizr_id");
var params = {name:name,school:school,public:public,owner:owner};
var success = function() {$.gritter.add({title:"New class was created", text:" ", time:1000});setTimeout(function() {window.location.reload()}, 1500);};
call_rpc("class", "new_record", params, success);
}
',
                       list(base_url=base_url))
                     )
                   )
              )
            )

  l$parent_selector <- "#new_class_tab "
  
  ## set a "handler" value to bypass script to send off values to a table
  tpl <-system.file("templates", "generic_form.html", package="questionr")

  show_form(tpl, l, fragment=TRUE)

}

## return list for template for a class
## loop over for all classes
make_class_list <- function(id,          # class id
                            user_id
                            ) {
  info <- Classes$get(id)
  
  l <- list(active = FALSE,             # override tomake active
            class_id=id,
            label=info$name,
            school=info$school,
            public=info$public,
            rows=list()
            )

  l$rows <- lapply(info$projects, function(project_id) {
    
    proj_info <- Projects$get(project_id)
    list(
         project_id=project_id,
         cells=list(
           list(label=input_text("name",
                  initial=proj_info$name)
                ),
           list(label=input_checkbox("public",
                  selected=proj_info$public)),
           list(label=input_text("keywords",
                  initial=paste(proj_info$keywords, collapse=", "),
                  placeholder="Comma separated values"
                  )
                )  
           )
         )
  })
  return(l)
} 

## Main form
## has means to
## a) select class to work on (tabs) or add a class
## b) for a class it
## i) lists projects allowing viewing/editing/deleting. Project order can be set via drag and dropping of the table rows.
## ii) button to add a new project
## iii) a form to edit basic class data
edit_classes <- function(request, ...) {
  user_id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=user_id)) {
    return(login_form(request))
  }

  ## This script handles post and non-post
  p <- request$POST()
  if(!is.null(p)) {
    return(edit_classes_process_post(p, user_id))
  } else {
    ## may have id passed in via get

    r <- request$GET()
    cur_class_id <- r$class_id
    if(is.null(cur_class_id))
      cur_class_id <- ""    
    if(!Classes$valid_id(cur_class_id))
      cur_class_id <- ""


    cur_classes <- Classes$filter(owner=user_id)
    
    class_ids <- names(cur_classes)
    if(length(class_ids) && !cur_class_id %in% class_ids )
      cur_class_id <- class_ids[1]
    classes <- lapply(class_ids, function(class_id) {
      message("make_class ", class_id)
      l <- make_class_list(class_id, user_id)
      l$active <- cur_class_id==class_id
      l
    })
    l <- list(classes=classes)

    ## add in drag and drop to table Could put in body, might make sense
    ready <- '
$(".dndtable").tableDnD({
  onDragClass:"dragging",
  onDrop: function(table, row) {
    var class_id = table.id;
    var new_order = [];
    var rows = table.tBodies[0].rows;
    $(rows).each(function() {new_order.push(this.id)});
    call_rpc("class", "rearrange_project_order",
             {owner:"XXX", class_id:class_id, new_order:new_order});
  }
});
'

    l$owner <- user_id
    l$CSS <- lapply(paste(getOption("questionr::static_url"), "/blueimp/css/",
                          c("jquery.fileupload-ui"), ".css", sep=""),
                    function(i) list(url=i))
    l$LEFT_PANEL=teacher_left_panel(user_id)
    
    l$NEW_CLASS_FORM <- edit_classes_make_new_class()
    l$new_class_active <- length(class_ids) == 0
    l$READY_SCRIPT ='$("#edit_classes").tab("show");'
    l$teacher_instructions <- "<strong>Edit Classes:</strong> A class defines a collection of projects that a section can clone. Classes are private, in which case only you can create sections from them, or public. The project order can be rearranged through drag and drop."
    
    tpl <- system.file("templates", "teacher_edit_classes.html", package="questionr")
    ti_tpl <- system.file("templates", "teacher_instructions.html", package="questionr")
    show_form(c(tpl, ti_tpl),  l)
  }
}    
