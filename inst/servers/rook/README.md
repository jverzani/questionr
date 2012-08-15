## To use we have
install("questionr")

## config. Change this next line
cfg_file <- system.file("servers", "rook", "config.dcf", package="questionr")
source(system.file("servers", "rook", "set_cfg.R", package="questionr"))
set_questionr_options(cfg_file)

require("questionr")
require(Rook)
s <- Rhttpd$new()
s$add(RhttpdApp$new(
    name="quizr",
    app=system.file('servers', 'rook', 'rook.R',
      package="questionr")
))
s$add(RhttpdApp$new(
    name="quizr_static",
    app=system.file('servers', 'rook', 'static.R', package="questionr")
))
s$start(port=9000L)



