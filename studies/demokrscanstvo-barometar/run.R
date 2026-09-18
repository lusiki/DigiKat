#!/usr/bin/env Rscript
# Run from the repository root. Every empirical stage enforces its prerequisites.
# Keep this bootstrap ASCII so Windows can select UTF-8 before sourcing files.
if (.Platform$OS.type == "windows" && !isTRUE(l10n_info()[["UTF-8"]])) {
  locale <- suppressWarnings(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
  if (!nzchar(locale) || !isTRUE(l10n_info()[["UTF-8"]])) {
    stop("A UTF-8 Windows locale is required for Croatian source files.", call. = FALSE)
  }
}

barometar_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  study <- "studies/demokrscanstvo-barometar"
  if (!file.exists(file.path(study, "BRIEF.md"))) {
    stop("Run this command from the DigiKat repository root.", call. = FALSE)
  }
  if ("--help" %in% args) {
    cat("Barometer commands (no arguments: checked refresh after G3):\n",
        "  --stage=update --workers=8  checked refresh; --edition starts a monthly edition\n",
        "  --stage=readiness   schema, snapshot, all-web day fingerprints\n",
        "  --stage=inventory   outlet/month continuity inventory\n",
        "  --stage=panel       eligible-article panel proposal for PI review\n",
        "  --stage=candidates  private superset retrieval after G1\n",
        "  --stage=boilerplate all-panel repeated-segment mask after G1\n",
        "  --stage=development classify the 30% development split after G1\n",
        "  --stage=classify --workers=8  frozen full-history classification\n",
        "  --stage=validation  prepare fresh blinded human coding package\n",
        "  --stage=accept-validation  record G3 from completed human evidence and bridge\n",
        "  --stage=bridge      independent old/new June reconstruction\n",
        "  --stage=aggregate [--edition]  accepted-route release preview after G3\n",
        "  --stage=figures     figures for the current checked preview\n",
        "  --stage=checks      reconciliation and restricted-text overlap\n",
        "  --stage=method-pdf  method-only conference fallback\n",
        "  --sample            invented data only, writes inside tempdir()\n",
        "--apply refuses installation before empirical validation and release checks.\n", sep = "")
    return(invisible(NULL))
  }
  gates <- jsonlite::fromJSON(file.path(study, "config/gates.json"), simplifyVector = FALSE)
  if (!identical(gates$initial_plan$status, "approved")) {
    stop("Initial execution plan has not been approved.", call. = FALSE)
  }
  if ("--apply" %in% args) {
    if(!identical(args,"--apply"))stop("Use --apply alone after the release preview passes.")
    source(file.path(study,"11_checks.R"),local=environment(),encoding="UTF-8")
    preview <- readRDS(file.path(barometar_workdir(),"release_manifest.rds"))
    return(invisible(barometar_apply_release(preview$directory)))
  }
  if ("--sample" %in% args || any(startsWith(args, "--definition="))) {
    if (identical(args,"--sample")) {
      source(file.path(study,"sample.R"),local=environment(),encoding="UTF-8")
      return(invisible(barometar_sample()))
    }
    stop("Definition migration requires a separately versioned and validated inventory. Use --sample alone for synthetic checks.",call.=FALSE)
  }
  stages <- args[startsWith(args, "--stage=")]
  worker_arg <- args[startsWith(args,"--workers=")]
  edition_arg <- args[args=="--edition"]
  if (length(stages) > 1L || length(worker_arg)>1L || length(edition_arg)>1L || length(setdiff(args, c(stages,worker_arg,edition_arg)))) {
    stop("Unknown or duplicate arguments. Use --help.", call. = FALSE)
  }
  stage <- if (length(stages)) substring(stages, 9L) else "update"
  if (!stage %in% c("update","readiness", "inventory", "panel", "candidates", "boilerplate", "development","classify","validation","accept-validation","bridge","aggregate","figures","checks","method-pdf")) {
    stop("Unknown stage. Use --help.", call. = FALSE)
  }
  if(length(worker_arg) && !stage %in% c("update","classify","development"))stop("--workers applies only to update, classify or development.",call.=FALSE)
  worker_text <- if(length(worker_arg))substring(worker_arg,11L) else if(stage=="update")"8" else "1"
  if(!worker_text %in% as.character(seq_len(12L)))stop("--workers must be an integer from 1 to 12.",call.=FALSE)
  workers <- as.integer(worker_text)
  new_edition <- length(edition_arg)==1L
  if(new_edition && !stage %in% c("update","aggregate"))stop("--edition applies only to update or aggregate.",call.=FALSE)
  if(stage %in% c("update","validation","accept-validation","bridge","aggregate","figures","checks","method-pdf")) {
    script <- c(update="12_update.R",validation="05_validation_draw.R",`accept-validation`="accept_validation.R",bridge="07_bridge.R",aggregate="08_aggregate.R",figures="09_figures.R",checks="11_checks.R",`method-pdf`="10_summary_pdf.R")
    source(file.path(study,script[[stage]]),local=environment(),encoding="UTF-8")
    if(stage=="update")return(invisible(barometar_update(workers=workers,new_edition=new_edition)))
    if(stage=="validation")return(invisible(barometar_prepare_validation()))
    if(stage=="accept-validation")return(invisible(barometar_accept_validation()))
    if(stage=="bridge")return(invisible(barometar_run_bridge()))
    if(stage=="aggregate")return(invisible(barometar_aggregate_release(new_edition=new_edition)))
    if(stage=="method-pdf")return(invisible(barometar_method_pdf()))
    preview <- readRDS(file.path(barometar_workdir(),"release_manifest.rds"))
    if(stage=="figures")return(invisible(barometar_figures(preview$directory)))
    candidates <- readRDS(file.path(barometar_workdir(),"candidate_manifest.rds"))
    return(invisible(barometar_release_checks(preview$directory,private_candidates=candidates$paths,
      extra_public_files=c("pages/demokrscanstvo/index.qmd","studies/demokrscanstvo-barometar/typeset/conference.typ"))))
  }
  if(stage %in% c("candidates","boilerplate","development","classify")) {
    source(file.path(study,"04_classify.R"),local=environment(),encoding="UTF-8")
    return(invisible(switch(stage,candidates=barometar_candidates(),boilerplate=barometar_boilerplate(),
      development=barometar_classify_candidates(development_only=TRUE,workers=workers),
      classify=barometar_classify_candidates(development_only=FALSE,workers=workers))))
  }
  for (script in c("00_readiness.R", "01_outlets.R")) {
    source(file.path(study, script), local = environment(), encoding = "UTF-8")
  }
  workdir <- barometar_workdir()
  con <- barometar_connect_readonly()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  if (stage == "readiness") return(invisible(barometar_readiness(con, workdir)))
  if (stage == "inventory") return(invisible(barometar_outlet_inventory(con, workdir = workdir)))

  registry_path <- file.path(study, "config/outlet_registry.csv")
  if (!file.exists(registry_path)) {
    stop("The proposed outlet registry is not prepared. Run --stage=inventory first.", call. = FALSE)
  }
  source(file.path(study, "02_panel.R"), local = environment(), encoding = "UTF-8")
  readiness_path <- file.path(workdir, "readiness.rds")
  inventory_path <- file.path(workdir, "outlet_inventory.rds")
  if (!file.exists(readiness_path) || !file.exists(inventory_path)) {
    stop("Run --stage=readiness and --stage=inventory before the panel proposal.", call. = FALSE)
  }
  readiness <- readRDS(readiness_path)
  barometar_assert_snapshot(readiness$snapshot, con)
  inventory <- readRDS(inventory_path)
  if (is.null(inventory$snapshot)) {
    stop("Inventory has no source fingerprint; rebuild it with --stage=inventory.", call. = FALSE)
  }
  barometar_assert_snapshot(inventory$snapshot, con)
  if (!identical(readiness$data_through, inventory$data_through)) {
    stop("Inventory and readiness use different cutoffs; rebuild both.", call. = FALSE)
  }
  registry <- utils::read.csv(registry_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
  from_values <- barometar_registry_candidate_from_values(inventory, registry)
  metadata <- barometar_eligible_metadata(con = con, readiness = readiness,
                                          inventory = inventory, workdir = workdir,
                                          from_values = from_values)
  result <- barometar_panel_proposal(con = con, readiness = readiness, inventory = inventory,
                                    registry_path = registry_path, workdir = workdir,
                                    metadata = metadata)
  message("Panel proposal prepared. G1 still requires PI ratification; no topic counts computed.")
  invisible(result)
}

barometar_main()
