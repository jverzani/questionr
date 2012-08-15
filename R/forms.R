## forms

##' @include auth.R
##' @include utils.R
NULL


get_quizr_id <- function(request, ...) {
  ## get ID or return NULL
  id <- request$cookies()[["quizr_id", exact=TRUE]]
  id
}


##' show a form
##'
##' @param form is template
##' @param .l if second argument is a list use that instead of ...
##' @param ... passed to \code{whisker.render} to populate template
##' @param script optional javascript to add to form
##' @param fragment if \code{TRUE} do not wrap in header and footer.
##' @return a character object with the form template
##' sandwiched between the header and footer text.
##' @export
show_form <- function(form, .l, ..., script, fragment=FALSE) {
  ## how to make a form

  if(!fragment) {
    head_tpl <- system.file("templates", "html_header.html", package="questionr")
    foot_tpl <- system.file("templates", "html_footer.html", package="questionr")
    tpl <- file_to_string(head_tpl, form, foot_tpl)
  } else {
    tpl <- file_to_string(form)
  }

  ## the parameters
  if(missing(.l))
    params <- list(...)
  else
    params <- .l

  if(!missing(script))
    params$READY_SCRIPT <- script

  ## add defaults by hand...
  params$BRANDING <- BRANDING
  if(is.null(params$PAGE_TITLE))
    params$PAGE_TITLE <- PAGE_TITLE_DEFAULT
  
  params$base_url <- getOption("questionr::base_url")
  params$static_url <- getOption("questionr::static_url")
  params$bootstrap_base_url <- getOption("questionr::bootstrap_base_url")
  
  out <- whisker.render(tpl, params)

  return(out) 

}


##' A template form, not used
##'
##' Match pu with a) router in quizr.R, b) a template
##' @param request values
##' @return web form
##' @export
show_basic <- function(request, ...) {
  tpl <- system.file("templates", "test.html", package="questionr")
  LEFT_PANEL <- "left side here"

  show_form(form=tpl, LEFT_PANEL=LEFT_PANEL)
}

## example of generic form use
generic_example <- function(...) {
  ## we need a list
  l <- list(
            title="title",
            small_title="optional smaller title",
            well="well",                # form class
            ## default handler needs ID and OBJ, calls rpc on edit
            set_value=TRUE,   # add JavaScript to call set_value
            submit_handler=FALSE,       # JavaSCript call on submit
            handler=NULL,               # define set_value function (key, value)
            ID="NROEELXWSC",            # which record to edit
            OBJ="answer",               # which Table to call, see rpc
            ## can set a handler too, just define a set_value function
#            handler="var set_value=function(key, value) {alert(key + \":\" + value)};",
            ## keep track of what you have
#A            handler="
#items={}; // global?
#var set_value = function(key, value) {items[key] = value};
#",

            elements=list(
         list(id="checkbox",
              label="checkbox label",
              help="Toggle state",
              control=input_checkbox(id="checkbox",
                selected=TRUE, button_label="Yes")
              ),
         list(id="radio",
              label="radio label",
              help="Select one of a few",
              control=input_radio(id="radio",
                state.name[1:3], initial=1)
              ),
         list(id="text",
              label="text label",
              help="Enter a value",
              control=input_text(id="text",
                placeholder="Select a state",
                typeahead=state.name)
              ),
         list(id="date",
              label="date label",
              help="Enter a date",
              control=input_date(id="date")
              ),
         list(id="combobox",
              label="comobobox label",
              help="Select a value",
              control=input_select(id="combobox",
                values=state.name,
                labels=toupper(state.name),
                initial=1)
              ),
              list(id="button",
                   label=NULL,
                   help=NULL,
                   control=input_button(id="button",
                     label="hello?",
                     type="primary",
                     icon_class="ok",
                     action="function() {alert(this.value + 'hello world')}"
                     )
                   )

         )
       )
  ## set a "handler" value to bypass script to send off values to a table
  tpl <-system.file("templates", "generic_form.html", package="questionr")
  show_form(tpl, l)
}

generic_tabbable_example <- function(request, ...) {
  l <- list(
            title="tabbable form",
            small_title="some subhead",
            pills=TRUE, well=TRUE,
            handler="var set_value=function(id, key, value) {alert(id + \":\" + key + \":\" + value)};",
            tabs=list(
              list(tab_id="TabID",
                   label="Section label",
                   active=" active",
                   class_active=" class=\"active\"",
                   elements=list(id="checkbox",
                     label="checkbox label",
                     help="Toggle state",
                     control=input_checkbox(id="checkbox",
                       selected=TRUE, button_label="Yes")
                     ),
                   list(id="radio",
                        label="radio label",
                        help="Select one of a few",
                        control=input_radio(id="radio",
                          state.name[1:3], initial=1)
                        )
                   ),
              list(tab_id="Tab_id_1",
                   label="another tabl",
                   active="",
                   class_active="",
                   elements=list(id="checkbox",
                     label="checkbox label",
                     help="Toggle state",
                     control=input_checkbox(id="checkbox",
                       selected=TRUE, button_label="Yes")
                     ),
                   list(id="radio",
                        label="radio label",
                        help="Select one of a few",
                        control=input_radio(id="radio",
                          state.name[1:3], initial=1)
                        )
                   )
                   )
            )
  
  ## set a "handler" value to bypass script to send off values to a table
  tpl <-system.file("templates", "generic_tabbable_form.html", package="questionr")
  show_form(tpl, l)
}

draggable_table <- function(request, ...) {
  "Demo of draggable table"
  print("Draggable table")

  ## use rownames for row ids, colnames for table header
  df_to_list <- function(df, table_id, col_headers=names(df)) {
    row_ids <- rownames(df)
    l <- list(table_id=table_id)
    l$headers <- lapply(col_headers, function(nm) list(label=nm))
    l$rows <- lapply(seq_len(nrow(df)), function(i) {
      l1 <- list(row_id=row_ids[i])
      l1$cells <- sapply(seq_along(df[i,]), function(j) {
        list(label=as.character(df[i,j]))
      }, simplify=FALSE, USE.NAMES=FALSE)
      #names(l1$cells) <- NULL
      l1
    })
    l
  }

  l <- df_to_list(mtcars[1:3, 1:4], "myid")

  
  l1 <- list(table_id="MyTable",
            headers=list(
              list(label="Label 1"),
              list(label="Label 2")
              ),
            rows=list(
              list(row_id="row 1",
                   cells=list(
                     list(label="cell 1"),
                     list(label="cell 2")
                     )),
              list(row_id="row 2",
                   cells=list(
                     list(label="cell 1 row 2"),
                     list(label="cell 2 row 2")
                     ))
              )
            )

  tpl <- system.file("templates", "draggable-table.html", package="questionr")

 
##  l$READY_SCRIPT <- whisker.render('$("#{{table_id}}").tableDnD();', l)
ready <- '
$("#{{table_id}}").tableDnD({
  onDragClass:"dragging",
  onDrop: function(table, row) {
    var new_order = [];
    var rows = table.tBodies[0].rows;
    $(rows).each(function() {new_order.push(this.id)});
    alert("we have a new order:" + new_order);
  }


});
'

  l$READY_SCRIPT <- whisker.render(ready, l)

  
  show_form(form=tpl, l)

}
##' welcome_form
##'
##' @param request request
##' @export
welcome_form <- function(request, ...) {
  tpl <- system.file("templates", "welcome.html", package="questionr")

  show_form(form=tpl, base_url=base_url)
}

## redirect to base url
redirect_to_base <- function() {
  response <- Response$new()
  response$redirect(sprintf("%s", getOption("questionr::base_url")))
  response        
}

testing_123 <- function(request, ...) {
  ##
  l1 <- list(table_id="tab1",
             headers=list(
               list(label=input_checkbox(id="select_all",
                             onchange="toggle_all(this);false")),
               list(label="Name")
               ),
             rows=list(
               list(row_id="row 1",
                    cells=list(
                      list(label=input_checkbox(id="11")
                           ),
                      list(label="John Verzani")
                      )
                    ),
               list(row_id="row 2",
                    cells=list(
                      list(label=input_checkbox(id="21")),
                      list(label="Jane S.")
                      )
                    )
               )
             )


  
  tpl <-  system.file("templates", "table.html", package="questionr")
  



  

  
  l <- list(title="Select students to send a message",
            instructs="Select messages: textarea",
            tabs=list(
              list(tab_id="tab1",
                   label="label 1",
                   tab_content=whisker.render(file_to_string(tpl), l1)
                   ),
              list(tab_id="tab2",
                   label="label 2",
                   active=TRUE,
                   tab_content=whisker.render(file_to_string(tpl), l1)
                   )
              )
            )

              
  l$script <- '
var toggle_all = function(self) {
  var value = self.checked;
  $(self).parents("table").find("[type=\'checkbox\']").each(function() {this.checked=value})
}
'
  
  tpl <- system.file("templates", "generic_tabbable.html", package="questionr")
  show_form(form=tpl, l)
}

## testing file upload
testing_upload <- function(request, ...) {
  

  
  ## we upload files
  p <- request$POST()
  if(!is.null(p)) {
    print("UPload files")
    print(p)
    filename <- p$`files[]`$filename
    fname <- p$`files[]`$tempfile
    content_type <- p$`files[]`$content_type
    description <- p$example
    
    response <- Response$new()
    response$header("Content-Type", "application/json")

    if(is.null(filename)) {
      response$status <- 400L
      response$body <- ""
    } else {
      ## process download file
      if(tools:::file_ext(filename) %in% c("Rmd", "rmd", "md")) {
        error <- NULL
        icon <- "icon-ok"
      } else {
        error <- sprintf("Wrong file type. Need Rmd, rmd, or md file. Your uploade %s",
                      tools:::file_ext(filename))
        icon <- "icon-remove"
      }
    
      l <- list(url="http://localhost/url",
                thumbnail_url = icon,
                name=filename,
                type=content_type,
                size=file.info(filename)$size,
                delete_url="deleteme/",
                delete_type="POST",
                valid=TRUE,
                error=error)
      response$body <- sprintf("[%s]",toJSON(l))
    }
    return(response)
  } else {
    
    tpl <- system.file("templates", "upload_template.html", package="questionr")

    show_form(form=tpl, base_url=base_url,
              CSS=lapply(paste(static_url, "/blueimp/css/",
                c("style", "jquery.fileupload-ui"), ".css", sep=""),
                function(i) list(url=i)))
  }
}
