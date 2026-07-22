#!/usr/bin/env Rscript
# Stage-A FOLLOW-UP CHECKS for catholic-education — reads the slice produced by slice.R (READ-ONLY),
# writes only into output/. Covers what the candidate table does not:
#   (5) homonym-precision eyeballing (stadler/samostan/isusov/franjev)  + per-sub-token de-bundling
#   (6) temporal coverage + the data_source 2024 collection-method confound (MEMORY.md) -> figure
#   (2/3) aggregate genuine-vs-incidental past-anchoring split (does the ~68% inflation lesson apply?)
# Run AFTER slice.R:  Rscript studies/catholic-education/stageA_checks.R
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr); library(ggplot2) })

slice_path <- here::here("studies/catholic-education/output/slice.rds")
if (!file.exists(slice_path)) stop("Run slice.R first — no ", slice_path)
slice   <- readRDS(slice_path)
out_dir <- here::here("studies/catholic-education/output")
tab_dir <- file.path(out_dir, "tables"); fig_dir <- file.path(out_dir, "figures")
for (d in c(tab_dir, fig_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# editorial theme if available (MEMORY.md: route figures through R/theme_digikat.R); else minimal.
theme_ok <- tryCatch({ source(here::here("R/theme_digikat.R")); TRUE }, error = function(e) FALSE)
if (!theme_ok) theme_set(theme_minimal(base_size = 12))
cat("theme_digikat:", if (theme_ok) "loaded" else "NOT found — using theme_minimal", "\n")

txt <- stringr::str_to_lower(slice$FULL_TEXT, locale = "hr")
yr  <- as.integer(format(as.Date(slice$DATE), "%Y"))
n_bad_yr <- sum(is.na(yr))   # r-reviewer Major #6: don't let table()'s useNA="no" silently drop bad years
if (n_bad_yr > 0) cat("WARNING:", n_bad_yr, "rows have NA year — excluded from the year × stream tables.\n")

# ---- (6) temporal coverage + data_source confound -------------------------------------------
has_ds <- "data_source" %in% names(slice)
has_st <- "SOURCE_TYPE" %in% names(slice)
if (has_ds) {
  ds_year <- as.data.frame(table(year = yr, data_source = slice$data_source))
  write.csv(ds_year, file.path(tab_dir, "spine_by_year_datasource.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  p <- ggplot(subset(ds_year, Freq > 0), aes(x = factor(year), y = Freq, fill = data_source)) +
    geom_col() +
    labs(title = "Education-spine posts by year × collection stream",
         subtitle = "data_source is a TIME-SEGREGATED collection-method marker (MEMORY.md): original_dta ~2021–24, filtered_religious ~2024–26.\nCross-year VOLUME is CONFOUNDED by the ~2024 method change — do NOT read as rising attention.",
         x = NULL, y = "posts", fill = "stream")
  ggsave(file.path(fig_dir, "spine_by_year_datasource.png"), p, width = 9, height = 5.5, dpi = 150)
  cat("\n-- (6) education-spine posts by year × data_source --\n")
  print(as.data.frame(xtabs(Freq ~ year + data_source, ds_year)))
} else cat("\n-- (6) data_source column ABSENT from slice — cannot show the collection-method confound. --\n")
if (has_st) {
  st_year <- as.data.frame(table(year = yr, platform = slice$SOURCE_TYPE))
  write.csv(st_year, file.path(tab_dir, "spine_by_year_platform.csv"), row.names = FALSE, fileEncoding = "UTF-8")
}

# ---- de-bundle the broad entities (recurrence-misrank concern) -------------------------------
# per-sub-token post counts inside the slice, so a bundle's rank is interpretable.
sub <- list(
  redovi_orders     = c(isusovci="isusova[cč]\\w*|isusovc\\w*|dru[žz]b\\w*\\s+isusov",  # corrected (Jesuit order, not 'of Jesus')
                        jezuiti="jezuit", franjevci="franjev", dominikanci="dominikan",
                        salezijanci="salezijan", casne_sestre="[čc]asn\\w*\\s+sestr", samostan="samostan"),
  odgoj_vrijednosti = c(odgoj="odgoj", kurikul="kurikul", krscanski_korijen="kr[šs][čc]ansk\\w*\\s+korijen",
                        vrijednost="\\bvrijednost"),
  katolicka_skola   = c(kat_skola="katoli[čc]k\\w*[\\s-]+(\\w+\\s+)?[šs]kol", hks="\\bhks\\b",
                        sjemeniste="sjemeni[šs]t", uciteljska="u[čc]iteljsk\\w*\\s+[šs]kol",
                        kat_uciliste="katoli[čc]ko\\s+u[čc]ili[šs]t", kat_sveuciliste="katoli[čc]k\\w*\\s+sveu[čc]ili[šs]t")
)
debundle <- do.call(rbind, lapply(names(sub), function(b) {
  do.call(rbind, lapply(names(sub[[b]]), function(k)
    data.frame(bundle = b, sub_token = k, n = sum(str_detect(txt, sub[[b]][[k]])), stringsAsFactors = FALSE)))
}))
debundle <- debundle[order(debundle$bundle, -debundle$n), ]
write.csv(debundle, file.path(tab_dir, "bundle_subtoken_counts.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\n-- de-bundled sub-token counts (which root drives each bundle's recurrence) --\n"); print(debundle, row.names = FALSE)

# ---- (5) homonym eyeballing: pull snippets for the noisy entities ----------------------------
snip <- function(rx, label, n = 6, width = 140) {
  hit <- which(str_detect(txt, rx)); if (!length(hit)) return(cat("  [", label, "] 0 hits\n"))
  take <- head(hit, n)
  cat("  [", label, "] ", length(hit), " hits; first ", length(take), ":\n", sep = "")
  for (i in take) {
    m <- str_locate(txt[i], rx)[1, "start"]
    s <- substr(slice$FULL_TEXT[i], max(1, m - 40), min(nchar(slice$FULL_TEXT[i]), m + width))
    cat("     …", gsub("\\s+", " ", s), "…\n")
  }
}
cat("\n-- (5) homonym-precision eyeballing (are these the intended sense?) --\n")
snip("\\bstadler\\b", "stadler (rail co. vs Bp. Stadler)")
snip("samostan", "samostan (monastery vs tourism/real-estate)")
snip("isusov", "isusov (Jesuit vs 'Isusov' = of-Jesus)")

# ---- (2/3) aggregate genuine-vs-incidental past-anchoring ------------------------------------
if (all(c("past_anchor_doc", "past_anchor_genuine") %in% names(slice))) {
  d <- mean(slice$past_anchor_doc); g <- mean(slice$past_anchor_genuine)
  cat(sprintf("\n-- (2/3) past-anchoring across the education slice --\n  doc-level: %.1f%%  |  windowed-genuine: %.1f%%  |  incidental: %.1f%% of doc-level\n",
              100 * d, 100 * g, if (d > 0) 100 * (1 - g / d) else NA_real_))
  cat("  (sister study's lesson: whole-document co-occurrence was ~68% incidental. Compare here.)\n")
}
cat("\nStage-A checks written to", tab_dir, "and", fig_dir, "\n")
