# Private, deterministic audit of the optimized classifier against the exact
# contextual engine. Output contains counts only, never evidence passages.
source("studies/demokrscanstvo-barometar/lib/io.R",encoding="UTF-8")
source("R/lib/barometar_engine.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/multiplatform_engine.R",encoding="UTF-8")
work <- file.path(barometar_workdir(),"multiplatform-v1")
folder <- jsonlite::fromJSON(file.path(work,"active.json"))$folder
classified <- jsonlite::fromJSON(file.path(folder,"classification.json"))$folder
stopifnot(file.exists(file.path(classified,"complete.json")))
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con,"SET threads=4")
q <- function(x)as.character(DBI::dbQuoteString(con,x))
query <- paste0("WITH selected AS (SELECT *,row_number() OVER(PARTITION BY platform,context_checked ORDER BY md5(record_key || 'audit-20260919')) AS rn ",
  "FROM read_parquet(",q(file.path(classified,"*.parquet")),")) SELECT d.*,c.TITLE,c.FULL_TEXT,c.source_name FROM selected d ",
  "JOIN read_parquet(",q(file.path(folder,"candidates","*.parquet")),") c USING(record_key) WHERE d.rn<=CASE WHEN d.context_checked THEN 5 ELSE 20 END ORDER BY d.month,d.record_key")
rows <- DBI::dbGetQuery(con,query)
DBI::dbDisconnect(con,shutdown=TRUE)
e <- multiplatform_engine();definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
definition$text_cap <- .Machine$integer.max
failures <- 0L
for(month in unique(rows$month)) {
  bp <- readRDS(file.path(classified,paste0(month,".parquet-boilerplate.rds")))
  for(i in which(rows$month==month)) {
    keys <- if(rows$platform[i]=="web")bp$segment_key[bp$source_name==rows$source_name[i]] else character()
    result <- e$barometar_classify(rows$TITLE[i],rows$FULL_TEXT[i],definition,rows$day[i],keys)
    if(!identical(paste(result$routes,collapse=";"),rows$route_set[i]))failures <- failures+1L
  }
}
report <- list(audit="exact-engine-versus-vector-screen",sampled_records=nrow(rows),
  platforms=length(unique(rows$platform)),screen_rejected=sum(!rows$context_checked),
  contextual_checked=sum(rows$context_checked),disagreements=failures,
  interpretation="Software regression audit, not human validation or a precision estimate.")
barometar_write_json(report,file.path(folder,"exact_engine_audit.json"))
stopifnot(failures==0L)
print(report)
