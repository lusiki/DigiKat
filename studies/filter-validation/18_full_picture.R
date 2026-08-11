#!/usr/bin/env Rscript
# Both halves of the corpus, end to end. The earlier option tables covered only the pre-2024 half
# (DetermDB spans 2021-01-01 to 2024-07-04, so a rebuild is possible there and nowhere else).
# Every rate below is measured; only the arithmetic is new.
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "studies/filter-validation/output/private"

cat("counting the master...\n")
m <- readRDS("data/merged_comprehensive.rds")
n_post <- sum(m$data_source == "filtered_religious")
n_pre  <- sum(m$data_source == "original_dta")
n_all  <- nrow(m); rm(m); invisible(gc())
cat("post-2024:", n_post, "| pre-2024:", n_pre, "| total:", n_all, "\n\n")

# measured rates ---------------------------------------------------------------------------------
ACC_POST <- 0.674   # 10_draw_holdout.R: v3 accepts this share of post-2024 master rows
ACC_PRE  <- 0.883   # 10_draw_holdout.R: ... and this share of pre-2024 master rows
P_POST   <- 0.773   # 12_score_holdout.R S1: precision of v3 on post-2024 accepts
P_PRE    <- 0.800   # 12_score_holdout.R S2: precision of v3 on pre-2024 accepts
P1_R1    <- 0.550   # round 1: precision of the CURRENT corpus, post-2024 half
P1_R2    <- 0.700   # round 1: precision of the CURRENT corpus, pre-2024 half
SP <- c(precision = 0.907, recall = 0.870)   # second pass, master material (15_where_to_spend.R)

pop <- read.csv(file.path(OUT, "holdout_population.csv"), stringsAsFactors = FALSE)
scale <- 19781689 / sum(pop$n)
n_reb <- pop$n[pop$group == "accept, new"] * scale     # new pre-2024 material a rebuild adds
P_REB <- pop$precision[pop$group == "accept, new"]
SP_REB <- c(precision = 0.807, recall = 0.797)         # second pass, new feed material (16_...)

after <- function(n, p, sp) {
  g <- n * p * sp[["recall"]]
  c(posts = g / sp[["precision"]], genuine = g)
}
row <- function(label, posts, genuine) data.frame(
  scenario = label, posts = round(posts, -2), genuine = round(genuine, -2),
  junk = round(posts - genuine, -2), clean = round(100 * genuine / posts, 1))

# post-2024 half: cleaning only, no raw feed exists for 2024-2026
post_now   <- c(n_post, n_post * P1_R1)
post_v3    <- c(n_post * ACC_POST, n_post * ACC_POST * P_POST)
post_v3_sp <- after(n_post * ACC_POST, P_POST, SP)

# pre-2024 half: clean, or clean and rebuild
pre_now    <- c(n_pre, n_pre * P1_R2)
pre_v3     <- c(n_pre * ACC_PRE, n_pre * ACC_PRE * P_PRE)
pre_v3_sp  <- after(n_pre * ACC_PRE, P_PRE, SP)
reb_sp     <- after(n_reb, P_REB, SP_REB)

cat("=== the post-2024 half (2024-2026) — can only be cleaned ===\n")
print(rbind(row("as it stands today", post_now[1], post_now[2]),
            row("re-filtered with the word list", post_v3[1], post_v3[2]),
            row("re-filtered + second step", post_v3_sp[["posts"]], post_v3_sp[["genuine"]])),
      row.names = FALSE)

cat("\n=== the pre-2024 half (2021-2024) — can be cleaned AND rebuilt ===\n")
print(rbind(row("as it stands today", pre_now[1], pre_now[2]),
            row("re-filtered with the word list", pre_v3[1], pre_v3[2]),
            row("re-filtered + second step", pre_v3_sp[["posts"]], pre_v3_sp[["genuine"]]),
            row("re-filtered + second step + rebuild",
                pre_v3_sp[["posts"]] + reb_sp[["posts"]],
                pre_v3_sp[["genuine"]] + reb_sp[["genuine"]])),
      row.names = FALSE)

cat("\n=== the whole corpus, end state ===\n")
print(rbind(
  row("today", post_now[1] + pre_now[1], post_now[2] + pre_now[2]),
  row("clean both halves, no rebuild",
      post_v3_sp[["posts"]] + pre_v3_sp[["posts"]],
      post_v3_sp[["genuine"]] + pre_v3_sp[["genuine"]]),
  row("clean both halves + rebuild pre-2024",
      post_v3_sp[["posts"]] + pre_v3_sp[["posts"]] + reb_sp[["posts"]],
      post_v3_sp[["genuine"]] + pre_v3_sp[["genuine"]] + reb_sp[["genuine"]])),
  row.names = FALSE)

g_today <- post_now[2] + pre_now[2]
g_final <- post_v3_sp[["genuine"]] + pre_v3_sp[["genuine"]] + reb_sp[["genuine"]]
cat(sprintf("\nFull plan vs today: %+s genuine Catholic posts (%+.0f%%), %.0f%% clean vs %.0f%%.\n",
            format(round(g_final - g_today, -2), big.mark = " "),
            100 * (g_final - g_today) / g_today,
            100 * g_final / (post_v3_sp[["posts"]] + pre_v3_sp[["posts"]] + reb_sp[["posts"]]),
            100 * g_today / (post_now[1] + pre_now[1])))
