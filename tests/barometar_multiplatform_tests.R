source("studies/demokrscanstvo-barometar/lib/io.R",encoding="UTF-8")
source("R/lib/barometar_engine.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/multiplatform_engine.R",encoding="UTF-8")
d <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
stopifnot(d$definition_version=="1.0.0+33429974d0b8")
e <- multiplatform_engine()
short <- "Demokršćanstvo je politička tradicija."
stopifnot("A1" %in% e$barometar_classify("",short,d,"2026-01-01")$routes,
          "A1" %in% e$barometar_classify(short,"",d,"2026-01-01")$routes,
          !e$barometar_classify("","Solidarnost i obitelj.",d,"2026-01-01")$broad_candidate)
long <- paste0(strrep("Obična rečenica bez teme. ",1600),short)
stopifnot("A1" %in% e$barometar_classify("",long,d,"2026-01-01")$routes)
# The optimization must retain every contextual route in the frozen fixture
# set. This is an inclusion-superset test, not a mirror of the implementation.
cases <- read.csv("tests/fixtures/barometar_cases.csv",fileEncoding="UTF-8",stringsAsFactors=FALSE)
text_columns <- intersect(c("sentence","title","full_text","text","TITLE","FULL_TEXT"),names(cases))
stopifnot(length(text_columns)>0L,nrow(cases)>20L)
texts <- unique(c(short,long,unlist(cases[text_columns],use.names=FALSE)))
texts <- texts[!is.na(texts)]
fields <- e$barometar_text_fields(texts)
active <- matrix(vapply(d$compiled,function(rule)stringi::stri_detect_regex(
  if(rule$case_sensitive)fields$txt else fields$low,rule$pattern),logical(length(texts))),nrow=length(texts))
possible <- multiplatform_possible(active,d$compiled)
for(i in seq_along(texts)) {
  result <- e$barometar_classify("",texts[i],d,"2026-01-01")
  if(length(result$routes))stopifnot(possible[i])
}
message("Multiplatform text policy and necessary-condition regression passed (",length(texts)," texts).")
