source("studies/demokrscanstvo-barometar/lib/io.R",encoding="UTF-8")
source("R/lib/barometar_engine.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/multiplatform_engine.R",encoding="UTF-8")
work <- file.path(barometar_workdir(),"multiplatform-v1")
active <- jsonlite::fromJSON(file.path(work,"active.json"))
folder <- active$folder
definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
identity <- list(extraction=active$signature,definition=definition$definition_version,
  adapter_sha256=digikat_hash_file("studies/demokrscanstvo-barometar/multiplatform_engine.R"))
output <- file.path(folder,paste0("classified-",substr(digikat_hash_object(identity),1L,16L)))
dir.create(output,recursive=TRUE,showWarnings=FALSE)
barometar_write_json(list(folder=output,identity=identity),file.path(folder,"classification.json"))
paths <- list.files(file.path(folder,"candidates"),pattern="[.]parquet$",full.names=TRUE)
pending <- paths[!file.exists(file.path(output,basename(paths)))]
workers <- as.integer(Sys.getenv("BAROMETAR_WORKERS","6"))
stopifnot(workers>=1L,workers<=12L)
context <- list(definition=definition,output=output)
if(length(pending)) {
  cluster <- parallel::makePSOCKcluster(min(workers,length(pending)),
    outfile=file.path(output,"workers.log"),rscript_args="--vanilla")
  tryCatch({
    parallel::clusterCall(cluster,function(root,library,context) {
      setwd(root);.libPaths(library)
      if(.Platform$OS.type=="windows")Sys.setlocale("LC_CTYPE","English_United States.utf8")
      source("studies/demokrscanstvo-barometar/lib/io.R",encoding="UTF-8")
      source("R/lib/barometar_engine.R",encoding="UTF-8")
      source("studies/demokrscanstvo-barometar/multiplatform_engine.R",encoding="UTF-8")
      assign("multiplatform_context",context,envir=.GlobalEnv)
      TRUE
    },normalizePath(getwd(),winslash="/"),.libPaths(),context)
    invisible(parallel::parLapplyLB(cluster,pending,function(path)multiplatform_month(path,multiplatform_context)))
  },finally=parallel::stopCluster(cluster))
}
if(file.exists(file.path(folder,"extraction_complete.json"))) {
  complete <- jsonlite::fromJSON(file.path(folder,"extraction_complete.json"))
  if(length(paths)==length(complete$months)) {
    stopifnot(all(file.exists(file.path(output,basename(paths)))))
    barometar_write_json(list(months=complete$months,identity=identity),file.path(output,"complete.json"))
    message("All platform classification complete.")
  } else message("Available chunks classified; rerun for the remaining extracted months.")
} else message("Available chunks classified; extraction is still running.")
