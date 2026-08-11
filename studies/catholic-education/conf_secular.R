#!/usr/bin/env Rscript
# Stage-A second pass (actor add-on): confessional vs secular composition per entity, using the PI's
# PROPOSED outlet labels (resources/dictionaries/source_labels.csv, status="proposed" — contestable, PI owns
# them; frame every share as INDICATIVE). Answers Q2½: is the Stepinac memory anchor carried by a different
# confessional/secular mix than the present-tense institutions? Reads slice READ-ONLY; writes output/ only.
suppressPackageStartupMessages({ library(here); library(dplyr) })
source(here::here("studies/catholic-education/study_input.R"), encoding = "UTF-8")

out_dir <- here::here("studies/catholic-education/output")
slice   <- readRDS(file.path(out_dir, "slice.rds"))
catholic_education_assert_slice_current(slice)
lab     <- read.csv(here::here("resources/dictionaries/source_labels.csv"),
                    encoding = "UTF-8", stringsAsFactors = FALSE)
label_conflicts <- lab |>
  group_by(from) |>
  summarise(n_labels = n_distinct(label), .groups = "drop") |>
  filter(n_labels > 1L)
if (nrow(label_conflicts)) {
  stop("source_labels.csv assigns conflicting labels to ", nrow(label_conflicts), " source(s).", call. = FALSE)
}
lab <- distinct(lab, from, .keep_all = TRUE)
cat("source_labels:", nrow(lab), "outlets; label levels:", paste(names(table(lab$label)), collapse = "/"), "\n")

# Join on FROM. "secular" institutional sources and "other" labelled individuals/accounts are
# both non-confessional for the paper's boundary comparison; blank labels remain unclassified.
lk <- setNames(lab$label, lab$from)
raw_label <- ifelse(!is.na(slice$FROM) & slice$FROM %in% names(lk), lk[slice$FROM], NA_character_)
slice$label <- rep("neoznačeno", length(raw_label))
slice$label[!is.na(raw_label) & raw_label == "confessional"] <- "confessional"
slice$label[!is.na(raw_label) & raw_label %in% c("secular", "other")] <- "non_confessional"

KEY <- c("stepinac", "vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "redovi_orders", "rituali", "strossmayer")
comp <- do.call(rbind, lapply(KEY, function(e) {
  sub <- slice[slice[[paste0("probe_", e)]] %in% TRUE, ]
  t <- prop.table(table(factor(sub$label, levels = c("confessional", "non_confessional", "neoznačeno"))))
  # confessional share AMONG the classified (drop unlabeled) — the honest comparison
  cl <- sub[sub$label %in% c("confessional", "non_confessional"), ]
  conf_of_classified <- if (nrow(cl)) mean(cl$label == "confessional") else NA_real_
  n_conf <- sum(sub$label == "confessional")
  n_nonconf <- sum(sub$label == "non_confessional")
  n_unlabeled <- sum(sub$label == "neoznačeno")
  data.frame(entity = e, n = nrow(sub),
             n_confessional = n_conf, n_non_confessional = n_nonconf, n_unlabeled = n_unlabeled,
             confessional = round(as.numeric(t["confessional"]), 3),
             non_confessional = round(as.numeric(t["non_confessional"]), 3),
             unlabeled = round(as.numeric(t["neoznačeno"]), 3),
             pct_classified = round(1 - as.numeric(t["neoznačeno"]), 3),
             confessional_share_of_classified = round(conf_of_classified, 3),
             confessional_lower_bound_all = round(n_conf / nrow(sub), 3),
             confessional_upper_bound_all = round((n_conf + n_unlabeled) / nrow(sub), 3),
             stringsAsFactors = FALSE)
}))
write.csv(comp, file.path(out_dir, "tables", "confessional_secular_by_entity.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\n-- confessional vs secular composition per entity (PI proposed labels; indicative) --\n")
print(comp, row.names = FALSE)
cat("\n  confessional_share_of_classified: among labeled posts, the fraction from confessional outlets.\n",
    "  Higher = more in-Church; lower = more secular/mainstream mediation of that anchor.\n")
