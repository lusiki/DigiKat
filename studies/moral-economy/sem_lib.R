#!/usr/bin/env Rscript
# moral-economy — SEMANTIC LIBRARY (the meaning lens's single source of truth).
#
# SOURCE this; never run it. It plays for the meaning lens exactly the role lexicon.R plays for the
# keyword lens: every constant, gate, and piece of scoring math lives here, so 05-10 cannot drift
# apart and a stale anchor set can never masquerade as fresh.
#
#   source(here::here("studies/moral-economy/sem_lib.R"))
#
# READ-ONLY on the semantic store and on the master (which it never opens at all).
#
# ---------------------------------------------------------------------------------------------
# THE CENTERING ALGEBRA — why one SQL pass scores 710,307 posts against every anchor at once.
#
# Stored vectors are unit-norm (gate G1 asserts it). Let mu = corpus mean vector, ||mu|| ~ 0.595.
# The corpus is ANISOTROPIC: random post pairs have mean cosine 0.354, not ~0. Under raw cosine an
# anchor's score is dominated by its projection onto that shared component, so BROAD wording scores
# high everywhere — this is precisely the pilot's euro artifact (a generic "euro/prices" anchor took
# 19.9% of the corpus vs 407 keyword-linked posts). Removing mu removes the term breadth exploits.
#
#   centred post direction:  p~ = (p - mu) / ||p - mu||,   ||p - mu||^2 = 1 - 2<p,mu> + ||mu||^2
#   anchor for concept d:    A_d = mean_{i in S_d}(p_i - mu) = mean(p_S) - mu,  a_d = A_d / ||A_d||
#   score:                   s_d(p) = <p~, a_d> = (<p,a_d> - <mu,a_d>) / sqrt(1 - 2<p,mu> + ||mu||^2)
#
# The denominator needs ONE inner product per row, shared by every anchor; each numerator is one
# inner product minus a precomputed scalar c_d = <mu, a_d>. Hence: one scan, all anchors. The closed
# form for ||p - mu|| uses ||p|| = 1 — which is why the unit-norm gate is a gate, not a nicety.
# ---------------------------------------------------------------------------------------------
suppressPackageStartupMessages({ library(here); library(DBI); library(duckdb) })
source(here::here("R/lib/digikat_utils.R"))

# ---- constants ------------------------------------------------------------------------------
ME_STORE     <- here::here("data/semantic/digikat.ragnar.duckdb")
ME_EMB_DIM   <- 1024L
ME_MODEL     <- "bge-m3"          # MUST be passed explicitly: ragnar's default is a different model
ME_SEED      <- 20260804L
ME_TRUNC     <- 4000L             # the store's embed-input truncation; mirrored when embedding anchors
ME_BATCH     <- 20000L            # rows per R-side embedding batch (~165 MB peak)
ME_OUT       <- here::here("studies/moral-economy/output")
ME_SEM       <- file.path(ME_OUT, "semantic")
ME_PRIVATE   <- file.path(ME_OUT, "private")

# CODEBOOK.md ax4 (register, 5-way + remainder) and ax5 (poverty split)
ME_REGISTERS <- c("object_institution", "object_cost_relig_life", "charity",
                  "justice", "devotional", "other")
ME_PSPLIT    <- c("economic_poverty", "doctrinal_poverty", "mixed")
ME_AXES      <- c("ax1_link_genuine", "ax2_geography", "ax3_actor_commentator",
                  "ax4_register", "ax5_poverty_split", "ax6_ksn_principle", "ax7_encyclical")
ME_DOMAINS   <- c("macro_aggregates", "euro_changeover", "taxes_fiscal", "business_comp",
                  "green_energy", "housing", "demography_econ", "inflation_prices",
                  "unemployment", "wages_income", "poverty_social")

dir.create(ME_SEM, recursive = TRUE, showWarnings = FALSE)
dir.create(ME_PRIVATE, recursive = TRUE, showWarnings = FALSE)

# ---- store access ---------------------------------------------------------------------------
# array = "matrix" is REQUIRED: without it FLOAT[1024] comes back as a list column, not a matrix.
sem_con <- function(path = ME_STORE) {
  if (!file.exists(path)) stop("No semantic store at ", path, " — see R/semantic/README.md.", call. = FALSE)
  tryCatch(
    dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE, array = "matrix"),
    error = function(e) stop(
      "Could not open the semantic store read-only: ", conditionMessage(e),
      "\n  Close any other R session holding it (Windows/Dropbox file lock).", call. = FALSE))
}

sem_disconnect <- function(con) try(dbDisconnect(con, shutdown = TRUE), silent = TRUE)

# ---- gates ----------------------------------------------------------------------------------
sem_gate_report <- function(name, pass, detail) {
  cat(sprintf("[%s] %-28s %s\n", if (pass) "PASS" else "FAIL", name, detail))
  if (!pass) stop("Gate ", name, " failed: ", detail, call. = FALSE)
  invisible(TRUE)
}

# G0 — the Stage A <-> store join. stageA carries `rid` (master row index); the store carries
# doc_id = sprintf("dk_%08d", rid) and chunk_id = the integer of that. Verified 300/300 on URL AND
# DATE, but this stays in code: a master rebuild or a store rebuild would silently break the join
# and every downstream number would be attached to the wrong post.
sem_gate_id_mapping <- function(con, cand, n = 500L, seed = ME_SEED) {
  digikat_require_columns(cand, c("rid", "URL", "DATE"), "stageA candidates")
  set.seed(seed)
  s <- cand[sample(nrow(cand), min(n, nrow(cand))), c("rid", "URL", "DATE"), drop = FALSE]
  s <- s[!duplicated(s$rid), ]
  q <- dbGetQuery(con, sprintf(
    "SELECT chunk_id AS rid, url, date FROM chunks WHERE chunk_id IN (%s)",
    paste(as.integer(s$rid), collapse = ",")))
  m <- merge(s, q, by = "rid")
  if (!nrow(m)) sem_gate_report("G0 rid<->doc_id", FALSE, "no rows matched in the store")
  url_ok  <- sum(identical_na(m$URL, m$url))
  date_ok <- sum(identical_na(as.character(as.Date(substr(m$DATE, 1, 10))), as.character(m$date)))
  ok <- url_ok == nrow(m) && date_ok == nrow(m) && nrow(m) == nrow(s)
  sem_gate_report("G0 rid<->doc_id", ok,
                  sprintf("%d/%d URL, %d/%d DATE exact (n matched %d/%d)",
                          url_ok, nrow(m), date_ok, nrow(m), nrow(m), nrow(s)))
}

identical_na <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)

# G1 — stored vectors are unit-norm. This is what licenses array_inner_product as cosine AND the
# closed-form ||p - mu||. One full scan, ~4 s.
sem_gate_unit_norm <- function(con, tol = 1e-4) {
  q <- dbGetQuery(con, "SELECT min(array_inner_product(embedding, embedding)) lo,
                               max(array_inner_product(embedding, embedding)) hi FROM chunks")
  ok <- abs(q$lo - 1) < tol && abs(q$hi - 1) < tol
  sem_gate_report("G1 unit-norm embeddings", ok, sprintf("||p||^2 in [%.6f, %.6f]", q$lo, q$hi))
}

# ---- vector helpers -------------------------------------------------------------------------
sem_unit <- function(M) {
  if (is.null(dim(M))) return(M / max(sqrt(sum(M^2)), 1e-9))
  M / pmax(sqrt(rowSums(M^2)), 1e-9)
}
sem_center <- function(M, mu) {
  if (is.null(dim(M))) return(M - mu)
  sweep(M, 2L, mu, "-")
}

# EXACT corpus mean over all 710,307 rows, accumulated in batches (never 5.8 GB in RAM at once).
# Cached; the fingerprint is store size + mtime + row count (hashing 13.6 GB every run is absurd).
sem_corpus_mean <- function(con, cache = file.path(ME_SEM, "corpus_mean.rds"), batch = ME_BATCH) {
  info <- file.info(ME_STORE)
  rng <- dbGetQuery(con, "SELECT min(chunk_id) lo, max(chunk_id) hi, count(*) n FROM chunks")
  fp <- list(bytes = unname(info$size), mtime = as.character(info$mtime), rows = rng$n)
  if (file.exists(cache)) {
    got <- readRDS(cache)
    if (identical(attr(got, "fingerprint"), fp)) return(got)
    cat("  corpus mean cache is stale for this store — recomputing.\n")
  }
  cat(sprintf("  computing exact corpus mean over %s rows...\n", digikat_format_integer(rng$n)))
  acc <- numeric(ME_EMB_DIM); seen <- 0L
  a <- rng$lo
  while (a <= rng$hi) {
    b <- a + batch - 1L
    P <- dbGetQuery(con, sprintf(
      "SELECT embedding FROM chunks WHERE chunk_id BETWEEN %d AND %d", a, b))$embedding
    if (length(P)) { acc <- acc + colSums(P); seen <- seen + nrow(P) }
    a <- b + 1L
  }
  if (seen != rng$n) stop("Corpus mean visited ", seen, " of ", rng$n, " rows.", call. = FALSE)
  mu <- acc / seen
  attr(mu, "fingerprint") <- fp
  attr(mu, "n_rows") <- seen
  digikat_atomic_replace_file(digikat_stage_rds(mu, cache), cache)
  cat(sprintf("  ||mu|| = %.4f over %s rows (isotropic would be ~0)\n",
              sqrt(sum(mu^2)), digikat_format_integer(seen)))
  mu
}

# ---- embedding arbitrary text (anchors, probes) ----------------------------------------------
# Uses ragnar::embed_ollama with the model PINNED. ragnar's default model is not bge-m3, and an
# unpinned call silently returns wrong-dimension vectors that would poison every anchor.
sem_embed_text <- function(x, model = ME_MODEL, batch_size = 64L) {
  x <- substr(as.character(x), 1L, ME_TRUNC)   # mirror the store's truncation contract
  M <- if (requireNamespace("ragnar", quietly = TRUE)) {
    ragnar::embed_ollama(x, model = model, batch_size = batch_size)
  } else {
    sem_embed_ollama_http(x, model = model)
  }
  if (!is.matrix(M)) M <- matrix(M, nrow = length(x), byrow = TRUE)
  if (ncol(M) != ME_EMB_DIM) {
    stop("Embedder returned ", ncol(M), " dims, expected ", ME_EMB_DIM,
         " — wrong model? (must be ", model, ")", call. = FALSE)
  }
  rownames(M) <- names(x)
  M
}

# Direct-HTTP fallback, used only if ragnar is unavailable.
sem_embed_ollama_http <- function(x, model = ME_MODEL, url = "http://localhost:11434/api/embed") {
  if (!requireNamespace("httr2", quietly = TRUE)) stop("Need ragnar or httr2 to embed text.", call. = FALSE)
  r <- httr2::request(url) |>
    httr2::req_body_json(list(model = model, input = unname(x))) |>
    httr2::req_timeout(300) |> httr2::req_perform() |> httr2::resp_body_json()
  do.call(rbind, lapply(r$embeddings, function(v) as.numeric(unlist(v))))
}

# ---- SQL scoring ----------------------------------------------------------------------------
sem_arr_literal <- function(v) {
  paste0("[", paste(sprintf("%.8g", as.numeric(v)), collapse = ","), "]::FLOAT[", ME_EMB_DIM, "]")
}

# Build the one-pass centered-scoring query. `A` = anchors as a named (n_anchor x 1024) matrix of
# ALREADY-CENTERED, UNIT-NORM directions; `mu` = corpus mean.
sem_score_sql <- function(A, mu, extra_cols = c("chunk_id", "platform", "data_source", "date"),
                          where = NULL, length_col = FALSE) {
  MU2 <- sum(mu^2)
  cd  <- as.numeric(A %*% mu)                    # c_d = <mu, a_d>
  den <- sprintf("sqrt(greatest(1.0 - 2.0*pm + %.10g, 1e-12))", MU2)
  terms <- vapply(seq_len(nrow(A)), function(i) sprintf(
    "  (array_inner_product(embedding, %s) - %.10g) / %s AS s_%s",
    sem_arr_literal(A[i, ]), cd[i], den, rownames(A)[i]), character(1))
  sprintf("WITH base AS (\n  SELECT %s,\n         array_inner_product(embedding, %s) AS pm,\n%s         embedding\n  FROM chunks%s\n)\nSELECT %s,\n%s\nFROM base",
          paste(extra_cols, collapse = ", "), sem_arr_literal(mu),
          if (length_col) "         length(text) AS text_chars,\n" else "",
          if (is.null(where)) "" else paste0("\n  WHERE ", where),
          paste(c(extra_cols, if (length_col) "text_chars"), collapse = ", "),
          paste(terms, collapse = ",\n"))
}

# R-side reference implementation of the same math — the G3 precision gate compares the two.
sem_score_r <- function(P, A, mu) {
  num <- P %*% t(A)                                   # <p, a_d>
  num <- sweep(num, 2L, as.numeric(A %*% mu), "-")    # - c_d
  den <- sqrt(pmax(1 - 2 * as.numeric(P %*% mu) + sum(mu^2), 1e-12))
  m <- num / den
  colnames(m) <- rownames(A)
  m
}

sem_fetch_embeddings <- function(con, ids, batch = ME_BATCH) {
  ids <- unique(as.integer(ids))
  out <- vector("list", ceiling(length(ids) / batch)); k <- 0L
  for (a in seq(1L, length(ids), by = batch)) {
    b <- min(a + batch - 1L, length(ids)); k <- k + 1L
    out[[k]] <- dbGetQuery(con, sprintf(
      "SELECT chunk_id, embedding FROM chunks WHERE chunk_id IN (%s)",
      paste(ids[a:b], collapse = ",")))
  }
  res <- do.call(rbind, out)
  P <- res$embedding
  rownames(P) <- as.character(res$chunk_id)
  P
}

# ---- statistics -------------------------------------------------------------------------------
# Wilson score interval (same helper 01_stageA_tag_linkage.R uses; every proportion gets one).
wilson <- function(k, n, z = 1.96) {
  if (!length(n) || is.na(n) || n == 0) return(c(NA_real_, NA_real_))
  p <- k / n; d <- 1 + z^2 / n
  c(max(0, (p + z^2 / (2 * n) - z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / d),
    min(1, (p + z^2 / (2 * n) + z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / d))
}

# Fleiss' kappa, majority adjudication, and the register collapse — COPIED VERBATIM from
# 04_iaa_validation.R so the two scripts cannot compute reliability differently.
fleiss_kappa <- function(mat) {
  mat <- mat[apply(mat, 1, function(r) sum(!is.na(r)) >= 2), , drop = FALSE]
  if (!nrow(mat)) return(NA_real_)
  cats <- sort(unique(na.omit(as.vector(mat)))); if (length(cats) < 2) return(NA_real_)
  Pi <- apply(mat, 1, function(r) {
    r <- r[!is.na(r)]; n <- length(r); if (n < 2) return(NA_real_)
    (sum(table(factor(r, levels = cats))^2) - n) / (n * (n - 1))
  })
  n_per <- apply(mat, 1, function(r) sum(!is.na(r)))
  pj <- sapply(cats, function(cc) sum(mat == cc, na.rm = TRUE)) / sum(n_per)
  Pbar <- mean(Pi, na.rm = TRUE); Pe <- sum(pj^2)
  if (Pe >= 1) return(NA_real_); (Pbar - Pe) / (1 - Pe)
}
majority <- function(r) {
  r <- r[!is.na(r) & r != ""]; if (!length(r)) return(NA_character_)
  t <- sort(table(r), decreasing = TRUE); names(t)[1]
}
collapse3 <- function(x) ifelse(
  x %in% c("object_institution", "object_cost_relig_life"), "object",
  ifelse(x == "justice", "justice",
         ifelse(x == "charity", "charity",
                ifelse(x %in% c("devotional", "other", ""), "remainder", x))))

# Cohen's kappa for two raters (classifier vs human majority).
cohen_kappa <- function(a, b) {
  ok <- !is.na(a) & !is.na(b); a <- a[ok]; b <- b[ok]
  if (!length(a)) return(NA_real_)
  lv <- sort(unique(c(a, b))); if (length(lv) < 2) return(NA_real_)
  t <- table(factor(a, lv), factor(b, lv)); n <- sum(t)
  po <- sum(diag(t)) / n; pe <- sum(rowSums(t) * colSums(t)) / n^2
  if (pe >= 1) return(NA_real_); (po - pe) / (1 - pe)
}

# ---- stratified draw (reused from 03_build_coding_sheet.R; strata = stream x label) -----------
sem_draw <- function(df, target, id = "rid") {
  if (nrow(df) <= target) return(df[[id]])
  df$stratum <- paste(df$stream, df$label, sep = " | ")
  sz <- table(df$stratum); frac <- sz / sum(sz)
  want <- pmin(as.integer(round(target * frac)), as.integer(sz))
  names(want) <- names(sz)   # as.integer() strips names — want[[s]] below would crash
  deficit <- target - sum(want)
  if (deficit != 0) {
    room <- as.integer(sz) - want; names(room) <- names(sz); ord <- order(-room); i <- 1
    while (deficit != 0 && ((deficit > 0 && any(room > 0)) || (deficit < 0 && any(want > 0)))) {
      s <- ord[((i - 1) %% length(ord)) + 1]
      if (deficit > 0 && room[s] > 0) { want[s] <- want[s] + 1; room[s] <- room[s] - 1; deficit <- deficit - 1 }
      else if (deficit < 0 && want[s] > 0) { want[s] <- want[s] - 1; deficit <- deficit + 1 }
      i <- i + 1
    }
  }
  unlist(lapply(names(sz), function(s) {
    pool <- df[[id]][df$stratum == s]; k <- want[[s]]
    if (k >= length(pool)) pool else sample(pool, k)
  }), use.names = FALSE)
}

# ---- disclosure ------------------------------------------------------------------------------
# Structural enforcement of the project's disclosure rule: row-level text, URLs, titles, source
# identities and rids never reach a TRACKED file. .gitignore tracks .csv/.png under studies/*/output/,
# so every such write is a publication act — this stops it being an accidental one.
ME_FORBIDDEN <- c("text", "text_800", "window", "URL", "url", "TITLE", "title",
                  "FROM", "actor", "rid", "doc_id", "chunk_id")

sem_assert_shareable <- function(df, what = "tracked output") {
  bad <- intersect(names(df), ME_FORBIDDEN)
  if (length(bad)) {
    stop("Refusing to write ", what, ": restricted column(s) present — ",
         paste(bad, collapse = ", "), ". Write it to output/private/ instead.", call. = FALSE)
  }
  invisible(TRUE)
}

# Small-cell suppression for tracked tables (re-identification risk on domain x register x stream x label).
sem_suppress_small <- function(df, count_col = "n", min_n = 10L) {
  if (!count_col %in% names(df)) return(df)
  hit <- !is.na(df[[count_col]]) & df[[count_col]] < min_n
  df$n_suppressed <- as.integer(hit)
  df[[count_col]][hit] <- NA_integer_
  df
}

sem_write_shareable <- function(df, path, suppress = FALSE) {
  sem_assert_shareable(df, basename(path))
  if (suppress) df <- sem_suppress_small(df)
  write.csv(df, path, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(path)
}

sem_write_private <- function(df, path) {
  if (!grepl("[\\\\/]private[\\\\/]", path)) {
    stop("Restricted output must live under output/private/: ", path, call. = FALSE)
  }
  write.csv(df, path, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(path)
}

# ---- fingerprinted checkpoints (01_stageA_tag_linkage.R idiom, generalized) --------------------
sem_checkpoint <- function(path, fp, compute, label = basename(path)) {
  if (file.exists(path)) {
    got <- readRDS(path)
    if (identical(attr(got, "fingerprint"), fp)) {
      cat("  [cached] ", label, " — inputs unchanged.\n", sep = "")
      return(got)
    }
    cat("  [stale] ", label, " — inputs changed, recomputing.\n", sep = "")
  }
  val <- compute()
  attr(val, "fingerprint") <- fp
  digikat_atomic_replace_file(digikat_stage_rds(val, path), path)
  val
}

sem_manifest <- function(generator, inputs = list(), outputs = list(), extra = list()) {
  c(list(schema_version = 1L,
         generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
         generator = generator,
         store = list(path = "data/semantic/digikat.ragnar.duckdb",
                      model = ME_MODEL, dim = ME_EMB_DIM, truncation_chars = ME_TRUNC),
         seed = ME_SEED, inputs = inputs, outputs = outputs), extra)
}

invisible(TRUE)
