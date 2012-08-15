## These can be overridden by setting an option
## questionr::XXX
## One must set API_key!
BRANDING <- " <h1>logo name<small>&nbsp;Some branding content to go here</small></h1>"
PAGE_TITLE_DEFAULT <-  "questionr"
##
base_url <- "http://localhost:9000/custom/quizr" ## base URL
bootstrap_base_url <- "http://twitter.github.com/bootstrap"
table_dir <- "/tmp/quizr"
base_project_dir <- sprintf("%s/project_files", table_dir)
API_key <- ""

Answer <- NULL

.onLoad <- function(libname, pkgname) {
  ## config from options
  cfg <- function(key) {
    val <- sprintf("questionr::%s", key)
    if(!is.null(getOption(val)))
      assign(key, getOption(val), inherits=TRUE)
  }
  sapply(c("BRANDING", "PAGE_TITLE_DEFAULT",
           "base_url", "bootstrap_url", "static_url",
           "table_dir", "base_project_dir",
           "API_key"), cfg)

  ## make table instances
  if(!file.exists(table_dir))
    dir.create(table_dir, recursive=TRUE)
  
  assign("Answers", AnswersTable$new(), inherits=TRUE)
  assign("Auth", AuthTable$new(), inherits=TRUE)
  assign("Classes", ClassTable$new(), inherits=TRUE)
  assign("Messages",MessagesTable$new(), inherits=TRUE)
  assign("Projects", ProjectsTable$new(), inherits=TRUE)
  assign("Sections", SectionsTable$new(), inherits=TRUE)
  assign("Students", StudentsTable$new(), inherits=TRUE)
  assign("Teachers", TeachersTable$new(), inherits=TRUE)
  
}
