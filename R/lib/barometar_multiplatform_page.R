# Read-only aggregate loader for the explicitly provisional expanded edition.
barometar_multiplatform_release <- function(directory) {
  manifest <- jsonlite::fromJSON(file.path(directory,"manifest.json"),simplifyVector=FALSE)
  expected <- c("monthly.csv","platforms.csv","text_availability.csv","themes.csv","routes.csv","summary.json","definitions.json","README.md")
  stopifnot(identical(sort(names(manifest$files)),sort(expected)))
  for(name in expected) {
    stopifnot(identical(digest::digest(file=file.path(directory,name),algo="sha256",serialize=FALSE),manifest$files[[name]]))
  }
  summary <- jsonlite::fromJSON(file.path(directory,"summary.json"),simplifyVector=FALSE)
  stopifnot(identical(summary$schema,"barometar-multiplatform-v1"),
    identical(summary$status,"provisional_empirical"),identical(summary$synthetic,FALSE),
    identical(summary$data_through,manifest$data_through),identical(summary$edition,manifest$edition))
  tables <- setNames(lapply(sub("[.]csv$","",expected[endsWith(expected,".csv")]),function(name)
    read.csv(file.path(directory,paste0(name,".csv")),fileEncoding="UTF-8",stringsAsFactors=FALSE,na.strings="")),
    sub("[.]csv$","",expected[endsWith(expected,".csv")]))
  stopifnot(sum(tables$monthly$matching_records)==summary$matching_records,
    sum(tables$monthly$eligible_records)==summary$eligible_records,
    all(tables$monthly$matching_records<=tables$monthly$eligible_records))
  list(summary=summary,tables=tables)
}
