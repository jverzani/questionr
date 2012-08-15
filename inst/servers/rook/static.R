## app to show static files under the inst/extra directory
app <- function(env) {
  request <- Request$new(env)
  
  path_info <- gsub("^/", "", request$path_info())
  path <- system.file("extra", path_info, package="questionr")
  if(file.exists(path)) {
    fi <- file.info(path)
    headers <- list(
		    'Last-Modified' = Utils$rfc2822(fi$mtime),
		    'Content-Type' = Mime$mime_type(Mime$file_extname(basename(path))),
		    'Content-Length' = as.character(fi$size)
                    )
    names(path) <- "file"
    response <- Response$new()
    response$headers <- headers
    response$body <- path
  }
  response$finish()
}
