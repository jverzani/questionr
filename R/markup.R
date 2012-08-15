##' @include classes.R
NULL

## markup functions and classes

##' Use Bootstrap's pretty print of tables
##'
##' S3 generic to write a pretty table. At this point only a method
##' for data frames is written.
##' @param x object to dispatch on
##' @param opts options from "striped", "bordered", and "condensed".
##' @param ... ignored for now
##' @export
write_table <- function(x, opts, ...) UseMethod("write_table")

##' S3 method for data frames
##'
##' @rdname write_table
##' @method write_table data.frame
##' @S3method write_table data.frame
##' @export
write_table.data.frame <- function(x, opts=c("striped", "bordered", "condensed"), ...) {

  out <- sprintf('<table class="table %s"',
                 paste("table-", opts, sep="", collapse=" "))

  make_row <- function(x, tag="td") {
    sprintf("<tr>%s<tr>",
            paste(sprintf("<%s>", tag),
                  x,
                  sprintf("</%s>", tag),
                  sep="", collapse="")
            )
  }

  ## we need to make header row
  out <- c(out, paste("<thead>",
                      make_row(names(x), "th"),
                      "<tbody>",
                      paste(sapply(seq_len(nrow(x)), function(i) make_row(x[i,], "td")), collapse="\n"),
                      "</tbody>",                      
                      "</thead>",
                      sep="\n", collapse=""))
  out <- c(out, "</table>\n")

  paste(out, collapse="\n")

}

##' Make a label
##'
##' @param txt the text
##' @param type empty for the default, else specifies the class
##' @export
label <- function(txt, type=c("success", "warning", "important", "info", "inverse")) {
  sprintf("<span class='label %s'>%s</span>",
          ifelse(missing(type), "", paste("label-",type, sep="")),
          txt)
}


##' Make a dismissable label
##'
##' @param title title of label
##' @param txt HTML formatted text
##' @param type type of label
##' @export
alert <- function(title="", txt, type=c("block", "error", "success", "info")) {
  sprintf('
<div class="alert%s">
<a class="close" data-dismiss="alert" href="#">×</a>
<h4 class="alert-heading">%s</h4>
%s
</div>
', paste(" alert-", match.arg(type), sep=""), title, txt)
}
  
## badge

##' Make a badge
##'
##' Badges are typically numbered
##' @param txt the text, typically a number
##' @param type empty for the default, else specifies the class
##' @param id optional unique DOM id for object if wanting to adjust later
##' @export
badge <- function(txt, type=c("success", "warning", "important", "info", "inverse"), id) {
  sprintf("<span %s class='badge %s'>%s</span>",
          ifelse(missing(id), "", sprintf("id='%s'", id)),
          ifelse(missing(type), "", paste("badge-",type, sep="")),
          txt)
}

## some widgets
## @param x a vector, data frame
radio <- function(x, selected=1, horizontal=TRUE, id, name=id,  label=NULL, help=NULL) {
  if(is.vector(x)) {
    x <- data.frame(value=x, label=x, stringsAsFactors=FALSE)
  }
  if(is.matrix(x)) {
    if(ncol(x) == 0) stop("Need a column atleast")
    if(ncol(x) == 1) x[,2] <- x[,1]
    x <- data.frame(x, stringsAsFactors=FALSE)
  }
  if(is.data.frame(x)) {
    if(ncol(x) == 0) stop("Need a column at least")
    if(ncol(x) == 1) x[[2]] <- x[[1]]
  }
  x <- setNames(x[,1:2], c("value", "label"))

  tmp <- rep("", nrow(x))
  if(selected > 0)
    tmp[selected] <- 'checked="checked"'
  selected <- tmp

  vals <- lapply(seq_len(nrow(x)), function(i) as.list(x[i,]))
  rvals <- mapply(function(x, y) {x$selected <- y;x}, vals, selected, SIMPLIFY=FALSE)
  
  tpl <- system.file("templates", "radio.html", package="questionr")
  whisker.render(file_to_string(tpl),
                 list(label=label,
                      vertical=ifelse(horizontal, "", "<br />"),
                      id=id,
                      name=name,
                      radio=rvals,
                      help=help
                      ))
}


##' gritter is a growl like transient message
gritter <- function(title="",
                    text="",
                    time=NULL,
                    image=NULL) {
  l <- list(title=title, text=text, time=time, image=image)
  whisker.render("$.gritter.add({{{params}}});", list(params=toJSON(l)))
}

##################################################
## basic form controls for generic_form use
input_checkbox <- function(id=NULL,
                           name=id,
                           selected=TRUE,
                           onchange=NULL,
                           ...) {

  whisker.render('<input type="checkbox" {{#id}}id="{{id}}"{{/id}}  name="{{name}}" {{#selected}}checked{{/selected}} {{#onchange}}onchange="{{{onchange}}}"{{/onchange}}/>')

}

##' a radio button input
##' @param id DOM id
##' @param values values passed back
##' @param labels optional labels for values
##' @param initial integer index or one or matched against the values
##' @param collapse set to \code{"</br>"} to make vertical
input_radio <- function(id=NULL,
                        values,
                        labels=values,
                        initial=-1,
                        collapse="",
                        ...) {

  
  checked <- rep("", length=length(values))
  if(is.numeric(initial) && 1 <= initial && initial <= length(values))
    checked[as.integer(initial)] <- " checked"
  if(is.character(initial) && !is.na(idx <- match(initial, values)))
    checked[idx] <- " checked"
    
  paste(sprintf('<input type="radio" name="%s" value="%s" %s/>&nbsp;%s&nbsp;&nbsp;',
                id, values, checked, labels), collapse=collapse)
}

input_text <- function(id=NULL,
                       name=id,
                       initial=NULL,
                       placeholder=NULL,
                       typeahead=character(0),
                       onchange=NULL,
                       ...) {

  if(length(typeahead) > 0)
    typeahead <- toJSON(typeahead)

  whisker.render('<input type="text" id="{{id}}" name="{{name}}" {{#placeholder}}placeholder="{{{placeholder}}}"{{/placeholder}} {{#initial}}value="{{{initial}}}"{{/initial}} {{#typeahead}} data-provide="typeahead" data-items="8" data-source=\'{{{typeahead}}}\' {{/typeahead}}{{#onchange}}onchange="{{{onchange}}}"{{/onchange}}/>')

}


input_date <- function(id=NULL,
                       name=id,
                       initial=NULL,
                       onchange=NULL,
                       ...) {
  
  whisker.render('<input type="date" id="{{id}}" name="{{name}}" {{#initial}}value="{{initial}}"{{/initial}}{{#onchange}} onchange="{{{onchange}}}"{{/onchange}}/>')

}


input_select <- function(id=NULL,
                         name=id,
                         values,
                         labels=values,
                         initial=-1,
                         onchange=NULL,
                         ...) {

  values <- c("", values)
  if(!missing(labels))
    labels <- c(gettext("Select a value..."), labels)

  checked <- rep("", length=length(values))
  if(is.numeric(initial) && 1 <= initial && initial <= length(values))
    checked[as.integer(initial) + 1] <- " selected"
  if(is.character(initial) && !is.na(idx <- match(initial, values)))
    checked[idx] <- " checked"
  
  options <- paste(sprintf("<option value='%s' %s>%s</option>", values, checked, labels),
                   collapse="\n")
  whisker.render('<select {{#id}}id="{{id}}"{{/id}}{{#name}} name="{{name}}"{{/name}}{{#onchange}} onchange="{{{onchange}}}"{{/onchange}}>{{{options}}}</select>')
}

input_textarea <- function(id=NULL,
                           name=id,
                           initial="",
                           rows=3,
                           onchange=NULL,
                           ...) {

  tpl <- '
<textarea class="input-xlarge" {{#id}}id="{{id}}"{{/id}} name="{{name}}"{{#rows}} rows="{{rows}}"{{/rows}}{{#onchange}} onchange="{{{onchange}}}{{/onchange}}>{{initial}}</textarea>
'

  whisker.render(tpl)


}
                           


input_button <- function(id=NULL,
                         label="",
                         type=c("primary", "danger", "warning", "success", "info"),
                         icon_class=NULL,
                         submit=FALSE,
                         action=NULL,   # JavaScript call on click
                                        # function() {}
                         ...
                         ) {

  type <- paste(" btn-", match.arg(type), sep="")
  if(!is.null(icon_class))
    icon_class <- whisker.render('<i class="icon-{{icon_class}} icon-white"></i>')

  tpl <- '
<div class="btn-group">
<button {{#id}}id="{{id}}"{{/id}} {{#submit}}type="submit"{{/submit}} class="btn{{type}}">
{{{icon_class}}}
<span>{{{label}}}</span>
</button>
</div>  
{{#action}}  
<script>$("#{{id}}").click({{{action}}});</script>
{{/action}}
'
  
 whisker.render(tpl)
}

##' Create javascript for processing a form using serializeArray.
##'
##' The post require `get_post_from_raw(request)` to be read
##' properly. After processing POST request pass back url of next page.
##' @param form_id DOM id of form
##' @param script_name script name after base url
form_action <- function(form_id, script_name, success) {
  if(missing(success))
    success <- "function(data) {window.location.replace(data)}"
  tpl <- '
function() {
  var items={};
$($("#{{form_id}}").serializeArray()).each(function() {items[this.name] = this.value});
$.ajax({url:"{{{base_url}}}/{{{script_name}}}",
        type:"POST",
        contentType:"application/json",
        processData:false,
        data:JSON.stringify(items),
        success:{{{success}}}
       });
return(false)
}
'

  whisker.render(tpl,
                 list(base_url=getOption("questionr::base_url"),
                      success=success,
                      form_id=form_id,
                      script_name=script_name))

}
