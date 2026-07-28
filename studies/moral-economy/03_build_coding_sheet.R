#!/usr/bin/env Rscript
# moral-economy STAGE B prep — build the STRATIFIED, POWER-SIZED coding pool (NO master read).
# From Stage A's linked candidate pool, draw a fixed per-domain target sample stratified by
# stream (data_source) x outlet label (confessional/secular/neoznaceno). Fixed per-domain n
# (NOT proportional to pool size) because the confirmatory quantity (justice share ~3%) needs
# ~1,000 coded/domain for a usable CI regardless of how big the domain's pool is (PLAN_census §2).
#
# Emits TWO files (bias-safe): a BLIND coder-facing sheet (rid + window + blank 7 axes; no outlet/
# date shown, so register coding is not anchored on the outlet), and a KEY (rid -> metadata) joined
# back AFTER coding. Logs the allocation + everything dropped (rare-cell honesty).
#
#   Rscript studies/moral-economy/03_build_coding_sheet.R [target_per_domain]
suppressPackageStartupMessages({ library(here); library(dplyr) })
source(here::here("studies/moral-economy/lexicon.R"))

out_dir <- here::here("studies/moral-economy/output")
private_dir <- file.path(out_dir, "private")
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)
cand_path <- file.path(out_dir, "stageA_candidates.rds")
if (!file.exists(cand_path)) stop("Run 01_stageA_tag_linkage.R first (need stageA_candidates.rds).")
cand <- readRDS(cand_path)

args <- commandArgs(trailingOnly = TRUE)
TARGET <- if (length(args) >= 1) as.integer(args[1]) else 1000L   # per-domain coded target
set.seed(20260707)

# stratified draw within one domain: strata = stream x label, proportional w/ per-stratum cap,
# remainder filled at random. Returns sampled rid vector + an allocation record.
draw_domain <- function(df, target) {
  if (nrow(df) <= target) return(list(rid = df$rid, alloc = df %>% count(stream, label, name = "taken")))
  df$stratum <- paste(df$stream, df$label, sep = " | ")
  sz <- table(df$stratum); frac <- sz / sum(sz)
  want <- pmin(as.integer(round(target * frac)), as.integer(sz))   # cap at availability
  names(want) <- names(sz)   # r-review CRITICAL: as.integer() strips names -> want[[s]] below crashes
  # fix rounding drift to exactly `target`
  deficit <- target - sum(want)
  if (deficit != 0) {
    room <- as.integer(sz) - want; ord <- order(-room)
    i <- 1
    # condition per branch: add needs room; remove needs a non-zero cell (r-review secondary note)
    while (deficit != 0 && ((deficit > 0 && any(room > 0)) || (deficit < 0 && any(want > 0)))) {
      s <- ord[((i - 1) %% length(ord)) + 1]
      if (deficit > 0 && room[s] > 0) { want[s] <- want[s] + 1; room[s] <- room[s] - 1; deficit <- deficit - 1 }
      else if (deficit < 0 && want[s] > 0) { want[s] <- want[s] - 1; deficit <- deficit + 1 }
      i <- i + 1
    }
  }
  rid <- unlist(lapply(names(sz), function(s) {
    pool <- df$rid[df$stratum == s]; k <- want[[s]]
    if (k >= length(pool)) pool else sample(pool, k)
  }))
  alloc <- data.frame(stratum = names(sz)) %>%
    tidyr::separate(stratum, c("stream","label"), sep = " \\| ", fill = "right") %>%
    mutate(available = as.integer(sz), taken = as.integer(want))
  list(rid = rid, alloc = alloc)
}

picked <- list(); alloc_rep <- list()
for (d in unique(cand$domain)) {
  sub <- cand[cand$domain == d, ]
  dr <- draw_domain(sub, TARGET)
  picked[[d]] <- sub[sub$rid %in% dr$rid, ]
  alloc_rep[[d]] <- cbind(domain = d, dr$alloc)
}
pool <- bind_rows(picked)

# a post can be a candidate in >1 domain; keep domain-specific rows (each coded in its domain
# context), but de-dup the same (rid,domain) if any. confirmatory_eligible=FALSE for inflation
# (held out of H1/H4 per anti-salami rule; still coded for the descriptive MAP).
pool <- pool %>% distinct(rid, domain, .keep_all = TRUE) %>%
  mutate(confirmatory_eligible = domain != "inflation_prices")

# --- BLIND coder sheet: rid + domain (needed for Axis-5 gating) + window + blank 7 axes ---------
coder <- pool %>% transmute(
  rid, domain, window,
  ax1_link_genuine = "",           # genuine | incidental
  ax2_geography = "",              # domestic | foreign | mixed
  ax3_actor_commentator = "",      # actor | commentator | both
  ax4_register = "",               # object_institution | object_cost_relig_life | charity | justice | devotional | other
  ax5_poverty_split = "",          # economic_poverty | doctrinal_poverty | mixed | NA  (poverty domain only)
  ax6_ksn_principle = "",          # solidarnost|supsidijarnost|opce_dobro|dostojanstvo_rada|opcija_siromasne|integralna_ekologija|univ_namjena|none (multi, ; sep)
  ax7_encyclical = "")             # named document | none
write.csv(coder, file.path(private_dir, "coding_sheet.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# --- KEY (joined back after coding; withheld from annotators) -----------------------------------
key <- pool %>% transmute(rid, domain, tier, DATE, year, month, FROM, SOURCE_TYPE, stream, label,
                          actor_only_caritas, foreign_hint, infl_metaphor_hint, confirmatory_eligible,
                          TITLE, URL)
write.csv(key, file.path(private_dir, "coding_key.csv"), row.names = FALSE, fileEncoding = "UTF-8")

alloc <- bind_rows(alloc_rep)
write.csv(alloc, file.path(out_dir, "coding_allocation.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("== STAGE B coding pool (target", TARGET, "/domain) ==\n")
summ <- pool %>% group_by(domain, tier) %>%
  summarise(pool_available = sum(cand$domain == first(domain)), coded_n = n(),
            confessional = sum(label == "confessional"), secular = sum(label == "secular"),
            stream_2021_24 = sum(stream == "original_dta", na.rm = TRUE),
            stream_2024_26 = sum(stream == "filtered_religious", na.rm = TRUE), .groups = "drop") %>%
  arrange(tier, domain)
print(as.data.frame(summ), row.names = FALSE)
cat("\nTOTAL coded core:", nrow(pool), "posts across", length(unique(pool$domain)), "domains\n")
cat("Rare-cell note: domains where coded_n < target are pool-limited (report descriptively, PLAN §2).\n")
cat("Restricted files: coding_sheet.csv (BLIND) | coding_key.csv ->", private_dir, "\n")
cat("Shareable allocation report: coding_allocation.csv ->", out_dir, "\n")
cat("Next: run the 3-annotator coding on private/coding_sheet.csv (CODEBOOK.md 7 axes), then 04_iaa_validation.R.\n")
