#!/usr/bin/env Rscript
# =============================================================================
# R/capture_environment.R
# Snapshot the computational environment for reproducibility (FAIR).
# Writes ENVIRONMENT.md (R version, platform, locale, key package versions,
# Quarto version, the pinned udpipe model + hash) and refreshes renv.lock.
#
# Run where R lives:   Rscript R/capture_environment.R
# =============================================================================
suppressPackageStartupMessages({
  if (!requireNamespace("here", quietly = TRUE)) stop("Package 'here' is required.")
  library(here)
})

out        <- here::here("ENVIRONMENT.md")
model_path <- here::here("resources/models/croatian-set-ud-2.5-191206.udpipe")
PINNED_SHA <- "b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7"

# --- hash the udpipe model (sha256 if openssl/digest available, else md5 base R) ---
hash_file <- function(path) {
  if (!file.exists(path)) return(list(algo = NA, hash = "(model file not found)", size = NA))
  size <- file.info(path)$size
  if (requireNamespace("openssl", quietly = TRUE))
    return(list(algo = "sha256", hash = as.character(openssl::sha256(file(path, "rb"))), size = size))
  if (requireNamespace("digest", quietly = TRUE))
    return(list(algo = "sha256", hash = digest::digest(path, algo = "sha256", file = TRUE), size = size))
  list(algo = "md5", hash = unname(tools::md5sum(path)), size = size)
}
m <- hash_file(model_path)
sha_note <- if (identical(m$algo, "sha256"))
  (if (identical(m$hash, PINNED_SHA)) "MATCHES pinned value" else "DOES NOT MATCH pinned value — model file changed!")
  else "(install 'openssl' or 'digest' to verify against the pinned sha256)"

# --- quarto version (best effort) ---
quarto_ver <- tryCatch(paste(system2("quarto", "--version", stdout = TRUE, stderr = TRUE), collapse = " "),
                       error = function(e) "(quarto not found)")

# --- renv snapshot (best effort) ---
renv_status <- if (requireNamespace("renv", quietly = TRUE))
  tryCatch({ renv::snapshot(prompt = FALSE); "renv.lock refreshed" },
           error = function(e) paste("renv snapshot failed:", conditionMessage(e)))
  else "renv not installed — run renv::init() on this machine first"

si   <- sessionInfo()
pkgs <- sort(unique(names(c(si$otherPkgs, si$loadedOnly))))

con <- file(out, open = "w", encoding = "UTF-8")
writeLines(c(
  "# Environment Snapshot — DigiKat", "",
  paste0("- Generated: ", format(Sys.time(), tz = "UTC"), " UTC"),
  paste0("- R version: ", R.version.string),
  paste0("- Platform: ", R.version$platform),
  paste0("- Locale (LC_CTYPE): ", Sys.getlocale("LC_CTYPE")),
  paste0("- Native UTF-8 (R >= 4.2): ", isTRUE(getRversion() >= "4.2.0")),
  paste0("- Quarto: ", quarto_ver),
  paste0("- renv: ", renv_status), "",
  "## Pinned udpipe model",
  "- file: `resources/models/croatian-set-ud-2.5-191206.udpipe`",
  paste0("- size: ", m$size, " bytes"),
  paste0("- ", m$algo, ": `", m$hash, "`  (", sha_note, ")"), "",
  "## Loaded packages (full pinned set is in renv.lock)",
  paste0("- ", pkgs)
), con)
close(con)
cat("Wrote", out, "\n")
cat("udpipe model", m$algo, ":", m$hash, "-", sha_note, "\n")
