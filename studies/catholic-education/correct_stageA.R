#!/usr/bin/env Rscript
# CORRECTION pass for Stage A (2026-07-06), applied to the existing slice.rds WITHOUT re-reading the
# 1.2 GB master. Valid because both fixes only make the probe STRICTER -> the corrected slice is a
# SUBSET of the existing one (removing false positives never adds posts), so every reported quantity
# can be recomputed within the existing superset. Fixes:
#   (A) isusov homonym: bare "isusov" matched ~63k "Isusov dar / Isusova braća" (OF-JESUS), not Jesuits
#       -> restrict redovi_orders to the ORDER forms; this shrinks the bundle + may drop isusov-only posts.
#   (B) r-reviewer Critical #1: past-anchoring "genuine" was computed vs the OR of ALL spine bundles, so
#       a co-occurring bundle near a past token credited every entity. Recompute PER ENTITY (past token
#       near THAT entity's own match) -> the construct-validity gate + candidate table become entity-true.
# Reads/overwrites only studies/catholic-education/output/. Never touches data/.
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr) })

out_dir  <- here::here("studies/catholic-education/output")
slice    <- readRDS(file.path(out_dir, "slice.rds"))
cat("loaded existing slice (superset):", nrow(slice), "rows\n")
txt <- stringr::str_to_lower(slice$FULL_TEXT, locale = "hr")

# --- corrected probe (MUST match slice.R) ----------------------------------------------------
probe <- list(
  vjeronauk        = "vjeronauk|vjerou[čc]itelj",
  katolicka_skola  = "katoli[čc]k\\w*[\\s-]+(\\w+\\s+)?[šs]kol|katoli[čc]ko\\s+u[čc]ili[šs]t|katoli[čc]k\\w*\\s+sveu[čc]ili[šs]t|\\bhks\\b|sjemeni[šs]t|u[čc]iteljsk\\w*\\s+[šs]kol",
  odgoj_vrijednosti= "odgoj|kurikul|kr[šs][čc]ansk\\w*\\s+korijen|\\bvrijednost",
  stepinac         = "stepinac",
  strossmayer      = "strossmayer|strosmajer",
  stadler          = "\\bstadler\\b",
  petkovic_marija  = "marij\\w*\\s+petkovi[ćc]|bla[žz]en\\w*\\s+marij\\w*\\s+petkovi[ćc]|petkovi[ćc]\\w*\\s+(redovnic|sestr|milosrdnic)",
  redovi_orders    = "isusova[cč]\\w*|isusovc\\w*|dru[žz]b\\w*\\s+isusov|jezuit|franjev|dominikan|salezijan|[čc]asn\\w*\\s+sestr|samostan",
  past_anchor      = "komunist|komuniz|sekular|jugoslavij|\\b1991\\b|domovinsk|[žz]rtv\\w*|\\brat\\w*|(po)?slijeratn|predratn|poratn",
  rituali          = "hod za [žz]ivot|\\bshkm\\b|progledaj srcem|antunovsk\\w*\\s+hod|procesij|hodo[čc]a[šs]"
)
spine_keys <- c("vjeronauk","katolicka_skola","odgoj_vrijednosti","stepinac",
                "strossmayer","stadler","petkovic_marija","redovi_orders")
past_rx <- probe$past_anchor

# --- (A) recompute flags with the corrected probe; re-derive the slice ------------------------
flags <- sapply(c(spine_keys, "rituali"), function(k) stringr::str_detect(txt, probe[[k]]))
spine_hit <- rowSums(flags[, spine_keys, drop = FALSE]) > 0
past_doc  <- stringr::str_detect(txt, past_rx)

# isusov contamination magnitude: old bundle used bare "isusov"
old_isusov <- stringr::str_detect(txt, "isusov")               # OLD (contaminated)
new_orders <- flags[, "redovi_orders"]
cat(sprintf("\n[A] isusov fix: bare 'isusov' hits = %d; corrected redovi_orders hits = %d (was 122082).\n",
            sum(old_isusov), sum(new_orders)))
cat(sprintf("    education-spine rows: %d -> %d (%d posts leave the slice as isusov-only false positives).\n",
            nrow(slice), sum(spine_hit), nrow(slice) - sum(spine_hit)))

# --- (B) PER-ENTITY genuine windowed past-anchoring ------------------------------------------
WINDOW <- 160L
near_past_ent <- function(s, ent_rx) {          # past token within WINDOW of THIS entity's match
  sp <- stringr::str_locate_all(s, ent_rx)[[1]]
  pa <- stringr::str_locate_all(s, past_rx)[[1]]
  if (nrow(sp) == 0L || nrow(pa) == 0L) return(FALSE)
  any(abs(outer(sp[, "start"], pa[, "start"], `-`)) <= WINDOW)
}
entity_genuine <- function(ecol) {              # per-row genuine flag for entity ecol, within slice'
  g  <- logical(nrow(slice))
  gi <- which(flags[, ecol] & spine_hit & past_doc)   # only rows in slice' with entity-hit AND a past token
  if (length(gi)) g[gi] <- vapply(txt[gi], near_past_ent, logical(1), ent_rx = probe[[ecol]])
  g
}

candidates <- do.call(rbind, lapply(c(spine_keys, "rituali"), function(e) {
  hit <- flags[, e] & spine_hit; n <- sum(hit)
  if (n == 0) return(data.frame(entity = e, recurrence_n = 0L, past_anchor_doc = NA_real_,
                                past_anchor_genuine = NA_real_, incidental_share = NA_real_))
  gen <- entity_genuine(e)
  data.frame(entity = e, recurrence_n = n,
             past_anchor_doc     = round(mean(past_doc[hit]), 3),
             past_anchor_genuine = round(mean(gen[hit]), 3),
             incidental_share    = round(mean(past_doc[hit]) - mean(gen[hit]), 3),
             stringsAsFactors = FALSE)
}))
candidates <- candidates[order(-candidates$recurrence_n), ]
cat("\n-- CORRECTED candidate table (per-entity genuine past-anchoring) --\n")
print(candidates, row.names = FALSE)

# --- construct-validity gate, now entity-true ------------------------------------------------
gv <- function(e) candidates$past_anchor_genuine[candidates$entity == e]
cat(sprintf("\n[B] construct-validity (ENTITY-SPECIFIC): stepinac genuine = %.3f  vs  odgoj foil = %.3f  (ratio %.2fx)\n",
            gv("stepinac"), gv("odgoj_vrijednosti"), gv("stepinac") / gv("odgoj_vrijednosti")))
cat("    => separation holds iff stepinac > foil (PROPOSAL §3).\n")

# --- slice-wide aggregate (combined 'near ANY spine hit' is the right notion here) ------------
spine_rx <- paste0("(?:", paste(unlist(probe[spine_keys]), collapse = "|"), ")")
near_any <- function(s) near_past_ent(s, spine_rx)
gi <- which(spine_hit & past_doc)
comb <- logical(nrow(slice)); comb[gi] <- vapply(txt[gi], near_any, logical(1))
d <- mean(past_doc[spine_hit]); g <- mean(comb[spine_hit])
cat(sprintf("\n[2/3] slice-wide past-anchoring: doc-level %.1f%% | windowed-genuine %.1f%% | incidental %.1f%% of doc\n",
            100 * d, 100 * g, 100 * (1 - g / d)))

# --- persist corrected outputs ----------------------------------------------------------------
slice2 <- slice[spine_hit, , drop = FALSE]
# refresh the stored probe flags + doc/combined-genuine on the corrected slice (stable schema)
pf <- as.data.frame(flags[spine_hit, , drop = FALSE]); names(pf) <- paste0("probe_", names(pf))
for (nm in names(pf)) slice2[[nm]] <- pf[[nm]]
slice2$past_anchor_doc     <- past_doc[spine_hit]
slice2$past_anchor_genuine <- comb[spine_hit]
saveRDS(slice2, file.path(out_dir, "slice.rds"))
write.csv(candidates, file.path(out_dir, "candidate_sites_of_memory.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
# stale pre-windowing checkpoint was built with the OLD probe -> remove so no run resumes stale.
raw_path <- file.path(out_dir, "_slice_raw.rds")
if (file.exists(raw_path)) { file.remove(raw_path); cat("\nremoved stale _slice_raw.rds (old-probe checkpoint)\n") }
cat("corrected slice.rds (", nrow(slice2), "rows) + candidate table written.\n")
