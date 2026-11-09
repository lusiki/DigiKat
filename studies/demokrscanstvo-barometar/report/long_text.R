# Fixed-model longer-text sensitivity on the purposive development set.
source('studies/demokrscanstvo-barometar/lib/io.R',encoding='UTF-8')
invisible(Sys.setlocale('LC_CTYPE','English_United States.utf8'))
p <- file.path(barometar_workdir(),'analytical-report-v1')
docs <- jsonlite::fromJSON(file.path(p,'development_review.json'),simplifyVector=FALSE)
target <- file.path(p,'long-tokens')
dir.create(target,showWarnings=FALSE)
model <- udpipe::udpipe_load_model('resources/models/croatian-set-ud-2.5-191206.udpipe')
for(i in seq_along(docs)) {
  d <- docs[[i]];file <- file.path(target,paste0(i,'.json'))
  txt <- paste(d$title,d$body,sep='\n')
  sig <- digest::digest(txt,algo='sha256',serialize=FALSE)
  if(file.exists(file) && identical(jsonlite::fromJSON(file)$input_sha256,sig))next
  a <- as.data.frame(udpipe::udpipe_annotate(model,x=txt,doc_id=d$record_key,parser='none'))
  selected <- a$lemma[a$upos %in% c('NOUN','PROPN','ADJ') & !is.na(a$lemma)]
  barometar_write_json(list(record_key=d$record_key,input_sha256=sig,lemmas=tolower(selected),characters=nchar(txt)),file)
  message('Long text ',i,' / ',length(docs))
}
