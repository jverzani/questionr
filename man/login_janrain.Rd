\name{login_janrain}
\alias{login_janrain}
\title{The login function is called by janrain to authenticate}
\usage{
  login_janrain(request, token, ...)
}
\arguments{
  \item{request}{request}

  \item{token}{passed in by rpxnow}
}
\value{
  returns a status, quizr_id, and a redirect
}
\description{
  we use the token coming from a POST request
}

