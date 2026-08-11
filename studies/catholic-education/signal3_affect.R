#!/usr/bin/env Rscript
# Stage-A SECOND PASS (part 2 of 2): AFFECTIVE CHARGE (signal #3), sample-first via udpipe + the project
# sentiment/emotion lexicons. Answers: is the Stepinac memory anchor affectively CHARGED (non-neutral, and
# in which register) vs the present-tense institutions? Reuses diskurs.qmd's canonical lexicon loading + the
# lemma-keyed join (MEMORY.md: match on the SAME normalization both sides or coverage collapses).
# Reads slice READ-ONLY; writes output/ only. NB: lexicons key on LEMMAS -> udpipe lemmatize, lowercase both sides.
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr); library(tidyr)
                                 library(readxl); library(udpipe); library(ggplot2) })
source(here::here("studies/catholic-education/study_input.R"), encoding = "UTF-8")
set.seed(20260706)

out_dir <- here::here("studies/catholic-education/output")
tab_dir <- file.path(out_dir, "tables"); fig_dir <- file.path(out_dir, "figures")
theme_ok <- tryCatch({ source(here::here("R/theme_digikat.R")); TRUE }, error = function(e) FALSE)
if (!theme_ok) theme_set(theme_minimal(base_size = 12))

# ---- lexicons (canonical logic from pages/mapa/diskurs.qmd, paths from repo root) ------------
lx <- here::here("resources/lexicons"); dx <- here::here("resources/dictionaries")
crosentilex_full <- bind_rows(
  read.delim(file.path(lx, "crosentilex-negatives.txt"), header = FALSE, sep = " ",
             stringsAsFactors = FALSE, fileEncoding = "UTF-8") |> rename(word = V1, sentiment_value = V2) |>
    mutate(sentiment_value = -sentiment_value),
  read.delim(file.path(lx, "crosentilex-positives.txt"), header = FALSE, sep = " ",
             stringsAsFactors = FALSE, fileEncoding = "UTF-8") |> rename(word = V1, sentiment_value = V2)
) |> mutate(word = str_to_lower(word, locale = "hr")) |> distinct(word, .keep_all = TRUE) |> as_tibble()

emotion_hr <- c(Anger = "Ljutnja", Anticipation = "Iščekivanje", Disgust = "Gađenje", Fear = "Strah",
                Joy = "Radost", Sadness = "Tuga", Surprise = "Iznenađenje", Trust = "Povjerenje")
nrc_raw  <- read_excel(file.path(dx, "lilaHR_clean.xlsx"), sheet = "Sheet1", .name_repair = "unique_quiet")
if ("...1" %in% names(nrc_raw)) nrc_raw <- nrc_raw |> select(-"...1")
nrc_long <- nrc_raw |> rename(word = HR) |>
  pivot_longer(cols = all_of(names(emotion_hr)), names_to = "emotion", values_to = "value") |>
  filter(value == 1) |> mutate(word = str_to_lower(word, locale = "hr"), emotion = recode(emotion, !!!emotion_hr)) |>
  select(word, emotion) |> distinct()
cat("lexicons: crosentilex", nrow(crosentilex_full), "words | lilaHR", n_distinct(nrc_long$word), "words x 8 emotions\n")

# ---- sample-first: cap each entity, union, truncate for udpipe speed ------------------------
slice <- readRDS(file.path(out_dir, "slice.rds"))
catholic_education_assert_slice_current(slice)
slice$doc_id <- paste0("d", seq_len(nrow(slice)))
KEY <- c("stepinac", "vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "redovi_orders", "rituali", "strossmayer")
CAP <- 800L
idx <- unique(unlist(lapply(KEY, function(e) {
  w <- which(slice[[paste0("probe_", e)]] %in% TRUE)
  if (length(w) > CAP) sample(w, CAP) else w
})))
samp <- slice[idx, ]
samp$txt <- substr(samp$FULL_TEXT, 1, 1500)               # lead is representative for sentiment; bounds udpipe cost
cat("affect sample:", nrow(samp), "unique posts (cap", CAP, "/entity)\n")

# ---- udpipe lemmatize ------------------------------------------------------------------------
model <- udpipe_load_model(here::here("resources/models/croatian-set-ud-2.5-191206.udpipe"))
ann <- as.data.frame(udpipe_annotate(model, x = samp$txt, doc_id = samp$doc_id))
ann$lemma <- str_to_lower(ann$lemma, locale = "hr")
tok <- ann |> filter(!is.na(lemma), lemma != "", upos != "PUNCT")
cat("tokens:", nrow(tok), "| unique lemmas:", n_distinct(tok$lemma), "\n")

# ---- per-doc polarity (CroSentilex) + coverage ----------------------------------------------
pol <- tok |> left_join(crosentilex_full, by = c("lemma" = "word"))
doc_pol <- pol |> group_by(doc_id) |>
  summarise(n_tok = n(), n_match = sum(!is.na(sentiment_value)),
            mean_sent = if (any(!is.na(sentiment_value))) mean(sentiment_value, na.rm = TRUE) else NA_real_,
            nonneutral = if (any(!is.na(sentiment_value))) mean(abs(sentiment_value) > 0, na.rm = TRUE) else NA_real_,
            .groups = "drop")
coverage <- sum(doc_pol$n_match) / sum(doc_pol$n_tok)
doc_coverage <- mean(doc_pol$n_match > 0)
cat(sprintf("CroSentilex coverage: %.1f%% of tokens | %.1f%% of documents\n",
            100 * coverage, 100 * doc_coverage))

# ---- per-doc emotions (lilaHR) --------------------------------------------------------------
emo <- tok |> inner_join(nrc_long, by = c("lemma" = "word"), relationship = "many-to-many") |>
  group_by(doc_id, emotion) |> summarise(k = n(), .groups = "drop") |>
  group_by(doc_id) |> mutate(share = k / sum(k)) |> ungroup()
emo_wide <- emo |> select(doc_id, emotion, share) |> pivot_wider(names_from = emotion, values_from = share, values_fill = 0)

# ---- aggregate per entity -------------------------------------------------------------------
affect <- do.call(rbind, lapply(KEY, function(e) {
  docs <- samp$doc_id[samp[[paste0("probe_", e)]] %in% TRUE]
  dp <- doc_pol[doc_pol$doc_id %in% docs, ]
  em <- emo_wide[emo_wide$doc_id %in% docs, setdiff(names(emo_wide), "doc_id"), drop = FALSE]
  n_emo <- nrow(em)
  data.frame(entity = e, n_sampled = length(docs),
             polarity_docs = sum(dp$n_match > 0),
             polarity_doc_coverage = round(mean(dp$n_match > 0), 3),
             polarity_token_coverage = round(sum(dp$n_match) / sum(dp$n_tok), 3),
             emotion_docs = n_emo,
             emotion_doc_coverage = round(n_emo / length(docs), 3),
             mean_sentiment = round(mean(dp$mean_sent, na.rm = TRUE), 3),
             nonneutral_share = round(mean(dp$nonneutral, na.rm = TRUE), 3),
             as.list(round(colMeans(em, na.rm = TRUE), 3)), check.names = FALSE, stringsAsFactors = FALSE)
}))
write.csv(affect, file.path(tab_dir, "affect_by_entity.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(
  data.frame(
    metric = c("unique_posts", "token_count", "unique_lemmas", "crosentilex_token_coverage",
               "crosentilex_document_coverage", "emotion_document_coverage"),
    value = c(nrow(samp), nrow(tok), n_distinct(tok$lemma), coverage, doc_coverage,
              mean(samp$doc_id %in% unique(emo$doc_id)))
  ),
  file.path(tab_dir, "affect_run_metrics.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
cat("\n-- affect per entity (mean polarity, non-neutral share, 8-emotion profile) --\n")
print(affect, row.names = FALSE)

# emotion-profile figure (Stepinac vs institutions)
emo_long <- affect |> select(entity, all_of(unname(emotion_hr))) |>
  pivot_longer(-entity, names_to = "emocija", values_to = "share")
p <- ggplot(emo_long, aes(x = emocija, y = share, fill = entity)) +
  geom_col(position = "dodge") +
  labs(title = "Emocionalni profil po entitetu (lilaHR, 8 emocija)",
       subtitle = sprintf("Uzorak %d objava; pokrivenost CroSentilexa %.0f%%. Indikativno, nije ručno validirano.",
                           nrow(samp), 100 * coverage),
       x = NULL, y = "prosječni udio emocije", fill = NULL) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
ggsave(file.path(fig_dir, "affect_emotion_profile.png"), p, width = 11, height = 6, dpi = 150)
cat("\nsignal3_affect.R done — affect_by_entity.csv + affect_emotion_profile.png. Coverage:",
    sprintf("%.1f%%", 100 * coverage), "\n")
