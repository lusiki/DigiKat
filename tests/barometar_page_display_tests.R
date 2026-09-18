# Source-free regression for the observed static/enhanced matrix color mismatch.
source("R/lib/barometar_page.R",encoding="UTF-8")
stopifnot(identical(barometar_validation_number(.0123),"0,012"),identical(barometar_validation_number(-.0123),"-0,012"))
bins <- c(10000/31,10000/31,10000/30,10000/30)
csv_rates <- utils::read.csv(text="rate\n322.58064516129\n333.333333333333")$rate
expected <- c(0L,2L)
representations <- list(bins,
  jsonlite::fromJSON(jsonlite::toJSON(bins,digits=12)),
  jsonlite::fromJSON(jsonlite::toJSON(bins,digits=16)))
for(cutoffs in representations) {
  stopifnot(identical(vapply(csv_rates,barometar_matrix_bin,integer(1),bins=cutoffs),expected))
  stopifnot(identical(vapply(c(10000/31,10000/30),barometar_matrix_bin,integer(1),bins=cutoffs),expected))
}
# Genuine differences beyond the boundary remain visible despite roundoff tolerance.
stopifnot(identical(vapply(c(bins[1]-1e-6,bins[1]+1e-6,bins[3]+1e-6),
  barometar_matrix_bin,integer(1),bins=bins),c(0L,2L,4L)))
cat("PASS: static/enhanced matrix boundary round trips and genuine cutoff changes.\n")

# The diagnostic joins by period and cannot change the primary series.
rows <- data.frame(frequency="monthly",scope="uze",period_id=c("2024-01","2024-02","2024-03"),
  total_articles=c(100L,0L,200L),matching_articles=c(2L,0L,3L),
  visibility_status=c("published","unavailable","partial"),visibility_per_10000=c(200,NA,150))
diagnostics <- data.frame(frequency="monthly",scope="uze",period_id=rev(rows$period_id),
  diagnostic="A2",articles=c(4L,0L,1L),total_articles=rev(rows$total_articles))
original <- rows
a2 <- barometar_a2_series(rows,diagnostics)
stopifnot(identical(rows,original),identical(a2$matching_articles,c(1L,0L,4L)),
  identical(a2$visibility_per_10000,c(100,NA_real_,200)))
rejects <- function(expr)inherits(tryCatch({force(expr);NULL},error=identity),"error")
stopifnot(rejects(barometar_a2_series(rows,rbind(diagnostics,diagnostics[1,]))),
  rejects(barometar_a2_series(rows,diagnostics[-1,])))
bad <- diagnostics;bad$total_articles[1] <- 201L
stopifnot(rejects(barometar_a2_series(rows,bad)))

# A manifest-valid replacement of the dated file still cannot change its binding.
directory <- tempfile("barometar-page-edition-");dir.create(directory)
dir.create(file.path(directory,"izdanja","2024-01"),recursive=TRUE)
for(name in c("monthly","weekly","rolling28"))utils::write.csv(rows,file.path(directory,paste0(name,".csv")),row.names=FALSE)
write_json <- function(x,name)jsonlite::write_json(x,file.path(directory,name),auto_unbox=TRUE)
edition_name <- "izdanja/2024-01/summary.json"
write_json(list(edition="2024-01",findings=list()),edition_name)
hash <- function(name)digest::digest(file=file.path(directory,name),algo="sha256",serialize=FALSE)
summary <- list(synthetic=TRUE,data_through="2024-03-31",edition="2024-01",edition_summary_sha256=hash(edition_name))
write_json(summary,"summary.json")
manifest <- function() {
  names <- c("monthly.csv","weekly.csv","rolling28.csv","summary.json",edition_name)
  write_json(list(data_through=summary$data_through,files=as.list(setNames(vapply(names,hash,character(1L)),names))),"manifest.json")
}
manifest()
stopifnot(identical(barometar_read_release(directory,TRUE)$edition$edition,"2024-01"))
write_json(list(edition="2024-01",findings=list("replacement")),edition_name);manifest()
stopifnot(rejects(barometar_read_release(directory,TRUE)))
summary$edition_summary_sha256 <- hash(edition_name);write_json(summary,"summary.json");manifest()
stopifnot(identical(barometar_read_release(directory,TRUE)$edition$findings[[1]],"replacement"))
summary$edition <- "../2024-01";write_json(summary,"summary.json");manifest()
stopifnot(rejects(barometar_read_release(directory,TRUE)))
cat("PASS: A2 keyed denominators/statuses and immutable dated-edition binding.\n")
