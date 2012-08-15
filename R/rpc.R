## rpc

##' Call a method
##'
##' @param obj object (Reference class)
##' @param meth method name
##' @param params list of argument
##' @param request httpd request object passed into environment of call
call_ref_meth <- function(obj, meth, params, request) {
  ## print(list(
  ##            "call ref",
  ##            obj=class(obj),
  ##            meth=meth,
  ##            params=params))
  
  if(exists(meth, obj, inherits=FALSE))
    f <- get(meth, obj)
  else
    f <- methods:::envRefInferField(obj, meth, getClass(class(obj), obj))

  ## shove request into environment
  e <- environment(f)
  e$request <- request
  
  ## call
  if(is.null(params) || length(params) == 0)
    out <- f()
  else
    out <- do.call(f, params)
  out
}

## an rpc all returns JSON
rpc <- function(request, ...) {
  ## rpc *for now* is only for teachers
  user_id <- get_quizr_id(request)
  if(!Auth$is_teacher(id=user_id)) {
    return(login_form(request))
  }

  message("Call rpc")
  
  ## default return values, modified during this script
  status <- 200L
  out <- I(NULL)
  error <- "null"
  

  ## pass in params like
  ## {obj:'answer', method:'get_value', params:JSON.stringify({x:'1',y:'2'}), id:'fred"}

  ## DEBUG assign("tmp", request, .GlobalEnv)

  ## we actually parse post differently if it is multipart (file upload)
  ## or not, as POST() doesn't reliably de-JSONify data
  if(request$media_type() == "multipart/form-data") {
    p <- request$POST()
    if(!is.null(p$params))
      params <- try(as.list(fromJSON(p$params)), silent=TRUE)
    else
      params <- NULL
    
    if(inherits(params, "try-error"))
      params <- as.list(fromJSON(utils::URLdecode(p$params)))

  } else {
    p <- get_post_from_raw(request)
    params <- as.list(p$params)
  }

  ## add in user_id to params
  params$user_id <- user_id
  
  ## need to lookup object
  obj <- p$obj                          # character
  meth <- p$method
  

  obj <- switch(obj,
                "answer"=Answers,
                "auth"=Auth,
                "class"=Classes,
                "message"=Messages,
                "project"=Projects,
                "section"=Sections,
                "student"=Students,
                "teacher"=Teachers)
  if(!is(obj, "Table")) {
    error <- "Only accepts Table classes"
  } else {

 

    out <- try(call_ref_meth(obj, meth, params, request), silent=TRUE)
    if(inherits(out, "try-error")) {
      status <- 400L
      error <- attr(out, "condition")$message
      message("rpc error")
      print(list(out=out, params=params))
      out <- attr(out, "condition")$message
    }
    if(is.null(out))
      out <- I("null")
  }


  
  ## finish off
  response <- Response$new(status=status)
  response$header("Content-Type", "application/json")
  response$body <- toJSON(list(error=error, response=out, id=p$id))
  return(response)
}
