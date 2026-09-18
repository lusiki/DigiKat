#!/usr/bin/env Rscript

# Fail when a trackable study artifact exposes row-level text, URLs, or account
# identifiers. This conservative guard does not replace human review of small
# cells and indirect identifiers.

args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(if (length(args)) args[[1L]] else ".", winslash = "/", mustWork = TRUE)
old_wd <- setwd(root)
on.exit(setwd(old_wd), add = TRUE)

git_lines <- function(arguments) {
  out <- suppressWarnings(system2("git", arguments, stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    stop("git command failed: git ", paste(arguments, collapse = " "), "\n",
         paste(out, collapse = "\n"), call. = FALSE)
  }
  enc2utf8(out[nzchar(out)])
}

tracked <- git_lines(c("ls-files", "--", "studies", "data/barometar"))
untracked <- git_lines(c("ls-files", "--others", "--exclude-standard", "--", "studies", "data/barometar"))
files <- sort(unique(c(tracked, untracked)))
files <- files[file.exists(files) & !dir.exists(files)]

artifact_ext <- c("csv", "tsv", "rds", "rda", "rdata", "xlsx", "xls", "json", "jsonl", "parquet", "feather")
files <- files[tolower(tools::file_ext(files)) %in% artifact_ext]

direct_identifiers <- c(
  "url", "urls", "permalink", "link_url", "uri",
  "full_text", "raw_text", "text", "body", "content", "caption",
  "title", "description", "window", "context", "excerpt", "quote",
  "username", "user_name", "screen_name", "handle", "author_id",
  "email", "phone", "ip", "ip_address"
)

read_schema <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("csv", "tsv")) {
    sep <- if (ext == "tsv") "\t" else ","
    obj <- tryCatch(
      utils::read.table(path, header = TRUE, sep = sep, nrows = 0L,
                        quote = "\"", comment.char = "", check.names = FALSE,
                        fileEncoding = "UTF-8-BOM"),
      error = function(e) NULL
    )
    return(if (is.null(obj)) character() else names(obj))
  }
  if (ext == "rds" && file.info(path)$size <= 50 * 1024^2) {
    obj <- tryCatch(readRDS(path), error = function(e) NULL)
    return(if (is.data.frame(obj)) names(obj) else character())
  }
  character()
}

violations <- character()
source("R/lib/barometar_disclosure.R",encoding="UTF-8")
for (path in files) {
  normalized <- gsub("\\\\", "/", path)
  if (grepl("/output/(private|intermediate)/", normalized, ignore.case = TRUE)) {
    violations <- c(violations, sprintf(
      "%s: private/intermediate artifact is trackable; check .gitignore", path
    ))
    next
  }

  schema <- read_schema(path)
  risky <- intersect(tolower(schema), direct_identifiers)
  if (length(risky)) {
    violations <- c(violations, sprintf(
      "%s: direct row-level field(s): %s", path, paste(sort(risky), collapse = ", ")
    ))
  }
  if(startsWith(normalized,"data/barometar/")) {
    ext <- tolower(tools::file_ext(path))
    obj <- tryCatch(switch(ext,
      json=jsonlite::fromJSON(path,simplifyVector=FALSE),
      csv=utils::read.csv(path,fileEncoding="UTF-8-BOM",check.names=FALSE,stringsAsFactors=FALSE),
      tsv=utils::read.delim(path,fileEncoding="UTF-8-BOM",check.names=FALSE,stringsAsFactors=FALSE),
      stop("Unsupported public release artifact type")),error=function(e)e)
    if(inherits(obj,"error"))violations <- c(violations,paste0(path,": cannot inspect: ",conditionMessage(obj)))
    else violations <- c(violations,barometar_public_inspect(obj,path)$issues)
  }
}

if (length(violations)) {
  cat("Disclosure guard FAILED:\n", paste0("- ", violations, collapse = "\n"), "\n", sep = "")
  cat("\nMove restricted rows to studies/<study>/output/private/ and commit only reviewed aggregates.\n")
  quit(status = 1L, save = "no")
}

cat(sprintf("Disclosure guard passed: %d trackable study/public barometer artifact(s) inspected.\n", length(files)))
