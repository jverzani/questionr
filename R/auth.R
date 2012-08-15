##' @include tables.R
NULL


## authenticated users

Auth <- NULL                        # instance of this Table set in zzz.R
AuthTable <- setRefClass("AuthTable",
                         contains="Table",
                         fields=list(
                           identifier="CharField", # from authentification
                           name="CharField",
                           email="CharField",
                           photo="CharField", # html, e.g. gravatar
                           roles="ArrayField"
                           ),
                         methods=list(
                           initialize=function(...) {
                             
                                nm <- sprintf("%s%s%s", table_dir, .Platform$file.sep, "authusers_table.rds")
                                callSuper(file=nm, ...)
                              },
                           ## Roles
                           is_role = function(id, role) {
                             if(!valid_id(id))
                               return(FALSE)
                             user_roles <- get(id=id, "roles")
                             role %in% user_roles
                           },
                           is_admin = function(id) is_role(id, "admin"),
                           is_teacher = function(id) is_role(id, "teacher"),
                           is_student = function(id) is_role(id, "student")
                           )
                         )
                            


## method to add user role. Call from shell
add_role <- function(user_id, role=c("teacher", "admin")) {
  if(!Auth$valid_id(user_id))
    stop("Invalid user_id")

  add_role <- function(user_id, role) {
    Auth$push_j(user_id, "roles", role)
  }
  
  role <- match.arg(role)
  if(role == "teacher" && !Auth$is_teacher(user_id)) {
    add_role(user_id, role)
    Teachers$new_record(id=user_id)
  }
  if(role == "amdin" && !Auth$is_admin(user_id))
    add_role(user_id, role)
}
  
