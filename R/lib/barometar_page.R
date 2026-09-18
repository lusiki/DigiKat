# Page reads an already-built release; rendering never opens a source database.
barometar_matrix_bin <- function(value,bins)sum(value>bins+1e-10)
barometar_validation_number <- function(x)if(length(x)!=1L||is.na(x))"—" else formatC(x,format="f",digits=3L,decimal.mark=",")

barometar_read_release <- function(directory, synthetic_allowed=FALSE) {
  summary_path <- file.path(directory,"summary.json")
  manifest_path <- file.path(directory,"manifest.json")
  if(!file.exists(summary_path)||!file.exists(manifest_path))stop("Barometer release missing; complete validation/install, or use the explicit synthetic preview.")
  summary <- jsonlite::fromJSON(summary_path,simplifyVector=FALSE)
  manifest <- jsonlite::fromJSON(manifest_path,simplifyVector=FALSE)
  if(isTRUE(summary$synthetic) && !synthetic_allowed)stop("Synthetic data cannot be used for a production render.")
  if(!isTRUE(summary$synthetic) && !isTRUE(summary$human_validation_complete))stop("Human validation gate is incomplete.")
  if(!identical(summary$data_through,manifest$data_through))stop("Manifest data-cutoff mismatch.")
  minimum <- c("monthly.csv","weekly.csv","rolling28.csv","summary.json")
  required <- if(isTRUE(summary$synthetic))minimum else c(minimum,"themes.csv","composition.csv","sensitivity.csv",
    "outlets.csv","validation.csv","diagnostics.csv","validation_summary.json","bridge_summary.csv","definitions_v1.json","releases.csv","revisions.csv","README.md")
  if(!all(required %in% names(manifest$files)))stop("Incomplete release manifest.")
  for(name in names(manifest$files)) {
    if(stringi::stri_detect_regex(name,"(?:^/|^[A-Za-z]:|\\\\|(?:^|/)\\.\\.(?:/|$))"))stop("Unsafe release filename.")
    path <- file.path(directory,name)
    if(!file.exists(path)||!identical(digest::digest(file=path,algo="sha256",serialize=FALSE),manifest$files[[name]]))stop("Release hash mismatch: ",name)
  }
  tables <- setNames(lapply(c("monthly","weekly","rolling28"),function(name) {
    utils::read.csv(file.path(directory,paste0(name,".csv")),fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE,na.strings="")
  }),c("monthly","weekly","rolling28"))
  for(name in c("themes","composition","diagnostics","validation","sensitivity","concentration","outlets","releases","revisions","bridge_summary"))
    if(file.exists(file.path(directory,paste0(name,".csv")))) {
      if(!paste0(name,".csv") %in% names(manifest$files))stop("Unmanifested page input: ",name)
      tables[[name]] <- utils::read.csv(file.path(directory,paste0(name,".csv")),fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE,na.strings="")
    }
  read_json <- function(name) {
    if(!name %in% names(manifest$files))stop("Unmanifested page input: ",name)
    jsonlite::fromJSON(file.path(directory,name),simplifyVector=FALSE)
  }
  edition <- NULL
  if(!is.null(summary$edition)) {
    if(!stringi::stri_detect_regex(summary$edition,"^[0-9]{4}-[0-9]{2}$"))stop("Invalid dated edition.")
    name <- paste0("izdanja/",summary$edition,"/summary.json")
    edition <- read_json(name)
    if(!identical(manifest$files[[name]],summary$edition_summary_sha256))stop("Dated edition hash mismatch.")
    if(!identical(edition$edition,summary$edition))stop("Dated edition identifier mismatch.")
  } else if(!isTRUE(summary$synthetic))stop("Dated edition missing.")
  definitions <- if("definitions_v1.json" %in% names(manifest$files))read_json("definitions_v1.json") else NULL
  validation <- if("validation_summary.json" %in% names(manifest$files))read_json("validation_summary.json") else NULL
  list(summary=summary,tables=tables,edition=edition,definitions=definitions,validation=validation)
}

# Align diagnostics by key, never CSV row order. They never enter a numerator.
barometar_a2_series <- function(series,diagnostics) {
  d <- series[series$scope=="uze",,drop=FALSE]
  if(is.null(diagnostics)||!nrow(d))return(d[FALSE,])
  a <- diagnostics[diagnostics$scope=="uze" & diagnostics$diagnostic=="A2",,drop=FALSE]
  key <- function(x)paste(x$frequency,x$period_id,sep="|")
  if(anyDuplicated(key(a)))stop("Duplicate A2 diagnostic key.")
  i <- match(key(d),key(a))
  if(anyNA(i))stop("Missing A2 diagnostic period.")
  if(any(d$total_articles!=a$total_articles[i]))stop("A2 diagnostic denominator mismatch.")
  d$matching_articles <- a$articles[i]
  d$visibility_per_10000 <- ifelse(d$visibility_status=="unavailable"|d$total_articles==0,NA_real_,10000*d$matching_articles/d$total_articles)
  d
}

barometar_page_payload <- function(release) {
  fields <- c("scope","period_id","period_start","period_end","visibility_status","breadth_status",
    "total_articles","matching_articles","panel_outlets","panel_active","matching_outlets","visibility_per_10000","breadth_pct",
    "comparison_status","visibility_difference","breadth_difference_pp")
  # Only weekly-ending rolling values are needed on this page.
  tables <- release$tables[c("monthly","weekly","rolling28")]
  tables$rolling28 <- tables$rolling28[tables$rolling28$period_end %in% tables$weekly$period_end,,drop=FALSE]
  columnar <- lapply(tables,function(table)list(columns=fields,rows=lapply(seq_len(nrow(table)),function(i)unname(as.list(table[i,fields])))))
  meta <- release$summary[intersect(names(release$summary),c("synthetic","data_through","panel_outlets","default_scope","available_scopes",
    "panel_version","definition_version","release_version","matrix_bins","annotations","break_policy"))]
  themes <- release$tables$themes
  theme_pack <- list()
  composition <- list()
  if(!is.null(themes)) {
    ids <- unique(themes$theme_id)
    theme_pack <- list(ids=ids,labels=themes$theme_label_hr[match(ids,themes$theme_id)],modes=list())
    for(frequency in c("monthly","weekly"))for(scope in unique(tables[[frequency]]$scope)) {
      period <- tables[[frequency]][tables[[frequency]]$scope==scope,,drop=FALSE]
      subset <- themes[themes$frequency==frequency & themes$scope==scope,,drop=FALSE]
      # Explicit period lookup avoids assumptions about CSV row order.
      counts <- lapply(period$period_id,function(id) {
        a <- subset[subset$period_id==id,,drop=FALSE]
        unname(as.list(a$articles_with_theme[match(ids,a$theme_id)]))
      })
      theme_pack$modes[[paste(frequency,scope,sep="_")]] <- list(counts=counts,
        statuses=subset$theme_status[match(ids,subset$theme_id)])
      current <- tail(period[period$visibility_status=="published" & period$breadth_status=="published",],1L)
      if(nrow(current) && !is.null(release$tables$composition)) {
        a <- release$tables$composition
        a <- a[a$frequency==frequency & a$scope==scope & a$period_id==current$period_id & a$articles>0,c("facet","value","articles"),drop=FALSE]
        composition[[paste(frequency,scope,sep="_")]] <- list(period=current$period_id,
          rows=lapply(seq_len(nrow(a)),function(i)unname(as.list(a[i,]))))
      }
    }
  }
  diagnostics <- lapply(tables[c("monthly","weekly")],function(d)as.list(barometar_a2_series(d,release$tables$diagnostics)$matching_articles))
  payload <- list(meta=meta,tables=columnar,themes=theme_pack,composition=composition,a2=diagnostics)
  json <- jsonlite::toJSON(payload,auto_unbox=TRUE,null="null",na="null",digits=16)
  json <- stringi::stri_replace_all_fixed(json,"<","\\u003c")
  if(nchar(json,type="bytes")>200000L)stop("Page payload exceeds 200 kB.")
  json
}
