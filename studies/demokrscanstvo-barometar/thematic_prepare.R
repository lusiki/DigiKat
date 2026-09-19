# Reconstruct qualifying contexts and annotate Croatian. Private outputs only.
# Run from the repository root; the configured work directory is external.
source("studies/demokrscanstvo-barometar/lib/io.R", encoding="UTF-8")
source("studies/demokrscanstvo-barometar/multiplatform_engine.R", encoding="UTF-8")
if (.Platform$OS.type == "windows") invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
work <- file.path(barometar_workdir(), "multiplatform-v1")
active <- jsonlite::fromJSON(file.path(work,"active.json"))
classification <- jsonlite::fromJSON(file.path(active$folder,"classification.json"))
model_path <- "resources/models/croatian-set-ud-2.5-191206.udpipe"
input_paths <- sort(c(list.files(classification$folder,full.names=TRUE),
  list.files(file.path(active$folder,"candidates"),pattern="[.]parquet$",full.names=TRUE)))
identity <- list(extraction=active$signature, classification=classification$identity,
  inputs=unname(vapply(input_paths,function(p)digest::digest(file=p,algo="sha256"),character(1))),
  generator=digest::digest(file="studies/demokrscanstvo-barometar/thematic_prepare.R",algo="sha256"),
  udpipe_model=digest::digest(file=model_path,algo="sha256"), udpipe=as.character(packageVersion("udpipe")))
signature <- substr(digest::digest(identity,algo="sha256"),1,20)
output <- file.path(work,"thematic",signature)
dir.create(output,recursive=TRUE,showWarnings=FALSE)
barometar_write_json(list(folder=output,identity=identity),file.path(work,"thematic-active.json"))
if(file.exists(file.path(output,"complete.json"))) {
  message("Thematic annotation cache is current.")
  quit(status=0)
}
e <- multiplatform_engine()
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con,"SET threads=4")
quote_sql <- function(x)as.character(DBI::dbQuoteString(con,x))
paths <- sort(list.files(classification$folder,pattern="[.]parquet$",full.names=TRUE))
documents <- list()
for(path in paths) {
  rows <- DBI::dbGetQuery(con,paste0("SELECT d.*,c.TITLE,c.FULL_TEXT,c.source_name FROM read_parquet(",
    quote_sql(path),") d JOIN read_parquet(",quote_sql(file.path(active$folder,"candidates",basename(path))),
    ") c USING(record_key) WHERE regexp_matches(route_set,'(^|;)(A1|B|C)(;|$)') ORDER BY record_key"))
  evidence <- readRDS(paste0(path,"-evidence.rds"))
  names(evidence) <- vapply(evidence,`[[`,character(1),"record_key")
  bp <- readRDS(paste0(path,"-boilerplate.rds"))
  keys <- split(bp$segment_key,bp$source_name)
  for(i in seq_len(nrow(rows))) {
    item <- evidence[[rows$record_key[i]]]
    body <- e$barometar_prepare_text(rows$TITLE[i],rows$FULL_TEXT[i])$body
    body <- e$barometar_mask_boilerplate(body,if(rows$platform[i]=="web")keys[[rows$source_name[i]]] else character())$body
    fields <- list(title=e$barometar_normalize_text(rows$TITLE[i]),body=e$barometar_normalize_text(body))
    windows <- Filter(function(w)w$route %in% c("A1","B","C"),item$windows)
    passages <- character()
    for(field in names(fields)) {
      tokens <- e$barometar_tokens(fields[[field]])
      selected <- sort(unique(unlist(lapply(Filter(function(w)w$field==field,windows),
        function(w)seq.int(w$token_low,w$token_high)))))
      if(!length(selected))next
      stopifnot(max(selected)<=nrow(tokens))
      runs <- split(selected,cumsum(c(TRUE,diff(selected)>1L)))
      passages <- c(passages,vapply(runs,function(idx)stringi::stri_sub(fields[[field]],
        tokens$start[min(idx)],tokens$end[max(idx)]),character(1)))
    }
    context <- paste(unique(passages),collapse="\n")
    stopifnot(nchar(context)>0)
    documents[[length(documents)+1L]] <- list(record_key=rows$record_key[i],
      month=rows$month[i],platform=rows$platform[i],text_basis=rows$text_basis[i],
      context=context,context_id=digest::digest(tolower(context),algo="sha256",serialize=FALSE))
  }
  message("Contexts: ",basename(path),"; total ",length(documents))
}
DBI::dbDisconnect(con,shutdown=TRUE)
write_lines <- function(items,path) {
  lines <- vapply(items,function(x)jsonlite::toJSON(x,auto_unbox=TRUE,null="null"),character(1))
  writeLines(enc2utf8(lines),path,useBytes=TRUE)
}
write_lines(documents,file.path(output,"contexts.jsonl"))
unique_docs <- documents[!duplicated(vapply(documents,`[[`,character(1),"context_id"))]
model <- udpipe::udpipe_load_model(model_path)
for(start in seq.int(1L,length(unique_docs),by=100L)) {
  target <- file.path(output,sprintf("tokens-%04d.jsonl",start))
  if(file.exists(target))next
  batch <- unique_docs[start:min(start+99L,length(unique_docs))]
  annotation <- as.data.frame(udpipe::udpipe_annotate(model,
    x=vapply(batch,`[[`,character(1),"context"),doc_id=vapply(batch,`[[`,character(1),"context_id"),
    tagger="default",parser="none"))
  selected <- annotation[annotation$upos %in% c("NOUN","PROPN","ADJ") & !is.na(annotation$lemma),]
  lemmas <- split(tolower(selected$lemma),selected$doc_id)
  write_lines(lapply(batch,function(doc)list(context_id=doc$context_id,
    lemmas=unname(lemmas[[doc$context_id]]))),target)
  message("Lemmatized ",min(start+99L,length(unique_docs))," / ",length(unique_docs)," distinct contexts")
}
barometar_write_json(list(records=length(documents),distinct_contexts=length(unique_docs),
  identity=identity),file.path(output,"complete.json"))
message("Private thematic annotation complete.")
