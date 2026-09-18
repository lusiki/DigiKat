# Emit bounded private development windows for an assistant reviewer.
# These are NEVER reported human labels. No source titles/URLs are emitted.
source("studies/demokrscanstvo-barometar/03_candidates.R",encoding="UTF-8")
args <- as.integer(commandArgs(trailingOnly=TRUE))
if(length(args)!=2L || anyNA(args))stop("Supply first and last development indices.")
workdir <- barometar_workdir()
manifest <- readRDS(file.path(workdir,"development_review_manifest.rds"))
review <- readRDS(file.path(manifest$folder,"review-private.rds"))
boilerplate <- readRDS(file.path(workdir,"boilerplate.rds"))
indices <- seq.int(args[1L],min(args[2L],nrow(review$rows)))
log <- review$rows[indices,c("doc_key","article_hash","purpose")]
log$coder <- "Codex assistant; not human validation";log$read_date <- "2026-09-18"
barometar_write_csv(log,file.path(manifest$folder,sprintf("agent_reads_%03d_%03d.csv",min(indices),max(indices))))
for(i in indices) {
  row <- review$rows[i,];result <- review$results[[i]]
  stopifnot(row$development)
  prepared <- barometar_prepare_text(row$TITLE,row$FULL_TEXT)
  keys <- boilerplate$segment_key[boilerplate$outlet_id==row$outlet_id & boilerplate$month==substr(row$day,1L,7L)]
  texts <- list(title=barometar_normalize_text(row$TITLE),body=barometar_normalize_text(barometar_mask_boilerplate(prepared$body,keys)$body))
  h <- result$evidence
  windows <- Filter(function(w)w$field=="body",result$windows)
  if(!length(windows)) {
    anchors <- which(h$field=="body" & (h$family %in% c("cd_label","grounding","church_speaker","actor_church") |
      h$source_group %in% c("doctrinal_anchors.yaml","concept_families.yaml")))
    priority <- ifelse(h$source_group[anchors]=="doctrinal_anchors.yaml",1L,
      ifelse(h$family[anchors] %in% c("cd_label","grounding"),2L,ifelse(h$source_group[anchors]=="concept_families.yaml",3L,4L)))
    anchors <- anchors[order(priority,h$start[anchors])]
    anchors <- anchors[!duplicated(h$entry_id[anchors])]
    anchors <- head(anchors,4L)
    windows <- lapply(anchors,function(at)list(field=h$field[at],start=h$start[at],end=h$end[at],route="probe"))
  }
  snippets <- unique(vapply(head(windows,4L),function(w) {
    txt <- texts[[w$field]];tokens <- barometar_tokens(txt)
    centre <- max(1L,findInterval(w$start,tokens$start));first <- max(1L,centre-15L);last <- min(nrow(tokens),first+79L)
    snippet <- stringi::stri_sub(txt,tokens$start[first],tokens$end[last])
    normalized_title <- barometar_normalize_text(row$TITLE)
    if(!is.na(normalized_title) && nzchar(normalized_title))snippet <- stringi::stri_replace_all_fixed(snippet,normalized_title,"[naslov uklonjen]")
    snippet
  },character(1L)))
  cat(jsonlite::toJSON(list(index=i,purpose=row$purpose,batch=row$source_batch,
    routes=result$routes,themes=result$themes,masked_chars=result$masked_chars,passages=snippets),auto_unbox=TRUE),"\n")
}
