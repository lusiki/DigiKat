# Source-free regression for the observed static/enhanced matrix color mismatch.
source("R/lib/barometar_page.R",encoding="UTF-8")
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
