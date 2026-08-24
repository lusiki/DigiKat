# 02_analyze.R — items.rds → compact aggregates + every scalar the story quotes.
#
#   Rscript 02_analyze.R
#
# Reads  output/items.rds
# Writes output/agg/*.csv   (small tables, no titles, no URLs — publishable)
#        output/agg/derived.json (scalars; the story text is generated FROM this, never typed)
#        output/private/*.csv    (anything carrying a headline)
#
# All measures are descriptive. "Who published first" is a timestamp comparison, not a claim of
# influence; "rewarded" is recorded attention, not quality; frames are dictionary hits.

setwd(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))))
source("lib.R")

items <- readRDS(file.path(OUT_DIR, "items.rds"))
assert_rows(items, 50, "items.rds")
SYNTH <- is_synthetic(items)
fcols <- paste0("f_", names(FRAMES))
om <- items[about_omis == TRUE]
assert_rows(om, 30, "Omiš items")

D <- list(synthetic = SYNTH, generated_at = format(Sys.time(), "%Y-%m-%d %H:%M", tz = TZ), t0 = format(T0, "%Y-%m-%d %H:%M", tz = TZ))
wcsv <- function(dt, name) fwrite(dt, file.path(AGG_DIR, paste0(name, ".csv")), bom = TRUE)
clock <- function(h) format(T0 + h * 3600, "%a %d.%m. %H:%M", tz = TZ)

# ---------------------------------------------------------------------------------------------
# A. Volume in time
# ---------------------------------------------------------------------------------------------
hourly <- om[, .(n = .N, interactions = sum(interactions)), by = .(hb, platform, outlet_type)]
wcsv(hourly, "hourly")
hourly_tot <- om[, .(n = .N, interactions = sum(interactions)), by = hb][order(hb)]
grid <- data.table(hb = seq(floor(min(om$hb)), ceiling(max(om$hb))))
hourly_tot <- merge(grid, hourly_tot, by = "hb", all.x = TRUE)[is.na(n), `:=`(n = 0L, interactions = 0)]
hourly_tot[, n_ma3 := frollmean(n, 3, align = "center", fill = NA)]
wcsv(hourly_tot, "hourly_total")

peak <- hourly_tot[which.max(n)]
D$n_items <- nrow(om); D$n_items_all_fires <- nrow(items); D$n_sources <- uniqueN(om$from_lc)
D$span_hours <- round(max(om$h) - min(om$h), 1)
D$peak_hour <- peak$hb; D$peak_n <- peak$n; D$peak_clock <- clock(peak$hb)
# half-life: first hour after the peak at which the 3-hour moving average stays under half the peak's moving average
pk_ma <- hourly_tot[hb == peak$hb, n_ma3]; if (is.na(pk_ma)) pk_ma <- peak$n
after <- hourly_tot[hb > peak$hb & !is.na(n_ma3)]
below <- after[, n_ma3 < pk_ma / 2]
hl <- NA_real_
if (any(below)) { r <- rle(below); idx <- which(r$values & r$lengths >= 3)[1]; if (!is.na(idx)) hl <- after$hb[sum(r$lengths[seq_len(idx - 1)]) + 1] - peak$hb }
D$half_life_hours <- hl
# share of everything inside the first 24 / 48 h
for (w in c(6, 12, 24, 48, 72)) { D[[paste0("share_items_first_", w, "h")]] <- round(100 * mean(om$h <= w), 1); D[[paste0("share_interactions_first_", w, "h")]] <- round(100 * sum(om$interactions[om$h <= w]) / max(1, sum(om$interactions)), 1) }
# t50 / t80 overall
cs <- om[order(h), .(h, cum = seq_len(.N) / .N)]
D$t50_hours <- round(cs[cum >= 0.5, h][1], 1); D$t80_hours <- round(cs[cum >= 0.8, h][1], 1)

daily <- om[, .(n = .N, interactions = sum(interactions)), by = .(day, outlet_type)][order(day)]
wcsv(daily, "daily")

# ---------------------------------------------------------------------------------------------
# B. Who lit it — the cascade of entry
# ---------------------------------------------------------------------------------------------
cascade <- om[, .(platform = platform[1], outlet_type = outlet_type[1], ring = ring[1],
                  first_h = min(h), last_h = max(h), median_h = median(h), n = .N,
                  interactions = sum(interactions), first_title_len = nchar(TITLE[which.min(h)])),
              by = .(FROM = from_lc)][order(first_h)]
cascade[, entry_rank := seq_len(.N)]
wcsv(cascade, "cascade")

first_by_type <- om[, .(first_h = min(h), first_clock = clock(min(h)), first_source = from_lc[which.min(h)], n = .N), by = outlet_type][order(first_h)]
wcsv(first_by_type, "first_by_type")
first_by_platform <- om[, .(first_h = min(h), first_clock = clock(min(h)), first_source = from_lc[which.min(h)], n = .N), by = platform][order(first_h)]
wcsv(first_by_platform, "first_by_platform")
for (i in seq_len(nrow(first_by_type))) D[[paste0("first_h_", first_by_type$outlet_type[i])]] <- round(first_by_type$first_h[i], 2)
D$first_item <- list(h = round(min(om$h), 2), clock = clock(min(om$h)), platform = om$platform[which.min(om$h)], outlet_type = om$outlet_type[which.min(om$h)])
# lag between the first local and the first national item, and first official
D$lag_local_to_national_h <- round(D$first_h_nacionalni - D$first_h_lokalni, 2)
D$lag_first_to_official_h <- round(D$first_h_sluzbeni - D$first_item$h, 2)
D$lag_first_to_foreign_h  <- round(D$first_h_strani - D$first_item$h, 2)
# first movers (private: has titles)
fwrite(om[order(h)][1:min(40, .N), .(h = round(h, 2), clock = clock(h), platform, FROM, outlet_type, interactions, TITLE, URL)],
       file.path(PRIV_DIR, "first_movers.csv"), bom = TRUE)
# how many sources had entered by hour X
entered <- cascade[, .(first_h)][order(first_h)][, .(hb = hour_bin(first_h)), ][, .(new_sources = .N), by = hb][order(hb)][, cum_sources := cumsum(new_sources)]
wcsv(entered, "sources_entered")
D$sources_entered_by_6h <- entered[hb < 6, sum(new_sources)]; D$sources_entered_by_24h <- entered[hb < 24, sum(new_sources)]

# ---------------------------------------------------------------------------------------------
# C. What the story was about — frames over time and by type
# ---------------------------------------------------------------------------------------------
om[, hb3 := hour_bin(h, 3)]
fr_long <- melt(om[, c("item_id", "hb", "hb3", "outlet_type", "interactions", fcols), with = FALSE],
                id.vars = c("item_id", "hb", "hb3", "outlet_type", "interactions"), variable.name = "frame", value.name = "hit")
fr_long[, frame := sub("^f_", "", frame)]
frames_hourly <- fr_long[, .(n_hit = sum(hit), n_items = uniqueN(item_id), share = round(100 * sum(hit) / uniqueN(item_id), 1)), by = .(hb3, frame)][order(hb3, frame)]
wcsv(frames_hourly, "frames_hourly")
frames_type <- fr_long[, .(n_hit = sum(hit), n_items = uniqueN(item_id), share = round(100 * sum(hit) / uniqueN(item_id), 1)), by = .(outlet_type, frame)][order(outlet_type, -share)]
wcsv(frames_type, "frames_type")
# frame "onset" (first 3-h bin with ≥ 8 items where the frame is carried by ≥ 25 % of items) and peak
onset <- frames_hourly[n_items >= 8][, .(onset_h = hb3[which(share >= 25)[1]], peak_h = hb3[which.max(share)], peak_share = max(share)), by = frame]
wcsv(onset, "frames_onset")
for (i in seq_len(nrow(onset))) { D[[paste0("frame_", onset$frame[i], "_onset_h")]] <- onset$onset_h[i]; D[[paste0("frame_", onset$frame[i], "_peak_h")]] <- onset$peak_h[i]; D[[paste0("frame_", onset$frame[i], "_peak_share")]] <- onset$peak_share[i] }
# frames rewarded: interactions per item with vs without frame (web + facebook only, where interactions mean something)
fr_rew <- fr_long[outlet_type %in% c("lokalni","nacionalni","ostali_web","drustveni")][, .(items = .N, ipi = round(mean(interactions), 1)), by = .(frame, hit)]
fr_rew <- dcast(fr_rew, frame ~ hit, value.var = c("items", "ipi"))
setnames(fr_rew, c("frame", "items_without", "items_with", "ipi_without", "ipi_with"))
fr_rew[, lift := round(ipi_with / pmax(ipi_without, 0.1), 2)]
wcsv(fr_rew, "frames_rewarded")

# ---------------------------------------------------------------------------------------------
# D. Produced vs rewarded; concentration; zero share
# ---------------------------------------------------------------------------------------------
pr_type <- om[, .(items = .N, interactions = sum(interactions), ipi = round(mean(interactions), 1),
                  zero_share = round(100 * mean(!has_interaction), 1), sources = uniqueN(from_lc)), by = outlet_type]
pr_type[, `:=`(share_items = round(100 * items / sum(items), 1), share_interactions = round(100 * interactions / max(1, sum(interactions)), 1))]
pr_type[, gap_pp := share_interactions - share_items]
wcsv(pr_type[order(-items)], "produced_rewarded_type")
pr_plat <- om[, .(items = .N, interactions = sum(interactions), views = sum(views), ipi = round(mean(interactions), 1), zero_share = round(100 * mean(!has_interaction), 1)), by = platform]
pr_plat[, `:=`(share_items = round(100 * items / sum(items), 1), share_interactions = round(100 * interactions / max(1, sum(interactions)), 1))]
pr_plat[, gap_pp := share_interactions - share_items]
wcsv(pr_plat[order(-items)], "produced_rewarded_platform")
D$produced_rewarded_type <- pr_type[, .(outlet_type, share_items, share_interactions, gap_pp, ipi, zero_share)]
D$produced_rewarded_platform <- pr_plat[, .(platform, share_items, share_interactions, gap_pp, ipi, zero_share)]

top_share <- function(x, k = 10) round(100 * sum(sort(x, decreasing = TRUE)[seq_len(min(k, length(x)))]) / max(1, sum(x)), 1)
conc <- rbind(data.table(scope = "all", items = nrow(om), top10_share = top_share(om$interactions), top1_share = top_share(om$interactions, 1), zero_share = round(100 * mean(!om$has_interaction), 1)),
              om[, .(items = .N, top10_share = top_share(interactions), top1_share = top_share(interactions, 1), zero_share = round(100 * mean(!has_interaction), 1)), by = .(scope = platform)])
wcsv(conc, "concentration")
D$top10_share_all <- conc[scope == "all", top10_share]; D$top1_share_all <- conc[scope == "all", top1_share]
D$zero_share_web <- conc[scope == "web", zero_share]
# the top-10 attention items — private (titles), plus a public shape (type/platform/hour only)
top10 <- om[order(-interactions)][1:min(10, .N)]
fwrite(top10[, .(rank = seq_len(.N), h = round(h, 1), clock = clock(h), platform, FROM, outlet_type, interactions, sensational, TITLE, URL)], file.path(PRIV_DIR, "top10_attention.csv"), bom = TRUE)
wcsv(top10[, .(rank = seq_len(.N), h = round(h, 1), platform, outlet_type, interactions, sensational, frames = apply(.SD, 1, function(r) paste(names(FRAMES)[as.logical(r)], collapse = "+"))), .SDcols = fcols], "top10_attention_public")
D$top10_median_entry_h <- round(median(top10$h), 1)
D$top10_platforms <- as.list(top10[, .N, by = platform][, setNames(N, platform)])

# ---------------------------------------------------------------------------------------------
# E. Blast radius — the geographic rings
# ---------------------------------------------------------------------------------------------
rings <- merge(RINGS, om[, .(n = .N, first_h = round(min(h), 2), first_clock = clock(min(h)), median_h = round(median(h), 1), interactions = sum(interactions), sources = uniqueN(from_lc)), by = ring], by = "ring", all.x = TRUE)
rings[is.na(n), n := 0L][, share := round(100 * n / sum(n), 1)]
wcsv(rings, "rings")
D$rings <- rings[, .(ring, ring_hr, n, share, first_h, median_h, sources)]
D$foreign_share <- round(100 * mean(om$ring >= 3), 1)
lang_tab <- om[ring >= 3, .N, by = lang][order(-N)][1:min(.N, 8)]
wcsv(lang_tab, "foreign_languages")
D$foreign_languages <- as.list(lang_tab[, setNames(N, lang)])

# ---------------------------------------------------------------------------------------------
# F. Cumulative curves per outlet type (the "window" chart) and t50/t80 per type
# ---------------------------------------------------------------------------------------------
cum_type <- om[order(h), .(h = h, cum_share = seq_len(.N) / .N, n = .N), by = outlet_type]
cum_grid <- CJ(outlet_type = unique(om$outlet_type), hb = seq(0, ceiling(max(om$h))))
cum_grid <- cum_grid[, .(cum_share = { s <- om[outlet_type == .BY$outlet_type, h]; round(100 * mean(s <= hb), 1) }), by = .(outlet_type, hb)]
wcsv(cum_grid, "cumulative_type")
t_type <- om[, .(n = .N, t50 = round(quantile(h, 0.5), 1), t80 = round(quantile(h, 0.8), 1), median_h = round(median(h), 1)), by = outlet_type][order(t50)]
wcsv(t_type, "window_type")
D$window_type <- t_type

# ---------------------------------------------------------------------------------------------
# G. Temperature of language
# ---------------------------------------------------------------------------------------------
sens_type <- om[, .(items = .N, sensational_share = round(100 * mean(sensational), 1), ipi_sens = round(mean(interactions[sensational]), 1), ipi_plain = round(mean(interactions[!sensational]), 1)), by = outlet_type][order(-sensational_share)]
sens_type[, lift := round(ipi_sens / pmax(ipi_plain, 0.1), 2)]
wcsv(sens_type, "sensational_type")
sens_time <- om[, .(items = .N, sensational_share = round(100 * mean(sensational), 1)), by = hb3][order(hb3)]
wcsv(sens_time, "sensational_time")
D$sensational_share_all <- round(100 * mean(om$sensational), 1)
D$sensational_type <- sens_type[, .(outlet_type, sensational_share, lift)]
# which sensational words, how often (title level)
words <- c("apokalips", "pak[ao]o|paklen", "katastrof", "horor", "dram", "u[žz]as", "strav", "nevi[đd]en", "kaos", "inferno", "jeziv", "[šs]ok", "stihij")
wtab <- rbindlist(lapply(words, function(w) data.table(word = w, n = sum(rx_hit(stri_trans_tolower(om$TITLE), fold(stri_trans_tolower(om$TITLE)), w)))))[order(-n)]
wcsv(wtab, "sensational_words")

# ---------------------------------------------------------------------------------------------
# H. Echo — the same headline across outlets
# ---------------------------------------------------------------------------------------------
web_om <- om[platform == "web"]
D$echo_share_web <- round(100 * mean(web_om$echo), 1)
D$hina_share_web <- round(100 * mean(web_om$hina), 1)
D$echo_share_by_type <- as.list(web_om[, .(s = round(100 * mean(echo), 1)), by = outlet_type][, setNames(s, outlet_type)])
clusters <- web_om[cluster_sources >= 3, .(cluster_sources = cluster_sources[1], cluster_n = cluster_n[1], first_h = round(min(h), 2), first_source = from_lc[which.min(h)], first_type = outlet_type[which.min(h)],
                                            spread_h = round(max(h) - min(h), 1), interactions = sum(interactions), title = TITLE[which.min(h)]), by = title_key][order(-cluster_sources)]
fwrite(clusters[1:min(30, .N)], file.path(PRIV_DIR, "echo_clusters.csv"), bom = TRUE)
wcsv(clusters[1:min(30, .N), .(rank = seq_len(.N), cluster_sources, cluster_n, first_h, first_type, spread_h, interactions)], "echo_clusters_public")
D$echo_clusters_n <- nrow(clusters)
D$echo_first_type <- as.list(clusters[, .N, by = first_type][, setNames(N, first_type)])
D$echo_median_spread_h <- if (nrow(clusters)) round(median(clusters$spread_h), 1) else NA

# ---------------------------------------------------------------------------------------------
# I. Which fire got the story
# ---------------------------------------------------------------------------------------------
fires <- items[, .(items = .N, share = round(100 * .N / nrow(items), 1), first_h = round(min(h), 1), interactions = sum(interactions), sources = uniqueN(from_lc)), by = fire][order(-items)]
wcsv(fires, "fires")
D$fires <- fires

# ---------------------------------------------------------------------------------------------
# J. Early vs late — attention per item by entry window (the promotion lesson, descriptively)
# ---------------------------------------------------------------------------------------------
om[, entry_window := cut(h, breaks = c(-Inf, 3, 6, 12, 24, 48, 72, Inf), labels = c("0–3 h", "3–6 h", "6–12 h", "12–24 h", "24–48 h", "48–72 h", "72 h+"))]
early <- om[platform %in% c("web", "facebook"), .(items = .N, ipi = round(mean(interactions), 1), median_i = median(interactions), zero_share = round(100 * mean(!has_interaction), 1)), by = .(platform, entry_window)][order(platform, entry_window)]
wcsv(early, "early_late")
ew <- early[platform == "web"]
D$early_late_web <- ew
if (nrow(ew) >= 4) D$early_vs_late_ipi_ratio_web <- round(ew[entry_window == "0–3 h", ipi] / pmax(ew[entry_window == "24–48 h", ipi], 0.1), 2)

# ---------------------------------------------------------------------------------------------
# K. Hour-of-day (clock) publishing vs attention — when did people actually engage
# ---------------------------------------------------------------------------------------------
om[, hod := as.integer(format(t, "%H", tz = TZ))]
hod <- om[, .(items = .N, interactions = sum(interactions), ipi = round(mean(interactions), 1)), by = .(day, hod)][order(day, hod)]
wcsv(hod, "hour_of_day")

# ---------------------------------------------------------------------------------------------
# Write derived scalars
# ---------------------------------------------------------------------------------------------
write_json(D, file.path(AGG_DIR, "derived.json"), auto_unbox = TRUE, pretty = TRUE, na = "null", digits = NA)
cat(sprintf("Omiš items %s of %s | sources %s | peak %s items at story hour %s (%s) | half-life %s h | t50 %s h | t80 %s h\n",
            fmt_hr(D$n_items), fmt_hr(D$n_items_all_fires), fmt_hr(D$n_sources), D$peak_n, D$peak_hour, D$peak_clock, D$half_life_hours, D$t50_hours, D$t80_hours))
cat("First by outlet type:\n"); print(first_by_type)
cat("Produced vs rewarded by type:\n"); print(pr_type[order(-items), .(outlet_type, items, share_items, share_interactions, gap_pp, ipi, zero_share)])
cat("Rings:\n"); print(rings[, .(ring, ring_hr, n, share, first_h, sources)])
cat("Frame onset/peak (3-h bins):\n"); print(onset)
cat(sprintf("Sensational titles %.1f%% | echo (>=3 outlets, web) %.1f%% | Hina credited %.1f%% | foreign share %.1f%%\n", D$sensational_share_all, D$echo_share_web, D$hina_share_web, D$foreign_share))
if (SYNTH) cat("\n>>> ", SYNTH_TAG_EN, " <<<\n")
