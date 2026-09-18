source("studies/demokrscanstvo-barometar/04_classify.R",encoding="UTF-8")
workdir <- barometar_workdir()
manifest <- readRDS(file.path(workdir,"development_review_manifest.rds"))
review <- readRDS(file.path(manifest$folder,"review-private.rds"))
definition <- barometar_definition();boilerplate <- readRDS(file.path(workdir,"boilerplate.rds"))
elapsed <- system.time(result <- barometar_classify_batch(review$rows,definition,boilerplate))[["elapsed"]]
check <- lapply(seq_len(min(10L,nrow(review$rows))),function(i) {
  row <- review$rows[i,];keys <- boilerplate$segment_key[boilerplate$outlet_id==row$outlet_id & boilerplate$month==substr(row$day,1L,7L)]
  barometar_classify(row$TITLE,row$FULL_TEXT,definition,row$day,keys)
})
stopifnot(identical(result[seq_along(check)],check))
cat("Operational batch benchmark: ",nrow(review$rows)," development articles in ",elapsed," seconds; scalar equivalence passed.\n",sep="")
saveRDS(list(n=nrow(review$rows),elapsed=elapsed,definition_hash=definition$definition_hash,
  items_per_second=nrow(review$rows)/elapsed),file.path(workdir,"engine_benchmark.rds"))
