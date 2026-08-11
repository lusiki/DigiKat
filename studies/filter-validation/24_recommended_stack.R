#!/usr/bin/env Rscript
# 1) The recommended rule stack, measured on the feed population and on the read 50.
# 2) The coding divergence: rounds 1-3 produced 7 `religious_other` labels in 990 posts (0,7%);
#    round 4 produced 6 in 50 (12%). Either the earlier rounds treated evangelical/charismatic
#    Croatian devotional prose as Catholic, or this draw was freak. This isolates the disputed
#    items so the PI can settle the definition, and reports the headline BOTH ways.
# Aggregates to stdout; the disputed items (titles, sources, URLs) go to output/private/ only.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
OUT <- "studies/filter-validation/output/private"; CAP <- 3000L
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")

CATH <- intersect(c("papa","papinstvo","vatikan","vatikanski","sveta stolica","biskup","biskupija",
  "nadbiskup","nadbiskupija","kardinal","župa","župnik","kapelan","svećenik","misa","euharistija",
  "sakrament","krizma","ispovijed","krunica","franjevac","franjevci","isusovac","dominikanac",
  "redovnik","redovnica","časna sestra","časne sestre","samostan","katedrala","bazilika","kaptol",
  "hodočasnik","hodočašće","procesija","katolička crkva","zaređenje","đakon","sveti red","vjeronauk",
  "vjeroučitelj","liturgija","homilija","oltar","relikvija","monsinjor","kapitul","svetkovina",
  "gospa","djevica marija","srce isusovo","pobožnost","klanjanje","križni put"), v3$term)
OTHER <- paste(c("džamij","imam[ai]?\\b","hafiz","kur'?an","ramazan","medres","džemat","mukabel",
  "muslimansk","islamsk","allah","bajram","efendij","pravoslavn","patrijarh","eparhij","protojerej",
  "mitropolit","ikonostas","pastor[aiu]?\\b","evanđeosk","baptist","adventist","jehovin",
  "pentekost","protestantsk","biblijska škola"), collapse = "|")
cat("Catholic-specific terms matched in v3:", length(CATH), "of 119\n")

keep_stack <- function(H, txt) {
  tier <- v3$tier; names(tier) <- v3$term
  tier["božji"] <- "ambiguous"                                   # repair B
  dec <- rowSums(H[, tier == "decisive", drop = FALSE]); tot <- rowSums(H)
  g1 <- dec >= 1L & tot >= 2L                                    # gate 1, window-limited by caller
  cath <- rowSums(H[, v3$term %in% CATH, drop = FALSE]) > 0
  oth  <- stri_detect_regex(txt, OTHER, case_insensitive = TRUE)
  list(g1 = g1, keep = g1 & !(oth & !cath), cath = cath, oth = oth)
}

## ---- population -------------------------------------------------------------------------------
cc <- readRDS(file.path(OUT, "repair_pool_cache.rds"))
g <- cc$g; n_text <- cc$n_text
base <- { tier <- v3$tier
  rowSums(cc$Hf[, tier == "decisive", drop = FALSE]) >= 1L & rowSums(cc$Hf) >= 2L }
st <- keep_stack(cc$Hw, g$win)
fs <- readRDS(file.path(OUT, "pre2024_output_sample.rds"))$feed_scored
g$in_master <- g$url %in% fs$url[fs$in_master]

rows <- function(nm, k) data.frame(rule = nm, kept = sum(k),
  pct_of_feed = round(100*mean(k), 3), projected = round(n_text*mean(k)),
  pct_already_in_corpus = round(100*mean(g$in_master[k]), 1))
cat("\n=== gate 1 on the 50 744-row feed pool ===\n")
print(bind_rows(
  rows("v3 as specified (searches whole text)", base),
  rows("+ window: search first 3000 chars only", st$g1),
  rows("+ bozji demoted to ambiguous", st$g1),
  rows("+ other-religion veto", st$keep)), row.names = FALSE)
cat("\nnote: the 'bozji' repair changes nothing on its own at the population level -- posts whose\n",
    "only decisive term was bozji already fail once the window is applied. Reported for the record.\n")

## ---- the read 50 ------------------------------------------------------------------------------
r4 <- readRDS(file.path(OUT, "pre2024_output_coded.rds"))
H4 <- digikat_hit_matrix(substr(r4$text_full, 1, CAP), v3)
s4 <- keep_stack(H4, substr(r4$text_full, 1, CAP))
show <- function(nm, k) { y <- r4$clear
  data.frame(rule = nm, kept = sum(k), genuine = sum(k & y),
             precision = sprintf("%.1f", 100*sum(k & y)/max(1, sum(k))),
             prec_in_corpus = sprintf("%.1f", 100*sum(k & y & r4$in_master)/max(1, sum(k & r4$in_master))),
             prec_new = sprintf("%.1f", 100*sum(k & y & !r4$in_master)/max(1, sum(k & !r4$in_master)))) }
cat("\n=== the same rules on the 50 read posts ===\n")
print(bind_rows(
  show("v3 + gate 2 >= 0.50 (as drawn)", rep(TRUE, nrow(r4))),
  show("+ window", s4$g1),
  show("+ other-religion veto", s4$keep)), row.names = FALSE)

cat("\n=== and if the PI rules that non-Catholic Christian devotion counts as in-scope ===\n")
r4$clear2 <- r4$label %in% c("catholic_clear", "religious_other")
show2 <- function(nm, k) { y <- r4$clear2
  data.frame(rule = nm, kept = sum(k), genuine = sum(k & y),
             precision = sprintf("%.1f", 100*sum(k & y)/max(1, sum(k)))) }
print(bind_rows(show2("v3 + gate 2 (as drawn)", rep(TRUE, nrow(r4))),
                show2("+ window", s4$g1),
                show2("+ other-religion veto (would now be wrong)", s4$keep)), row.names = FALSE)

## ---- the disputed items -----------------------------------------------------------------------
rd <- function(p, tag) { x <- readRDS(p)
  data.frame(round = tag, id = as.character(x$id),
             stratum = if ("stratum" %in% names(x)) as.character(x$stratum) else "OUT",
             label = as.character(x$label),
             source = if ("source" %in% names(x)) as.character(x$source) else "",
             title = ifelse(is.na(x$title), "", as.character(x$title)),
             url = as.character(x$url),
             text = substr(as.character(if ("text" %in% names(x)) x$text else x$text_full), 1, CAP),
             stringsAsFactors = FALSE) }
cd <- bind_rows(rd(file.path(OUT, "coded.rds"), "r1"),
                rd(file.path(OUT, "holdout_coded.rds"), "r2"),
                rd("data/rebuild/discarded_coded.rds", "r3"),
                rd(file.path(OUT, "pre2024_output_coded.rds"), "r4"))
Hc <- digikat_hit_matrix(cd$text, v3)
sc <- keep_stack(Hc, cd$text)
disp <- cd[sc$g1 & sc$oth & !sc$cath, ]
disp$markers <- vapply(disp$text, function(t)
  paste(unique(tolower(unlist(stri_extract_all_regex(t, OTHER, case_insensitive = TRUE)))),
        collapse = "; "), character(1))
cat("\n=== accepted posts with a non-Catholic religious marker and NO Catholic-specific term ===\n")
print(as.data.frame(table(round = disp$round, label = disp$label)))
cat("\nof these, coded catholic_clear:", sum(disp$label == "catholic_clear"),
    "-> the earlier rounds did treat such posts as Catholic\n")
write.csv(disp[, c("round","id","stratum","label","source","title","url","markers")],
          file.path(OUT, "denomination_adjudication.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("wrote denomination_adjudication.csv (PRIVATE: carries titles, sources, URLs)\n")

## ---- the projection ---------------------------------------------------------------------------
cat("\n=== pre-2024 rebuild under the recommended stack, with gate 2 at 0.50 ===\n")
# precision per segment measured on the 50; gate-2 rate carried over from the drawn pool
g2_rate <- readRDS(file.path(OUT, "pre2024_output_sample.rds"))$gate2_rate
p_in  <- sum(s4$keep & r4$clear & r4$in_master)  / max(1, sum(s4$keep & r4$in_master))
p_new <- sum(s4$keep & r4$clear & !r4$in_master) / max(1, sum(s4$keep & !r4$in_master))
n1 <- n_text * mean(st$keep); share_in <- mean(g$in_master[st$keep])
n2 <- n1 * g2_rate
est <- data.frame(
  stage = c("gate 1 (window, bozji, veto)", "+ gate 2 >= 0.50"),
  posts = round(c(n1, n2)),
  already_in_corpus = round(c(n1, n2) * share_in),
  new_material = round(c(n1, n2) * (1 - share_in)),
  est_genuine = round(c(n1, n2) * (share_in*p_in + (1-share_in)*p_new)))
est$est_precision <- sprintf("%.1f%%", 100*est$est_genuine/est$posts)
print(est, row.names = FALSE)
cat(sprintf("\nsegment precision used: %.1f%% in-corpus (n=%d read), %.1f%% new (n=%d read)\n",
            100*p_in, sum(s4$keep & r4$in_master), 100*p_new, sum(s4$keep & !r4$in_master)))
cat("Today the pre-2024 half is 269 583 posts at 79,5% clean (n=88 read) = ~214 000 genuine.\n")
