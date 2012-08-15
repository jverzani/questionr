## login form

##' @include forms.R
NULL


##' The login function is called by janrain to authenticate
##' 
##' we use the token coming from a POST request
##' @param request request
##' @param token passed in by rpxnow
##' @export
##' @return returns a status, quizr_id, and a redirect 
login_janrain <- function(request, token, ...) {
  response <- POST('https://rpxnow.com/api/v2/auth_info',
                   body=list(
                     token=token,
                     apiKey=getOption("questionr::API_key")
                     )
                   )

  status <- response$status_code

## $stat
## [1] "ok"

## $profile
## $profile$preferredUsername
## [1] "John"

## $profile$email
## [1] "jverzani@yahoo.com"

## $profile$displayName
## [1] "John"

## $profile$gender
## [1] "male"

## $profile$utcOffset
## [1] "-05:00"

## $profile$name
##      formatted 
## "John Verzani" 

## $profile$photo
## [1] "https://a248.e.akamai.net/sec.yimg.com/i/identity/profile_48b.png"

  ## This is the unique key for the user...
## $profile$identifier
## [1] "https://me.yahoo.com/a/PjnBMMJ3yIBoB0Fo7M6bSo6yBFMt#41ec7"

## $profile$verifiedEmail
## [1] "jverzani@yahoo.com"

## $profile$providerName
## [1] "Yahoo!"

  
  if(as.integer(status) != 200L) {
    ## didn't work, que lastima
    print(list("login_janrain", reponse=response))
    return(list(status=status, msg="Can't authenticate"))
  }

  ## Okay, we logged on, return id,
  response <- fromJSON(rawToChar(response$content))
  identifier <- response$profile$identifier


#   assign("tmp", response, .GlobalEnv)
#  print(list("janrain response", r=response))
  
  ## for now, hard code
#  identifier <- "jverzani@gmail.com" ## teacher
#  identifier <- "jverzani@yahoo.com" ## student

  gravatar_photo <- function(email) {
    sprintf("http://www.gravatar.com/avatar/%s",
            digest(str_trim(email)))
  }

  
  rec <- Auth$filter(identifier=identifier)
  if(length(rec) != 1) {
    message("add new user")
    ## photo
    email <- response$profile$verifiedEmail
    photo <- response$profile$photo %||% gravatar_photo(email)

    
    s_id <- Auth$new_record(
                            identifier=response$profile$identifier,
                            name=response$profile$name %||% "Anonymous",
                            email=email,
                            photo=whisker.render('<img src="{{{photo}}}" />',
                              list(photo=response$profile$photo)),
                            roles=c("student")
                            )
    print(list("Auth new record", id=s_id))
    ## make a new student record
    out <- Students$new_record(id=s_id, random_seed=sample(1:1000, 1))

    message("made new student record", out)
    message("redirect to enroll")
    
    response <- list(status=200L,
                     quizr_id=s_id,
                     redirect="enroll",
                     msg="A okay")
    return(response)
  }
  ## otherwise we are okay
  rec <- rec[[1]]
  id <- rec$id
  goto <- if(Auth$is_teacher(id=id)) "teacher" else "student"

  response <- list(status=200L,
       quizr_id=id,
       redirect=goto,
       msg="A okay")
  
  response
}



##' Form for logging in
##'
##' @param request request
##' @param ... dots
##' @export
login_form <- function(request, ...) {
  tpl <- system.file("templates", "login.html", package="questionr")

  show_form(form=tpl,  base_url=base_url)
}

##' Logout form
##'
##' @param request request
##' @param ... dots
##' @export
logout_form <- function(request, ...) {
  ## set cookie and redirect

  response <- Response$new()
  ## use Utils to set path
  Rook:::Utils$set_cookie_header(response$headers,"quizr_id", "null",
                                 path="/")
  response$redirect(sprintf("%s", base_url))
  response                              # return Response instance
}

