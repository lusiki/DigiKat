# Read frozen private inputs; only write into the new text-addendum-v1 directory.
source('studies/demokrscanstvo-barometar/lib/io.R', encoding='UTF-8')
invisible(Sys.setlocale('LC_CTYPE','English_United States.utf8'))
work <- barometar_workdir()
old <- file.path(work,'analytical-report-v1')
out <- file.path(work,'text-addendum-v1')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
write_jsonl <- function(x,path) writeLines(vapply(x,function(z)jsonlite::toJSON(z,auto_unbox=TRUE,null='null',digits=16),character(1)),path,useBytes=TRUE)
docs <- jsonlite::fromJSON(file.path(old,'grouped-documents.json'),simplifyVector=FALSE)
reps <- jsonlite::fromJSON(file.path(old,'representatives.json'))
active <- jsonlite::fromJSON(file.path(work,'multiplatform-v1','active.json'))
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con,'SET threads=4')
DBI::dbWriteTable(con,'wanted',data.frame(record_key=vapply(docs,`[[`,character(1),'record_key')))
path <- gsub('\\\\','/',file.path(active$folder,'candidates','*.parquet'))
sources <- DBI::dbGetQuery(con,paste0('SELECT c.record_key,c.source_name FROM read_parquet(',as.character(DBI::dbQuoteString(con,path)),') c JOIN wanted w USING(record_key)'))
stopifnot(nrow(sources)==2306L,!anyDuplicated(sources$record_key),setequal(sources$record_key,vapply(docs,`[[`,character(1),'record_key')))
barometar_write_json(sources,file.path(out,'sources.json'))
DBI::dbDisconnect(con,shutdown=TRUE)
selected <- Filter(function(d)d$record_key %in% reps,docs)
extended <- list()
for(d in selected) {
  sentences <- list()
  for(field in c('title','body')) {
    local <- Filter(function(s)s$field==field,d$sentences)
    if(!length(local))next
    boundaries <- stringi::stri_locate_all_boundaries(d[[field]],type='sentence')[[1]]
    keep <- sort(unique(unlist(lapply(local,function(s)seq.int(max(1L,s$sentence_index-1L),min(nrow(boundaries),s$sentence_index+1L))))))
    for(j in keep) {
      span <- boundaries[j,];txt <- stringi::stri_sub(d[[field]],span[1],span[2])
      if(!nzchar(trimws(txt)))next
      sentences[[length(sentences)+1L]] <- list(field=field,sentence_index=j,start=span[1],end=span[2],text=txt,sentence_id=digest::digest(txt,algo='sha256',serialize=FALSE))
    }
  }
  extended[[length(extended)+1L]] <- list(record_key=d$record_key,sentences=sentences)
}
write_jsonl(extended,file.path(out,'expanded-sentences.jsonl'))
existing <- unlist(lapply(list.files(file.path(old,'sentence-tokens'),pattern='jsonl$',full.names=TRUE),function(p)lapply(readLines(p,encoding='UTF-8'),jsonlite::fromJSON)),recursive=FALSE)
existing_ids <- vapply(existing,`[[`,character(1),'sentence_id')
all_s <- unlist(lapply(extended,`[[`,'sentences'),recursive=FALSE)
ids <- vapply(all_s,`[[`,character(1),'sentence_id')
new <- all_s[!duplicated(ids) & !ids %in% existing_ids]
model_path <- 'resources/models/croatian-set-ud-2.5-191206.udpipe'
model <- udpipe::udpipe_load_model(model_path)
dir.create(file.path(out,'sentence-tokens'),showWarnings=FALSE)
for(start in seq.int(1L,length(new),by=100L)) {
  batch <- new[start:min(start+99L,length(new))]
  target <- file.path(out,'sentence-tokens',sprintf('%05d.jsonl',start))
  ids <- vapply(batch,`[[`,character(1),'sentence_id')
  signature <- digest::digest(list(ids,digest::digest(file=model_path,algo='sha256')),algo='sha256')
  if(file.exists(target) && file.exists(paste0(target,'.sha256')) && identical(readLines(paste0(target,'.sha256')),signature))next
  anno <- as.data.frame(udpipe::udpipe_annotate(model,x=vapply(batch,`[[`,character(1),'text'),doc_id=ids,parser='none'))
  bydoc <- split(anno,anno$doc_id)
  result <- lapply(seq_along(ids),function(ii) {
    a <- bydoc[[ids[ii]]];original <- batch[[ii]]$text;cursor <- 1L
    starts <- ends <- integer(nrow(a))
    for(t in seq_len(nrow(a))) {
      loc <- stringi::stri_locate_first_fixed(stringi::stri_sub(original,cursor),a$token[t])
      if(is.na(loc[1]))stop('Offset mismatch')
      starts[t] <- cursor+loc[1]-1L; ends[t] <- cursor+loc[2]-1L;cursor <- ends[t]+1L
    }
    a$start <- starts;a$end <- ends
    list(sentence_id=ids[ii],tokens=a[,c('sentence_id','token_id','token','lemma','upos','feats','start','end')])
  })
  write_jsonl(result,target);writeLines(signature,paste0(target,'.sha256'))
  message('Additional sentence annotation ',min(start+99L,length(new)),' / ',length(new))
}
capture.output(sessionInfo(),file=file.path(out,'sessionInfo.txt'))
barometar_write_json(list(source_rows=nrow(sources),missing_sources=sum(is.na(sources$source_name)|!nzchar(sources$source_name)),expanded_documents=length(extended),new_sentences=length(new),model_sha256=digest::digest(file=model_path,algo='sha256'),R=R.version.string,udpipe=as.character(packageVersion('udpipe'))),file.path(out,'prepared.json'))
