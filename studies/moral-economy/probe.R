#!/usr/bin/env Rscript
# Study probe: moral-economy — the religion x economy nexus, bird's-eye (Stage-0 FEASIBILITY, v2).
# v2 after the 5-critic adversarial review (2026-07-06): lexicon DE-CONTAMINATED (no register
# vocabulary inside domain definitions; no charity-operations terms in poverty; no plače/plaće
# homonym; demography restricted to economic anchors), window widened to the sister-validated
# +/-220 chars, linkage reported WITHIN data_source stream with Wilson CIs and with/without
# Caritas (religion-as-actor overlap), NA text + unparseable dates counted, NA-safe indexing.
#
# Tags the corpus with a 11-domain ECONOMY lexicon (recall-first), then estimates, per domain:
# n posts, % of corpus, by-year/by-month x stream counts, pairwise overlap, confessional
# composition (PI proposed labels — indicative), and SAMPLED windowed religion-linkage rates.
# These are CANDIDATE-GENERATOR numbers (sister study: regex precision ceiling ~0.4) — never
# publishable as engagement; Stage B coding is what measures anything.
#
# Reads the corpus READ-ONLY; writes ONLY into studies/moral-economy/output/. NEVER touches
# data/ or the global >=2-match religion filter.
#
# Run where R + the master live (see CLAUDE.local.md):
#   Rscript studies/moral-economy/probe.R
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr) })

USE_SAMPLE <- !file.exists(here::here("data/merged_comprehensive.rds"))
src <- if (USE_SAMPLE) here::here("data/sample/merged_sample.rds") else here::here("data/merged_comprehensive.rds")
if (!file.exists(src)) stop("No corpus found (need the master or data/sample/). See CLAUDE.local.md.")

out_dir <- here::here("studies/moral-economy/output")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# --- 1. the ECONOMY domain lexicon (study-local; recall-first for DETECTION) -------------------
# Ordered along the pre-declared abstraction gradient: A = aggregate/system, B = sectoral/
# transitional, C = lived/person-level.
# DESIGN RULE (referee finding): domain lexicons must be REGISTER-NEUTRAL — no CST/justice
# vocabulary (dostojanstvo rada, radnička prava), no charity-operations vocabulary (banka hrane,
# pučka kuhinja) may DEFINE domain membership; registers are assigned by Stage-B coding only.
# HOMONYM HAZARDS (hand-validation priorities): deficit (attention/demographic), gospodarstv
# (OPG farms), tecajn (courses), tvrtk (any firm), nekretnin (listings), siromas (spiritual
# poverty: "siromasi duhom", "zavjet siromastva"), otpustanj guarded by worker-collocate
# (otpustanje grijeha!), inflacij metaphors ("inflacija rijeci") unguarded here — the sister
# metaphor guard + validated pipeline apply at Stage A. plače/plaće homonym ELIMINATED (v2):
# no bare plać* form is matched, only economically-collocated ones.
econ <- list(
  # --- tier A: aggregates / system ---
  macro_aggregates = "\\bbdp\\w{0,3}\\b|bruto\\s+doma[cč]\\w+|gospodarsk\\w+\\s+rast|gospodarstv|recesij|javn\\w+\\s+dug|dr[zž]avn\\w+\\s+dug|prora[cč]unsk\\w+\\s+(manjk|deficit)|\\bdeficit|kamatn\\w+\\s+stop|monetarn\\w+\\s+politik|fiskaln",
  euro_changeover  = "eurozon|uvo[dđ]enj\\w*\\s+eura|prelaz\\w+\\s+na\\s+euro|zamjen\\w+\\s+kun|konverzij\\w+\\s+(kun|cijen)|dvojn\\w+\\s+iskaz|te[cč]ajn",
  taxes_fiscal     = "porezn|\\bporez\\w{0,3}\\b|\\bpdv\\b|fiskaliz|redistribuc|socijaln\\w+\\s+davanj",
  business_comp    = "poduzetni|konkurent|investicij|tvrtk|obrtni[kc]",
  # --- tier B: sectoral / transitional ---
  green_energy     = "energetsk\\w+\\s+(kriz|tranzicij|siroma[sš])|cijen\\w*\\s+(struje|plina|energenata|goriva)|zelen\\w+\\s+tranzicij|obnovljiv\\w+\\s+izvor|dekarboniz|klimatsk\\w+\\s+(promjen|politik)|green\\s+deal",
  housing          = "stanovanj|najamnin|nekretnin|stamben|cijen\\w*\\s+stanov|priu[sš]tiv",
  demography_econ  = "radn\\w+\\s+snag|stran\\w+\\s+radnik|uvoz\\w*\\s+radnik|odljev\\w*\\s+mozgov|nedostat\\w+\\s+radnik|manjak\\s+radnik|mirovinsk\\w+\\s+sustav",  # v2: ECONOMIC anchors only; natalitet/depopulacija/iseljavanje are moralized non-econ discourse (kept OUT)
  # --- tier C: lived / person-level ---
  inflation_prices = "inflacij|poskup|(rast|porast|skok)\\w*\\s+cijen|tro[sš]\\w*\\s+[zž]ivota|kupovn\\w*\\s+mo[cć]",  # sister-study anchors; metaphor guard + validated linkage machinery at Stage A
  unemployment     = "nezaposlen|zapo[sš]ljavanj|otpu[sš]tanj\\w*\\s+(radnik|zaposlen|djelatnik)|masovn\\w+\\s+otpu[sš]tanj|\\botkaz(a|e|i|u|om|ima)?\\b|tr[zž]i[sš]t\\w*\\s+rada|radn\\w+\\s+mjest",
  wages_income     = "minimaln\\w+\\s+pla[cć]|prosje[cč]n\\w+\\s+pla[cć]|rast\\w*\\s+pla[cć]|nisk\\w+\\s+pla[cć]|pove[cć]anj\\w*\\s+pla[cć]|mirovin(a|e|i|u|om|ama)?\\b|sindikat|prekarn",
  poverty_social   = "siroma[sš]|socijaln\\w+\\s+(pomo[cć]|skrb|ugro[zž]en)|be[sz]ku[cć]ni|\\bovrh|ovr[sš]n|du[zž]ni[kc]\\w*"
)
TIER <- c(macro_aggregates = "A", euro_changeover = "A", taxes_fiscal = "A", business_comp = "A",
          green_energy = "B", housing = "B", demography_econ = "B",
          inflation_prices = "C", unemployment = "C", wages_income = "C", poverty_social = "C")

# Religion probe for LINKAGE WINDOWS only (NOT the corpus filter). Probe-quality, morphology
# extended (v2); Stage A swaps in the validated tightened 95-term lexicon (R/religious_terms.R).
# caritas/karitas is held SEPARATE so linkage can be reported with/without it — Caritas is often
# the ECONOMIC ACTOR itself (religion-as-actor), not religion commenting on the economy.
relig_core <- paste(
  "crkv", "katoli[cč]", "nadbiskup", "biskup", "sve[cć]en", "[zž]upn", "vatikan",
  "\\bpap[aeiu]\\b", "papinsk", "kr[sš][cć]an", "vjernik", "vjersk", "vjerou[cč]",
  "redovni[kc]", "redovnic", "[cč]asn\\w+\\s+sestr",
  "\\bmis(a|e|i|u|om|ama)\\b", "liturgij", "evan[dđ]elj", "hodo[cč]a[sš]", "krunic", "katedral",
  "biskupij", "nuncij", "enciklik", "sinod", "molitv", "blagoslov",
  "\\bisus\\w{0,4}\\b", "\\bkrist(a|u|om|e)?\\b", "\\bgosp(a|e|i|u|om)\\b", "stepinac", "duhovn",
  "teolo[sšg]", "sveti[sš]t", "samostan", "\\bfratr|\\bfra\\b", "\\bdon\\b",
  sep = "|")
caritas_rx <- "caritas|karitas"
relig_rx   <- paste(relig_core, caritas_rx, sep = "|")

WINDOW <- 220   # sister-validated window (PAPER_v1: recall 0.89 at +/-220)
NSAMP  <- 1200

# --- 2. build (or resume) the domain-flag table; checkpoint fingerprints lexicons + params + src
flags_path <- file.path(out_dir, "_probe_flags.rds")
fingerprint <- list(econ = econ, relig = relig_rx, window = WINDOW, nsamp = NSAMP,
                    src = src, use_sample = USE_SAMPLE)
tab <- NULL
if (file.exists(flags_path)) {
  cached <- readRDS(flags_path)
  if (identical(attr(cached, "fingerprint"), fingerprint)) {
    cat("Resuming from cached probe flags:", flags_path, "| rows:", nrow(cached), "\n"); tab <- cached
  } else cat("Cached flags built with a DIFFERENT lexicon/params/source — re-reading the corpus.\n")
}

if (is.null(tab)) {
  cat("Reading corpus:", src, "\n"); t0 <- Sys.time()
  corpus <- readRDS(src)
  if (inherits(corpus, "data.table")) data.table::setDF(corpus) else corpus <- as.data.frame(corpus)
  miss <- setdiff(c("FULL_TEXT", "DATE"), names(corpus))
  if (length(miss)) stop("Master is missing required columns: ", paste(miss, collapse = ", "))
  if (USE_SAMPLE && mean(grepl("REDACTED", corpus$FULL_TEXT, fixed = TRUE)) > 0.5)
    stop("Sample FULL_TEXT is redacted — the probe needs real text. Run where the master lives.")
  cat(sprintf("  loaded %s rows in %.1f min\n", format(nrow(corpus), big.mark = ","),
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))

  # lowercase BEFORE matching (MEMORY.md); locale='hr' is Croatian-diacritic-correct.
  lowered <- str_to_lower(corpus$FULL_TEXT, locale = "hr")
  n_na_text <- sum(is.na(lowered)); n_empty_text <- sum(!is.na(lowered) & !nzchar(lowered))
  cat("  FULL_TEXT accounting: NA =", n_na_text, "| empty =", n_empty_text,
      "| usable =", sum(!is.na(lowered) & nzchar(lowered)), "\n")

  tab <- data.frame(row_id = seq_len(nrow(corpus)))
  tab$DATE <- corpus$DATE
  tab$FROM <- if ("FROM" %in% names(corpus)) corpus$FROM else NA_character_
  tab$data_source <- if ("data_source" %in% names(corpus)) corpus$data_source else NA_character_

  for (d in names(econ)) {
    t1 <- Sys.time()
    tab[[paste0("econ_", d)]] <- str_detect(lowered, regex(econ[[d]])) %in% TRUE  # NA text -> FALSE, counted above
    cat(sprintf("  tagged %-17s n=%7d  (%.1fs)\n", d, sum(tab[[paste0("econ_", d)]]),
                as.numeric(difftime(Sys.time(), t1, units = "secs"))))
  }

  # --- sampled windowed linkage (+/-220 chars), per domain; stream recorded per sampled post ---
  set.seed(20260706)  # house convention: YYYYMMDD
  link_rows <- list(); link_summ <- list()
  for (d in names(econ)) {
    idx <- which(tab[[paste0("econ_", d)]])
    if (!length(idx)) { link_summ[[d]] <- data.frame(domain = d, n_sampled = 0L); next }
    smp <- if (length(idx) > NSAMP) sample(idx, NSAMP) else idx
    res <- lapply(smp, function(i) {
      txt <- lowered[i]
      locs <- str_locate_all(txt, regex(econ[[d]]))[[1]]
      if (!nrow(locs)) return(c(FALSE, FALSE))
      core <- FALSE; any_r <- FALSE
      for (r in seq_len(nrow(locs))) {           # v2: no per-post window cap
        win <- str_sub(txt, max(1L, locs[r, 1] - WINDOW), min(str_length(txt), locs[r, 2] + WINDOW))
        if (!any_r && str_detect(win, regex(relig_rx)))  any_r <- TRUE
        if (!core  && str_detect(win, regex(relig_core))) core  <- TRUE
        if (any_r && core) break
      }
      c(any_r, core)
    })
    m <- do.call(rbind, res)
    link_rows[[d]] <- data.frame(domain = d, stream = tab$data_source[smp],
                                 linked = m[, 1], linked_ex_caritas = m[, 2])
  }
  attr(tab, "linkage_rows") <- do.call(rbind, link_rows)
  attr(tab, "text_accounting") <- c(na = n_na_text, empty = n_empty_text)
  attr(tab, "fingerprint") <- fingerprint
  rm(corpus, lowered); gc()
  saveRDS(tab, flags_path)
  cat("Checkpoint written:", flags_path, "\n")
}

lrows <- attr(tab, "linkage_rows")
txt_acct <- attr(tab, "text_accounting")

# --- 3. summaries ------------------------------------------------------------------------------
wilson <- function(k, n, z = 1.96) {  # Wilson score interval
  if (n == 0) return(c(NA_real_, NA_real_))
  p <- k / n; den <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / den
  hw  <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  c(max(0, ctr - hw), min(1, ctr + hw))
}

dcols <- paste0("econ_", names(econ))
N <- nrow(tab)

lab_path <- here::here("resources/dictionaries/source_labels.csv")
if (file.exists(lab_path)) {
  lab <- read.csv(lab_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  lk <- setNames(lab$label, lab$from)
  tab$label <- ifelse(!is.na(tab$FROM) & tab$FROM %in% names(lk), lk[tab$FROM], "neoznačeno")
} else tab$label <- "neoznačeno"

date_parsed <- suppressWarnings(as.Date(substr(as.character(tab$DATE), 1, 10)))
n_bad_date <- sum(is.na(date_parsed) & !is.na(tab$DATE))
cat("DATE accounting: unparseable =", n_bad_date, "of", N, "\n")
tab$year <- format(date_parsed, "%Y"); tab$ym <- format(date_parsed, "%Y-%m")

summ <- do.call(rbind, lapply(names(econ), function(d) {
  f <- tab[[paste0("econ_", d)]] %in% TRUE
  lr <- lrows[lrows$domain == d, ]
  ns <- nrow(lr); k <- sum(lr$linked); ci <- wilson(k, ns)
  s1 <- lr[lr$stream %in% "original_dta", ]; s2 <- lr[lr$stream %in% "filtered_religious", ]
  cl <- tab[f & tab$label %in% c("confessional", "secular"), ]
  data.frame(domain = d, tier = TIER[[d]], n = sum(f),
             pct_corpus = round(100 * sum(f) / N, 2),
             n_sampled = ns,
             linked = if (ns) round(k / ns, 3) else NA_real_,
             linked_lo = round(ci[1], 3), linked_hi = round(ci[2], 3),
             linked_ex_caritas = if (ns) round(mean(lr$linked_ex_caritas), 3) else NA_real_,
             linked_stream_2021_24 = if (nrow(s1)) round(mean(s1$linked), 3) else NA_real_,
             linked_stream_2024_26 = if (nrow(s2)) round(mean(s2$linked), 3) else NA_real_,
             pct_classified = round(mean(tab$label[f] != "neoznačeno"), 3),
             confessional_share_of_classified = if (nrow(cl)) round(mean(cl$label == "confessional", na.rm = TRUE), 3) else NA_real_)
}))
write.csv(summ, file.path(out_dir, "domains_summary.csv"), row.names = FALSE, fileEncoding = "UTF-8")

any_econ <- Reduce(`|`, lapply(dcols, function(c) tab[[c]] %in% TRUE))
by_year <- tab %>% filter(any_econ) %>% count(year, data_source) %>% arrange(year)
write.csv(by_year, file.path(out_dir, "econ_by_year_stream.csv"), row.names = FALSE, fileEncoding = "UTF-8")

by_month <- do.call(rbind, lapply(names(econ), function(d) {
  tab %>% filter(.data[[paste0("econ_", d)]] %in% TRUE) %>% count(ym, data_source) %>% mutate(domain = d)
}))
write.csv(by_month, file.path(out_dir, "domains_by_month_stream.csv"), row.names = FALSE, fileEncoding = "UTF-8")

ov <- outer(dcols, dcols, Vectorize(function(a, b) sum(tab[[a]] & tab[[b]], na.rm = TRUE)))
dimnames(ov) <- list(names(econ), names(econ))
write.csv(as.data.frame(ov), file.path(out_dir, "domain_overlap.csv"), fileEncoding = "UTF-8")

cat("\n== moral-economy Stage-0 probe v2 — corpus N =", format(N, big.mark = ","),
    "| text NA/empty =", txt_acct["na"], "/", txt_acct["empty"], "==\n")
cat("(recall-first CANDIDATE counts; linkage sampled, +/-220-char windows, Wilson 95% CI;\n",
    " linked_ex_caritas excludes caritas/karitas from the religion probe; streams reported separately)\n\n")
print(summ, row.names = FALSE)
cat("\nAny-economy-domain posts:", format(sum(any_econ), big.mark = ","),
    sprintf("(%.1f%% of corpus)\n", 100 * sum(any_econ) / N))
cat("Outputs ->", out_dir, "\n")
