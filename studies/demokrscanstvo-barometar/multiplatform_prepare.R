# Export the frozen retrieval contract; no source records are read here.
source("studies/demokrscanstvo-barometar/lib/io.R",encoding="UTF-8")
source("R/lib/barometar_engine.R",encoding="UTF-8")
work <- file.path(barometar_workdir(),"multiplatform-v1")
dir.create(work,recursive=TRUE,showWarnings=FALSE)
d <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
barometar_write_json(list(definition_version=d$definition_version,
  definition_hash=d$definition_hash,prefilter=d$prefilter,
  policy="all-platforms-v1-full-stored-text",
  source_code=vapply(c("R/lib/barometar_engine.R","R/lib/barometar_rules.R","R/lib/barometar_text.R"),
    digikat_hash_file,character(1L))),file.path(work,"contract.json"))
barometar_write_json(list(definition_version=d$definition_version,
  adapter_policy="all-platforms-v1-full-stored-text",max_tokens=80L,max_sentences=3L,
  theme_labels=d$documents[["domain_themes.yaml"]]$labels,
  entries=lapply(d$compiled,function(rule)rule$entry[intersect(names(rule$entry),
    c("id","family","tier","kind","forms","slots","order","ascii_variants","exclude_if","excluded_forms","case_sensitive","gap_max","principle"))])),
  file.path(work,"definitions.json"))
barometar_write_json(list(R_version=R.version.string,locale=Sys.getlocale(),
  worker_LC_CTYPE="English_United States.utf8",renv_lock_sha256=digikat_hash_file("renv.lock"),
  packages=as.list(setNames(vapply(c("duckdb","stringi","digest","yaml","jsonlite","data.table"),
    function(p)as.character(utils::packageVersion(p)),character(1L)),c("duckdb","stringi","digest","yaml","jsonlite","data.table")))),
  file.path(work,"environment.json"))
message("Frozen retrieval contract, public dictionary inventory and environment exported.")
