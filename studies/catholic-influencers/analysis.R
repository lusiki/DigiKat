options(stringsAsFactors = FALSE, encoding = "UTF-8")

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(file_arg) != 1L) stop("Run this file with Rscript.", call. = FALSE)
study_dir <- normalizePath(dirname(file_arg), winslash = "/", mustWork = TRUE)
project_root <- normalizePath(file.path(study_dir, "../.."), winslash = "/", mustWork = TRUE)
source(file.path(project_root, "R/lib/digikat_paths.R"), encoding = "UTF-8")
source(file.path(study_dir, "actor_classification.R"), encoding = "UTF-8")

out_dir <- file.path(study_dir, "output")
table_dir <- file.path(out_dir, "tables")
figure_dir <- file.path(out_dir, "figures")
private_dir <- file.path(out_dir, "private")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)

write_csv_utf8 <- function(x, path) fwrite(x, path, bom = TRUE, na = "")
named_rows <- function(dt, key, value) setNames(as.list(dt[[value]]), dt[[key]])

gini_coefficient <- function(x) {
  x <- sort(as.numeric(x[is.finite(x) & x >= 0]))
  if (!length(x) || sum(x) == 0) return(NA_real_)
  n <- length(x)
  sum((2 * seq_len(n) - n - 1) * x) / (n * sum(x))
}

js_divergence <- function(p, q) {
  p <- as.numeric(p) / sum(p)
  q <- as.numeric(q) / sum(q)
  middle <- (p + q) / 2
  kl <- function(a, b) sum(ifelse(a > 0, a * log2(a / b), 0))
  (kl(p, middle) + kl(q, middle)) / 2
}

cramers_v <- function(tab) {
  test <- suppressWarnings(chisq.test(tab, correct = FALSE))
  sqrt(unname(test$statistic) / (sum(tab) * (min(dim(tab)) - 1)))
}

hc3_vcov <- function(model) {
  x <- model.matrix(model)
  residual <- residuals(model)
  leverage <- hatvalues(model)
  bread <- solve(crossprod(x))
  weight <- as.numeric((residual / (1 - leverage))^2)
  bread %*% crossprod(x, x * weight) %*% bread
}

robust_coefficient <- function(model, term) {
  vcov_matrix <- hc3_vcov(model)
  estimate <- unname(coef(model)[term])
  standard_error <- unname(sqrt(diag(vcov_matrix))[term])
  statistic <- estimate / standard_error
  degrees_freedom <- df.residual(model)
  critical <- qt(.975, degrees_freedom)
  data.table(
    term = term,
    estimate = estimate,
    std_error = standard_error,
    statistic = statistic,
    p = 2 * pt(abs(statistic), df = degrees_freedom, lower.tail = FALSE),
    ci_low = estimate - critical * standard_error,
    ci_high = estimate + critical * standard_error
  )
}

bootstrap_two_group <- function(dt, value, statistic, reps = 2000L, seed = 20260812L) {
  x <- dt[actor_group == "Influencer", get(value)]
  y <- dt[actor_group == "Institutional", get(value)]
  set.seed(seed)
  draws <- replicate(reps, statistic(sample(x, length(x), replace = TRUE)) -
                       statistic(sample(y, length(y), replace = TRUE)))
  unname(quantile(draws, c(.025, .975), na.rm = TRUE))
}

percent_labeller <- scales::label_percent(
  accuracy = 1,
  decimal.mark = ",",
  suffix = " %"
)
number_labeller <- scales::label_number(big.mark = ".", decimal.mark = ",")
colour_creator <- "#d96b2b"
colour_institution <- "#183b57"

old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)
corpus_path <- normalizePath(digikat_corpus_path(), winslash = "/", mustWork = TRUE)
manifest_path <- normalizePath(digikat_corpus_manifest_path(), winslash = "/", mustWork = TRUE)
corpus_manifest <- jsonlite::fromJSON(manifest_path, simplifyVector = TRUE)
actual_sha <- digest::digest(file = corpus_path, algo = "sha256", serialize = FALSE)
stopifnot(identical(actual_sha, corpus_manifest$corpus$sha256))

message("Reading official corpus: ", corpus_path)
dta <- as.data.table(readRDS(corpus_path))
stopifnot(nrow(dta) == corpus_manifest$corpus$rows)
official_sources <- uniqueN(dta$FROM)
required <- c("DATE", "FROM", "URL", "SOURCE_TYPE", "FULL_TEXT", "INTERACTIONS")
if (length(missing <- setdiff(required, names(dta)))) {
  stop("Missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
}
dta[, DATE := as.IDate(DATE)]
if (anyNA(dta$DATE)) stop("DATE conversion introduced missing values.", call. = FALSE)

# TikTok remains outside the study because the inherited classifier never covered it. No row is
# removed from the official corpus; this is a study-local analytical exclusion.
excluded_tiktok <- dta[SOURCE_TYPE == "tiktok", .N]
dta <- dta[!is.na(SOURCE_TYPE) & SOURCE_TYPE != "tiktok"]
dta[, `:=`(
  interaction_observed = is.finite(INTERACTIONS) & INTERACTIONS >= 0,
  collection_year = as.integer(format(DATE, "%Y"))
)]

# Classify one source label once, then propagate the result across its observed platforms.
social_platforms <- c("facebook", "instagram", "youtube", "twitter")
source_index <- dta[, .(
  url_context = paste(head(unique(na.omit(URL)), 5), collapse = " "),
  has_social = any(SOURCE_TYPE %in% social_platforms)
), by = FROM]
classified <- lapply(seq_len(nrow(source_index)), function(i) {
  classify_actor_source(source_index$FROM[i], source_index$url_context[i], source_index$has_social[i])
})
source_index[, `:=`(
  ACTOR_TYPE = vapply(classified, `[[`, character(1), "actor_type"),
  classification_rule = vapply(classified, `[[`, character(1), "rule"),
  classification_confidence = vapply(classified, `[[`, character(1), "confidence")
)]
source_index[, Actor_Group := fifelse(
  ACTOR_TYPE %in% c("Lay Influencers", "Individual Priests", "Charismatic Communities"),
  "Influencer",
  fifelse(ACTOR_TYPE %in% c("Institutional Official", "Diocesan", "Academic"),
          "Institutional", NA_character_)
)]
source_index[, high_confidence := classification_confidence == "high"]
dta[source_index, on = "FROM", `:=`(
  ACTOR_TYPE = i.ACTOR_TYPE,
  Actor_Group = i.Actor_Group,
  classification_rule = i.classification_rule,
  classification_confidence = i.classification_confidence,
  high_confidence = i.high_confidence
)]

# Public audit tables show only aggregates. Identifiers remain in the ignored private directory.
actor_counts <- dta[, .(
  sources = uniqueN(FROM),
  posts = .N,
  posts_with_recorded_interactions = sum(interaction_observed),
  total_recorded_interactions = sum(INTERACTIONS[interaction_observed])
), by = .(ACTOR_TYPE, Actor_Group, classification_confidence)][order(-posts)]
rule_counts <- source_index[, .(sources = .N),
  by = .(ACTOR_TYPE, Actor_Group, classification_rule, classification_confidence)][order(-sources)]
coverage <- dta[, .(
  posts = .N,
  recorded = sum(interaction_observed),
  recorded_pct = mean(interaction_observed)
), by = .(Actor_Group, high_confidence, SOURCE_TYPE)][order(Actor_Group, -posts)]
write_csv_utf8(actor_counts, file.path(table_dir, "actor_counts.csv"))
write_csv_utf8(rule_counts, file.path(table_dir, "classification_rule_counts.csv"))
write_csv_utf8(coverage, file.path(table_dir, "interaction_coverage.csv"))

private_audit <- dta[, .(
  actor_type = first(ACTOR_TYPE),
  actor_group = first(Actor_Group),
  classification_rule = first(classification_rule),
  confidence = first(classification_confidence),
  posts = .N,
  posts_with_recorded_interactions = sum(interaction_observed),
  total_recorded_interactions = sum(INTERACTIONS[interaction_observed])
), by = FROM][order(actor_group, -posts)]
write_csv_utf8(private_audit, file.path(private_dir, "source_classification_audit.csv"))

primary_posts <- dta[!is.na(Actor_Group) & high_confidence]
broad_posts <- dta[!is.na(Actor_Group)]
primary_source_counts <- primary_posts[, .(sources = uniqueN(FROM), posts = .N), by = Actor_Group]
sample_flow <- data.table(
  stage = c(
    "Službeni DigiKat korpus",
    "Studijski obuhvat nakon isključenja TikToka",
    "Svi klasificirani izvori, široki skup osjetljivosti",
    "Primarni skup visoke pouzdanosti",
    "Primarni skup s opaženim interakcijama"
  ),
  posts = c(
    corpus_manifest$corpus$rows,
    nrow(dta),
    nrow(broad_posts),
    nrow(primary_posts),
    primary_posts[interaction_observed == TRUE, .N]
  ),
  sources = c(
    official_sources,
    uniqueN(dta$FROM),
    uniqueN(broad_posts$FROM),
    uniqueN(primary_posts$FROM),
    primary_posts[interaction_observed == TRUE, uniqueN(FROM)]
  )
)
write_csv_utf8(sample_flow, file.path(table_dir, "analysis_sample_flow.csv"))

# H1. Concentration among high-confidence creator-layer source labels.
inf_posts <- primary_posts[Actor_Group == "Influencer" & interaction_observed]
inf_sources <- inf_posts[, .(
  posts = .N,
  total_interactions = sum(INTERACTIONS),
  mean_interactions = mean(INTERACTIONS),
  actor_type = first(ACTOR_TYPE)
), by = FROM][posts > 0]
setorder(inf_sources, -total_interactions, FROM)
inf_sources[, rank := seq_len(.N)]
total_inf_interactions <- sum(inf_sources$total_interactions)
gini_primary <- gini_coefficient(inf_sources$total_interactions)
cr10_primary <- sum(head(inf_sources$total_interactions, 10)) / total_inf_interactions
cr_top10pct_primary <- sum(head(inf_sources$total_interactions, ceiling(.1 * nrow(inf_sources)))) /
  total_inf_interactions
rank_positive <- inf_sources[total_interactions > 0]
rank_model <- lm(log(total_interactions) ~ log(rank), data = rank_positive)

set.seed(20260812)
gini_boot <- replicate(2000, {
  gini_coefficient(sample(inf_sources$total_interactions, nrow(inf_sources), replace = TRUE))
})
gini_ci <- unname(quantile(gini_boot, c(.025, .975), na.rm = TRUE))

broad_inf_sources <- broad_posts[Actor_Group == "Influencer" & interaction_observed, .(
  total_interactions = sum(INTERACTIONS)
), by = FROM]
gini_broad <- gini_coefficient(broad_inf_sources$total_interactions)

lorenz <- copy(inf_sources)
setorder(lorenz, total_interactions, FROM)
lorenz[, `:=`(
  source_share = seq_len(.N) / .N,
  attention_share = cumsum(total_interactions) / sum(total_interactions)
)]
lorenz <- rbind(data.table(source_share = 0, attention_share = 0),
                lorenz[, .(source_share, attention_share)])
write_csv_utf8(lorenz, file.path(table_dir, "h1_lorenz.csv"))
write_csv_utf8(inf_sources[, .(rank, posts, total_interactions, mean_interactions, actor_type)],
               file.path(table_dir, "h1_source_distribution.csv"))

p_lorenz <- ggplot(lorenz, aes(source_share, attention_share)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey55") +
  geom_ribbon(aes(ymin = attention_share, ymax = source_share),
              fill = colour_creator, alpha = .20) +
  geom_line(colour = colour_creator, linewidth = 1.05) +
  coord_equal() +
  scale_x_continuous(labels = percent_labeller, limits = c(0, 1)) +
  scale_y_continuous(labels = percent_labeller, limits = c(0, 1)) +
  labs(x = "Kumulativni udio izvora", y = "Kumulativni udio zabilježenih interakcija") +
  theme_minimal(base_size = 12)
ggsave(file.path(figure_dir, "h1_lorenz.png"), p_lorenz, width = 7, height = 6, dpi = 220)

p_rank <- ggplot(rank_positive, aes(rank, total_interactions)) +
  geom_point(alpha = .62, colour = colour_creator) +
  geom_smooth(method = "lm", se = FALSE, colour = colour_institution, linewidth = .8) +
  scale_x_log10() +
  scale_y_log10(labels = number_labeller) +
  labs(x = "Rang izvora, logaritamska skala",
       y = "Ukupne zabilježene interakcije, logaritamska skala") +
  theme_minimal(base_size = 12)
ggsave(file.path(figure_dir, "h1_rank_size.png"), p_rank, width = 7, height = 5, dpi = 220)

# H2. Source-level interactions per recorded post. The high-confidence set is primary.
source_engagement <- dta[!is.na(Actor_Group) & interaction_observed, .(
  posts = .N,
  total_interactions = sum(INTERACTIONS),
  mean_interactions = mean(INTERACTIONS),
  actor_group = first(Actor_Group),
  actor_type = first(ACTOR_TYPE),
  confidence = first(classification_confidence),
  mean_collection_year = mean(as.numeric(DATE)) / 365.25,
  share_facebook = mean(SOURCE_TYPE == "facebook"),
  share_youtube = mean(SOURCE_TYPE == "youtube"),
  share_twitter = mean(SOURCE_TYPE == "twitter"),
  share_web = mean(SOURCE_TYPE == "web")
), by = FROM]

primary_engagement <- source_engagement[confidence == "high"]
eligible_engagement <- primary_engagement[posts >= 5]
eng_summary <- eligible_engagement[, .(
  sources = .N,
  posts = sum(posts),
  median = median(mean_interactions),
  mean = mean(mean_interactions),
  q1 = quantile(mean_interactions, .25),
  q3 = quantile(mean_interactions, .75)
), by = actor_group]

x_inf <- eligible_engagement[actor_group == "Influencer", mean_interactions]
x_inst <- eligible_engagement[actor_group == "Institutional", mean_interactions]
wilcox_h2 <- wilcox.test(x_inf, x_inst, alternative = "two.sided", exact = FALSE)
rank_biserial <- 2 * unname(wilcox_h2$statistic) / (length(x_inf) * length(x_inst)) - 1
median_diff_ci <- bootstrap_two_group(eligible_engagement, "mean_interactions", median)

# A within-platform comparison supplies common support that a pooled platform adjustment cannot.
youtube_source_pool <- primary_posts[
  interaction_observed & SOURCE_TYPE == "youtube",
  .(
    posts = .N,
    mean_interactions = mean(INTERACTIONS),
    mean_collection_year = mean(as.numeric(DATE)) / 365.25,
    actor_group = first(Actor_Group)
  ),
  by = FROM
]
youtube_sources <- youtube_source_pool[posts >= 5]
youtube_sources[, actor_group := factor(actor_group, levels = c("Institutional", "Influencer"))]
h2_youtube_model <- lm(
  log1p(mean_interactions) ~ actor_group + log(posts) + mean_collection_year,
  data = youtube_sources
)
h2_youtube_group <- robust_coefficient(h2_youtube_model, "actor_groupInfluencer")
h2_youtube_group[, ratio := exp(estimate)]

h2_youtube_sensitivity <- rbindlist(lapply(c(1L, 5L, 10L, 20L), function(min_posts) {
  tmp <- copy(youtube_source_pool[posts >= min_posts])
  tmp[, actor_group := factor(actor_group, levels = c("Institutional", "Influencer"))]
  fit <- lm(log1p(mean_interactions) ~ actor_group + log(posts) + mean_collection_year, data = tmp)
  row <- robust_coefficient(fit, "actor_groupInfluencer")
  row[, `:=`(
    min_posts = min_posts,
    influencer_sources = sum(tmp$actor_group == "Influencer"),
    institutional_sources = sum(tmp$actor_group == "Institutional"),
    ratio = exp(estimate)
  )]
  row
}))

h2_robustness <- rbindlist(lapply(list(
  list(label = "Primarni skup, najmanje 1 objava", data = primary_engagement),
  list(label = "Primarni skup, najmanje 5 objava", data = eligible_engagement),
  list(label = "Široki skup, najmanje 1 objava", data = source_engagement),
  list(label = "Široki skup, najmanje 5 objava", data = source_engagement[posts >= 5])
), function(spec) {
  tmp <- copy(spec$data)
  tmp[, actor_group := factor(actor_group, levels = c("Institutional", "Influencer"))]
  fit <- lm(log1p(mean_interactions) ~ actor_group + log(posts), data = tmp)
  coef_row <- robust_coefficient(fit, "actor_groupInfluencer")
  coef_row[, `:=`(
    specification = spec$label,
    influencer_sources = sum(tmp$actor_group == "Influencer"),
    institutional_sources = sum(tmp$actor_group == "Institutional"),
    ratio = exp(estimate)
  )]
  coef_row
}), fill = TRUE)

write_csv_utf8(eng_summary, file.path(table_dir, "h2_group_summary.csv"))
write_csv_utf8(h2_youtube_group, file.path(table_dir, "h2_youtube_model.csv"))
write_csv_utf8(h2_youtube_sensitivity, file.path(table_dir, "h2_youtube_threshold_sensitivity.csv"))
write_csv_utf8(h2_robustness, file.path(table_dir, "h2_robustness.csv"))

p_h2 <- ggplot(eligible_engagement,
               aes(factor(actor_group, levels = c("Institutional", "Influencer")),
                   mean_interactions, fill = actor_group)) +
  geom_violin(scale = "width", trim = TRUE, alpha = .45, colour = NA) +
  geom_boxplot(width = .17, outlier.shape = NA, fill = "white", linewidth = .45) +
  geom_jitter(width = .10, alpha = .48, size = 1.2) +
  scale_y_continuous(trans = scales::pseudo_log_trans(base = 10, sigma = 1),
                     labels = number_labeller) +
  scale_x_discrete(labels = c(Institutional = "Institucionalni izvori",
                              Influencer = "Kreatorski izvori")) +
  scale_fill_manual(values = c(Institutional = colour_institution, Influencer = colour_creator)) +
  labs(x = NULL, y = "Prosječne interakcije po zabilježenoj objavi") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
ggsave(file.path(figure_dir, "h2_interactions_per_post.png"), p_h2,
       width = 7, height = 5, dpi = 220)

# H3. Platform allocation in the high-confidence set, reported at post and source levels.
group_posts <- primary_posts[, .N, by = .(Actor_Group, SOURCE_TYPE)]
group_posts[, share := N / sum(N), by = Actor_Group]
post_tab <- table(primary_posts$Actor_Group, primary_posts$SOURCE_TYPE)
post_chi <- suppressWarnings(chisq.test(post_tab, correct = FALSE))
post_v <- cramers_v(post_tab)

presence <- unique(primary_posts[, .(FROM, Actor_Group, SOURCE_TYPE)])
presence_v <- cramers_v(table(presence$Actor_Group, presence$SOURCE_TYPE))
source_mix <- primary_posts[, .(
  social_share = mean(SOURCE_TYPE %in% social_platforms),
  web_share = mean(SOURCE_TYPE == "web")
), by = .(FROM, actor_group = Actor_Group)]
social_diff <- source_mix[actor_group == "Influencer", mean(social_share)] -
  source_mix[actor_group == "Institutional", mean(social_share)]
social_diff_ci <- bootstrap_two_group(source_mix, "social_share", mean)

social_share_inf <- group_posts[Actor_Group == "Influencer" & SOURCE_TYPE %in% social_platforms, sum(share)]
social_share_inst <- group_posts[Actor_Group == "Institutional" & SOURCE_TYPE %in% social_platforms, sum(share)]
web_share_inf <- group_posts[Actor_Group == "Influencer" & SOURCE_TYPE == "web", sum(share)]
web_share_inst <- group_posts[Actor_Group == "Institutional" & SOURCE_TYPE == "web", sum(share)]
write_csv_utf8(group_posts, file.path(table_dir, "h3_platform_distribution.csv"))
write_csv_utf8(source_mix[, .(
  sources = .N,
  mean_social_share = mean(social_share),
  median_social_share = median(social_share),
  mean_web_share = mean(web_share)
), by = actor_group], file.path(table_dir, "h3_source_weighted_platforms.csv"))

p_h3 <- ggplot(group_posts, aes(SOURCE_TYPE, share, fill = Actor_Group)) +
  geom_col(position = position_dodge(width = .78), width = .72) +
  scale_y_continuous(labels = percent_labeller, expand = expansion(mult = c(0, .07))) +
  scale_x_discrete(labels = c(
    facebook = "Facebook", instagram = "Instagram", twitter = "Twitter/X",
    web = "Web", youtube = "YouTube"
  )) +
  scale_fill_manual(
    values = c(Influencer = colour_creator, Institutional = colour_institution),
    labels = c(Influencer = "Kreatorski izvori", Institutional = "Institucionalni izvori")
  ) +
  labs(x = NULL, y = "Udio objava", fill = NULL) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1), legend.position = "top")
ggsave(file.path(figure_dir, "h3_platform_mix.png"), p_h3, width = 8, height = 5, dpi = 220)

# H4. Transparent multi-label dictionary. The source-cluster bootstrap preserves within-source posts.
theme_patterns <- list(
  Devocijski = "molitv|isus|gospa|marij|sveti|blagoslov|krunic",
  Liturgijski = "misa|sakrament|euharist|ispovijed|kršten|liturgij",
  Institucionalni = "biskupij|nadbiskup|papa|vatikan|sinod|dokument",
  Socijalni = "obitelj|mladi|odgoj|škola|karita|siromašn|pravd",
  Politički = "izbor|vlada|zakon|pobačaj|lgbt|rodn.*ideolog|gender",
  Zajednički = "zajednic|susret|hodočašć|proslav|blagdan"
)

theme_analysis <- function(posts) {
  theme_posts <- posts[!is.na(FULL_TEXT) & nzchar(FULL_TEXT),
                       .(FROM, actor_group = Actor_Group, text = tolower(FULL_TEXT))]
  theme_posts[, post_id := seq_len(.N)]
  hits <- rbindlist(lapply(names(theme_patterns), function(theme) {
    theme_posts[grepl(theme_patterns[[theme]], text, perl = TRUE),
                .(post_id, FROM, actor_group, theme)]
  }))
  source_counts <- hits[, .N, by = .(FROM, actor_group, theme)]
  dist <- source_counts[, .(N = sum(N)), by = .(actor_group, theme)]
  dist[, share := N / sum(N), by = actor_group]
  wide <- dcast(dist, theme ~ actor_group, value.var = "share", fill = 0)
  wide[, theme_order := match(theme, names(theme_patterns))]
  setorder(wide, theme_order)
  wide[, theme_order := NULL]
  wide[, difference := Influencer - Institutional]
  list(posts = theme_posts, hits = hits, source = source_counts, wide = wide,
       js = js_divergence(wide$Influencer, wide$Institutional))
}

theme_primary <- theme_analysis(primary_posts)
theme_broad <- theme_analysis(broad_posts)
sources_by_group <- split(
  unique(theme_primary$source[, .(FROM, actor_group)])$FROM,
  unique(theme_primary$source[, .(FROM, actor_group)])$actor_group
)

set.seed(20260812)
theme_boot <- rbindlist(lapply(seq_len(2000), function(iteration) {
  sampled <- rbindlist(lapply(names(sources_by_group), function(group) {
    ids <- sample(sources_by_group[[group]], length(sources_by_group[[group]]), replace = TRUE)
    weights <- as.data.table(table(ids))
    setnames(weights, c("FROM", "weight"))
    tmp <- theme_primary$source[actor_group == group][weights, on = "FROM", nomatch = 0]
    tmp[, .(N = sum(N * weight)), by = theme][, actor_group := group]
  }))
  wide <- dcast(sampled, theme ~ actor_group, value.var = "N", fill = 0)
  wide <- merge(data.table(theme = names(theme_patterns)), wide, by = "theme", all.x = TRUE)
  wide[is.na(wide)] <- 0
  wide[, `:=`(
    Influencer = Influencer / sum(Influencer),
    Institutional = Institutional / sum(Institutional)
  )]
  data.table(
    iteration = iteration,
    js = js_divergence(wide$Influencer, wide$Institutional),
    theme = wide$theme,
    difference = wide$Influencer - wide$Institutional
  )
}))
js_ci <- theme_boot[, unname(quantile(js, c(.025, .975))), by = iteration][
  , unname(quantile(V1, c(.025, .975)))]
theme_ci <- theme_boot[, .(
  ci_low = quantile(difference, .025),
  ci_high = quantile(difference, .975)
), by = theme]
theme_wide <- merge(theme_primary$wide, theme_ci, by = "theme", all.x = TRUE)
theme_wide[, theme_order := match(theme, names(theme_patterns))]
setorder(theme_wide, theme_order)
theme_wide[, theme_order := NULL]
write_csv_utf8(theme_wide, file.path(table_dir, "h4_theme_distribution.csv"))

p_h4 <- ggplot(theme_wide,
               aes(reorder(theme, difference), difference, fill = difference > 0)) +
  geom_hline(yintercept = 0, colour = "grey60", linewidth = .45) +
  geom_col(width = .68) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = .18, linewidth = .55) +
  coord_flip() +
  scale_y_continuous(labels = percent_labeller) +
  scale_fill_manual(values = c(`TRUE` = colour_creator, `FALSE` = colour_institution), guide = "none") +
  labs(x = NULL, y = "Razlika u udjelu tematskih oznaka") +
  theme_minimal(base_size = 12)
ggsave(file.path(figure_dir, "h4_theme_difference.png"), p_h4, width = 7, height = 5, dpi = 220)

# H5. Exploratory source-level model within the creator layer. Primary platform is not estimable
# because nearly every eligible high-confidence creator source is primarily on YouTube.
creator_model_data <- copy(eligible_engagement[actor_group == "Influencer"])
creator_model_data[, `:=`(
  priest = as.integer(actor_type == "Individual Priests"),
  charismatic = as.integer(actor_type == "Charismatic Communities"),
  primary_youtube = as.integer(share_youtube > pmax(share_facebook, share_twitter, share_web))
)]
h5_model <- lm(
  log1p(mean_interactions) ~ log(posts) + priest + charismatic,
  data = creator_model_data
)
h5_coefs <- rbindlist(lapply(c("log(posts)", "priest", "charismatic"), function(term) {
  robust_coefficient(h5_model, term)
}))
h5_coefs[, ratio := exp(estimate)]

h5_sensitivity <- rbindlist(lapply(c(1L, 5L, 10L, 20L), function(min_posts) {
  tmp <- copy(primary_engagement[actor_group == "Influencer" & posts >= min_posts])
  tmp[, `:=`(
    priest = as.integer(actor_type == "Individual Priests"),
    charismatic = as.integer(actor_type == "Charismatic Communities")
  )]
  fit <- lm(log1p(mean_interactions) ~ log(posts) + priest + charismatic, data = tmp)
  rows <- rbindlist(lapply(c("log(posts)", "priest", "charismatic"), function(term) {
    robust_coefficient(fit, term)
  }))
  rows[, `:=`(
    min_posts = min_posts,
    sources = nrow(tmp),
    priest_sources = sum(tmp$priest),
    charismatic_sources = sum(tmp$charismatic),
    ratio = exp(estimate)
  )]
  rows
}))
write_csv_utf8(h5_coefs, file.path(table_dir, "h5_model_coefficients.csv"))
write_csv_utf8(h5_sensitivity, file.path(table_dir, "h5_threshold_sensitivity.csv"))

h5_plot <- copy(h5_coefs)
h5_plot[, label := fifelse(
  term == "log(posts)", "Logaritam broja objava",
  fifelse(term == "priest", "Svećenički izvor", "Karizmatska zajednica")
)]
p_h5 <- ggplot(h5_plot, aes(reorder(label, estimate), estimate)) +
  geom_hline(yintercept = 0, linetype = 2, colour = "grey55") +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = .14,
                colour = colour_creator, linewidth = .65) +
  geom_point(colour = colour_creator, size = 2.6) +
  coord_flip() +
  labs(x = NULL, y = "Koeficijent i 95-postotni robusni interval") +
  theme_minimal(base_size = 12)
ggsave(file.path(figure_dir, "h5_coefficients.png"), p_h5, width = 7, height = 5, dpi = 220)

# One machine-readable numerical source for prose, tables and the public study profile.
results <- list(
  run = list(
    generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    analysis_file = "studies/catholic-influencers/analysis.R",
    random_seed = 20260812,
    bootstrap_repetitions = 2000
  ),
  corpus = list(
    rows_official = corpus_manifest$corpus$rows,
    columns_official = corpus_manifest$corpus$columns,
    sha256 = actual_sha,
    generated_utc = corpus_manifest$generated_utc,
    date_min = corpus_manifest$corpus$date_min,
    date_max = corpus_manifest$corpus$date_max
  ),
  sample = list(
    posts = nrow(dta),
    sources = uniqueN(dta$FROM),
    excluded_tiktok = excluded_tiktok,
    date_min = as.character(min(dta$DATE)),
    date_max = as.character(max(dta$DATE)),
    broadly_classified_posts = nrow(broad_posts),
    broadly_classified_sources = uniqueN(broad_posts$FROM),
    primary_posts = nrow(primary_posts),
    primary_sources = uniqueN(primary_posts$FROM),
    primary_influencer_posts = primary_posts[Actor_Group == "Influencer", .N],
    primary_influencer_sources = primary_posts[Actor_Group == "Influencer", uniqueN(FROM)],
    primary_institutional_posts = primary_posts[Actor_Group == "Institutional", .N],
    primary_institutional_sources = primary_posts[Actor_Group == "Institutional", uniqueN(FROM)],
    primary_interaction_coverage = mean(primary_posts$interaction_observed)
  ),
  h1 = list(
    sources = nrow(inf_sources),
    observed_posts = nrow(inf_posts),
    total_interactions = total_inf_interactions,
    gini = gini_primary,
    gini_ci_low = gini_ci[1],
    gini_ci_high = gini_ci[2],
    cr10 = cr10_primary,
    cr_top10pct = cr_top10pct_primary,
    rank_slope = unname(coef(rank_model)[2]),
    rank_r2 = summary(rank_model)$r.squared,
    broad_gini = gini_broad
  ),
  h2 = list(
    influencer_sources = eng_summary[actor_group == "Influencer", sources],
    institutional_sources = eng_summary[actor_group == "Institutional", sources],
    medians = named_rows(eng_summary, "actor_group", "median"),
    q1 = named_rows(eng_summary, "actor_group", "q1"),
    q3 = named_rows(eng_summary, "actor_group", "q3"),
    median_difference = median(x_inf) - median(x_inst),
    median_difference_ci_low = median_diff_ci[1],
    median_difference_ci_high = median_diff_ci[2],
    wilcoxon_w = unname(wilcox_h2$statistic),
    wilcoxon_p = wilcox_h2$p.value,
    rank_biserial = rank_biserial,
    youtube_influencer_sources = youtube_sources[actor_group == "Influencer", .N],
    youtube_institutional_sources = youtube_sources[actor_group == "Institutional", .N],
    youtube_adjusted_estimate = h2_youtube_group$estimate,
    youtube_adjusted_se = h2_youtube_group$std_error,
    youtube_adjusted_p = h2_youtube_group$p,
    youtube_adjusted_ci_low = h2_youtube_group$ci_low,
    youtube_adjusted_ci_high = h2_youtube_group$ci_high,
    youtube_adjusted_ratio = h2_youtube_group$ratio,
    youtube_adjusted_ratio_ci_low = exp(h2_youtube_group$ci_low),
    youtube_adjusted_ratio_ci_high = exp(h2_youtube_group$ci_high),
    youtube_sensitivity_min_estimate = min(h2_youtube_sensitivity$estimate),
    youtube_sensitivity_max_p = max(h2_youtube_sensitivity$p)
  ),
  h3 = list(
    post_chisq = unname(post_chi$statistic),
    post_df = unname(post_chi$parameter),
    post_p = post_chi$p.value,
    post_cramers_v = post_v,
    source_presence_cramers_v = presence_v,
    social_share_influencer = social_share_inf,
    social_share_institutional = social_share_inst,
    web_share_influencer = web_share_inf,
    web_share_institutional = web_share_inst,
    source_weighted_social_share_influencer = source_mix[actor_group == "Influencer", mean(social_share)],
    source_weighted_social_share_institutional = source_mix[actor_group == "Institutional", mean(social_share)],
    source_weighted_social_difference = social_diff,
    source_weighted_social_difference_ci_low = social_diff_ci[1],
    source_weighted_social_difference_ci_high = social_diff_ci[2]
  ),
  h4 = list(
    posts_with_text = nrow(theme_primary$posts),
    coded_posts = uniqueN(theme_primary$hits$post_id),
    assignments = nrow(theme_primary$hits),
    coverage = uniqueN(theme_primary$hits$post_id) / nrow(theme_primary$posts),
    js = theme_primary$js,
    js_ci_low = js_ci[1],
    js_ci_high = js_ci[2],
    broad_js = theme_broad$js,
    devotional_difference = theme_wide[theme == "Devocijski", difference],
    devotional_ci_low = theme_wide[theme == "Devocijski", ci_low],
    devotional_ci_high = theme_wide[theme == "Devocijski", ci_high],
    institutional_difference = theme_wide[theme == "Institucionalni", difference],
    institutional_ci_low = theme_wide[theme == "Institucionalni", ci_low],
    institutional_ci_high = theme_wide[theme == "Institucionalni", ci_high]
  ),
  h5 = list(
    sources = nrow(creator_model_data),
    lay_sources = creator_model_data[actor_type == "Lay Influencers", .N],
    priest_sources = creator_model_data[actor_type == "Individual Priests", .N],
    charismatic_sources = creator_model_data[actor_type == "Charismatic Communities", .N],
    primary_youtube_sources = sum(creator_model_data$primary_youtube),
    adjusted_r2 = summary(h5_model)$adj.r.squared,
    activity_estimate = h5_coefs[term == "log(posts)", estimate],
    activity_p = h5_coefs[term == "log(posts)", p],
    priest_estimate = h5_coefs[term == "priest", estimate],
    priest_p = h5_coefs[term == "priest", p],
    priest_ci_low = h5_coefs[term == "priest", ci_low],
    priest_ci_high = h5_coefs[term == "priest", ci_high],
    priest_ratio = h5_coefs[term == "priest", ratio],
    charismatic_estimate = h5_coefs[term == "charismatic", estimate],
    charismatic_p = h5_coefs[term == "charismatic", p],
    primary_platform_estimable = length(unique(creator_model_data$primary_youtube)) > 1 &&
      min(table(creator_model_data$primary_youtube)) >= 5
  )
)

findings <- data.table(
  question = paste0("P", 1:5),
  finding = c(
    "Vrlo visoka koncentracija zabilježenih interakcija među pouzdano klasificiranim kreatorskim izvorima.",
    "Više interakcija po objavi za kreatorske izvore; razlika ostaje u YouTube usporedbi sa zajedničkom platformom.",
    "Kreatorski i institucionalni izvori imaju snažno različite platformske profile.",
    "Tematski profili dijele zajedničku jezgru, uz jači devocijski naglasak kreatora i institucionalni naglasak institucija.",
    "Primarna platforma nije procjenjiva unutar kreatorskoga sloja; svećenički izvori imaju niže interakcije po objavi u eksplorativnom modelu."
  ),
  inferential_status = c("robust_descriptive", "supported_within_youtube", "robust_descriptive",
                         "modest_divergence", "exploratory_limited_overlap")
)
write_csv_utf8(findings, file.path(table_dir, "findings_summary.csv"))

input_manifest <- list(
  schema_version = 2,
  generated_utc = results$run$generated_utc,
  input = list(
    path = "data/digikat_corpus.rds",
    sha256 = actual_sha,
    rows = corpus_manifest$corpus$rows,
    columns = corpus_manifest$corpus$columns,
    official_manifest = "data/digikat_corpus_manifest.json"
  ),
  scope = list(
    excluded_platform = "tiktok",
    excluded_rows = excluded_tiktok,
    analytical_rows = nrow(dta),
    primary_classification = "high confidence",
    partial_2026 = TRUE
  ),
  provenance = list(
    upstream_repository = "https://github.com/lusiki/Katolicki_Influenceri",
    upstream_commit = "fa34ff5ae1c8027c355f2523d404c8febf03a24a",
    recovered_source = "code/analysis_hr.qmd",
    analysis_sha256 = digest::digest(file = file.path(study_dir, "analysis.R"),
                                     algo = "sha256", serialize = FALSE),
    classifier_sha256 = digest::digest(file = file.path(study_dir, "actor_classification.R"),
                                       algo = "sha256", serialize = FALSE),
    manuscript_sha256 = digest::digest(file = file.path(study_dir, "PAPER.qmd"),
                                       algo = "sha256", serialize = FALSE)
  )
)
jsonlite::write_json(input_manifest, file.path(out_dir, "analysis_input_manifest.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = 15)
jsonlite::write_json(results, file.path(out_dir, "analysis_results.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = 15, null = "null")

stopifnot(
  nrow(dta) + excluded_tiktok == corpus_manifest$corpus$rows,
  nrow(primary_posts) < nrow(broad_posts),
  all(c("Influencer", "Institutional") %in% eng_summary$actor_group),
  h2_youtube_group$estimate > 0,
  is.finite(gini_primary),
  is.finite(theme_primary$js),
  !results$h5$primary_platform_estimable,
  file.exists(file.path(out_dir, "analysis_results.json"))
)
message("Analysis complete. Results: ", file.path(out_dir, "analysis_results.json"))
