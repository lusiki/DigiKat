# Private denominator-stage I/O. Source from the repository root.
# DetermDB is always opened read-only; all writable objects live in WORKDIR.
if (!exists("digikat_determdb_path", mode = "function")) {
  source("R/lib/digikat_paths.R", encoding = "UTF-8")
}
if (!exists("digikat_hash_object", mode = "function")) {
  source("R/lib/digikat_utils.R", encoding = "UTF-8")
}

barometar_workdir <- function(workdir = NULL) {
  if (is.null(workdir)) workdir <- digikat_barometar_workdir()
  dir.create(workdir, recursive = TRUE, showWarnings = FALSE)
  normalizePath(workdir, winslash = "/", mustWork = TRUE)
}

barometar_connect_readonly <- function(path = NULL) {
  if (is.null(path)) path <- digikat_determdb_path()
  if (!file.exists(path)) stop("DetermDB input is missing; see CLAUDE.local.md.", call. = FALSE)
  con <- tryCatch(DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE),
    error = function(e) stop("DetermDB se upravo zapisuje; ponovi nakon uvoza. Cannot open the source read-only: ",
      conditionMessage(e), call. = FALSE))
  attr(con, "barometar_input_path") <- normalizePath(path, winslash = "/", mustWork = TRUE)
  DBI::dbExecute(con, "SET threads = 8")
  con
}

barometar_table_sql <- function(con, table = NULL) {
  if (is.null(table)) table <- digikat_determdb_table()
  parts <- stringi::stri_split_fixed(table, ".")[[1L]]
  if (length(parts) != 2L || any(!stringi::stri_detect_regex(parts, "^[A-Za-z_][A-Za-z0-9_]*$"))) {
    stop("DetermDB table must be a schema.table identifier.", call. = FALSE)
  }
  paste(as.character(DBI::dbQuoteIdentifier(con, parts)), collapse = ".")
}

barometar_write_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(x, file = path, bom = TRUE, eol = "\n", na = "")
  invisible(path)
}

barometar_write_json <- function(x, path) {
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  staged <- tempfile(paste0(".",basename(path),"-"),tmpdir=dirname(path))
  on.exit(if(file.exists(staged))unlink(staged),add=TRUE)
  json <- jsonlite::toJSON(x,pretty=TRUE,auto_unbox=TRUE,null="null",na="null",digits=16)
  connection <- file(staged,"wb")
  tryCatch(writeBin(charToRaw(enc2utf8(paste0(json,"\n"))),connection),finally=close(connection))
  digikat_atomic_replace_file(staged,path)
  invisible(path)
}

barometar_source_snapshot <- function(con, quiet_seconds = 300) {
  path <- attr(con, "barometar_input_path")
  info <- if (!is.null(path)) file.info(path) else NULL
  if (!is.null(info) && as.numeric(difftime(Sys.time(), info$mtime, units = "secs")) < quiet_seconds) {
    stop("DetermDB changed in the last five minutes; wait for upstream loading to finish.", call. = FALSE)
  }
  tables <- DBI::dbGetQuery(con, "SELECT table_schema, table_name FROM information_schema.tables ORDER BY 1,2")
  names <- intersect(c("maintenance_import_log", "load_log", "build_log"), tables$table_name)
  logs <- setNames(lapply(names, function(nm) {
    id <- DBI::dbQuoteIdentifier(con, DBI::Id(schema = "main", table = nm))
    # Loader logs contain operational metadata, never article text.
    DBI::dbGetQuery(con, paste0("SELECT * FROM ", id, " ORDER BY ALL"))
  }), names)
  for (log in logs) {
    timestamp_columns <- vapply(log, inherits, logical(1L), what = "POSIXt")
    for (column in log[timestamp_columns]) {
      if (length(column) && any(!is.na(column)) &&
          as.numeric(difftime(Sys.time(), max(column, na.rm = TRUE), units = "secs")) < quiet_seconds) {
        stop("Recent loader-log activity detected; wait for upstream loading to finish.", call. = FALSE)
      }
    }
  }
  list(file_bytes = if (is.null(info)) NULL else unname(info$size),
       file_mtime = if (is.null(info)) NULL else as.numeric(info$mtime),
       logs_digest = digikat_hash_object(logs), logs = logs)
}

barometar_assert_snapshot <- function(snapshot, con) {
  now <- barometar_source_snapshot(con, quiet_seconds = 0)
  if (!identical(snapshot[c("file_bytes", "file_mtime", "logs_digest")],
                 now[c("file_bytes", "file_mtime", "logs_digest")])) {
    stop("DetermDB changed during the run; discard this run and restart from readiness.", call. = FALSE)
  }
  invisible(TRUE)
}

barometar_script_main <- function(filename) {
  file_arg <- commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]
  length(file_arg) == 1L && identical(basename(substring(file_arg, 8L)), filename)
}
