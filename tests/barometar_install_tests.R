# Local transaction fixtures only. Every generation and sidecar is invented.
run_barometar_install_tests <- function() {
  source("R/lib/digikat_utils.R", encoding = "UTF-8")
  source("R/lib/barometar_install.R", encoding = "UTF-8")
  root <- tempfile("barometar-invented-installs-"); dir.create(root)
  root <- normalizePath(root, winslash = "/")
  stopifnot(startsWith(root, paste0(normalizePath(tempdir(), winslash = "/"), "/")))
  put <- function(path, bytes) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    connection <- file(path, "wb"); on.exit(close(connection), add = TRUE)
    writeBin(bytes, connection)
  }
  read_bytes <- function(path) if (file.exists(path)) readBin(path, "raw", n = file.info(path)$size) else NULL
  tree <- function(path) {
    if (!dir.exists(path)) return(NULL)
    files <- list.files(path, recursive = TRUE, all.files = TRUE)
    setNames(vapply(file.path(path, files), digikat_hash_file, character(1L)), files)
  }
  counter <- 0L
  fixture <- function(replacement = TRUE) {
    counter <<- counter + 1L
    workspace <- file.path(root, paste0("workspace-", counter)); dir.create(workspace)
    target <- file.path(workspace, "data/barometar/demokrscanstvo")
    staged <- file.path(workspace, "data/barometar/staging")
    backup <- file.path(workspace, "studies/demokrscanstvo-barometar/output/backups")
    dir.create(backup, recursive = TRUE)
    put(file.path(staged, "summary.json"), charToRaw('{"invented":"new"}\n'))
    put(file.path(staged, "izdanja/2024-01/summary.json"), charToRaw('{"invented":"frozen"}\n'))
    if (replacement) {
      put(file.path(target, "summary.json"), charToRaw('{"invented":"old"}\n'))
      put(file.path(target, "izdanja/2024-01/summary.json"), charToRaw('{"invented":"frozen"}\n'))
    }
    destinations <- file.path(workspace, c("private-work/installed_release.rds", "pages/demokrscanstvo/_metadata.yml",
      "studies/demokrscanstvo-barometar/config/gates.json"))
    original <- list(serialize(list(invented = "old"), NULL, version = 2L),
      charToRaw(enc2utf8("data-cutoff: 2024-01-31\nlabel: 'Izmišljeni zapis'\n")),
      charToRaw('{"invented":"old-gate"}\n'))
    desired <- list(serialize(list(invented = "new"), NULL, version = 2L),
      charToRaw(enc2utf8("data-cutoff: 2024-02-29\nlabel: 'Izmišljeni zapis'\n")),
      charToRaw('{"invented":"new-gate"}\n'))
    for (i in seq_along(destinations)) {
      dir.create(dirname(destinations[i]), recursive = TRUE, showWarnings = FALSE)
      if (replacement || i > 1L) put(destinations[i], original[[i]])
    }
    sources <- file.path(workspace, "studies/demokrscanstvo-barometar/output/sidecars", basename(destinations))
    for (i in seq_along(sources)) put(sources[i], desired[[i]])
    unrelated <- file.path(workspace, "unrelated/invented-sentinel.bin")
    put(unrelated, as.raw(c(0, 1, 255, 10)))
    list(workspace = workspace, target = target, staged = staged, backup = backup,
      sidecars = setNames(sources, destinations), originals = lapply(destinations, read_bytes), desired = desired,
      old_tree = tree(target), new_tree = tree(staged), unrelated = unrelated, sentinel = read_bytes(unrelated))
  }
  checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) stop("Install fixture failed: ", label)
  }
  install <- function(x, finalize = digikat_atomic_replace_file) barometar_install_generation(x$staged, x$target,
    x$sidecars, x$backup, workspace = x$workspace, finalize_file = finalize)
  fail_at <- function(index, after = FALSE, partial = FALSE) {
    calls <- 0L
    function(staged, target) {
      calls <<- calls + 1L
      if (calls == index && !after) {
        if (partial) put(target, charToRaw("invented partial write"))
        stop("Invented sidecar failure.")
      }
      digikat_atomic_replace_file(staged, target)
      if (calls == index && after) stop("Invented sidecar failure after mutation.")
    }
  }
  for (replacement in c(FALSE, TRUE)) for (after in c(FALSE, TRUE)) for (index in 1:3) {
    x <- fixture(replacement)
    error <- tryCatch(install(x, fail_at(index, after)), error = identity)
    label <- paste(if (replacement) "replacement" else "first install", if (after) "after" else "before", "sidecar", index)
    check(inherits(error, "error") && grepl("Invented sidecar failure", conditionMessage(error), fixed = TRUE), paste(label, "reports failure"))
    check(identical(tree(x$target), x$old_tree) && identical(tree(x$staged), x$new_tree), paste(label, "restores old generation and retains new staging"))
    check(identical(lapply(names(x$sidecars), read_bytes), x$originals), paste(label, "restores exact original sidecar bytes and absence"))
    check(identical(read_bytes(x$unrelated), x$sentinel), paste(label, "leaves unrelated files untouched"))
  }
  x <- fixture(TRUE)
  error <- tryCatch(install(x, fail_at(2L, partial = TRUE)), error = identity)
  check(inherits(error, "error") && identical(lapply(names(x$sidecars), read_bytes), x$originals) &&
    identical(tree(x$target), x$old_tree), "rollback repairs a partially overwritten sidecar")
  # Re-stage consumed sidecars exactly as the caller does on a fresh retry.
  for (i in seq_along(x$sidecars)) put(x$sidecars[i], x$desired[[i]])
  old_backup <- install(x)
  check(identical(tree(x$target), x$new_tree) && identical(tree(old_backup), x$old_tree), "retry succeeds and retains the prior generation privately")
  check(identical(lapply(names(x$sidecars), read_bytes), x$desired), "retry installs all sidecars together")
  first <- fixture(FALSE)
  prior <- install(first)
  check(is.null(prior) && identical(tree(first$target), first$new_tree) && !dir.exists(first$staged), "successful first install has no phantom prior generation")
  check(identical(lapply(names(first$sidecars), read_bytes), first$desired), "successful first install creates the new private receipt and metadata")
  unsafe <- fixture(TRUE)
  unsafe$target <- file.path(unsafe$workspace, "outside-barometar")
  put(file.path(unsafe$target, "keep.bin"), as.raw(42))
  before <- tree(unsafe$target)
  error <- tryCatch(install(unsafe), error = identity)
  check(inherits(error, "error") && identical(tree(unsafe$target), before) && dir.exists(unsafe$staged), "out-of-scope target is rejected before mutation")
  unsafe <- fixture(TRUE)
  unsafe$backup <- file.path(unsafe$workspace, "outside-backups"); dir.create(unsafe$backup)
  error <- tryCatch(install(unsafe), error = identity)
  check(inherits(error, "error") && identical(tree(unsafe$target), unsafe$old_tree), "out-of-scope backup location is rejected before mutation")
  invalid <- fixture(TRUE)
  names(invalid$sidecars)[2L] <- names(invalid$sidecars)[1L]
  error <- tryCatch(install(invalid), error = identity)
  check(inherits(error, "error") && identical(tree(invalid$target), invalid$old_tree), "duplicate sidecar destinations are rejected before mutation")
  cat("Barometer install audit: ", checked, "/", checked, " invented checks passed.\n", sep = "")
  invisible(checked)
}
run_barometar_install_tests()
