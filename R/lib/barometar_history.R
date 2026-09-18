# Public release history is independent of private classification and human labels.
barometar_release_code_hashes <- function() {
  paths <- c("R/lib/barometar_release.R","R/lib/barometar_history.R","R/lib/barometar_metrics.R","R/lib/barometar_figures.R",
    "R/lib/barometar_disclosure.R","R/lib/barometar_page.R","R/lib/barometar_install.R","studies/demokrscanstvo-barometar/lib/io.R",
    "studies/demokrscanstvo-barometar/08_aggregate.R","studies/demokrscanstvo-barometar/09_figures.R",
    "studies/demokrscanstvo-barometar/11_checks.R","studies/demokrscanstvo-barometar/12_update.R")
  setNames(vapply(paths,digikat_hash_file,character(1L)),paths)
}

barometar_release_version <- function(previous=NULL,date=Sys.Date()) {
  base <- format(as.Date(date),"%Y.%m.%d")
  if(is.null(previous)||!startsWith(previous,base))return(base)
  if(!stringi::stri_detect_regex(previous,paste0("^",stringi::stri_replace_all_fixed(base,".","[.]"),"(-[0-9]+)?$")))stop("Invalid previous release version.")
  suffix <- if(identical(previous,base))1L else as.integer(tail(stringi::stri_split_fixed(previous,"-")[[1L]],1L))
  paste0(base,"-",suffix+1L)
}

barometar_empty_revisions <- function()data.frame(table=character(),row_key=character(),frequency=character(),scope=character(),
  period_id=character(),field=character(),previous_value=character(),current_value=character(),previous_release=character(),release_version=character())

barometar_table_revisions <- function(previous,current,table,previous_release,release_version) {
  keys <- switch(table,monthly=c("frequency","scope","period_id"),weekly=c("frequency","scope","period_id"),
    rolling28=c("frequency","scope","period_id"),themes=c("frequency","scope","period_id","theme_id"),
    composition=c("frequency","scope","period_id","facet","value"),sensitivity=c("frequency","scope","period_id","variant"),
    diagnostics=c("frequency","scope","period_id","diagnostic"),concentration=c("frequency","scope","period_id"),outlets=c("outlet_id","year"),NULL)
  if(is.null(keys)||!all(keys %in% names(previous))||!all(keys %in% names(current)))return(barometar_empty_revisions())
  key <- function(x)do.call(paste,c(x[keys],sep="|"))
  old_key <- key(previous);new_key <- key(current)
  if(anyDuplicated(old_key)||anyDuplicated(new_key))stop("Release history requires unique keys: ",table)
  fields <- setdiff(intersect(names(previous),names(current)),c(keys,"release_version","data_through","computed_at","code_commit"))
  out <- list();indices <- match(old_key,new_key)
  value <- function(x)if(is.na(x))"" else if(is.numeric(x))format(x,digits=17L,scientific=FALSE,trim=TRUE) else as.character(x)
  for(i in seq_len(nrow(previous)))for(field in fields) {
    before <- value(previous[[field]][i]);after <- if(is.na(indices[i]))"" else value(current[[field]][indices[i]])
    if(!identical(before,after))out[[length(out)+1L]] <- data.frame(table=table,row_key=old_key[i],
      frequency=if("frequency" %in% names(previous))previous$frequency[i] else "",scope=if("scope" %in% names(previous))previous$scope[i] else "",
      period_id=if("period_id" %in% names(previous))previous$period_id[i] else "",field=field,previous_value=before,current_value=after,
      previous_release=previous_release,release_version=release_version,stringsAsFactors=FALSE)
  }
  if(length(out))as.data.frame(data.table::rbindlist(out)) else barometar_empty_revisions()
}

barometar_prepare_history <- function(tables,summary,directory,previous_directory=NULL,new_edition=FALSE) {
  read <- function(path)utils::read.csv(path,fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE,na.strings="")
  revisions <- barometar_empty_revisions();releases <- NULL
  edition <- substr(summary$latest_publishable_month,1L,7L)
  if(!is.null(previous_directory)) {
    previous <- barometar_read_release(previous_directory,isTRUE(summary$synthetic))$summary
    if(!identical(previous$definition_version,summary$definition_version)||!identical(previous$panel_version,summary$panel_version))stop("Definition/panel migration needs a separately reviewed release.")
    summary$matrix_bins <- previous$matrix_bins
    if(identical(previous$release_version,summary$release_version))stop("A changed release needs a new version.")
    history <- file.path(previous_directory,"izdanja")
    if(dir.exists(history))for(name in list.files(history,recursive=TRUE)) {
      target <- file.path(directory,"izdanja",name);dir.create(dirname(target),recursive=TRUE,showWarnings=FALSE)
      if(!file.copy(file.path(history,name),target,overwrite=FALSE))stop("Could not preserve frozen edition: ",name)
    }
    if(!new_edition) {
      edition <- previous$edition
      summary$findings <- previous$findings
    }
    revisions <- read(file.path(previous_directory,"revisions.csv"))
    for(name in names(tables)) {
      path <- file.path(previous_directory,paste0(name,".csv"))
      if(file.exists(path))revisions <- as.data.frame(data.table::rbindlist(list(revisions,
        barometar_table_revisions(read(path),read(file.path(directory,paste0(name,".csv"))),name,previous$release_version,summary$release_version)),fill=TRUE))
    }
    releases <- read(file.path(previous_directory,"releases.csv"))
  }
  summary$edition <- edition
  row <- data.frame(release_version=summary$release_version,data_through=summary$data_through,
    definition_version=summary$definition_version,panel_version=summary$panel_version,edition=edition)
  releases <- as.data.frame(data.table::rbindlist(list(releases,row),fill=TRUE))
  summary$releases <- lapply(seq_len(nrow(releases)),function(i)as.list(releases[i,]))
  frozen <- file.path(directory,"izdanja",edition,"summary.json")
  if(file.exists(frozen)&&new_edition)stop("Monthly edition already frozen; use a new edition instead of rewriting it.")
  if(!file.exists(frozen))barometar_write_json(summary,frozen)
  summary$edition_summary_sha256 <- digikat_hash_file(frozen)
  barometar_write_csv(releases,file.path(directory,"releases.csv"))
  barometar_write_csv(revisions,file.path(directory,"revisions.csv"))
  summary
}
