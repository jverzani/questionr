#!/usr/bin/env Rscript

# Execute this file from the shell like so:
# Rook.sh 9000 &

## Read port from command line
port <- as.numeric(commandArgs(trailingOnly=TRUE))
if(length(port) == 0)
  port <- 8100

## config. Change this next line
cfg_file <- system.file("servers", "rook", "config.dcf", package="questionr")
source(system.file("servers", "rook", "set_cfg.R", package="questionr"))
set_questionr_options(cfg_file)

## require after setting options above
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

message("Starting server")
try(s$start(port=as.integer(port)), silent=TRUE)

message(sprintf("Running at port %s.", port))

## prevent it from closing
while(TRUE) Sys.sleep(.Machine$integer.max)
