# Rebuild current retrieval/mask dependencies, then run development-only gates.
source("studies/demokrscanstvo-barometar/check_prefilter.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/check_segmenter.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/development.R",encoding="UTF-8")
workdir <- barometar_workdir();readiness <- readRDS(file.path(workdir,"readiness.rds"))
current <- try(barometar_population_identity(workdir,readiness),silent=TRUE)
proposal <- if(inherits(current,"try-error"))barometar_panel_proposal() else readRDS(file.path(workdir,"panel_proposal.rds"))
stopifnot(identical(sort(proposal$panel$outlet_id),sort(barometar_require_panel()$outlet_id)),
  identical(unique(proposal$panel$panel_hash),unique(barometar_require_panel()$panel_hash)))
barometar_candidates()
barometar_boilerplate()
barometar_check_prefilter()
barometar_check_segmenter()
barometar_prepare_development()
