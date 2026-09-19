# Read-only loader for the all-platform aggregate release.
barometar_multiplatform_release <- function(directory) {
  manifest <- jsonlite::fromJSON(file.path(directory,"manifest.json"),simplifyVector=FALSE)
  expected <- c("monthly.csv","platforms.csv","text_availability.csv","themes.csv","routes.csv","summary.json","definitions.json","README.md")
  stopifnot(identical(sort(names(manifest$files)),sort(expected)))
  for(name in expected) {
    stopifnot(identical(digest::digest(file=file.path(directory,name),algo="sha256",serialize=FALSE),manifest$files[[name]]))
  }
  summary <- jsonlite::fromJSON(file.path(directory,"summary.json"),simplifyVector=FALSE)
  stopifnot(identical(summary$schema,"barometar-multiplatform-v1"),
    identical(summary$status,"empirical"),identical(summary$synthetic,FALSE),
    identical(summary$data_through,manifest$data_through),identical(summary$edition,manifest$edition))
  tables <- setNames(lapply(sub("[.]csv$","",expected[endsWith(expected,".csv")]),function(name)
    read.csv(file.path(directory,paste0(name,".csv")),fileEncoding="UTF-8",stringsAsFactors=FALSE,na.strings="")),
    sub("[.]csv$","",expected[endsWith(expected,".csv")]))
  stopifnot(sum(tables$monthly$matching_records)==summary$matching_records,
    sum(tables$monthly$eligible_records)==summary$eligible_records,
    all(tables$monthly$matching_records<=tables$monthly$eligible_records))
  list(summary=summary,tables=tables)
}

barometar_thematic_release <- function(directory, base_directory) {
  manifest <- jsonlite::fromJSON(file.path(directory,"manifest.json"),simplifyVector=FALSE)
  expected <- c("topic_monthly.csv","topics.csv","summary.json","README.md")
  stopifnot(identical(sort(names(manifest$files)),sort(expected)))
  for(name in expected)stopifnot(identical(
    digest::digest(file=file.path(directory,name),algo="sha256",serialize=FALSE),manifest$files[[name]]))
  summary <- jsonlite::fromJSON(file.path(directory,"summary.json"),simplifyVector=FALSE)
  stopifnot(identical(summary$schema,"barometar-themes-v1"),identical(summary$base_manifest_sha256,
    digest::digest(file=file.path(base_directory,"manifest.json"),algo="sha256",serialize=FALSE)))
  monthly <- read.csv(file.path(directory,"topic_monthly.csv"),fileEncoding="UTF-8",stringsAsFactors=FALSE)
  base <- read.csv(file.path(base_directory,"monthly.csv"),stringsAsFactors=FALSE)
  totals <- aggregate(records~platform+month,monthly,sum)
  joined <- merge(base,totals,by=c("platform","month"),all=TRUE,suffixes=c("_base","_themes"))
  joined$records_themes[is.na(joined$records_themes)] <- 0
  stopifnot(!anyNA(joined$matching_records),all(joined$matching_records==joined$records_themes),
    sum(monthly$records)==summary$records,
    sum(vapply(summary$topics,`[[`,numeric(1),"records"))==summary$records)
  list(summary=summary,monthly=monthly)
}
