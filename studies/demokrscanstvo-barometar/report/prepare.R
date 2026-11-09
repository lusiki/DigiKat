# Read-only reconstruction. All row-level artifacts stay in the private workdir.
source('studies/demokrscanstvo-barometar/lib/io.R', encoding='UTF-8')
source('studies/demokrscanstvo-barometar/multiplatform_engine.R', encoding='UTF-8')
invisible(Sys.setlocale('LC_CTYPE','English_United States.utf8'))
work <- file.path(barometar_workdir(),'multiplatform-v1')
output <- file.path(barometar_workdir(),'analytical-report-v1')
dir.create(output,recursive=TRUE,showWarnings=FALSE)
active <- jsonlite::fromJSON(file.path(work,'active.json'))
classification <- jsonlite::fromJSON(file.path(active$folder,'classification.json'))
thematic <- jsonlite::fromJSON(file.path(work,'thematic-active.json'))
e <- multiplatform_engine()
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con,'SET threads=4')
quote_sql <- function(x)as.character(DBI::dbQuoteString(con,x))
write_jsonl <- function(x,path) {
  writeLines(vapply(x,function(z)jsonlite::toJSON(z,auto_unbox=TRUE,null='null',digits=16),character(1)),path,useBytes=TRUE)
}
documents <- list()
paths <- sort(list.files(classification$folder,pattern='[.]parquet$',full.names=TRUE))
for(path in paths) {
  rows <- DBI::dbGetQuery(con,paste0('SELECT d.*,c.TITLE,c.FULL_TEXT,c.source_name FROM read_parquet(',quote_sql(path),
    ') d JOIN read_parquet(',quote_sql(file.path(active$folder,'candidates',basename(path))),
    ") c USING(record_key) WHERE regexp_matches(route_set,'(^|;)(A1|B|C)(;|$)') ORDER BY record_key"))
  evidence <- readRDS(paste0(path,'-evidence.rds'))
  names(evidence) <- vapply(evidence,`[[`,character(1),'record_key')
  bp <- readRDS(paste0(path,'-boilerplate.rds'))
  keys <- split(bp$segment_key,bp$source_name)
  for(i in seq_len(nrow(rows))) {
    item <- evidence[[rows$record_key[i]]]
    prepared <- e$barometar_prepare_text(rows$TITLE[i],rows$FULL_TEXT[i])
    body <- e$barometar_mask_boilerplate(prepared$body,if(rows$platform[i]=='web')keys[[rows$source_name[i]]] else character())$body
    fields <- list(title=e$barometar_normalize_text(ifelse(is.na(rows$TITLE[i]),'',rows$TITLE[i])),body=e$barometar_normalize_text(body))
    windows <- Filter(function(w)w$route %in% c('A1','B','C'),item$windows)
    passages <- list(); sentences <- list()
    for(field in names(fields)) {
      tokens <- e$barometar_tokens(fields[[field]])
      selected <- sort(unique(unlist(lapply(Filter(function(w)w$field==field,windows),function(w)seq.int(w$token_low,w$token_high)))))
      if(!length(selected))next
      stopifnot(max(selected)<=nrow(tokens))
      runs <- split(selected,cumsum(c(TRUE,diff(selected)>1L)))
      spans <- lapply(runs,function(idx)c(tokens$start[min(idx)],tokens$end[max(idx)]))
      for(span in spans)passages[[length(passages)+1L]] <- list(field=field,start=span[1],end=span[2],text=stringi::stri_sub(fields[[field]],span[1],span[2]))
      # Expand each qualifying span to its original ICU sentence boundaries.
      # Never join separate fields or disjoint sentences to create adjacency.
      boundaries <- stringi::stri_locate_all_boundaries(fields[[field]],type='sentence')[[1]]
      for(j in seq_len(nrow(boundaries))) {
        span <- boundaries[j,]
        if(any(vapply(spans,function(s)s[1]<=span[2] && s[2]>=span[1],logical(1)))) {
          txt <- stringi::stri_sub(fields[[field]],span[1],span[2])
          if(!nzchar(trimws(txt)))next
          sentences[[length(sentences)+1L]] <- list(field=field,sentence_index=j,start=span[1],end=span[2],text=txt,
            sentence_id=digest::digest(txt,algo='sha256',serialize=FALSE))
        }
      }
    }
    context <- paste(unique(vapply(passages,`[[`,character(1),'text')),collapse='\n')
    documents[[length(documents)+1L]] <- list(record_key=rows$record_key[i],day=rows$day[i],month=rows$month[i],platform=rows$platform[i],
      text_basis=rows$text_basis[i],route_set=rows$route_set[i],title=fields$title,body=fields$body,stored_body=e$barometar_normalize_text(prepared$body),
      context_id=digest::digest(tolower(context),algo='sha256',serialize=FALSE),context=context,passages=passages,sentences=sentences)
  }
  if(length(documents))message(basename(path),': ',length(documents))
}
DBI::dbDisconnect(con,shutdown=TRUE)
stopifnot(length(documents)==2306L,!anyDuplicated(vapply(documents,`[[`,character(1),'record_key')))
write_jsonl(documents,file.path(output,'documents.jsonl'))
all_sentences <- unlist(lapply(documents,`[[`,'sentences'),recursive=FALSE)
sentence_ids <- vapply(all_sentences,`[[`,character(1),'sentence_id')
unique_s <- all_sentences[!duplicated(sentence_ids)]
model_path <- 'resources/models/croatian-set-ud-2.5-191206.udpipe'
model <- udpipe::udpipe_load_model(model_path)
dir.create(file.path(output,'sentence-tokens'),showWarnings=FALSE)
for(start in seq.int(1L,length(unique_s),by=100L)) {
  batch <- unique_s[start:min(start+99L,length(unique_s))]
  target <- file.path(output,'sentence-tokens',sprintf('%05d.jsonl',start))
  ids <- vapply(batch,`[[`,character(1),'sentence_id')
  # Cache is keyed by exact ordered sentence IDs and model hash.
  signature <- digest::digest(list(ids,digest::digest(file=model_path,algo='sha256')),algo='sha256')
  sigpath <- paste0(target,'.sha256')
  if(file.exists(target) && file.exists(sigpath) && identical(readLines(sigpath),signature))next
  anno <- as.data.frame(udpipe::udpipe_annotate(model,x=vapply(batch,`[[`,character(1),'text'),doc_id=ids,parser='none'))
  bydoc <- split(anno,anno$doc_id)
  result <- lapply(seq_along(ids),function(ii) {
    id <- ids[ii]; a <- bydoc[[id]]; original <- batch[[ii]]$text; cursor <- 1L
    starts <- ends <- integer(nrow(a))
    for(t in seq_len(nrow(a))) {
      loc <- stringi::stri_locate_first_fixed(stringi::stri_sub(original,cursor),a$token[t])
      if(is.na(loc[1]))stop('Token does not match source at ',id,' / ',t)
      starts[t] <- cursor+loc[1]-1L; ends[t] <- cursor+loc[2]-1L; cursor <- ends[t]+1L
    }
    a$start <- starts;a$end <- ends
    list(sentence_id=id,tokens=a[,c('sentence_id','token_id','token','lemma','upos','feats','start','end')])
  })
  write_jsonl(result,target);writeLines(signature,sigpath)
  message('Annotated ',min(start+99L,length(unique_s)),' / ',length(unique_s),' original sentences')
}
barometar_write_json(list(records=length(documents),unique_sentences=length(unique_s),
  offset_contract='one-based inclusive code points in normalized title or title-stripped boilerplate-masked body, not raw bytes',
  sentence_method='ICU boundaries expanded to full sentence if overlapping a qualifying evidence window; UDPipe subdivides if needed',
  model_sha256=digest::digest(file=model_path,algo='sha256'),udpipe=as.character(packageVersion('udpipe')),
  libPaths=.libPaths(),R=R.version.string,extraction=active$signature,thematic_folder=thematic$folder,
  generator_sha256=digest::digest(file='studies/demokrscanstvo-barometar/report/prepare.R',algo='sha256')),
  file.path(output,'prepared.json'))
message('Private report inputs ready: ',output)
