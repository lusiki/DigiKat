#!/usr/bin/env Rscript
# =============================================================================
# R/prune_backups.R
# Retention policy for data/merged_comprehensive_backup_<UTC>.rds backups.
# Keeps: the newest 3 overall, PLUS the newest one per calendar month.
# DRY-RUN BY DEFAULT (lists only); pass --delete to actually remove.
#
#   Rscript R/prune_backups.R            # dry-run: show keep / prune lists
#   Rscript R/prune_backups.R --delete   # actually delete the prune list
#
# Uses file.remove() (NOT shell rm) on purpose; keeps a floor so a bad append is
# always recoverable. Backups are gitignored, so this never touches git.
# =============================================================================
suppressPackageStartupMessages({ library(here) })
do_delete   <- "--delete" %in% commandArgs(trailingOnly = TRUE)
KEEP_NEWEST <- 3L

dir <- here::here("data")
bk  <- list.files(dir, pattern = "^merged_comprehensive_backup_.*\\.rds$", full.names = TRUE)
if (!length(bk)) { cat("No backups found in", dir, "\n"); quit(save = "no") }

info       <- file.info(bk)
info$path  <- rownames(info)
info       <- info[order(info$mtime, decreasing = TRUE), ]
info$month <- format(info$mtime, "%Y-%m")

keep <- unique(c(head(info$path, KEEP_NEWEST),                       # newest N overall
                 unname(tapply(info$path, info$month, function(p) p[1]))))  # newest per month
drop <- setdiff(info$path, keep)

cat("Backups:", nrow(info), "| keep:", length(keep), "| prune:", length(drop), "\n")
cat("\nKEEP:\n");  cat(paste0("  ", basename(keep)), sep = "\n")
cat("\nPRUNE:\n"); if (length(drop)) cat(paste0("  ", basename(drop)), sep = "\n") else cat("  (none)\n")
if (!do_delete) { cat("\nDry-run. Re-run with --delete to remove the PRUNE list.\n"); quit(save = "no") }
ok <- file.remove(drop)
cat("\nDeleted", sum(ok), "of", length(drop), "backups.\n")
