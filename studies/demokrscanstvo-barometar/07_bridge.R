# Independent June reconstructions. All source access is read-only; every
# article-level intermediate remains in the external private work directory.
source("studies/demokrscanstvo-barometar/04_classify.R",encoding="UTF-8")
source("R/lib/barometar_bridge.R",encoding="UTF-8")

barometar_bridge_fingerprint <- function(path,table,batch,end="2024-06-30") {
  con <- barometar_connect_readonly(path);on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  snapshot <- barometar_source_snapshot(con)
  ordering <- DBI::dbGetQuery(con,paste0('SELECT COUNT(*) AS bad FROM ',barometar_table_sql(con,table),
    " WHERE SOURCE_TYPE='web' AND (DATETIME IS NULL OR \"DATE\" IS NULL OR \"DATE\"<>strftime(DATETIME,'%Y-%m-%d'))",
    if(batch=="new")" AND SOURCE_BATCH='mediaspace_full'" else ""))
  if(ordering$bad>0)stop("Source DATE/DATETIME invariant failed; bounded global deduplication is unsafe.")
  days <- DBI::dbGetQuery(con,paste0('SELECT "DATE" AS day,COUNT(*) AS n,COUNT(FULL_TEXT) AS bodies,',
    'CAST(SUM(CAST(hash(URL) AS HUGEINT)) AS VARCHAR) AS url_hash_sum,',
    "CAST(SUM(CAST(hash(coalesce(FULL_TEXT,'')) AS HUGEINT)) AS VARCHAR) AS text_hash_sum FROM ",barometar_table_sql(con,table),
    " WHERE SOURCE_TYPE='web' AND \"DATE\">='2021-01-01' AND \"DATE\"<=",DBI::dbQuoteString(con,end),
    if(batch=="new")" AND SOURCE_BATCH='mediaspace_full'" else "",' GROUP BY 1 ORDER BY 1'))
  barometar_assert_snapshot(snapshot,con)
  list(snapshot=snapshot,days=days,digest=digikat_hash_object(days))
}

barometar_bridge_population <- function(path,table,batch,registry,panel,definition,folder,fingerprint,start="2024-06-01",end="2024-06-30") {
  con <- barometar_connect_readonly(path);on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  snapshot <- barometar_source_snapshot(con)
  table <- barometar_table_sql(con,table)
  barometar_assert_snapshot(fingerprint$snapshot,con)
  coverage <- fingerprint$days[fingerprint$days$day>=start & fingerprint$days$day<=end,,drop=FALSE]
  observed <- coverage$day[coverage$bodies/coverage$n>=.9]
  if(!length(observed))stop("Bridge run has no observed days.")
  maps <- barometar_registry_maps(registry)
  source_batch <- if(batch=="old")"luka_opce" else "mediaspace_full"
  item_sql <- if(batch=="old")"''" else "coalesce(CAST(ITEM_ID AS VARCHAR),'')"
  identity_sql <- paste0("md5(concat_ws('|',",DBI::dbQuoteString(con,source_batch),",SOURCE_TYPE,",item_sql,",coalesce(URL,''),",
    "strftime(DATETIME,'%Y-%m-%dT%H:%M:%S'),md5(coalesce(FULL_TEXT,''))))")
  query <- paste0('SELECT "DATE" AS day,lower("FROM") AS from_value,URL,replace(TITLE,chr(0),\'�\') AS TITLE,',
    "replace(FULL_TEXT,chr(0),'�') AS FULL_TEXT,strftime(DATETIME,'%Y-%m-%dT%H:%M:%S') AS captured_at,",
    identity_sql," AS doc_key,sha256(FULL_TEXT) AS original_text_sha256 FROM ",table,
    " WHERE SOURCE_TYPE='web' AND \"DATE\" IN (",paste(DBI::dbQuoteString(con,observed),collapse=","),") AND FULL_TEXT IS NOT NULL",
    if(batch=="new")" AND SOURCE_BATCH='mediaspace_full'" else "")
  cursor <- DBI::dbSendQuery(con,query)
  on.exit(if(DBI::dbIsValid(cursor))DBI::dbClearResult(cursor),add=TRUE)
  local <- DBI::dbConnect(duckdb::duckdb());on.exit(DBI::dbDisconnect(local,shutdown=TRUE),add=TRUE)
  DBI::dbExecute(local,"SET threads=2")
  dir.create(folder,recursive=TRUE,showWarnings=FALSE);paths <- character()
  repeat {
    rows <- DBI::dbFetch(cursor,n=2000L);if(!nrow(rows))break
    chars <- barometar_body_chars(rows$TITLE,rows$FULL_TEXT)
    rows <- rows[!is.na(chars) & chars>=200L,,drop=FALSE]
    if(!nrow(rows))next
    rows$outlet_id <- maps$from$outlet_id[match(rows$from_value,maps$from$value)]
    override <- maps$host$outlet_id[match(barometar_url_host(rows$URL),maps$host$value)]
    rows$outlet_id[!is.na(override)] <- override[!is.na(override)]
    rows <- rows[rows$outlet_id %in% panel$outlet_id,,drop=FALSE]
    if(!nrow(rows))next
    rows$canonical_url <- barometar_canonicalize_url(rows$URL)
    rows$noneditorial_reason <- barometar_noneditorial_reason(rows$URL,rows$TITLE)
    policy <- barometar_outlet_url_policy(rows$canonical_url);rows$canonical_url <- policy$article_url_key
    use <- is.na(rows$noneditorial_reason);rows$noneditorial_reason[use] <- policy$noneditorial_reason[use]
    rows <- rows[rows$outlet_id %in% panel$outlet_id & !is.na(rows$canonical_url) & nzchar(rows$canonical_url),,drop=FALSE]
    if(!nrow(rows))next
    target <- file.path(folder,sprintf("eligible-captures-%04d.parquet",length(paths)+1L))
    DBI::dbWriteTable(local,"chunk",rows,overwrite=TRUE)
    DBI::dbExecute(local,paste0("COPY chunk TO ",DBI::dbQuoteString(local,target)," (FORMAT PARQUET, COMPRESSION ZSTD)"))
    paths <- c(paths,target)
  }
  DBI::dbClearResult(cursor)
  barometar_assert_snapshot(snapshot,con)
  if(!length(paths))stop("Bridge panel is empty.")
  sources <- paste(DBI::dbQuoteString(local,paths),collapse=",")
  DBI::dbExecute(local,paste0("CREATE VIEW june_representatives AS SELECT * FROM (SELECT * FROM read_parquet([",sources,
    "]) QUALIFY row_number() OVER(PARTITION BY outlet_id,canonical_url ORDER BY captured_at ASC NULLS LAST,day,doc_key)=1) WHERE noneditorial_reason IS NULL"))
  # A June recapture cannot move a globally earlier eligible article into June.
  # Prior captures need only metadata; SQL computes the exact uncapped title-
  # stripped character count, then the shared R URL helper resolves identity.
  title_prefix <- "^[\\p{Z}\\p{P}\\x{0009}-\\x{000D}\\x{0085}]+"
  transported_title <- "replace(TITLE,chr(0),'�')"
  transported_body <- "replace(FULL_TEXT,chr(0),'�')"
  prior_body <- paste0("CASE WHEN TITLE IS NOT NULL AND length(TITLE)>0 AND starts_with(",transported_body,",",transported_title,") THEN regexp_replace(substr(",transported_body,",length(TITLE)+1),",
    DBI::dbQuoteString(con,title_prefix),",'') ELSE ",transported_body," END")
  june_keys <- DBI::dbGetQuery(local,"SELECT outlet_id,canonical_url FROM june_representatives")
  june_keys <- paste(june_keys$outlet_id,june_keys$canonical_url,sep="|")
  prior_days <- fingerprint$days$day[fingerprint$days$day<start & fingerprint$days$bodies/fingerprint$days$n>=.9]
  prior <- list()
  if(length(prior_days)) {
    before <- DBI::dbSendQuery(con,paste0("SELECT URL,lower(\"FROM\") AS from_value,\"DATE\" AS day,strftime(DATETIME,'%Y-%m-%dT%H:%M:%S') AS captured_at,",
      identity_sql," AS doc_key FROM ",table," WHERE SOURCE_TYPE='web' AND \"DATE\" IN (",paste(DBI::dbQuoteString(con,prior_days),collapse=","),") AND length(",prior_body,")>=200",
      if(batch=="new")" AND SOURCE_BATCH='mediaspace_full'" else ""))
    repeat {
      rows <- DBI::dbFetch(before,n=50000L);if(!nrow(rows))break
      rows$outlet_id <- maps$from$outlet_id[match(rows$from_value,maps$from$value)]
      override <- maps$host$outlet_id[match(barometar_url_host(rows$URL),maps$host$value)]
      rows$outlet_id[!is.na(override)] <- override[!is.na(override)]
      rows <- rows[rows$outlet_id %in% panel$outlet_id,,drop=FALSE]
      if(!nrow(rows))next
      rows$canonical_url <- barometar_outlet_url_policy(barometar_canonicalize_url(rows$URL))$article_url_key
      keep <- paste(rows$outlet_id,rows$canonical_url,sep="|") %in% june_keys
      if(any(keep))prior[[length(prior)+1L]] <- rows[keep,c("doc_key","outlet_id","canonical_url","captured_at","day"),drop=FALSE]
    }
    DBI::dbClearResult(before)
  }
  if(length(prior)) {
    DBI::dbWriteTable(local,"prior_captures",as.data.frame(data.table::rbindlist(prior)))
    DBI::dbExecute(local,"CREATE VIEW representatives AS SELECT * FROM june_representatives WHERE doc_key IN (SELECT doc_key FROM (SELECT doc_key,outlet_id,canonical_url,captured_at,day FROM june_representatives UNION ALL SELECT * FROM prior_captures) QUALIFY row_number() OVER(PARTITION BY outlet_id,canonical_url ORDER BY captured_at ASC NULLS LAST,day,doc_key)=1)")
  } else DBI::dbExecute(local,"CREATE VIEW representatives AS SELECT * FROM june_representatives")
  # Same raw title stripping, splitter, trigger, key and repetition thresholds
  # as the full-history mask. It is rebuilt separately for each instrument.
  title_prefix <- "^[\\p{Z}\\p{P}\\x{0009}-\\x{000D}\\x{0085}]+"
  whitespace <- "[\\x{0009}-\\x{000D}\\x{0020}\\x{0085}\\x{00A0}\\x{1680}\\x{2000}-\\x{200B}\\x{2028}\\x{2029}\\x{202F}\\x{205F}\\x{3000}]+"
  body <- paste0("CASE WHEN TITLE IS NOT NULL AND length(TITLE)>0 AND starts_with(FULL_TEXT,TITLE) THEN regexp_replace(substr(FULL_TEXT,length(TITLE)+1),",
    DBI::dbQuoteString(local,title_prefix),",'') ELSE FULL_TEXT END")
  boilerplate <- DBI::dbGetQuery(local,paste0("WITH segments AS (SELECT outlet_id,doc_key,day,substr(day,1,7) AS month,unnest(regexp_split_to_array(",body,",",
    DBI::dbQuoteString(local,BAROMETAR_BOILERPLATE_SPLIT_PATTERN),")) AS segment FROM representatives), keyed AS (SELECT outlet_id,doc_key,day,month,",
    "md5(trim(regexp_replace(regexp_replace(replace(lower(replace(segment,'İ','i̇')),'ς','σ'),'[0-9]','#','g'),",
    DBI::dbQuoteString(local,whitespace),",' ','g'))) AS segment_key FROM segments WHERE length(segment)>=40 AND regexp_matches(segment,",
    DBI::dbQuoteString(local,definition$prefilter$literal_pattern),")) SELECT outlet_id,month,segment_key,COUNT(DISTINCT doc_key) AS documents,COUNT(DISTINCT day) AS days ",
    "FROM keyed GROUP BY 1,2,3 HAVING COUNT(DISTINCT doc_key)>=5 AND COUNT(DISTINCT day)>=3 ORDER BY 1,2,3"))
  saveRDS(boilerplate,file.path(folder,"boilerplate-private.rds"))
  population <- DBI::dbGetQuery(local,"SELECT doc_key,outlet_id,day,md5(outlet_id || '|' || canonical_url) AS article_hash,original_text_sha256 FROM representatives ORDER BY doc_key")
  population$route_set <- ""
  population$facet_data <- "[]";population$hdz_only <- FALSE
  candidates <- DBI::dbSendQuery(local,paste0("SELECT TITLE,FULL_TEXT,day,outlet_id,doc_key FROM representatives WHERE ",definition$prefilter$sql_condition," ORDER BY doc_key"))
  repeat {
    rows <- DBI::dbFetch(candidates,n=500L);if(!nrow(rows))break
    results <- barometar_classify_batch(rows,definition,boilerplate)
    population$route_set[match(rows$doc_key,population$doc_key)] <- vapply(results,function(x)paste(x$routes,collapse=";"),character(1L))
    population$facet_data[match(rows$doc_key,population$doc_key)] <- vapply(results,function(x)
      as.character(jsonlite::toJSON(x$facets,dataframe="rows",auto_unbox=TRUE)),character(1L))
    population$hdz_only[match(rows$doc_key,population$doc_key)] <- vapply(results,`[[`,logical(1L),"hdz_only")
  }
  DBI::dbClearResult(candidates)
  stopifnot(!anyDuplicated(population$article_hash))
  barometar_assert_snapshot(snapshot,con)
  list(rows=population,coverage=coverage,observed_days=length(observed),snapshot=snapshot,
    boilerplate_hash=digikat_hash_object(boilerplate),definition_version=definition$definition_version,batch=batch,
    input_digest=fingerprint$digest,prior_matching_captures=sum(vapply(prior,nrow,integer(1L))))
}

barometar_run_bridge <- function() {
  workdir <- barometar_workdir();definition <- barometar_definition();panel <- barometar_require_panel()
  gates <- jsonlite::fromJSON("studies/demokrscanstvo-barometar/config/gates.json",simplifyVector=FALSE)
  if(!identical(gates$G2_definition$status,"approved") || !identical(gates$G2_definition$definition_version,definition$definition_version))stop("Bridge topic counts require G2.")
  registry <- utils::read.csv("studies/demokrscanstvo-barometar/config/outlet_registry.csv",fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE)
  paths <- c(old=digikat_determdb_old_path(),new=digikat_determdb_path())
  fingerprints <- setNames(lapply(names(paths),function(batch)barometar_bridge_fingerprint(paths[[batch]],
    if(batch=="old")"main.media_data" else digikat_determdb_table(),batch)),names(paths))
  identity <- list(definition=definition$definition_hash,panel=panel$panel_hash[1L],
    source=lapply(fingerprints,function(x)list(digest=x$digest,snapshot=x$snapshot)),registry=digikat_hash_file("studies/demokrscanstvo-barometar/config/outlet_registry.csv"),
    code=vapply(c("studies/demokrscanstvo-barometar/07_bridge.R","studies/demokrscanstvo-barometar/02_panel.R","R/lib/digikat_utils.R",
      "R/lib/barometar_bridge.R","R/lib/barometar_outlet_urls.R","R/lib/barometar_url_rules.R",
      "R/lib/barometar_engine.R","R/lib/barometar_text.R","R/lib/barometar_rules.R"),digikat_hash_file,character(1L)))
  folder <- file.path(workdir,"bridge",substr(digikat_hash_object(identity),1L,24L));dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  runs <- list()
  for(batch in names(paths)) {
    target <- file.path(folder,paste0(batch,"-private.rds"))
    if(file.exists(target))runs[[batch]] <- readRDS(target) else {
      runs[[batch]] <- barometar_bridge_population(paths[[batch]],if(batch=="old")"main.media_data" else digikat_determdb_table(),
        batch,registry,panel,definition,file.path(folder,batch),fingerprints[[batch]])
      saveRDS(runs[[batch]],target)
    }
    message("Private bridge reconstruction completed: ",batch,".")
  }
  for(batch in names(paths)) {
    check <- barometar_connect_readonly(paths[[batch]])
    tryCatch(barometar_assert_snapshot(fingerprints[[batch]]$snapshot,check),
      finally=DBI::dbDisconnect(check,shutdown=TRUE))
  }
  validation_path <- file.path(workdir,"validation",definition$definition_version,"validation-result.rds")
  validated <- file.exists(validation_path)
  validation <- if(validated)readRDS(validation_path) else NULL
  if(validated) {
    source("studies/demokrscanstvo-barometar/06_validation_score.R",local=environment(),encoding="UTF-8")
    coding_folder <- dirname(validation_path);draw <- readRDS(file.path(coding_folder,"draw.rds"))
    barometar_check_coding_package(coding_folder,draw)
    if(!isTRUE(validation$human_validation_complete) || !identical(validation$draw_id,draw$draw_id) ||
       !identical(draw$definition_version,definition$definition_version))stop("Bridge certification requires verified current human results.")
  }
  accepted <- if(validated)validation$accepted_routes else c("A1","B","C")
  counts <- contributions <- list()
  shared <- intersect(runs$old$rows$article_hash,runs$new$rows$article_hash)
  for(batch in names(runs))for(scope in c("siri","uze")) {
    rows <- runs[[batch]]$rows
    qualifies <- vapply(stringi::stri_split_fixed(rows$route_set,";"),function(x)any(x %in% if(scope=="uze")"A1" else accepted),logical(1L))
    fact <- data.frame(outlet_id=rows$outlet_id,N=1L,D=as.integer(qualifies))
    grouped <- aggregate(cbind(N,D)~outlet_id,fact,sum);grouped$batch <- batch;grouped$scope <- scope
    counts[[paste(batch,scope)]] <- grouped
    overlap <- ifelse(rows$article_hash %in% shared,"shared",paste0(batch,"_only"))
    contributions[[paste(batch,scope)]] <- data.frame(batch=batch,scope=scope,overlap=c("shared",paste0(batch,"_only")),
      D=vapply(c("shared",paste0(batch,"_only")),function(group)sum(qualifies & overlap==group),integer(1L)))
  }
  result <- barometar_bridge_estimate(do.call(rbind,counts),panel$outlet_id)
  coverage_ok <- all(vapply(runs,function(run)run$observed_days>=27L,logical(1L)))
  result$gate_pass <- result$gate_pass & coverage_ok
  result$definition_version <- definition$definition_version;result$panel_version <- unique(panel$panel_version)
  result$validation_status <- if(validated)"human_scored" else "provisional_unvalidated_routes"
  passed <- validated && isTRUE(validation$broad_publishable) && isTRUE(validation$narrow_publishable) && all(result$gate_pass)
  policy <- if(passed)"comparable_bridged" else "not_comparable_seam"
  result$break_policy <- policy
  barometar_write_csv(result,file.path(folder,"bridge_summary.csv"))
  barometar_write_csv(do.call(rbind,contributions),file.path(folder,"bridge_contributions.csv"))
  manifest <- list(folder=folder,identity=identity,summary=result,contributions=do.call(rbind,contributions),
    break_policy=policy,validated=validated,accepted_routes=accepted,source_fingerprints=fingerprints,
    validation_result_hash=if(validated)digikat_hash_file(validation_path) else NULL)
  saveRDS(manifest,file.path(workdir,"bridge_manifest.rds"))
  message("Bridge diagnostics prepared privately; policy: ",policy,".")
  invisible(manifest)
}
if(barometar_script_main("07_bridge.R"))barometar_run_bridge()
