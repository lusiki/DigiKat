# Fixed-sample morphology verification only; never classifies documents.
# Restricted token/count artifacts stay in the configured private workdir.
source("studies/demokrscanstvo-barometar/03_candidates.R", encoding="UTF-8")

barometar_morphology_stems <- function() {
  builder <- paste(readLines("studies/demokrscanstvo-barometar/build_definition.py",encoding="UTF-8",warn=FALSE),collapse="\n")
  calls <- stringi::stri_extract_all_regex(builder,"(?:adj|nf|nm|nn|forms)\\('[^']+'",omit_no_match=TRUE)[[1L]]
  derived <- stringi::stri_match_first_regex(calls,"^[^']+'([^']+)'")[,2L]
  # Literal paradigms, allomorphs and deliberately broad near-homonym probes.
  # Broad stems retrieve review candidates; they never become matching rules.
  extra <- stringi::stri_split_regex(paste(
    "demokršć demokrsc demohrišć demo-kršć kršćansk krscansk hrišćansk",
    "christdemokrat christlich democristian democrat democrac cristian",
    "načel vrijedn tradicij ideolog doktrin identitet nadahnu baštin korijen",
    "svjetonazor orijentacij etik misao misl mišl koncept idej",
    "strank stranc stranak unij klub koalicij kandidat čelni vođ kancelar",
    "premijer zastupni frakcij vlad izbor birač ministr politič",
    "socijaln društven nauk crkv crkav katolič katolic učenj",
    "opć opc univerzaln namjen dobr opredjeljenj opcij siromašn povlašten ljubav",
    "integraln ekolog personaliz personalist enciklik enciklic",
    "dostojanst ljudsk osob čovjek rad radni radnic vjersk slobod savjest savješ",
    "solidarn pravd prav pravedn plać neradn nedjelj supsidijarn subsidiar",
    "građansk participacij civiln lokaln samouprav tržišn gospodarstv ekonomij",
    "zajedničk partnerstv obitelj demograf roditelj dopust dječ doplat",
    "zaštit život nerođen odgoj pobačaj abortus eutanaz medicinsk potpomognut",
    "oplodnj palijativn skrb hod vjeronauk škol",
    "demokracij demokratij pluraliz vladavin ustav zakon javn",
    "mirov mir pomirenj europsk europ brig briz zajedničk dom okoliš",
    "evanđelj evanđeosk savjest biskup nadbiskup pap karitas caritas",
    "proračun porez sud općin gradonačelni županij ministarstv",
    "zahtijev protiv polaz temel traž bran zala poziv pozv",
    "istič ističu istakn rek kaž kaz navod smatr predlož predlag",
    "uveo uvest unije unijet slijed primjen proved",
    "predstav prijevod obljetnic promoc objav odgovorn tužb jamč",
    "hdz hbk cdu csu övp epp eppo eps hss hkdu hkds hds nsi",
    "rerum quadragesim mater magistra pacem terris gaudium spes populorum progressio",
    "octogesim adveniens laborem exercens sollicitud socialis centesim annus",
    "veritate evangelii gaudium laudat fratelli tutti dignitas infinita",
    "njemačk austrij talij bavars francusk hrvatsk bosn hercegov sloveni poljsk zagreb"
  )," +")[[1L]]
  stems <- sort(unique(stringi::stri_trans_tolower(stringi::stri_trans_nfc(c(derived,extra)),"hr")))
  data.frame(stem=stems,source=ifelse(stems%in%derived,"builder_paradigm","brief_literal_allomorph_or_exclusion_probe"),stringsAsFactors=FALSE)
}

barometar_morphology_units <- function(txt) {
  word <- stringi::stri_extract_all_regex(txt,"[\\p{L}\\p{M}]+",omit_no_match=TRUE)[[1L]]
  compound <- stringi::stri_extract_all_regex(txt,"[\\p{L}\\p{M}]+(?:[-\\x{2010}-\\x{2015}][\\p{L}\\p{M}]+)+",omit_no_match=TRUE)[[1L]]
  data.frame(unit=c(word,compound),unit_kind=c(rep("word",length(word)),rep("compound",length(compound))),stringsAsFactors=FALSE)
}

barometar_audit_morphology <- function(workdir=NULL) {
  workdir <- barometar_workdir(workdir)
  manifest <- readRDS(file.path(workdir,"development_review_manifest.rds"))
  review_path <- file.path(manifest$folder,"review-private.rds")
  review <- readRDS(review_path)
  stopifnot(nrow(review$rows)==217L,all(review$rows$development),!anyDuplicated(review$rows$doc_key))
  definition <- barometar_definition()
  stems <- barometar_morphology_stems()
  folder <- file.path(manifest$folder,"morphology")
  dir.create(folder,showWarnings=FALSE)
  # Snapshot the inputs privately before extraction; concurrent definition edits
  # after this point do not change the dictionary object used in this audit.
  snapshot <- list(sample_sha256=digest::digest(file=review_path,algo="sha256"),
    ordered_key_sha256=digest::digest(review$rows$doc_key,algo="sha256"),
    definition_version=definition$definition_version,definition_hash=definition$definition_hash,
    builder_sha256=digest::digest(file="studies/demokrscanstvo-barometar/build_definition.py",algo="sha256"),
    script_sha256=digest::digest(file="studies/demokrscanstvo-barometar/audit_morphology.R",algo="sha256"),
    date="2026-09-18",documents=nrow(review$rows),reviewer="Codex assistant; not human validation",
    strata="Existing fixed purposive sample; purpose x source_batch; no resampling")
  saveRDS(snapshot,file.path(folder,"snapshot.rds"))
  saveRDS(definition,file.path(folder,"definition_snapshot.rds"))
  barometar_write_csv(stems,file.path(folder,"stem_catalog.csv"))
  strata <- aggregate(rep(1L,nrow(review$rows)),review$rows[,c("purpose","source_batch")],sum)
  names(strata)[3L] <- "documents"
  barometar_write_csv(strata,file.path(folder,"sample_strata.csv"))
  bp <- readRDS(file.path(workdir,"boilerplate.rds"))
  rows <- vector("list",2L*nrow(review$rows)); at <- 0L
  stem_pattern <- paste0("^(?:",paste(paste0("\\Q",stems$stem,"\\E"),collapse="|"),")")
  for(i in seq_len(nrow(review$rows))) {
    row <- review$rows[i,]
    prepared <- barometar_prepare_text(row$TITLE,row$FULL_TEXT)
    keys <- bp$segment_key[bp$outlet_id==row$outlet_id & bp$month==substr(row$day,1L,7L)]
    fields <- list(title=barometar_normalize_text(row$TITLE),
      body=barometar_normalize_text(barometar_mask_boilerplate(prepared$body,keys)$body))
    for(field in names(fields)) {
      txt <- fields[[field]]
      if(is.na(txt)||!nzchar(txt))next
      units <- barometar_morphology_units(txt)
      units$token <- stringi::stri_trans_tolower(stringi::stri_trans_nfc(units$unit),"hr")
      units <- units[stringi::stri_detect_regex(units$token,stem_pattern),c("token","unit_kind")]
      if(!nrow(units))next
      counted <- aggregate(rep(1L,nrow(units)),units,sum)
      names(counted)[3L] <- "count"
      counted$sample_index <- i;counted$field <- field
      counted$purpose <- row$purpose;counted$source_batch <- row$source_batch
      at<-at+1L;rows[[at]]<-counted
    }
  }
  tokens <- do.call(rbind,rows[seq_len(at)])
  # No original text, headline or URL is written by this verifier.
  saveRDS(tokens,file.path(folder,"token_counts_by_sample_private.rds"))
  form_map <- do.call(rbind,lapply(definition$compiled,function(rule){
    e <- rule$entry
    positive <- unique(c(e$forms,e$ascii_variants,unlist(e$slots,use.names=FALSE)))
    excluded <- e$excluded_forms
    parts <- function(v,status) {
      if(!length(v))return(NULL)
      u<-do.call(rbind,lapply(v,barometar_morphology_units))
      u$token<-stringi::stri_trans_tolower(stringi::stri_trans_nfc(u$unit),"hr")
      unique(data.frame(entry_id=e$id,token=u$token,unit_kind=u$unit_kind,status=status,stringsAsFactors=FALSE))
    }
    rbind(parts(positive,"enumerated_component"),parts(excluded,"excluded_component"))
  }))
  saveRDS(form_map,file.path(folder,"form_map_private.rds"))
  pairs <- unique(tokens[,c("token","unit_kind")])
  out <- lapply(seq_len(nrow(pairs)),function(i){
    token<-pairs$token[i];kind<-pairs$unit_kind[i]
    rr<-tokens[tokens$token==token & tokens$unit_kind==kind,]
    ff<-form_map[form_map$token==token & form_map$unit_kind==kind,]
    includes<-sort(unique(ff$entry_id[ff$status=="enumerated_component"]))
    excludes<-sort(unique(ff$entry_id[ff$status=="excluded_component"]))
    matching_stems<-stems$stem[startsWith(token,stems$stem)]
    data.frame(token=token,unit_kind=kind,stems=paste(matching_stems,collapse=";"),
      token_count=sum(rr$count),document_count=length(unique(rr$sample_index)),
      body_count=sum(rr$count[rr$field=="body"]),title_count=sum(rr$count[rr$field=="title"]),
      strata_count=length(unique(paste(rr$purpose,rr$source_batch))),
      enumerated_in=paste(includes,collapse=";"),excluded_in=paste(excludes,collapse=";"),
      membership=if(length(includes))"enumerated_component" else if(length(excludes))"excluded_component" else "not_enumerated",
      decision=if(length(includes))"retain_enumerated_contextually" else if(length(excludes))"retain_excluded_contextually" else "review_required",
      reason=if(length(includes))"Existing token or phrase-slot component; phrase/role restrictions still apply." else if(length(excludes))"Existing excluded phrase component; exclusion remains context-dependent." else "",
      stringsAsFactors=FALSE)
  })
  out<-do.call(rbind,out)
  out<-out[order(out$membership,-out$token_count,out$token,method="radix"),]
  decisions_path<-file.path(folder,"review_decisions.csv")
  if(file.exists(decisions_path)) {
    decisions<-read.csv(decisions_path,fileEncoding="UTF-8",stringsAsFactors=FALSE)
    stopifnot(all(c("token","unit_kind","decision","reason")%in%names(decisions)),
      !anyDuplicated(paste(decisions$token,decisions$unit_kind)))
    idx<-match(paste(out$token,out$unit_kind),paste(decisions$token,decisions$unit_kind))
    hit<-!is.na(idx);out$decision[hit]<-decisions$decision[idx[hit]];out$reason[hit]<-decisions$reason[idx[hit]]
  }
  barometar_write_csv(out,file.path(folder,"token_form_review_private.csv"))
  stratum_counts<-aggregate(tokens$count,tokens[,c("token","unit_kind","purpose","source_batch")],sum)
  names(stratum_counts)[5L]<-"token_count"
  barometar_write_csv(stratum_counts,file.path(folder,"token_counts_by_stratum_private.csv"))
  # Actor completeness is static inventory inspection, not party affiliation inference.
  actor_document<-definition$documents[["actors.yaml"]]
  registry<-actor_document$registry
  required<-c("id","name_hr","aliases","role","valid_from","valid_to","country","sources","status")
  actors<-do.call(rbind,lapply(registry,function(x)data.frame(id=x$id,role=x$role,
    missing_fields=paste(setdiff(required,names(x)),collapse=";"),
    valid_from=x$valid_from,valid_to=x$valid_to,status=x$status,stringsAsFactors=FALSE)))
  barometar_write_csv(actors,file.path(folder,"actor_registry_schema_review.csv"))
  summary<-list(status="development_morphology_audit_not_validation",snapshot=snapshot,
    stem_count=nrow(stems),unique_units=nrow(out),word_units=sum(out$unit_kind=="word"),
    compound_units=sum(out$unit_kind=="compound"),membership=as.list(table(out$membership)),
    decisions=as.list(table(out$decision)),registry_records=length(registry),
    rule_actor_entries=sum(vapply(definition$compiled,function(x)startsWith(x$family,"actor_"),logical(1L))),
    note="Token/slot membership is not phrase matching or document classification. Compound and word counts overlap.")
  jsonlite::write_json(summary,file.path(folder,"summary.json"),pretty=TRUE,auto_unbox=TRUE)
  cat(jsonlite::toJSON(summary[c("status","stem_count","unique_units","word_units","compound_units","membership","decisions","registry_records","rule_actor_entries")],auto_unbox=TRUE),"\n")
  invisible(summary)
}
barometar_finalize_morphology_review <- function(workdir=NULL) {
  workdir<-barometar_workdir(workdir)
  manifest<-readRDS(file.path(workdir,"development_review_manifest.rds"))
  folder<-file.path(manifest$folder,"morphology")
  out<-read.csv(file.path(folder,"token_form_review_private.csv"),fileEncoding="UTF-8",stringsAsFactors=FALSE)
  decisions<-read.csv(file.path(folder,"review_decisions.csv"),fileEncoding="UTF-8",stringsAsFactors=FALSE)
  stopifnot(!anyDuplicated(paste(decisions$token,decisions$unit_kind)))
  at<-match(paste(out$token,out$unit_kind),paste(decisions$token,decisions$unit_kind))
  hit<-!is.na(at)
  out$decision[hit]<-decisions$decision[at[hit]]
  out$reason[hit]<-decisions$reason[at[hit]]
  stopifnot(all(nzchar(out$reason)),!any(out$decision=="review_required"))
  barometar_write_csv(out,file.path(folder,"token_form_review_private.csv"))
  summary<-jsonlite::read_json(file.path(folder,"summary.json"),simplifyVector=FALSE)
  summary$decisions<-as.list(table(out$decision))
  summary$review_status<-"Complete assistant token-inventory review; proposed decisions require definition implementation and tests"
  summary$decision_sha256<-digest::digest(file=file.path(folder,"review_decisions.csv"),algo="sha256")
  summary$finalizer_script_sha256<-digest::digest(file="studies/demokrscanstvo-barometar/audit_morphology.R",algo="sha256")
  summary$remaining_unreviewed<-0L
  jsonlite::write_json(summary,file.path(folder,"summary.json"),pretty=TRUE,auto_unbox=TRUE)
  cat(jsonlite::toJSON(summary[c("unique_units","decisions","remaining_unreviewed","review_status")],auto_unbox=TRUE),"\n")
  invisible(summary)
}
if(sys.nframe()==0L) {
  if("--finalize"%in%commandArgs(trailingOnly=TRUE))barometar_finalize_morphology_review()
  else barometar_audit_morphology()
}
