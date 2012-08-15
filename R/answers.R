##' @include tables.R
NULL


Answers <- NULL                        # instance of this Table set in zzz.R
AnswersTable <- setRefClass("AnswersTable",
                            contains="Table",
                            fields=list(
                              student_id="CharField",
                              project_id="CharField",
                              date="DateField",
                              status="CharField", ## saved, submitted, graded
                              grade="CharField",
                              answers="ListField" 
                              ),
                            methods=list(
                              initialize=function(...) {
                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "answer_table.rds")
                                callSuper(file=nm, ...)
                              },
                              ## override new record, as we use a different id
                              new_record=function(student_id=NULL, project_id=NULL, ...) {
                                if(is.null(student_id) || is.null(project_id))
                                  stop("Need both a student and project id")

                                if(!Students$can_see_project(student_id, project_id))
                                  stop("Not authorized to view answers")

                                id <- make_ans_id(student_id, project_id)
                                callSuper(id=id, student_id=student_id,
                                          project_id=project_id, ...)
                                          
                              },
                              make_ans_id=function(student_id, project_id) {
                                sprintf("%s:%s", student_id, project_id)
                              },
                              valid_id2=function(student_id, project_id) {
                                "Give another signature?"
                                valid_id(make_ans_id(student_id, project_id))
                              }
                              )
                            )
                 

answer_icon <- function(x) {
  if(length(x) == 1)
    switch(x,
           "graded"="icon-leaf",
           "saved"="icon-file",
           "submitted" = "icon-check",
           "icon-edit")
  else
    "icon-ok"
}


## answers are keyed by prob1 prob2, ... this sorts on the number
answers_sort <- function(ans) {
  keys <- names(ans)
  ind <- as.numeric(gsub("prob_", "", names(ans)))
  ans[order(ind)]
}
