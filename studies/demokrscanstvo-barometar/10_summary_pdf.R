# Isolated Typst compilation, following the annual-report build boundary.
source("studies/demokrscanstvo-barometar/09_figures.R",encoding="UTF-8")

barometar_method_pdf <- function(output="studies/demokrscanstvo-barometar/output/conference") {
  fonts <- barometar_require_fonts()
  definition <- barometar_definition();panel <- barometar_require_panel()
  readiness <- readRDS(file.path(barometar_workdir(),"readiness.rds"))
  summary <- list(release_version="metoda-2026-09-18",panel_version=unique(panel$panel_version),panel_outlets=nrow(panel),
    definition_version=definition$definition_version,data_through=readiness$data_through,human_validation_complete=FALSE)
  build <- tempfile("barometar-conference-");dir.create(build)
  barometar_write_json(summary,file.path(build,"summary.json"))
  file.copy("studies/demokrscanstvo-barometar/typeset/conference.typ",file.path(build,"conference.typ"))
  typst <- "C:/Program Files/Quarto/bin/tools/x86_64/typst.exe"
  if(!file.exists(typst))typst <- Sys.which("typst")
  if(!nzchar(typst))stop("Typst is unavailable.")
  args <- c("compile",unlist(lapply(unique(dirname(fonts$path)),function(path)c("--font-path",shQuote(path)))),
    shQuote(file.path(build,"conference.typ")),shQuote(file.path(build,"conference.pdf")))
  if(system2(typst,args)!=0L)stop("Conference PDF compilation failed.")
  pdf <- file.path(build,"conference.pdf")
  dir.create(output,recursive=TRUE,showWarnings=FALSE)
  target <- file.path(output,"demokrscanstvo-metoda-2026-09-18.pdf")
  file.copy(pdf,target,overwrite=TRUE)
  barometar_write_json(summary,file.path(output,"summary.json"))
  if(system2("python",c("studies/demokrscanstvo-barometar/check_pdf.py",shQuote(target),
    shQuote(file.path(output,"summary.json")),shQuote(output)))!=0L)stop("PDF verification failed.")
  message("Method-only conference PDF compiled; inspect both rendered pages before delivery.")
  invisible(target)
}
if(barometar_script_main("10_summary_pdf.R"))barometar_method_pdf()
