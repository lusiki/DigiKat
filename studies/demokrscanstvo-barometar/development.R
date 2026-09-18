# Purposive, series-blind development review. Every selected item is in the30% split.
source("studies/demokrscanstvo-barometar/04_classify.R",encoding="UTF-8")

barometar_prepare_development <- function() {
  workdir <- barometar_workdir();definition <- barometar_definition()
  candidates <- readRDS(file.path(workdir,"candidate_manifest.rds"))
  if(!identical(candidates$prefilter_hash,digikat_hash_object(definition$prefilter$sql_condition)))stop("Stale candidate prefilter.")
  boilerplate <- readRDS(file.path(workdir,"boilerplate.rds"))
  con <- DBI::dbConnect(duckdb::duckdb());on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  paths <- paste(DBI::dbQuoteString(con,candidates$paths),collapse=",")
  clauses <- c(direct="regexp_matches(FULL_TEXT,'(?i)demokršć|kršćansko.?demokrat|demokrsc')",
    doctrine="regexp_matches(FULL_TEXT,'(?i)socijaln.{0,25}(nauk|doktrin)|rerum novarum|laudato si|personalizam')",
    grounding="regexp_matches(FULL_TEXT,'(?i)kršćansk.{0,20}(etik|vrijednost)|supsidijar|opće dobro')",
    collisions="regexp_matches(FULL_TEXT,'(?i)supsidijarn.{0,15}zaštit|personaliz|pučko otvoreno')",
    late="regexp_matches(substr(FULL_TEXT,3001),'(?i)demokršć|socijalni nauk|supsidijarn')",
    confessional="outlet_id IN ('web-hkm-hr','web-laudato-hr','web-novizivot-net')",
    papal="substr(day,1,7) IN ('2025-05','2026-05') AND regexp_matches(FULL_TEXT,'(?i)rerum novarum')")
  # Registry IDs are canonical hosts; derive this stratum instead of assuming IDs.
  registry <- utils::read.csv("studies/demokrscanstvo-barometar/config/outlet_registry.csv",fileEncoding="UTF-8-BOM")
  confessional <- registry$outlet_id[registry$segment=="confessional"]
  clauses[["confessional"]] <- paste0("outlet_id IN (",paste(DBI::dbQuoteString(con,confessional),collapse=","),")")
  selected <- list()
  for(purpose in names(clauses))for(batch in c("luka_opce","mediaspace_full")) {
    query <- paste0("SELECT *, '",purpose,"' AS purpose FROM read_parquet([",paths,
      "]) WHERE development AND source_batch=",DBI::dbQuoteString(con,batch)," AND ",clauses[[purpose]],
      " ORDER BY md5('20260918|",purpose,"|' || doc_key) LIMIT ",if(purpose %in% c("direct","doctrine","grounding"))25L else 10L)
    selected[[paste(purpose,batch)]] <- DBI::dbGetQuery(con,query)
  }
  rows <- as.data.frame(data.table::rbindlist(selected))
  purpose_map <- aggregate(purpose~doc_key,rows,function(x)paste(sort(unique(x)),collapse=";"))
  rows <- rows[!duplicated(rows$doc_key),];rows$purpose <- purpose_map$purpose[match(rows$doc_key,purpose_map$doc_key)]
  stopifnot(all(rows$development),nrow(rows)>=150L)
  folder <- file.path(workdir,"development",substr(definition$definition_hash,1L,24L))
  dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  results <- vector("list",nrow(rows));started <- proc.time()[[3L]]
  for(i in seq_len(nrow(rows))) {
    keys <- boilerplate$segment_key[boilerplate$outlet_id==rows$outlet_id[i] & boilerplate$month==substr(rows$day[i],1L,7L)]
    result <- barometar_classify(rows$TITLE[i],rows$FULL_TEXT[i],definition,rows$day[i],keys)
    results[[i]] <- result
    if(i%%25L==0L)message("Development item ",i,"/",nrow(rows),"; elapsed ",round(proc.time()[[3L]]-started,1L)," s.")
  }
  saveRDS(list(rows=rows,results=results,definition_version=definition$definition_version,
    definition_hash=definition$definition_hash,boilerplate_version=attr(boilerplate,"boilerplate_version")),file.path(folder,"review-private.rds"))
  log <- rows[,c("doc_key","article_hash","purpose")]
  log$coder <- "Codex assistant development review; not human validation"
  log$reviewed <- FALSE
  barometar_write_csv(log,file.path(folder,"review-log-private.csv"))
  saveRDS(list(folder=folder,definition_version=definition$definition_version,n=nrow(rows)),file.path(workdir,"development_review_manifest.rds"))
  message("Private purposive development material prepared. No period indicators computed.")
  invisible(folder)
}
if(sys.nframe()==0L)barometar_prepare_development()
