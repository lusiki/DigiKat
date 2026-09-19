# A separate text-policy adapter. Frozen v1 files and their hash are unchanged.
multiplatform_engine <- function() {
  e <- new.env(parent=globalenv())
  for(file in c("barometar_text.R","barometar_rules.R","barometar_engine.R"))
    sys.source(file.path("R/lib",file),envir=e)
  original_prepare <- e$barometar_prepare_text
  e$barometar_prepare_text <- function(title,full_text,min_chars=1L,cap=.Machine$integer.max) {
    result <- original_prepare(title,full_text,min_chars=1L,cap=.Machine$integer.max)
    result$body[is.na(result$body)] <- ""
    result$eligible <- stringi::stri_detect_regex(paste(ifelse(is.na(title),"",title),result$body),"[\\p{L}\\p{N}]")
    result
  }
  # Diagnostic near-miss sampling is not an inclusion condition and is not an
  # output of this edition. Avoid its extra per-clause walk on excluded rows.
  e$barometar_near_miss_conditions <- function(...)character()
  e
}

# A necessary-condition precheck, never a positive classification. Conditions
# must occur in one field; the exact engine then tests exclusions, distances,
# clauses, attribution and argument links. This reduces repeated sentence work.
multiplatform_possible <- function(active,compiled) {
  families <- vapply(compiled,`[[`,character(1L),"family")
  groups <- vapply(compiled,`[[`,character(1L),"source_group")
  tiers <- vapply(compiled,`[[`,character(1L),"tier")
  any_of <- function(sel)if(any(sel))rowSums(active[,sel,drop=FALSE])>0 else rep(FALSE,nrow(active))
  direct <- any_of(families=="cd_label")
  public <- any_of(families=="public")
  strong <- any_of(groups=="doctrinal_anchors.yaml" & tiers=="strong")
  application <- any_of(families %in% c("connector","attribution","policy_action"))
  grounding <- any_of(families %in% c("grounding","church_speaker","actor_church"))
  concept <- any_of(groups=="concept_families.yaml" | families=="identity_family" | (groups=="doctrinal_anchors.yaml" & tiers=="strong"))
  direct | (public & ((strong & application) | (grounding & concept & any_of(families=="connector"))))
}

multiplatform_boilerplate <- function(con,path,definition) {
  quote <- function(x)as.character(DBI::dbQuoteString(con,x))
  whitespace <- "[\\x{0009}-\\x{000D}\\x{0020}\\x{0085}\\x{00A0}\\x{1680}\\x{2000}-\\x{200B}\\x{2028}\\x{2029}\\x{202F}\\x{205F}\\x{3000}]+"
  prefix <- "^[\\p{Z}\\p{P}\\x{0009}-\\x{000D}\\x{0085}]+"
  body <- paste0("CASE WHEN length(TITLE)>0 AND starts_with(FULL_TEXT,TITLE) THEN regexp_replace(substr(FULL_TEXT,length(TITLE)+1),",quote(prefix),",'') ELSE FULL_TEXT END")
  # Every trigger-containing segment belongs to the extracted candidate set.
  # Counts are distinct records/days for a web source in this month, with the
  # same >=5 records and >=3 days rule as v1. Social repetition stays visible.
  query <- paste0("WITH segments AS (SELECT source_name,record_key,day,unnest(regexp_split_to_array(",body,",",
    quote(BAROMETAR_BOILERPLATE_SPLIT_PATTERN),")) AS segment FROM read_parquet(",quote(path),") WHERE platform='web'), keyed AS (",
    "SELECT source_name,record_key,day,md5(trim(regexp_replace(regexp_replace(replace(lower(replace(segment,'İ','i̇')),'ς','σ'),'[0-9]','#','g'),",
    quote(whitespace),",' ','g'))) AS segment_key FROM segments WHERE length(segment)>=40 AND regexp_matches(segment,",
    quote(definition$prefilter$literal_pattern),")) SELECT source_name,segment_key FROM keyed GROUP BY 1,2 HAVING count(DISTINCT record_key)>=5 AND count(DISTINCT day)>=3")
  DBI::dbGetQuery(con,query)
}

multiplatform_month <- function(path,context) {
  target <- file.path(context$output,basename(path))
  if(file.exists(target))return(target)
  started <- proc.time()[[3L]]
  e <- multiplatform_engine();definition <- context$definition
  definition$text_cap <- .Machine$integer.max
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  DBI::dbExecute(con,"SET threads=1")
  bp <- multiplatform_boilerplate(con,path,definition)
  bp_keys <- split(bp$segment_key,bp$source_name)
  saveRDS(bp,paste0(target,"-boilerplate.rds"))
  cursor <- DBI::dbSendQuery(con,paste0("SELECT * FROM read_parquet(",DBI::dbQuoteString(con,path),")"))
  decisions <- list();positive_evidence <- list();scanned <- classified_n <- 0L
  repeat {
    rows <- DBI::dbFetch(cursor,n=500L)
    if(!nrow(rows))break
    prepared <- e$barometar_prepare_text(rows$TITLE,rows$FULL_TEXT)
    keys <- lapply(seq_len(nrow(rows)),function(i)if(rows$platform[i]=="web")bp_keys[[rows$source_name[i]]] else character())
    body <- vapply(seq_len(nrow(rows)),function(i)e$barometar_mask_boilerplate(prepared$body[i],keys[[i]])$body,character(1L))
    fields <- list(title=e$barometar_text_fields(rows$TITLE),body=e$barometar_text_fields(body))
    active <- lapply(fields,function(field)matrix(vapply(definition$compiled,function(rule)
      stringi::stri_detect_regex(if(rule$case_sensitive)field$txt else field$low,rule$pattern),
      logical(nrow(rows))),nrow=nrow(rows)))
    possible <- Reduce(`|`,lapply(active,multiplatform_possible,compiled=definition$compiled))
    out <- rows[,c("record_key","day","month","platform","source_batch","text_basis")]
    out$route_set <- "";out$themes <- "";out$masked_chars <- 0L
    out$context_checked <- possible
    for(i in which(possible)) {
      result <- e$barometar_classify(rows$TITLE[i],rows$FULL_TEXT[i],definition,rows$day[i],keys[[i]],
        .active=lapply(active,function(m)m[i,]))
      out$route_set[i] <- paste(result$routes,collapse=";")
      out$themes[i] <- if(isTRUE(result$broad_candidate))paste(result$themes,collapse=";") else ""
      out$masked_chars[i] <- result$masked_chars
      if(isTRUE(result$broad_candidate)) {
        positive_evidence[[length(positive_evidence)+1L]] <- list(record_key=rows$record_key[i],
          evidence=result$evidence,windows=result$windows,facets=result$facets)
      }
    }
    scanned <- scanned+nrow(rows);classified_n <- classified_n+sum(possible)
    decisions[[length(decisions)+1L]] <- out
  }
  DBI::dbClearResult(cursor)
  output <- if(length(decisions))as.data.frame(data.table::rbindlist(decisions)) else data.frame(
    record_key=character(),day=character(),month=character(),platform=character(),source_batch=character(),
    text_basis=character(),route_set=character(),themes=character(),masked_chars=integer(),context_checked=logical())
  DBI::dbWriteTable(con,"output",output)
  DBI::dbExecute(con,paste0("COPY output TO ",DBI::dbQuoteString(con,paste0(target,".partial"))," (FORMAT PARQUET,COMPRESSION ZSTD)"))
  saveRDS(positive_evidence,paste0(target,"-evidence.rds"))
  if(!file.rename(paste0(target,".partial"),target))stop("Cannot finalize classification checkpoint")
  message("Classified ",basename(path),"; candidates=",scanned,"; contextual checks=",classified_n,
    "; elapsed=",round(proc.time()[[3L]]-started,1L),"s")
  target
}
