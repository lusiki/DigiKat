#!/usr/bin/env Rscript
# moral-economy — SEMANTIC SLICE (demo): redo the economic-coverage analysis through the meaning
# lens instead of keyword nets, on a sample, so we can SEE what the semantic version looks like
# before committing to the full run. READ-ONLY on the semantic store; writes only output/semantic/.
#
# Three deliverables, all from ONE sample of stored post-vectors scored against concept anchors:
#   (1) SEMANTIC COVERAGE RANKING — does poverty still dominate / aggregates stay cold, by MEANING?
#   (2) DOMAIN x REGISTER heatmap — the paper's headline grid, produced WITHOUT hand-coding.
#   (3) POVERTY economic-vs-doctrinal split — the fix for the keyword table's soft spot.
#
# Needs Ollama running (bge-m3) to embed the ~22 concept anchors; corpus vectors are already stored.
#   Rscript studies/moral-economy/semantic_slice.R
suppressPackageStartupMessages({ library(here); library(DBI); library(duckdb); library(httr2) })

STORE <- here::here("data/semantic/digikat.ragnar.duckdb")
if (!file.exists(STORE)) stop("No semantic store — build R/semantic/11_build.R first.")
out_dir <- here::here("studies/moral-economy/output/semantic")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
N_SAMPLE <- 20000L; SEED <- 20260709L

# --- 1. concept anchors (plain-language meaning, Croatian — matches the corpus best) -------------
econ <- c(
  macro_aggregates = "bruto domaći proizvod, gospodarski rast, recesija, javni dug i proračunski deficit",
  euro_changeover  = "uvođenje eura, prelazak s kune na euro, zamjena valute i konverzija cijena",
  taxes_fiscal     = "porezi, porezna politika, PDV, trošarine i fiskalna davanja državi",
  business_comp    = "poduzetništvo, tvrtke i obrti, konkurentnost gospodarstva, investicije i ulaganja",
  green_energy     = "energetska kriza, cijene struje i plina, zelena tranzicija i obnovljivi izvori energije",
  housing          = "stanovanje, najamnine, cijene nekretnina i priuštivost stanova",
  demography_econ  = "manjak radne snage, strani radnici, iseljavanje i tržište rada",
  inflation_prices = "inflacija, poskupljenja, rast cijena, trošak života i kupovna moć",
  unemployment     = "nezaposlenost, gubitak posla, otpuštanja radnika i tržište rada",
  wages_income     = "plaće, minimalna plaća, mirovine, primanja i radnička prava",
  poverty_social   = "siromaštvo, socijalna pomoć, ugroženi građani, beskućnici, ovrhe i dugovi"
)
# non-economic DECOYS: a post is "economic" only if it's closer to an econ anchor than to ALL of these
# (this corpus is religion-filtered, so most posts are about faith, not the economy — the decoys gate that).
decoy <- c(
  liturgy    = "misa, euharistija, liturgija, molitva, sakramenti i vjerski obredi",
  devotion   = "hodočašće, svetište, procesija, štovanje svetaca i Blažene Djevice Marije",
  church_org = "imenovanje biskupa, crkveni događaji, Papa i Vatikan, sinoda i crkveni nauk"
)
# REGISTER anchors (the voice religion takes when it meets the economy)
reg <- c(
  justice      = "strukturalni uzroci nepravde, kritika ekonomskog sustava, dostojanstvo rada, socijalna pravda i opće dobro",
  charity      = "Caritas, humanitarna pomoć, milostinja i prikupljanje pomoći za siromašne i potrebite",
  institution  = "Crkva kao institucija, biskupi i svećenici u javnom životu, crkvena imovina i sredstva",
  cost_relig   = "troškovi vjerskog života, cijena misa i sakramenata, crkvene naknade, poskupljenje vjenčanja i sprovoda",
  devotional   = "duhovno siromaštvo, evanđeoske vrijednosti, obraćenje srca, molitva i pobožnost"
)
# POVERTY split anchors
psplit <- c(
  economic  = "materijalno siromaštvo, rizik od siromaštva, socijalna ugroženost, ovrhe, dugovi i beskućništvo",
  doctrinal = "evanđeosko siromaštvo, blaženi siromasi duhom, redovnički zavjet siromaštva, milostinja kao kršćanska vrlina"
)
anchors <- c(econ, decoy, reg, psplit)

# --- 2. embed anchors via Ollama (bge-m3) -------------------------------------------------------
cat("Embedding", length(anchors), "concept anchors via Ollama (bge-m3)...\n")
emb_resp <- request("http://localhost:11434/api/embed") |>
  req_body_json(list(model = "bge-m3", input = unname(anchors))) |>
  req_timeout(120) |> req_perform() |> resp_body_json()
A <- do.call(rbind, lapply(emb_resp$embeddings, function(v) as.numeric(unlist(v))))
rownames(A) <- names(anchors)
stopifnot(ncol(A) == 1024L, nrow(A) == length(anchors))

# --- 3. pull a reservoir sample of stored post-vectors (read-only) ------------------------------
cat("Pulling", N_SAMPLE, "stored post-vectors from the semantic store...\n")
con <- dbConnect(duckdb::duckdb(), dbdir = STORE, read_only = TRUE, array = "matrix")
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
total <- dbGetQuery(con, "SELECT COUNT(*) n FROM chunks")$n
q <- sprintf("SELECT doc_id, platform, data_source, text, embedding FROM chunks USING SAMPLE %d ROWS (reservoir, %d)",
             N_SAMPLE, SEED)
S <- dbGetQuery(con, q)
P <- S$embedding                                  # N x 1024 matrix
cat(sprintf("  got %d of %d posts (dim %d)\n", nrow(P), total, ncol(P)))

# --- 4. cosine similarity: every sampled post vs every anchor -----------------------------------
unit <- function(M) M / pmax(sqrt(rowSums(M^2)), 1e-9)
sim <- unit(P) %*% t(unit(A))                     # N x n_anchors, cosine
colnames(sim) <- rownames(A)

en <- names(econ); dn <- names(decoy)
best_econ  <- max.col(sim[, en, drop = FALSE]);  best_econ_val  <- sim[cbind(seq_len(nrow(sim)), match(en[best_econ], colnames(sim)))]
best_decoy_val <- apply(sim[, dn, drop = FALSE], 1, max)
is_econ <- best_econ_val > best_decoy_val         # primarily economic (beats every faith decoy)
primary <- factor(ifelse(is_econ, en[best_econ], NA), levels = en)

# --- (1) SEMANTIC COVERAGE RANKING --------------------------------------------------------------
kw_linked <- c(poverty_social=38232, business_comp=31416, taxes_fiscal=23375, wages_income=13724,
               macro_aggregates=7090, housing=6106, unemployment=5849, green_energy=3425,
               inflation_prices=1607, demography_econ=1288, euro_changeover=407)  # from Stage A
cov <- as.data.frame(table(primary), responseName = "n_semantic")
names(cov)[1] <- "domain"; cov$domain <- as.character(cov$domain)
cov$pct_of_economic <- round(100 * cov$n_semantic / sum(cov$n_semantic), 1)
cov$semantic_rank <- rank(-cov$n_semantic, ties.method = "min")
cov$keyword_rank  <- rank(-kw_linked[cov$domain], ties.method = "min")
cov$mean_sim <- round(sapply(cov$domain, function(d) mean(sim[, d])), 3)
cov <- cov[order(cov$semantic_rank), ]
write.csv(cov, file.path(out_dir, "coverage_ranking.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat(sprintf("\n== (1) SEMANTIC COVERAGE — %.1f%% of the sampled religion-corpus is primarily ECONOMIC (vs faith) ==\n",
            100 * mean(is_econ)))
print(cov[, c("domain","n_semantic","pct_of_economic","semantic_rank","keyword_rank","mean_sim")], row.names = FALSE)
cat("  (semantic_rank vs keyword_rank: do the two lenses agree on the ordering?)\n")

# --- (2) DOMAIN x REGISTER heatmap (focus domains) ----------------------------------------------
focus <- c("poverty_social","wages_income","taxes_fiscal","inflation_prices","macro_aggregates")
rn <- names(reg); TOPK <- 600L
heat <- do.call(rbind, lapply(focus, function(d) {
  ord <- order(sim[, d], decreasing = TRUE)[seq_len(min(TOPK, nrow(sim)))]  # the posts most ABOUT this domain
  rr  <- rn[max.col(sim[ord, rn, drop = FALSE])]
  p   <- prop.table(table(factor(rr, levels = rn)))
  data.frame(domain = d, t(round(as.numeric(p), 2)))
}))
names(heat)[-1] <- rn
write.csv(heat, file.path(out_dir, "register_heatmap.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat(sprintf("\n== (2) DOMAIN x REGISTER — register mix of the top %d posts most about each domain ==\n", TOPK))
print(heat, row.names = FALSE)

# --- (3) POVERTY economic-vs-doctrinal split ----------------------------------------------------
ordp <- order(sim[, "poverty_social"], decreasing = TRUE)[seq_len(min(800L, nrow(sim)))]
psel <- c("economic","doctrinal")[max.col(sim[ordp, c("economic","doctrinal"), drop = FALSE])]
cat("\n== (3) POVERTY split — of the 800 posts most about 'poverty', economic vs doctrinal 'the poor' ==\n")
print(round(prop.table(table(psel)), 3))

# --- validation habit: eyeball the top hits per focus domain ------------------------------------
cat("\n== VALIDATION — top-3 semantic hits per focus domain (do they look right?) ==\n")
for (d in focus) {
  ord <- order(sim[, d], decreasing = TRUE)[1:3]
  cat("\n[", d, "]\n")
  for (i in ord) cat("  (", round(sim[i, d], 2), ")", substr(gsub("\\s+", " ", S$text[i]), 1, 160), "...\n")
}
cat("\nOutputs -> ", out_dir, "\n")
