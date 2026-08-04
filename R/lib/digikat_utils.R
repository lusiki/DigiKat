# Shared, dependency-light helpers for DigiKat pipeline scripts.
#
# Source this file from the repository root:
#   source("R/lib/digikat_utils.R", encoding = "UTF-8")

`%||%` <- function(x, fallback) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]]) || !nzchar(as.character(x[[1L]]))) {
    fallback
  } else {
    x
  }
}

digikat_parse_bool <- function(value, name = "value", default = FALSE) {
  if (is.null(value) || length(value) == 0L || is.na(value[[1L]]) ||
      !nzchar(trimws(as.character(value[[1L]])))) {
    return(isTRUE(default))
  }
  normalized <- tolower(trimws(as.character(value[[1L]])))
  if (normalized %in% c("1", "true", "yes", "y", "on")) return(TRUE)
  if (normalized %in% c("0", "false", "no", "n", "off")) return(FALSE)
  stop(
    name, " must be one of 1/0, true/false, yes/no, or on/off; received: ",
    sQuote(as.character(value[[1L]])),
    call. = FALSE
  )
}

digikat_cli_flag <- function(args, flag) {
  flag %in% args
}

digikat_cli_value <- function(args, name, default = NULL) {
  prefix <- paste0(name, "=")
  hits <- args[startsWith(args, prefix)]
  if (!length(hits)) return(default)
  if (length(hits) > 1L) stop("Argument supplied more than once: ", name, call. = FALSE)
  sub(prefix, "", hits[[1L]], fixed = TRUE)
}

digikat_normalize_path <- function(path) {
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

digikat_same_path <- function(left, right) {
  identical(tolower(digikat_normalize_path(left)), tolower(digikat_normalize_path(right)))
}

digikat_tracking_parameters <- function() {
  c(
    "fbclid", "gclid", "dclid", "msclkid", "mc_cid", "mc_eid", "igshid",
    "yclid", "vero_id", "_hsenc", "_hsmi", "mkt_tok", "_ga", "_gl"
  )
}

digikat_canonicalize_one_url <- function(value) {
  if (is.na(value)) return(NA_character_)
  value <- trimws(as.character(value))
  if (!nzchar(value)) return(NA_character_)

  value <- sub("#.*$", "", value)
  match <- regexec(
    "^([A-Za-z][A-Za-z0-9+.-]*://)?([^/?#]+)([^?#]*)(?:\\?([^#]*))?$",
    value,
    perl = TRUE
  )
  parts <- regmatches(value, match)[[1L]]
  if (!length(parts)) {
    return(sub("/+$", "", value))
  }

  scheme <- tolower(sub("://$", "", parts[[2L]]))
  host <- tolower(parts[[3L]])
  path <- parts[[4L]]
  query <- if (length(parts) >= 5L) parts[[5L]] else ""

  host <- sub("^www\\.", "", host)
  if (scheme == "http") host <- sub(":80$", "", host)
  if (scheme == "https") host <- sub(":443$", "", host)
  if (scheme %in% c("http", "https", "")) scheme <- "https"

  raw_params <- if (nzchar(query)) {
    strsplit(query, "&", fixed = TRUE)[[1L]]
  } else {
    character()
  }
  raw_params <- raw_params[nzchar(raw_params)]
  parameter_names <- if (length(raw_params)) {
    vapply(strsplit(raw_params, "=", fixed = TRUE), `[[`, character(1L), 1L)
  } else {
    character()
  }
  decoded_names <- tolower(utils::URLdecode(parameter_names))
  is_tracking <- startsWith(decoded_names, "utm_") |
    decoded_names %in% digikat_tracking_parameters()

  youtube_hosts <- c("youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be")
  is_youtube <- host %in% youtube_hosts
  if (is_youtube) {
    youtube_tracking <- c("si", "feature", "pp", "ab_channel", "t", "start")
    is_tracking <- is_tracking | decoded_names %in% youtube_tracking
    raw_params <- raw_params[!is_tracking]
    decoded_names <- decoded_names[!is_tracking]

    if (identical(host, "youtu.be")) {
      video_id <- sub("^/+", "", path)
      video_id <- sub("/.*$", "", video_id)
      if (nzchar(video_id)) {
        raw_params <- c(paste0("v=", video_id), raw_params)
        decoded_names <- c("v", decoded_names)
        path <- "/watch"
      }
      host <- "youtube.com"
    } else {
      host <- "youtube.com"
      video_match <- regexec("^/(?:shorts|embed|live)/([^/?]+)", path, perl = TRUE)
      video_parts <- regmatches(path, video_match)[[1L]]
      if (length(video_parts) >= 2L) {
        raw_params <- c(paste0("v=", video_parts[[2L]]), raw_params)
        decoded_names <- c("v", decoded_names)
        path <- "/watch"
      }
    }

    if (identical(path, "/watch") && any(decoded_names == "v")) {
      # A YouTube video is identified by v. Playlist position and other context
      # must not make the same video appear to be a different document.
      raw_params <- raw_params[decoded_names == "v"]
      decoded_names <- decoded_names[decoded_names == "v"]
    }
  } else {
    raw_params <- raw_params[!is_tracking]
    decoded_names <- decoded_names[!is_tracking]
  }

  if (length(raw_params)) {
    # Query order is not part of resource identity. Keep duplicate values, but
    # sort the complete name/value pairs for a stable key.
    raw_params <- sort(raw_params)
  }

  path <- sub("/+$", "", path)
  if (identical(path, "/")) path <- ""
  query_out <- if (length(raw_params)) paste0("?", paste(raw_params, collapse = "&")) else ""
  paste0(if (nzchar(scheme)) paste0(scheme, "://") else "", host, path, query_out)
}

digikat_canonicalize_url <- function(url) {
  vapply(url, digikat_canonicalize_one_url, character(1L), USE.NAMES = FALSE)
}

digikat_parse_date <- function(value, name = "DATE", allow_missing = TRUE) {
  raw <- as.character(value)
  parsed <- as.Date(raw)
  invalid <- !is.na(raw) & nzchar(trimws(raw)) & is.na(parsed)
  if (any(invalid)) {
    examples <- unique(raw[invalid])
    stop(
      name, " contains ", sum(invalid), " nonempty value(s) that are not ISO dates. Examples: ",
      paste(utils::head(examples, 5L), collapse = ", "),
      call. = FALSE
    )
  }
  if (!allow_missing && any(is.na(parsed))) {
    stop(name, " contains ", sum(is.na(parsed)), " missing date(s).", call. = FALSE)
  }
  parsed
}

digikat_normalize_date_year <- function(data, date_col = "DATE", year_col = "year",
                                        preserve_date_class = TRUE) {
  if (!date_col %in% names(data)) stop("Missing date column: ", date_col, call. = FALSE)
  parsed <- digikat_parse_date(data[[date_col]], name = date_col)
  derived_year <- as.integer(format(parsed, "%Y"))

  mismatch <- integer()
  if (year_col %in% names(data)) {
    upstream <- suppressWarnings(as.integer(as.character(data[[year_col]])))
    mismatch <- which(!is.na(upstream) & !is.na(derived_year) & upstream != derived_year)
  }

  data[[date_col]] <- if (isTRUE(preserve_date_class)) parsed else as.character(parsed)
  data[[year_col]] <- derived_year
  attr(data, "digikat_year_mismatch_rows") <- mismatch
  data
}

digikat_hash_file <- function(path, algorithm = "sha256") {
  if (!file.exists(path)) stop("Cannot hash missing file: ", path, call. = FALSE)
  if (requireNamespace("digest", quietly = TRUE)) {
    return(unname(digest::digest(path, algo = algorithm, file = TRUE)))
  }
  if (identical(algorithm, "md5")) return(unname(tools::md5sum(path)))
  stop("Package 'digest' is required for ", algorithm, " file hashes.", call. = FALSE)
}

digikat_hash_object <- function(object, algorithm = "sha256") {
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required for object fingerprints.", call. = FALSE)
  }
  digest::digest(object, algo = algorithm)
}

digikat_file_metadata <- function(path, include_hash = TRUE) {
  info <- file.info(path)
  if (!nrow(info) || is.na(info$size)) stop("Missing file: ", path, call. = FALSE)
  result <- list(
    path = gsub("\\\\", "/", path),
    bytes = unname(info$size),
    modified_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
  )
  if (isTRUE(include_hash)) result$sha256 <- digikat_hash_file(path)
  result
}

digikat_write_json_atomic <- function(object, path) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required to write manifests.", call. = FALSE)
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  staged <- tempfile(pattern = paste0(".", basename(path), "-"), tmpdir = dirname(path))
  on.exit(if (file.exists(staged)) unlink(staged), add = TRUE)
  jsonlite::write_json(
    object,
    path = staged,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null"
  )
  if (!file.rename(staged, path)) {
    if (!file.copy(staged, path, overwrite = TRUE)) {
      stop("Could not replace JSON file: ", path, call. = FALSE)
    }
    unlink(staged)
  }
  invisible(path)
}

digikat_stage_rds <- function(object, target, validate = identity, compress = TRUE) {
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  staged <- tempfile(pattern = paste0(".", basename(target), "-"), tmpdir = dirname(target))
  saveRDS(object, staged, compress = compress)
  round_trip <- readRDS(staged)
  validate(round_trip)
  staged
}

digikat_atomic_replace_file <- function(staged, target) {
  if (!file.exists(staged)) stop("Staged file is missing: ", staged, call. = FALSE)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  previous <- paste0(target, ".replace-", Sys.getpid())
  if (file.exists(previous)) {
    stop("Temporary replacement path already exists: ", previous, call. = FALSE)
  }

  had_target <- file.exists(target)
  if (had_target && !file.rename(target, previous)) {
    stop("Could not move current target aside: ", target, call. = FALSE)
  }

  installed <- file.rename(staged, target)
  if (!installed) {
    if (had_target) file.rename(previous, target)
    stop("Could not install staged file at: ", target, call. = FALSE)
  }

  # unlink() returns 0 on SUCCESS, so the warning must fire on a non-zero return.
  if (had_target && file.exists(previous) && unlink(previous) != 0) {
    warning("Installed new file but could not remove temporary previous file: ", previous)
  }
  invisible(target)
}

digikat_require_columns <- function(data, required, label = "data") {
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    stop(label, " is missing required column(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

digikat_format_integer <- function(value) {
  formatC(as.numeric(value), format = "d", big.mark = ".", decimal.mark = ",")
}

