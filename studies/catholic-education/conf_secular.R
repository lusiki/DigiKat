#!/usr/bin/env Rscript
# Stage-A second pass (actor add-on): confessional vs secular composition per entity, using the PI's
# PROPOSED outlet labels (resources/dictionaries/source_labels.csv, status="proposed" — contestable, PI owns
# them; frame every share as INDICATIVE). Answers Q2½: is the Stepinac memory anchor carried by a different
# confessional/secular mix than the present-tense institutions? Reads slice READ-ONLY; writes output/ only.
suppressPackageStartupMessages({ library(here); library(dplyr) })

out_dir <- here::here("studies/catholic-education/output")
slice   <- readRDS(file.path(out_dir, "slice.rds"))
lab     <- read.csv(here::here("resources/dictionaries/source_labels.csv"),
                    encoding = "UTF-8", stringsAsFactors = FALSE)
cat("source_labels:", nrow(lab), "outlets; label levels:", paste(names(table(lab$label)), collapse = "/"), "\n")

# join on FROM (outlet). unlabeled -> "neoznačeno"
lk <- setNames(lab$label, lab$from)
slice$label <- ifelse(!is.na(slice$FROM) & slice$FROM %in% names(lk), lk[slice$FROM], "neoznačeno")

KEY <- c("stepinac", "vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "redovi_orders", "rituali", "strossmayer")
comp <- do.call(rbind, lapply(KEY, function(e) {
  sub <- slice[slice[[paste0("probe_", e)]] %in% TRUE, ]
  t <- prop.table(table(factor(sub$label, levels = c("confessional", "secular", "neoznačeno"))))
  # confessional share AMONG the classified (drop unlabeled) — the honest comparison
  cl <- sub[sub$label %in% c("confessional", "secular"), ]
  conf_of_classified <- if (nrow(cl)) mean(cl$label == "confessional") else NA_real_
  data.frame(entity = e, n = nrow(sub),
             confessional = round(as.numeric(t["confessional"]), 3),
             secular = round(as.numeric(t["secular"]), 3),
             unlabeled = round(as.numeric(t["neoznačeno"]), 3),
             pct_classified = round(1 - as.numeric(t["neoznačeno"]), 3),
             confessional_share_of_classified = round(conf_of_classified, 3),
             stringsAsFactors = FALSE)
}))
write.csv(comp, file.path(out_dir, "tables", "confessional_secular_by_entity.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\n-- confessional vs secular composition per entity (PI proposed labels; indicative) --\n")
print(comp, row.names = FALSE)
cat("\n  confessional_share_of_classified: among labeled posts, the fraction from confessional outlets.\n",
    "  Higher = more in-Church; lower = more secular/mainstream mediation of that anchor.\n")
