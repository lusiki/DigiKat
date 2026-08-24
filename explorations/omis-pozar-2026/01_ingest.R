# 01_ingest.R — vendor export(s) → one clean, classified item table.
#
#   Rscript 01_ingest.R              reads every .xlsx/.csv in input/   (the real export)
#   Rscript 01_ingest.R --synthetic  reads output/synthetic/             (pipeline test)
#
# Writes  output/items.rds                (row level, private — never leaves the machine)
#         output/private/items_titles.csv (time · outlet · type · title · URL — for reading, not publishing)
#         output/agg/qa.json              (what came in, what was dropped, what is unclassified)
#
# Nothing here is a finding. This script decides what a row IS: when it was published, who
# published it, which fire it is about, which frames it carries, and how much attention it drew.

setwd(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))))
source("lib.R")
args <- commandArgs(trailingOnly = TRUE)
SYNTH <- "--synthetic" %in% args

# ---------------------------------------------------------------------------------------------
# 1. Read
# ---------------------------------------------------------------------------------------------
src_dir <- if (SYNTH) file.path(OUT_DIR, "synthetic") else IN_DIR
raw <- read_vendor_exports(src_dir)
if (is.null(raw)) {
  stop(sprintf(paste0(
    "No export found in %s.\n",
    "  Drop the vendor .xlsx/.csv export(s) into  input/  and rerun, or run with --synthetic to test the pipeline."),
    src_dir), call. = FALSE)
}
if (!SYNTH && is_synthetic(raw)) stop("input/ contains a SYNTHETIC file. Remove it; synthetic runs go through --synthetic.", call. = FALSE)
if (SYNTH && !is_synthetic(raw)) stop("--synthetic given but the file is not stamped SYNTHETIC.", call. = FALSE)

need <- c("DATE", "TIME", "TITLE", "FROM", "URL", "SOURCE_TYPE")
miss <- setdiff(need, names(raw))
if (length(miss)) stop("Export is missing required columns: ", paste(miss, collapse = ", "), call. = FALSE)
n_raw <- nrow(raw)
cat(sprintf("Read %s rows from %d file(s) in %s\n", fmt_hr(n_raw), uniqueN(raw$.source_file), src_dir))

# ---------------------------------------------------------------------------------------------
# 2. Types and time
# ---------------------------------------------------------------------------------------------
num_cols <- intersect(c("REACH","VIRALITY","ENGAGEMENT_RATE","INTERACTIONS","FOLLOWERS_COUNT","LIKE_COUNT","COMMENT_COUNT",
                        "SHARE_COUNT","TWEET_COUNT","LOVE_COUNT","WOW_COUNT","HAHA_COUNT","SAD_COUNT","ANGRY_COUNT",
                        "TOTAL_REACTIONS_COUNT","FAVORITE_COUNT","RETWEET_COUNT","VIEW_COUNT","DISLIKE_COUNT","COUNT",
                        "REPOST_COUNT","REDDIT_SCORE","INFLUENCE_SCORE","DIGG_COUNT","AUTHOR_FOLLOWER_COUNT","DURATION"),
                      names(raw))
for (cc in num_cols) set(raw, j = cc, value = suppressWarnings(as.numeric(raw[[cc]])))
for (cc in c("TITLE","FROM","URL","SOURCE_TYPE","FULL_TEXT","MENTION_SNIPPET","LANGUAGES","LOCATIONS","AUTHOR","GROUP_NAME"))
  if (!cc %in% names(raw)) raw[, (cc) := NA_character_]

# Excel exports sometimes carry DATE as a serial number or a datetime string — accept the common shapes.
parse_date_any <- function(x) {
  x <- trimws(as.character(x))
  d <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  alt <- is.na(d) & !is.na(x)
  if (any(alt)) d[alt] <- suppressWarnings(as.Date(x[alt], format = "%d.%m.%Y"))
  alt <- is.na(d) & !is.na(x) & grepl("^[0-9]{5}$", x)
  if (any(alt)) d[alt] <- as.Date(as.numeric(x[alt]), origin = "1899-12-30")
  alt <- is.na(d) & !is.na(x) & grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]", x)
  if (any(alt)) d[alt] <- as.Date(substr(x[alt], 1, 10))
  d
}
raw[, .date := parse_date_any(DATE)]
raw[, .time := trimws(as.character(TIME))]
raw[grepl("^[0-9]{1,2}:[0-9]{2}$", .time), .time := paste0(.time, ":00")]
raw[, .time_ok := grepl("^[0-9]{1,2}:[0-9]{2}:[0-9]{2}$", .time)]
raw[, t := as.POSIXct(paste(format(.date), fifelse(.time_ok, .time, "12:00:00")), tz = TZ, format = "%Y-%m-%d %H:%M:%S")]
n_no_date <- sum(is.na(raw$t))
n_no_time <- sum(!raw$.time_ok & !is.na(raw$.date))
raw <- raw[!is.na(t)]

# ---------------------------------------------------------------------------------------------
# 3. Deduplicate on canonical URL (borrow the project's canonicaliser; fall back if it cannot load)
# ---------------------------------------------------------------------------------------------
canon <- tryCatch({
  e <- new.env(); sys.source(file.path(REPO_ROOT, "R", "lib", "digikat_utils.R"), envir = e)
  e$digikat_canonicalize_url
}, error = function(err) {
  message("digikat_utils.R not loadable (", conditionMessage(err), ") — using a minimal canonicaliser.")
  function(u) { u <- tolower(trimws(u)); u <- sub("^https?://(www\\.)?", "", u); u <- sub("[?#].*$", "", u); sub("/+$", "", u) }
})
raw[, url_key := canon(URL)]
raw[is.na(url_key) | url_key == "", url_key := paste0("nourl:", seq_len(.N))]
setorder(raw, t)
n_before <- nrow(raw)
items <- raw[!duplicated(url_key)]
n_dupe <- n_before - nrow(items)

# ---------------------------------------------------------------------------------------------
# 4. Story clock, text, which fire
# ---------------------------------------------------------------------------------------------
items[, h := hours_since(t)]
items[, hb := hour_bin(h, 1)]
items[, day := as.Date(format(t, "%Y-%m-%d", tz = TZ))]
items[, platform := tolower(trimws(SOURCE_TYPE))]

items[, text_lc := stri_trans_tolower(paste(fifelse(is.na(TITLE), "", TITLE), substr(fifelse(is.na(FULL_TEXT), fifelse(is.na(MENTION_SNIPPET), "", MENTION_SNIPPET), FULL_TEXT), 1, 3000)))]
items[, text_fd := fold(text_lc)]
items[, title_lc := stri_trans_tolower(fifelse(is.na(TITLE), "", TITLE))]

# Which fire an item is ABOUT is decided by the title first, then the lead (first 300 characters),
# then the whole text — a Pelješac article that mentions Omiš in passing must not become an Omiš item.
tag_fire <- function(lc, fd) {
  out <- rep(NA_character_, length(lc))
  for (nm in names(FIRE_TAGS)) { hit <- is.na(out) & rx_hit(lc, fd, FIRE_TAGS[[nm]]); out[hit] <- nm }
  out
}
items[, lead_lc := substr(text_lc, 1, 300)][, lead_fd := fold(lead_lc)]
items[, fire := tag_fire(title_lc, fold(title_lc))]
items[is.na(fire), fire := tag_fire(lead_lc, lead_fd)]
items[is.na(fire), fire := tag_fire(text_lc, text_fd)]
items[is.na(fire), fire := "neodređeno"]
items[, about_omis := fire == "omis"]

# ---------------------------------------------------------------------------------------------
# 5. Outlet typology and geographic ring
# ---------------------------------------------------------------------------------------------
items[, from_lc := stri_trans_tolower(trimws(FROM))]
items[, from_fd := fold(from_lc)]
items[, loc := toupper(fifelse(is.na(LOCATIONS), "", LOCATIONS))]
items[, lang := tolower(fifelse(is.na(LANGUAGES), "", LANGUAGES))]
items[, has_hr := grepl("\\bHR\\b", loc) | grepl("\\bhr\\b", lang)]

items[, outlet_type := fcase(
  rx_hit(from_lc, from_fd, OFFICIAL_RX), "sluzbeni",
  platform %in% SOCIAL_PLATFORMS, "drustveni",
  rx_hit(from_lc, from_fd, FOREIGN_NAME_RX) | grepl(FOREIGN_TLD_RX, from_lc) | (!has_hr & nzchar(loc)), "strani",
  rx_hit(from_lc, from_fd, LOCAL_DALMATIA_RX), "lokalni",
  rx_hit(from_lc, from_fd, NATIONAL_RX), "nacionalni",
  default = "ostali_web"
)]
# social accounts of foreign media are still foreign for the ring, and official social pages count as official
items[platform %in% SOCIAL_PLATFORMS & rx_hit(from_lc, from_fd, OFFICIAL_RX), outlet_type := "sluzbeni"]
items[, foreign_any := outlet_type == "strani" | (!has_hr & nzchar(loc))]
items[, region := grepl(paste0("\\b(", paste(REGION_CC, collapse = "|"), ")\\b"), loc) | grepl("\\.(rs|ba|si|me|mk)$", from_lc) |
          rx_hit(from_lc, from_fd, "klix|avaz|oslobodjenje|nezavisne|blic|kurir|telegraf|b92|rts\\.rs|n1info\\.(rs|ba)|sputnik|rtvslo|24ur|delo\\.si|siol|dnevnik\\.si|vecer\\.com|nova\\.rs|vijesti\\.me|cdm\\.me|rtcg|hercegovina\\.info|bljesak|dnevnik\\.ba|federalna|radiosarajevo|fokus\\.ba|vecernji\\.ba|jabuka|hms\\.ba|poskok|tacno")]
items[, ring := fcase(
  outlet_type == "sluzbeni", 0L,
  outlet_type == "lokalni", 1L,
  foreign_any & region, 3L,
  foreign_any & !region, 4L,
  default = 2L
)]
items[, outlet_type_hr := OUTLET_TYPES[outlet_type]]
items[, outlet_type_en := OUTLET_TYPES_EN[outlet_type]]

# ---------------------------------------------------------------------------------------------
# 6. Frames, temperature, unified attention
# ---------------------------------------------------------------------------------------------
for (nm in names(FRAMES)) items[, (paste0("f_", nm)) := rx_hit(text_lc, text_fd, FRAMES[[nm]]$rx)]
fcols <- paste0("f_", names(FRAMES))
items[, n_frames := rowSums(.SD), .SDcols = fcols]
items[, sensational := rx_hit(title_lc, fold(title_lc), SENSATIONAL_RX)]   # judged on the TITLE only — that is what a reader sees first
items[, sensational_text := rx_hit(text_lc, text_fd, SENSATIONAL_RX)]

sum0 <- function(...) { m <- cbind(...); m[is.na(m)] <- 0; rowSums(m) }
items[, interactions := fcase(
  !is.na(INTERACTIONS), INTERACTIONS,
  platform == "facebook", sum0(LIKE_COUNT, COMMENT_COUNT, SHARE_COUNT, TOTAL_REACTIONS_COUNT * 0),
  platform == "twitter", sum0(RETWEET_COUNT, FAVORITE_COUNT, REPOST_COUNT),
  platform == "youtube", sum0(LIKE_COUNT, COMMENT_COUNT),
  platform == "reddit", sum0(REDDIT_SCORE, COMMENT_COUNT),
  platform == "instagram", sum0(LIKE_COUNT, COMMENT_COUNT),
  platform == "tiktok", sum0(LIKE_COUNT, COMMENT_COUNT, SHARE_COUNT),
  default = 0
)]
items[is.na(interactions), interactions := 0]
items[, views := fifelse(is.na(VIEW_COUNT), 0, VIEW_COUNT)]
items[, reach := fifelse(is.na(REACH), NA_real_, REACH)]
items[, has_interaction := interactions > 0]

# ---------------------------------------------------------------------------------------------
# 7. Echo: identical headlines across outlets (agency copy and copy-paste), and explicit Hina credits
# ---------------------------------------------------------------------------------------------
items[, title_key := gsub("\\s+", " ", gsub("[^a-z0-9 ]", " ", fold(title_lc)))]
items[, title_key := trimws(title_key)]
items[title_key == "", title_key := paste0("notitle:", seq_len(.N))]
web_like <- items[, platform == "web"]
ck <- items[web_like & about_omis, .(cluster_n = .N, cluster_sources = uniqueN(from_lc), cluster_first = min(t)), by = title_key]
items <- merge(items, ck, by = "title_key", all.x = TRUE, sort = FALSE)
items[is.na(cluster_n), `:=`(cluster_n = 1L, cluster_sources = 1L)]
items[, echo := cluster_sources >= 3L]
items[, hina := rx_hit(text_lc, text_fd, "\\(hina\\)|\\bhina\\b|izvor: hina|piše hina|prenosi hina")]
items[, cluster_rank := frank(-h, ties.method = "first"), by = title_key]                       # 1 = last, we want first
items[, is_cluster_first := is.na(cluster_first) | t == cluster_first]

setorder(items, t)
items[, item_id := seq_len(.N)]

# ---------------------------------------------------------------------------------------------
# 8. Write and report
# ---------------------------------------------------------------------------------------------
keep <- c("item_id","t","h","hb","day","platform","FROM","from_lc","AUTHOR","URL","url_key","TITLE","title_key",
          "outlet_type","outlet_type_hr","outlet_type_en","ring","foreign_any","region","loc","lang",
          "fire","about_omis", fcols, "n_frames","sensational","sensational_text",
          "interactions","views","reach","has_interaction","AUTO_SENTIMENT",
          "cluster_n","cluster_sources","cluster_first","is_cluster_first","echo","hina",
          "GROUP_NAME","KEYWORD_NAME",".source_file","text_lc")
saveRDS(items[, ..keep], file.path(OUT_DIR, "items.rds"))
fwrite(items[, .(t = format(t, "%Y-%m-%d %H:%M", tz = TZ), h = round(h, 2), platform, FROM, outlet_type, ring, fire,
                 sensational, interactions, echo, hina, cluster_sources, TITLE, URL)],
       file.path(PRIV_DIR, "items_titles.csv"), bom = TRUE)

uncl <- items[outlet_type == "ostali_web", .N, by = FROM][order(-N)][1:min(.N, 25)]
qa <- list(
  synthetic = SYNTH,
  files = unique(raw$.source_file),
  rows_read = n_raw, rows_no_date_dropped = n_no_date, rows_time_missing_set_noon = n_no_time,
  rows_duplicate_url_dropped = n_dupe, rows_kept = nrow(items),
  span = list(first = format(min(items$t), "%Y-%m-%d %H:%M", tz = TZ), last = format(max(items$t), "%Y-%m-%d %H:%M", tz = TZ),
              story_hour_first = round(min(items$h), 2), story_hour_last = round(max(items$h), 2)),
  before_ignition = sum(items$h < 0),
  fire = as.list(items[, .N, by = fire][order(-N)][, setNames(N, fire)]),
  platform = as.list(items[, .N, by = platform][order(-N)][, setNames(N, platform)]),
  outlet_type = as.list(items[, .N, by = outlet_type][order(-N)][, setNames(N, outlet_type)]),
  ring = as.list(items[, .N, by = ring][order(ring)][, setNames(N, paste0("ring_", ring))]),
  frames_any = as.list(items[, lapply(.SD, sum), .SDcols = fcols]),
  no_frame_share = round(100 * mean(items$n_frames == 0), 1),
  sensational_title_share = round(100 * mean(items$sensational), 1),
  echo_share_web_omis = round(100 * items[platform == "web" & about_omis, mean(echo)], 1),
  hina_share = round(100 * mean(items$hina), 1),
  zero_interaction_share_by_platform = as.list(items[, .(z = round(100 * mean(!has_interaction), 1)), by = platform][, setNames(z, platform)]),
  largest_unclassified_web_sources = as.list(setNames(uncl$N, uncl$FROM))
)
write_json(qa, file.path(AGG_DIR, "qa.json"), auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\nKept %s items (dropped %s duplicate URLs, %s without a date; %s had no clock time and were set to noon)\n",
            fmt_hr(nrow(items)), fmt_hr(n_dupe), fmt_hr(n_no_date), fmt_hr(n_no_time)))
cat(sprintf("Span %s -> %s  (story hours %.1f -> %.1f); %d items before ignition\n", qa$span$first, qa$span$last, min(items$h), max(items$h), qa$before_ignition))
cat("\nWhich fire:\n"); print(items[, .N, by = fire][order(-N)])
cat("\nOutlet type x platform:\n"); print(dcast(items[, .N, by = .(outlet_type, platform)], outlet_type ~ platform, value.var = "N", fill = 0))
cat(sprintf("\nFrames: %s items (%.1f%%) carry no frame; sensational titles %.1f%%; echo (same headline on >=3 web outlets) %.1f%% of Omiš web items; Hina credited %.1f%%\n",
            fmt_hr(sum(items$n_frames == 0)), qa$no_frame_share, qa$sensational_title_share, qa$echo_share_web_omis, qa$hina_share))
cat("\nLargest sources left in 'ostali_web' (check whether any is local/national/foreign and add it to lib.R):\n"); print(uncl)
if (SYNTH) cat("\n>>> ", SYNTH_TAG_EN, " <<<\n")
