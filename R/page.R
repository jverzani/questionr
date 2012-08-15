##' @include classes.R
NULL


## A method to set the answers. Should be used for grading
PAnswers <- setRefClass("PAnswers",
	               fields=list(
			problems="list"
		       ),
		       methods=list(
		       initialize=function(...) {
		         callSuper(...)
		       },
		       add_answer=function(type, id, value) {
   		         problems[[id]] <<- list(type=type, value=value)
		       },
                       write_answers = function() {
		         paste(toJSON(problems,collapse=""), collapse="\n")
                       }
		       ))

## A class to handle problem comments
Comments <- setRefClass("Comments",
                        fields=list(
                          comments="list"
                          ),
                        methods=list(
                          initialize=function(
                            missing="Missing answer",
                            correct="Correct answer",
                            incorrect="Incorrect answer",
                            ...) {
                            comments <<- list(
                                              missing=missing,
                                              correct=correct,
                                              incorrect=incorrect
                                              )
                            callSuper(...)
                          },
                          add = function(prob, lst) {
                            comments[[prob]] <<- lst
                          },
                          write = function() {
                            "Write JavaScript output"
                            paste("\n<script>comments=",
                                  toJSON(comments,collapse=""),
                                  ";</script>",
                                  sep="", collapse="")
                          }
                          ))


##' Main class for a page
##'
##' A page is setup by first defining the instance of this class. The
##' methods \code{write_header} and \code{write_footer} are the
##' bookends for a page. Within these, there are several methods for
##' specifying problem types:
##'
##' \code{new_problem} If \code{add_badge} is \code{TRUE} will place a
##' badge indicating the number of tries for a problem and a comment
##' area, otherwise places an icon.
##'
##' \code{radio_choice} To allow a selection of one from a few using radio buttons
##'
##' \code{checkgroup_choice} To allow a selection of one or more from
##' a few using checkbox buttons
##'
##' \code{combobox_choice} To allow a selection of one from many using a combobox
##'
##' \code{typeahead_choice} To allow a selection of one from many
##' using a entry box with typeahead enabled.
##'
##' \code{numeric_choice} To allow   single numeric value to be
##' selected, from within a range.
##'
##' These methods all have arguments:
##'
##' \code{comment} to leave a comment when the student is
##' wrong. Comments are specified using lists. For numeric values, the
##' components "less" and "more" are used to give a comment when the
##' student is below the range or above. For others, the components
##' are named to match the possible wrong answers. A default is given,
##' so you need not specify all of them.
##'
##' \code{hint} To have a hint popup when the user hovers near the
##' problem. The \code{...} argument allows one to pass a title to the
##' hint.
##'
##'
##' The methods also have wrapper functions which are documented.
##' 
##' The \code{grade_button} is used to allow the student to see their
##' current grade along with comments.
##'
##' The \code{grade_server_button} is used to send grades back to a server 
Page <- setRefClass("Page",
                    fields=list(
                      "ctr"="Ctr",
                      "answers"="PAnswers",
                      "comments"="Comments",
                      "queue"="Queue",
                      "instant_feedback"="logical",
                      "server"="logical" # use a server
                      ),
                    methods=list(
                      initialize=function(instant_feedback=TRUE,
                        server=TRUE, ...) {
                        initFields(instant_feedback=instant_feedback,
                                   server=server,
                                   ctr=Ctr$new(),
                                   answers=PAnswers$new(),
                                   comments=Comments$new()
                                   )
                        callSuper(...)
                      },
                      get_prob_id=function() sprintf("prob_%s", ctr$ct()),
                      get_next_prob_id=function() sprintf("prob_%s", ctr$ct() + 1),
                      write_header=function() {
                        ## the STUDENT_ID and PAGE_ID are filled in by whisker in a knit -> whisker.render -> markdownToHTML call
                        queue$push('
<script type="text/javascript"> 
var student_answers = {};
var comments = {missing:"Missing answer", correct:"Correct", incorrect:"Incorrect"};
var student_id = "{{{STUDENT_ID}}}";
var page_id = "{{{PAGE_ID}}}";
</script>
'
                                   )
                        queue$push(static="load_css.html",
                                   data=list(bootstrap_base_url=bootstrap_base_url))
                        queue$push(static="load_js.html",
                                   data=list(bootstrap_base_url=bootstrap_base_url))
                        queue$push("<div id='main_message'></div>")
                        queue$flush()
                      },
                      write_footer=function() {
                        queue$push("<div id='grade_alert'></div>")
                        queue$push("<script>")
                        queue$push(static="tabs-spy.js")
                        queue$push(static="comment.js")
                        queue$push(static="grader.js")
                        if(server)
                          queue$push(static="set_answers.js")
                        queue$push(static="grade_table.js")
                        ## get answers if on server, else save a call
                        if(server)
                          GET_ANSWERS <- whisker.render(file_to_string(system.file("static", "get_answers.js", package="questionr")),
                                                        list(
                                                             base_url=base_url,
                                                             msg="<b>This was already graded</b>, no more changes are possible."
                                                             
                                                             )
                                                        )
                        else
                          GET_ANSWERS <- NULL
                        ## on ready call. Here is one way to parameterize
                        queue$push(static="ready.js",
                                   data=list(GET_ANSWERS=GET_ANSWERS)
                                   )
                        
                        queue$push("</script>")
                        queue$push(write_answers())
                        queue$push(write_comments())
                        queue$flush()
                      },
                      ## @param title label for new problems
                      ## @param add_badge do we add a badge indicating tries
                      ## along with instant comments?
                      new_problem=function(title="New problem:", add_badge=instant_feedback) {
                        ## big difference if we add a badge:
                        ## * grading happens in real time
                        ## * comments updated each click

                        id <- get_next_prob_id()
                        if(add_badge) {
                          tpl <- '
<form class="form-inline">
  <fieldset> 
    <div class="control-group">
      <label class="control-label">{{{badge}}}&nbsp;{{{title}}}</label>
      <div class="controls">
        <p id="{{{help_id}}}" class="help-block">{{{help}}}</p>
      </div>
    </div>
  </fieldset>
</form>
'
                          label_id <- sprintf("%s_label", id)
                          help_id <- sprintf("%s_help",id)
                          badge <- sprintf("<span id='%s_badge' class='badge badge-info'>0 tries</span>", id)
                        } else {
                          tpl <- '
<form class="form-inline">
  <fieldset> 
    <div class="control-group">
      <label class="control-label"><i class="icon-certificate"></i>&nbsp;{{{title}}}</label>
      <div class="controls">
        <p id="{{{comment_id}}}" class="help-block">{{{help}}}</p>
      </div>
    </div>
  </fieldset>
</form>
'
                          comment_id <- sprintf("%s_comment", id)
                        }

                        queue$push(whisker.render(tpl))
                        queue$flush()
                      },
                      new_problem_with_badge=function(title="New problem:") {
                        tpl <- '
<form class="form-inline">
  <fieldset> 
    <div class="control-group">
      <label class="control-label">{{{badge}}}&nbsp;{{{title}}}</label>
      <div class="controls">
        <p id="{{{help_id}}}" class="help-block">{{{help}}}</p>
      </div>
    </div>
  </fieldset>
</form>
'
                        id <- get_next_prob_id()                        
                        label_id <- sprintf("%s_label", id)
                        help_id <- sprintf("%s_help",id)
                        badge <- sprintf("<span id='%s_badge' class='badge badge-info'>0 tries</span>", id)
                        ## return text, pushed onto queue in call
                        whisker.render(tpl)
                      },
                      ## problem types
                      radio_choice=function(x, value, inline=TRUE, linebreak=TRUE,  comment, hint, ...) {
                        x <- unique(x)
                        if(is.na(match(value, x))) stop("Bad answer for radio")

                        ctr$inc()	
                        prob_id <- get_prob_id()

                        answers$add_answer("radio", id=prob_id, value=value)
 
                        ## randomize
                        queue$push(sprintf("\n\n<fieldset><span id='%s'>", prob_id))

                        for(i in seq_along(x)) {
                          q_id <- sprintf("%s_%s", prob_id, i)
                          queue$push(sprintf("<label class='radio %s'><input type='radio' id='%s' class='%sXXX' name='%s' value='%s'>%s</label>",
                                             ifelse(inline, "inline",""), q_id, prob_id, prob_id, x[i],   x[i]))
 }

                        queue$push("</span></fieldset>")
                        if(linebreak) queue$push("<br/>")
 
                        if(!missing(hint)) hint(hint, prob_id, queue=queue,  ...)
                        if(!missing(comment)) comments$add(prob_id, comment)

                        queue$flush()
                      },
                      checkgroup_choice=function(x, value, inline=TRUE, linebreak=TRUE,  comment, hint, ...) {
                        if(!all(value %in% x))
                          stop("The value(s) must be elements of `x`")		  

                        ctr$inc()	
                        prob_id <- get_prob_id()

                        answers$add_answer("checkgroup", id=prob_id, value=I(value))

 
                        ## randomize  class='fieldset-auto-width'
                        queue$push(sprintf("\n\n<fieldset id='%s_fieldset'><span id='%s'>", prob_id, prob_id))
                        for(i in seq_along(x)) {
                          q_id <- sprintf("%s_%s", prob_id, i)
                          queue$push(sprintf("<label class='checkbox %s'><input type='checkbox' id='%s'  class='%s' name='%s' value='%s' />%s</label>",
                                             ifelse(inline, "inline",""), q_id, prob_id, prob_id, x[i], x[i]))
                        }
                        
                        queue$push("</span></fieldset>")
                        if(linebreak) queue$push("<br/>")
                        
                        if(!missing(hint)) hint(hint, prob_id, queue=queue,  ...)
                        if(!missing(comment)) comments$add(prob_id, comment)
                        
                        queue$flush()
                        
                      },
                      typeahead_choice=function(x, value, comment, hint, ...) {
                        x <- unique(x)
                        if(is.na(match(value, x))) stop("Bad choice")

                        ctr$inc()	
                        prob_id <- get_prob_id()
                        
                        answers$add_answer("typeahead", id=prob_id, value=value)
                        
                        ## use typeahead
                        queue$push(whisker.render("<input type='text' class='typeahead disabled' data-provide='typeahead' id='{{prob_id}}'>"))
                        queue$push(paste("\n<script>$('#",
                                         prob_id,
                                         "').typeahead({source:",
                                         toJSON(x),
                                         "});",
                                         "</script>\n",
                                         sep=""))
                        
                        ## add js
                        
                        if(!missing(hint)) hint(hint, prob_id, queue, ...)
                        if(!missing(comment)) comments$add(prob_id, comment)                        
                        queue$flush()
                        
                      },
                      combobox_choice=function(x, value, comment, hint, ...) {
                        x <- unique(x)
                        if(is.na(match(value, x))) stop("Bad choice")

                        ctr$inc()	
                        prob_id <- get_prob_id()

                        answers$add_answer("combobox", id=prob_id, value=value)




                      

                        options <- paste("\n\n<option value=''>Select one ...</option>\n\n",
                                         paste("<option value='", x, "'>",x,"</option>\n\n", sep="",collapse=""),
                                         sep="")

                        
                        queue$push(paste("<select class='combobox' id='",prob_id,"'>",options,"\n\n</select>\n\n", sep=""))
                        
                        if(!missing(hint)) hint(hint, prob_id, queue, ...)
                        if(!missing(comment)) comments$add(prob_id, comment)                        
                        queue$flush()
                      },
                      numeric_choice=function(x.lower, x.upper, digits, comment, hint, ...) {
                        ## in range (x.lower, x.upper) or within 2*10^-digits of x
                        if(missing(x.upper) && missing(digits))
                          x.upper = x.lower

                        if(missing(x.upper)) {
                          ## use digits
                          x.upper <- round(x.lower + 10^(-digits))
                          x.lower <- round(x.lower - 10^(-digits))
                        }

                        if(! as.numeric(x.lower) <= as.numeric(x.upper))
                          stop("Need to be <= relationship")
                        
                        ctr$inc()
                        prob_id <- get_prob_id()
                        answers$add_answer("numeric", id=prob_id, value=c(x.lower, x.upper))

                        ## student answer in range x.lower to x.upper is aok
                        queue$push(whisker.render("\n<input type='text' class='numeric_answer' id='{{prob_id}}'>\n"))
                        
                        if(!missing(hint)) hint(hint, prob_id, queue, ...)
                        if(!missing(comment)) comments$add(prob_id, comment)                        
                        queue$flush()
                      },
                      free_choice=function( hint, ...) {

                        ctr$inc()	
                        prob_id <- get_prob_id()

                        answers$add_answer("free", id=prob_id, value="null")

                        tpl <- '
<textarea class="free input-xlarge" id="{{id}}" rows=4 cols=80></textarea>
'
                        queue$push_whisker(tpl, id=prob_id)
                        if(!missing(hint)) hint(hint, prob_id, queue, ...)

                        queue$flush()
                      },
                      ##
                      write=function(txt, newline=TRUE) {
                        "Write a message to queue"
                        queue$push(whisker.render("{{#newline}}<br/>{{/newline}}{{txt}}"))
                        queue$flush()
                      },

                      ###
                      write_answers=function() {
                        tpl <- "<script>var actual_answers={{{ANSWERS}}};</script>"
                        ANSWERS <- answers$write_answers()
                        whisker.render(tpl)
                      },
                      write_comments=function() {
                        comments$write()
                      },
                      ##
                      grade_button=function() {
                        if(server) {
                          tpl <- '
<div class="btn-toolbar">
<button class="btn  btn-success" onclick="submit_work(\'saved\')">Save work</button>&nbsp;<button class="btn  btn-success" onclick="submit_work(\'submitted\')">Submit work</button>
</div>
'
                          out <- whisker.render(tpl)
                        } else {
                          tpl <- '
<br/>
<button class="btn  btn-success" onclick="write_grade_table()">Grade problems</button>
'
                          out <- whisker.render(tpl)
                        }
                        queue$push(out)
                        queue$flush()
                      },
                      grade_server_button=function(url) {
                        cat("XXX Write me")
                      }
                    ))
                      



## Tabs
##

Tabs <- setRefClass("Tabs",
                    contains="Ctr",
                    fields=list(
                      id="character",
                      queue="Queue"
                      ),
                    methods=list(
                      initialize=function(...) {
                        id <<- paste(sample(LETTERS, 10, TRUE), collapse="")
                        queue <<- Queue$new()
                        callSuper(...)
                      },
                      get_id=function() id,
                      write_header=function() {
                        queue$push(sprintf("<ul id='%s' class='nav nav-tabs'></ul>",
                                       get_id())
                                   )
                        ## We put in these bogus <span> tags as otherwise
                        ## the sundown parser handles the R code poorly within
                        ## the <div> tags. Go figure.
                       queue$push('<span><div class="tab-content">')
                       queue$flush()
                      },
                      write_footer=function() {
                        queue$push("</div></span>") ## close add()
                        queue$push("</div></span>") ## close write_header
                        queue$push("<hr/>")
                        queue$flush()
                      },
                      add=function(title) {
                        if(ct() > 0)
                          queue$push("</div></span>") ## close previous
                        inc()
                        queue$push(sprintf("\n<script>$('#%s').append(\"<li><a href='#tab_no_%s_%s'  data-toggle='tab'>%s</a></li>\");</script>",
                                           get_id(), id, ct(),  title)
                                   )
                        queue$push(sprintf('<span><div id="tab_no_%s_%s" class="tab-pane">', id, ct()))
                        queue$flush()
                      }
                      ))


NavBar <- setRefClass("NavBar",
                      fields=list(
                        nav="Ctr",
                        queue="Queue"
                        ),
                      methods=list(
                        initialize=function(...) {
                          nav <<- Ctr$new()
                          queue <<- Queue$new()
                          callSuper(...)
                        },
                        write_header=function(title, lead) {
                          "
Write the Navigation header.
@param title optional title for the page
@param lead optional sub title for the page
"
                          if(!missing(title))
                            queue$push(sprintf('<header class="jumbotron subhead"><h1>%s</h1>%s</header>',
                                               title,
                                               ifelse(missing(lead), "", sprintf("<p class='lead'>%s</p>",lead))
                                               ))

  
  
                          queue$push('
<span><div id="navbar" class="navbar  navbar-fixed-top"><div class="navbar-inner"><ul id="navbar-header" class="nav"></ul></div></div></span><span id="subnav"></span>
'
                                     )
                          queue$flush()
                        },
                        write_footer=function() {
## $('#navbar').scrollspy();
## $('body').attr('data-spy', 'scroll');
## $('[data-spy=\"scroll\"]').each(function () {
##   var $spy = $(this).scrollspy('refresh')
## });

                          tpl <- "
<script>
$('body').css('margin', '40px 10px');
//$('body').attr('data-offset','40');
//$('body').attr('data-target','#subnav');
$('body').attr('data-spy','scroll');
//$('[data-spy=\"scroll\"]').each(function () {
//   var $spy = $(this).scrollspy('refresh')
//});
</script>
"
                          ## 

                          queue$push(tpl)
                          queue$flush()
                        },
                        add=function(title, subhead, header=TRUE) {
                          "
Add a navigation anchor and optionally a header
@param title title for navigation bar and optionally the header
@param subhead if header is TRUE will add a subhead to the title
@param header if TRUE add a title to the page, not just the navigation bar
"
                          nav$inc()
  
                          queue$push(sprintf("\n<script>$('#navbar-header').append(\"<li><a href='#nav%s' target='_self'>%s</a></li>\");</script>", nav$ct(), title))
                          queue$push(sprintf('<span><div id="nav%s"></div></span>', nav$ct()))
                          ## if header, add to page
                          if(header)
                            queue$push(sprintf("<span><div class='page-header'><h2>%s%s</h2></div></span>",
                                               title,
                                               if(missing(subhead)) "" else sprintf("&nbsp;<small>%s</small>", subhead)
                                               ))
                          
                          queue$flush()
                        }
                       )) 
                        
navs <- Ctr$new(0L)

##' Add a navigation marker
##'
##' Adds a link in the top nav bar and an anchor in the file. Also can
##' add a header to the page.
##' @param title Name for link and possible header
##' @param subhead when \code{header=TRUE} add a sub heading in small
##' @param header if \code{TRUE} add a header to the page in addition to the anchor.
##' @export
add_nav <- function(title, subhead, header=TRUE) {
  queue <- Queue$new()
  navs$inc()
  
  queue$push(sprintf("\n<script>$('#navbar-header').append(\"<li><a href='#nav%s' target='_self'>%s</a></li>\");</script>", navs$ct(), title))
  if(header)
    queue$push(sprintf("<span><div class='page-header'><h1>%s%s</h1></div></span>",
                       title,
                       if(missing(subhead)) "" else sprintf("&nbsp;<small>%s</small>", subhead)
                       ))
  queue$push(sprintf('<span><div id="nav%s"></div></span>', navs$ct()))

  queue$flush("\n")
}

##' prepare HTML file for navigation header
##'
##' @param title optional title
##' @param lead optional subtitle (a lead)
##' @export
nav_header <- function(title, lead) {
  queue <- Queue$new()
  if(!missing(title))
    queue$push(sprintf('<header class="jumbotron subhead"><h1>%s</h1>%s</header>',
                       title,
                       ifelse(missing(lead), "", sprintf("<p class='lead'>%s</p>",lead))
                       ))

  
  
queue$push('
<span><div id="navbar" class="navbar  navbar-fixed-top"><div class="navbar-inner"><ul id="navbar-header" class="nav"></ul></div></div></span>
'
)
  queue$flush()
}

##' End navigation
##'
##' Placed at end of file after all the \code{add_nav} calls are done
##' @export
##' 
nav_footer <- function() {
 tpl <- "
<script>
$('#navbar').scrollspy();
$('body').attr('data-spy', 'scroll');
$('[data-spy=\"scroll\"]').each(function () {
  var $spy = $(this).scrollspy('refresh')
});
$('body').attr('data-offset','40');
$('body').css('margin', '40px 10px');
</script>
"
  tpl
}
