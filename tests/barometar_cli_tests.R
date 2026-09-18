# Exercise release-affecting argument routing without opening a source DB.
run_barometar_cli_tests <- function() {
  env <- new.env(parent=globalenv())
  expressions <- parse("studies/demokrscanstvo-barometar/run.R",encoding="UTF-8")
  main <- Filter(function(e)is.call(e) && identical(e[[1]],as.name("<-")) &&
    identical(e[[2]],as.name("barometar_main")),as.list(expressions))
  stopifnot(length(main)==1L)
  eval(main[[1L]],env)
  loaded <- character()
  env$source <- function(file,local,encoding) {
    loaded <<- c(loaded,basename(file))
    invisible(NULL)
  }
  env$barometar_update <- function(workers,new_edition)list(stage="update",workers=workers,edition=new_edition)
  env$barometar_aggregate_release <- function(new_edition)list(stage="aggregate",edition=new_edition)
  env$barometar_accept_validation <- function()list(stage="accept-validation")
  env$barometar_classify_candidates <- function(development_only,workers)list(stage="classify",development=development_only,workers=workers)
  checks <- 0L
  check <- function(ok) {stopifnot(ok);checks <<- checks+1L}
  check(identical(env$barometar_main(character()),list(stage="update",workers=8L,edition=FALSE)))
  check(identical(tail(loaded,1L),"12_update.R"))
  check(identical(env$barometar_main(c("--edition","--workers=12")),list(stage="update",workers=12L,edition=TRUE)))
  check(identical(env$barometar_main(c("--stage=update","--workers=1")),list(stage="update",workers=1L,edition=FALSE)))
  check(identical(env$barometar_main(c("--stage=aggregate","--edition")),list(stage="aggregate",edition=TRUE)))
  check(identical(tail(loaded,1L),"08_aggregate.R"))
  check(identical(env$barometar_main("--stage=aggregate"),list(stage="aggregate",edition=FALSE)))
  check(identical(env$barometar_main("--stage=accept-validation"),list(stage="accept-validation")))
  check(identical(tail(loaded,1L),"accept_validation.R"))
  check(identical(env$barometar_main("--stage=classify"),list(stage="classify",development=FALSE,workers=1L)))
  check(identical(env$barometar_main(c("--stage=development","--workers=8")),list(stage="classify",development=TRUE,workers=8L)))
  invalid <- c(lapply(c("0","13","-1","1.5","2e0","NA","Inf","","999999999999"),function(x)paste0("--workers=",x)),
    list(c("--workers=1","--workers=2"),c("--stage=update","--stage=aggregate"),
      c("--edition","--edition"),c("--stage=aggregate","--workers=2"),
      c("--stage=validation","--edition"),c("--apply","--edition"),
      c("--sample","--edition"),"--edition=2026-09","--stage=unknown","--unexpected"))
  for(args in invalid) {
    before <- length(loaded)
    result <- tryCatch(env$barometar_main(args),error=identity)
    check(inherits(result,"error") && length(loaded)==before)
  }
  help <- capture.output(env$barometar_main("--help"))
  check(any(grepl("no arguments: checked refresh after G3",help,fixed=TRUE)))
  message("All ",checks," isolated CLI routing/argument checks passed.")
  invisible(checks)
}
run_barometar_cli_tests()
