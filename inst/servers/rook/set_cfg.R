## set options for cfg file
## We have optins questionr::option_name
set_questionr_options <- function(cfg_file) {
  cfg <- read.dcf(cfg_file)
  cfg <- mapply(function(name, value) value, colnames(cfg), cfg, SIMPLIFY=FALSE)
  cfg <- setNames(cfg, sprintf("questionr::%s", names(cfg)) )
  options(cfg)
}
