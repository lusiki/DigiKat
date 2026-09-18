# Read-only corpus access; writes private review metadata/logs only.
# Restricted development passages are emitted only in explicit bounded show mode.
source("studies/demokrscanstvo-barometar/03_candidates.R",encoding="UTF-8")
args <- commandArgs(trailingOnly=TRUE)
if(!length(args) || !args[1L] %in% c("plan","show"))stop("Use plan, or show followed by up to 12 indices.")
workdir <- barometar_workdir()
manifest <- readRDS(file.path(workdir,"development_review_manifest.rds"))
review <- readRDS(file.path(manifest$folder,"review-private.rds"))
baseline <- readRDS(file.path(workdir,"development","0b9148a121ce247ea0621469","review-private.rds"))
stopifnot(all(review$rows$development),all(baseline$rows$development))
old_index <- match(review$rows$doc_key,baseline$rows$doc_key)
fields <- c("routes","themes","principles","register","reference_geography","speaker_type","hdz_only","masked_chars")
canonical <- function(x)paste(sort(unique(as.character(x))),collapse=";")
changed <- vapply(seq_len(nrow(review$rows)),function(i) {
  old <- old_index[i]
  if(is.na(old))return("new_sample")
  # A formerly absent output field is not by itself a changed content decision.
  applicable <- fields[fields %in% names(baseline$results[[old]])]
  paste(applicable[vapply(applicable,function(f)!identical(
    canonical(review$results[[i]][[f]]),canonical(baseline$results[[old]][[f]])),logical(1L))],collapse=";")
},character(1L))
delta <- data.frame(index=seq_len(nrow(review$rows)),old_index=old_index,
  doc_key=review$rows$doc_key,article_hash=review$rows$article_hash,changed=changed)
delta <- delta[nzchar(delta$changed),]
identity <- list(definition_version=review$definition_version,definition_hash=review$definition_hash,
  boilerplate_version=review$boilerplate_version,
  review_sha256=digest::digest(file=file.path(manifest$folder,"review-private.rds"),algo="sha256",serialize=FALSE))
if(args[1L]=="plan") {
  saveRDS(list(identity=identity,delta=delta),file.path(manifest$folder,"nlp_delta_plan_private.rds"))
  barometar_write_csv(delta,file.path(manifest$folder,"nlp_delta_plan_private.csv"))
  cat(jsonlite::toJSON(list(identity=identity,n_current=nrow(review$rows),n_baseline=nrow(baseline$rows),
    new_samples=sum(is.na(old_index)),removed_samples=sum(!baseline$rows$doc_key %in% review$rows$doc_key),
    changed=delta[,c("index","old_index","changed")]),auto_unbox=TRUE),"\n")
} else {
  indices <- as.integer(args[-1L])
  if(!length(indices) || length(indices)>12L || anyNA(indices) || any(!indices %in% delta$index))
    stop("Show requires 1-12 indices from the changed/new development set.")
  boilerplate <- readRDS(file.path(workdir,"boilerplate.rds"))
  if(!identical(attr(boilerplate,"boilerplate_version"),review$boilerplate_version))
    stop("Current boilerplate and review snapshot differ; wait for the completed final review.")
  log <- review$rows[indices,c("doc_key","article_hash","purpose")]
  log$coder <- "Codex assistant development delta review; not human validation"
  log$read_date <- "2026-09-18"
  log$definition_version <- review$definition_version
  barometar_write_csv(log,file.path(manifest$folder,paste0("delta_reads_",paste(indices,collapse="_"),".csv")))
  for(i in indices) {
    row <- review$rows[i,];result <- review$results[[i]]
    prepared <- barometar_prepare_text(row$TITLE,row$FULL_TEXT)
    keys <- boilerplate$segment_key[boilerplate$outlet_id==row$outlet_id & boilerplate$month==substr(row$day,1L,7L)]
    txt <- barometar_normalize_text(barometar_mask_boilerplate(prepared$body,keys)$body)
    h <- result$evidence
    windows <- Filter(function(w)w$field=="body",result$windows)
    if(!length(windows)) {
      anchors <- which(h$field=="body" & (h$family %in% c("cd_label","grounding","church_speaker","actor_church") |
        h$source_group %in% c("doctrinal_anchors.yaml","concept_families.yaml")))
      priority <- ifelse(h$source_group[anchors]=="doctrinal_anchors.yaml",1L,
        ifelse(h$family[anchors] %in% c("cd_label","grounding"),2L,3L))
      anchors <- anchors[order(priority,h$start[anchors])]
      anchors <- head(anchors[!duplicated(h$entry_id[anchors])],4L)
      windows <- lapply(anchors,function(at)list(start=h$start[at],end=h$end[at]))
    }
    tokens <- barometar_tokens(txt)
    snippets <- unique(vapply(head(windows,4L),function(w) {
      centre <- max(1L,findInterval(w$start,tokens$start))
      first <- max(1L,centre-15L);last <- min(nrow(tokens),first+79L)
      snippet <- stringi::stri_sub(txt,tokens$start[first],tokens$end[last])
      title <- barometar_normalize_text(row$TITLE)
      if(!is.na(title) && nzchar(title))snippet <- stringi::stri_replace_all_fixed(snippet,title,"[naslov uklonjen]")
      snippet
    },character(1L)))
    old <- old_index[i]
    old_fields <- if(is.na(old))NULL else baseline$results[[old]][intersect(fields,names(baseline$results[[old]]))]
    cat(jsonlite::toJSON(list(index=i,old_index=old,changed=changed[i],
      old=old_fields,current=result[intersect(fields,names(result))],
      facets=result$facets,passages=snippets),auto_unbox=TRUE),"\n")
  }
}
