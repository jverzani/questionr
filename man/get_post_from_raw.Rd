\name{get_post_from_raw}
\alias{get_post_from_raw}
\title{Get post from the Rook request object}
\usage{
  get_post_from_raw(request)
}
\description{
  Sometimes the Rook post parsing stuff chokes. The safest
  way is to pass in JSON via an ajax post call with
  contentType:"application/json" and parse the data this
  way (see \code{form_action} in markup.R)
  $.ajax({url:"http://localhost:9000/custom/quizr/request_teacher_status",
  type:"POST", contentType:"application/json",
  data:JSON.stringify({a:1, b:2, c:{d:"ab;c"}}),
  success:function(data)
  {tmp=data;window.location.replace(data)} });
}

