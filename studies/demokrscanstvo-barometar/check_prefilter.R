# The empirical superset gate samples rejected development representatives only.
source("studies/demokrscanstvo-barometar/03_candidates.R",encoding="UTF-8")

barometar_check_prefilter <- function(n_per_batch=20000L,seed=20260918L) {
  stopifnot(identical(as.integer(n_per_batch),20000L))
  workdir <- barometar_workdir();panel <- barometar_require_panel();definition <- barometar_definition()
  readiness <- readRDS(file.path(workdir,"readiness.rds"))
  proposal <- readRDS(file.path(workdir,"panel_proposal.rds"))
  identity <- list(input_digest=readiness$input_digest,population=barometar_population_identity(workdir,readiness),panel_hash=panel$panel_hash[1L],
    prefilter_hash=digikat_hash_object(definition$prefilter$sql_condition),seed=seed,n_per_batch=n_per_batch)
  folder <- file.path(workdir,"prefilter",substr(digikat_hash_object(identity),1L,24L))
  dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  con <- barometar_connect_readonly();on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  barometar_assert_snapshot(readiness$snapshot,con)
  DBI::dbExecute(con,paste0("ATTACH ",DBI::dbQuoteString(con,proposal$private_db)," AS denominator (READ_ONLY)"))
  ids <- paste(DBI::dbQuoteString(con,panel$outlet_id),collapse=",")
  anchors <- Filter(function(rule)rule$family=="cd_label" ||
    rule$source_group %in% c("doctrinal_anchors.yaml","christian_grounding.yaml") ||
    rule$family %in% c("church_speaker","actor_church"),definition$compiled)
  metrics <- list()
  for(batch in c("luka_opce","mediaspace_full")) {
    path <- file.path(folder,paste0(batch,"-private.rds"))
    if(file.exists(path))rows <- readRDS(path) else {
      query <- paste0("WITH rejected AS (SELECT ",barometar_doc_key_sql(),
        " AS doc_key, replace(TITLE,chr(0),'�') AS TITLE, replace(FULL_TEXT,chr(0),'�') AS FULL_TEXT FROM ",barometar_table_sql(con),
        " WHERE SOURCE_TYPE='web' AND SOURCE_BATCH=",DBI::dbQuoteString(con,batch)," AND NOT ",definition$prefilter$sql_condition,
        "), candidates AS (SELECT DISTINCT x.* FROM rejected x JOIN denominator.main.representatives r USING(doc_key) WHERE r.outlet_id IN (",ids,
        ") AND CAST(('0x' || substr(md5(r.outlet_id || '|' || r.canonical_url),1,7)) AS BIGINT)%10<3) ",
        "SELECT * FROM candidates ORDER BY md5('",seed,"|' || doc_key),doc_key LIMIT ",n_per_batch)
      rows <- DBI::dbGetQuery(con,query)
      if(nrow(rows)!=n_per_batch || anyDuplicated(rows$doc_key))stop("Incomplete rejected-row sample.")
      saveRDS(rows,path)
    }
    prepared <- barometar_prepare_text(rows$TITLE,rows$FULL_TEXT)
    fields <- list(title=barometar_text_fields(ifelse(is.na(prepared$title),"",prepared$title)),body=barometar_text_fields(prepared$body))
    hits <- rep(FALSE,nrow(rows))
    for(field in fields)for(rule in anchors)hits <- hits | stringi::stri_detect_regex(if(rule$case_sensitive)field$txt else field$low,rule$pattern)
    metrics[[batch]] <- data.frame(source_batch=batch,rejected_rows=nrow(rows),anchor_hits=sum(hits),pass=!any(hits))
    if(any(hits))saveRDS(rows[hits,,drop=FALSE],file.path(folder,paste0(batch,"-failures-private.rds")))
    message("Rejected-row superset check complete for ",batch,".")
  }
  result <- list(identity=identity,definition_version=definition$definition_version,
    normalization_hash=digikat_hash_file("R/lib/barometar_text.R"),metrics=do.call(rbind,metrics),
    pass=all(vapply(metrics,function(x)x$pass,logical(1L))))
  saveRDS(result,file.path(workdir,"prefilter_gate.rds"))
  barometar_write_json(result,file.path(folder,"report.json"))
  print(result$metrics,row.names=FALSE)
  if(!result$pass)stop("Empirical prefilter is not a superset.")
  invisible(result)
}
if(sys.nframe()==0L)barometar_check_prefilter()
