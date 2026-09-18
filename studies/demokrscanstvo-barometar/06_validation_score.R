# Import actual human exports. Never creates or infers a human answer.
source("studies/demokrscanstvo-barometar/05_validation_draw.R",encoding="UTF-8")

barometar_check_coding_package <- function(folder,draw) {
  path <- file.path(folder,"package_manifest.json")
  if(!file.exists(path))stop("Coding package integrity manifest is missing.")
  manifest <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  required <- c("draw.rds","draw_membership_private.csv","human_PI.html","human_second.html")
  if(!identical(manifest$draw_id,draw$draw_id) || !setequal(names(manifest$files),required))stop("Invalid coding package manifest.")
  for(name in required)if(!file.exists(file.path(folder,name)) || !identical(manifest$files[[name]],digikat_hash_file(file.path(folder,name))))stop("Coding package was altered: ",name)
  identity <- barometar_draw_identity(draw)
  if(!identical(identity,draw$draw_id))stop("Frozen draw identity mismatch.")
  current <- setNames(vapply(c("R/lib/barometar_validation.R","R/lib/barometar_coding.R","studies/demokrscanstvo-barometar/coder_template.html"),digikat_hash_file,character(1L)),c("sampling","context","template"))
  if(!identical(draw$input_identity$code_hashes,current))stop("Sampling, context or coding template changed since the draw.")
  invisible(TRUE)
}

barometar_read_human_export <- function(path,draw,role) {
  if(!file.exists(path))stop("Missing human export: ",basename(path))
  export <- jsonlite::fromJSON(path,simplifyVector=TRUE)
  if(!identical(export$draw_id,draw$draw_id) || !identical(export$definition_version,draw$definition_version) ||
     !identical(export$coder_type,role))stop("Human export belongs to another draw, definition or role.")
  if(is.null(export$coder_name) || length(export$coder_name)!=1L || !nzchar(trimws(export$coder_name)))stop("Human export requires the coder's name.")
  ids <- draw$assignments$item_id
  if(role=="human_second")ids <- ids[draw$assignments$double_code]
  export$answers <- barometar_validate_coding(export$answers,ids,role)
  export
}

barometar_adjudication_requirements <- function(pi,second,adjudicated=NULL) {
  fields <- c("qualifies","construct","speaker_type","geography","register","themes","axis1","axis2","axis3","axis4","masked_evidence")
  canonical <- function(x)paste(sort(unique(stringi::stri_split_fixed(x,";")[[1L]])),collapse=";")
  changed <- function(left,right) {
    ids <- intersect(left$item_id,right$item_id)
    rows <- lapply(ids,function(id) {
      a <- left[left$item_id==id,,drop=FALSE];b <- right[right$item_id==id,,drop=FALSE]
      different <- fields[vapply(fields,function(field)!identical(canonical(a[[field]]),canonical(b[[field]])),logical(1L))]
      if(!length(different))return(NULL)
      data.frame(item_id=id,fields=paste(different,collapse=";"),stringsAsFactors=FALSE)
    })
    as.data.frame(data.table::rbindlist(rows,fill=TRUE))
  }
  disagreements <- changed(pi,second)
  revisions <- if(is.null(adjudicated))data.frame() else changed(pi,adjudicated)
  all <- data.table::rbindlist(list(disagreements,revisions),fill=TRUE)
  if(!nrow(all))return(data.frame(item_id=character(),fields=character(),reason=character()))
  result <- aggregate(fields~item_id,as.data.frame(all),function(x)paste(sort(unique(unlist(stringi::stri_split_fixed(x,";")))),collapse=";"))
  result$reason <- ""
  result
}

barometar_score_human_exports <- function(pi_path,second_path,adjudicated_path=NULL,log_path=NULL) {
  workdir <- barometar_workdir();definition <- barometar_definition()
  folder <- file.path(workdir,"validation",definition$definition_version)
  draw <- readRDS(file.path(folder,"draw.rds"))
  if(!identical(draw$definition_version,definition$definition_version))stop("Definition changed after the human draw.")
  barometar_check_coding_package(folder,draw)
  pi <- barometar_read_human_export(pi_path,draw,"human_PI")
  second <- barometar_read_human_export(second_path,draw,"human_second")
  if(identical(tolower(trimws(pi$coder_name)),tolower(trimws(second$coder_name))))stop("The second coder must be a different human.")
  if(is.null(adjudicated_path)) {
    # A template is not an adjudicated label set. The human must review it and
    # explicitly mark review complete in the returned JSON before scoring.
    draft <- pi;draft$coder_type <- "human_PI_adjudicated"
    draft$answers$coder_type <- "human_PI_adjudicated";draft$human_review_complete <- FALSE
    target <- file.path(folder,"adjudication-template.json")
    if(file.exists(target))stop("Adjudication template already exists; refusing to overwrite human work.")
    barometar_write_json(draft,target)
    barometar_write_csv(barometar_adjudication_requirements(pi$answers,second$answers),file.path(folder,"adjudication-log-template.csv"))
    saveRDS(list(pi=pi,second=second),file.path(folder,"paired-human-exports-private.rds"))
    message("Adjudication templates prepared privately. No validation estimate produced.")
    return(invisible(folder))
  }
  final <- barometar_read_human_export(adjudicated_path,draw,"human_PI_adjudicated")
  if(!isTRUE(final$human_review_complete) || !identical(trimws(final$coder_name),trimws(pi$coder_name)))stop("Adjudication requires the PI's completed human review.")
  required <- barometar_adjudication_requirements(pi$answers,second$answers,final$answers)
  if(is.null(log_path) || !file.exists(log_path))stop("An adjudication log is required, including an empty header-only log when no disagreement exists.")
  log <- utils::read.csv(log_path,fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE,na.strings="")
  if(!all(c("item_id","fields","reason") %in% names(log)) || anyDuplicated(log$item_id) ||
     !all(required$item_id %in% log$item_id) || any(!log$item_id %in% draw$assignments$item_id))stop("Adjudication log omits disagreements/revisions or has invalid IDs.")
  if(nrow(required)) {
    audited <- log[match(required$item_id,log$item_id),,drop=FALSE]
    if(anyNA(audited$reason) || any(!nzchar(trimws(audited$reason))))stop("Every disagreement/revision needs the PI's explanation.")
    if(any(!vapply(seq_len(nrow(required)),function(i)all(stringi::stri_split_fixed(required$fields[i],";")[[1L]] %in%
      stringi::stri_split_fixed(audited$fields[i],";")[[1L]]),logical(1L))))stop("Adjudication log omits changed fields.")
  }
  result <- barometar_score_validation(draw,pi$answers,second$answers,final$answers,definition$definition_version)
  result$draw_id <- draw$draw_id
  result$input_hashes <- setNames(vapply(c(pi_path,second_path,adjudicated_path,log_path),digikat_hash_file,character(1L)),c("pi","second","adjudicated","log"))
  result$human_validation_complete <- TRUE
  saveRDS(result,file.path(folder,"validation-result.rds"))
  for(name in c("validation","per_batch","theme_precision","miss_diagnostics","route_set_precision"))
    barometar_write_csv(result[[name]],file.path(folder,paste0(name,".csv")))
  message("Actual human exports scored. Release scope: ",result$release_scope,". Bridge, disclosure and licence gates still apply.")
  invisible(result)
}

if(barometar_script_main("06_validation_score.R")) {
  args <- commandArgs(trailingOnly=TRUE)
  take <- function(key,required=FALSE) {
    value <- args[startsWith(args,paste0("--",key,"="))]
    if(length(value)>1L || (required && !length(value)))stop("Expected one --",key,"=path")
    if(length(value))substring(value,nchar(key)+4L) else NULL
  }
  if(any(!vapply(args,function(x)any(startsWith(x,paste0("--",c("pi","second","adjudicated","log"),"="))),logical(1L))))stop("Unknown scoring argument.")
  barometar_score_human_exports(take("pi",TRUE),take("second",TRUE),take("adjudicated"),take("log"))
}
