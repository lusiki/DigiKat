#!/usr/bin/env Rscript
# 07_reannotation_score.R — score the blind re-annotation against the June labels.
#
# What this can and cannot establish. Both annotations were produced by large language
# models, so what follows is inter-model reliability, not agreement with a human gold
# standard. No human read this validation set and the manuscript says so plainly. The
# re-annotation was run by a different model from the three that produced the June labels,
# which is a stronger test than a fourth run of the same model, but it is still the same
# model family; a genuinely cross-family check is noted as unmet in RECONSTRUCTION.md.
#
# Writes into output/: reannotation_agreement.csv, reannotation_confusion.csv,
# reannotation_by_stratum.csv, reannotation_disputed.csv, reannotation_errors.csv.

source("studies/inflation-salience/_lib.R")

rule("07_reannotation_score.R")

key <- fread(file.path(PRIVATE, "reannotation_key.csv"), encoding = "UTF-8")
bd  <- file.path(PRIVATE, "batches")
fs  <- list.files(bd, pattern = "^labels[0-9]+\\.csv$", full.names = TRUE)
if (!length(fs)) stop("no labels*.csv in ", bd, " — run the annotation first")

# The note field is free text and at least one annotator left commas in it unquoted, which
# breaks a normal CSV read and silently truncates a batch. Only the first five fields carry
# labels, so the line is split on the first five commas and everything after them is the
# note. Nothing is dropped and nothing is guessed.
read_labels <- function(f) {
  ln <- readLines(f, encoding = "UTF-8", warn = FALSE)
  ln <- ln[nzchar(trimws(ln))]
  ln <- ln[-1L]                                    # header
  m  <- stri_match_first_regex(ln, "^\\s*\"?([^,\"]+)\"?\\s*,\\s*([01])\\s*,\\s*([01])\\s*,\\s*([01])\\s*,\\s*\"?([A-Za-z_]+)\"?\\s*(?:,(.*))?$")
  bad <- which(is.na(m[, 1]))
  if (length(bad)) msg("  unparsed lines in ", basename(f), ": ", length(bad))
  data.table(item = m[, 2], infl = as.integer(m[, 3]), link = as.integer(m[, 4]),
             foreign = as.integer(m[, 5]), register = m[, 6], note = m[, 7])[!is.na(item)]
}
new <- rbindlist(lapply(fs, read_labels), fill = TRUE)
new <- unique(new, by = "item")
setnames(new, c("infl", "link", "foreign", "register"),
         c("n_infl2", "n_link2", "n_foreign2", "n_register2"), skip_absent = TRUE)
new[, n_register2 := fifelse(n_register2 == "cost_relig_life", "crl", n_register2)]

msg("batches read: ", length(fs), " | items returned: ", nrow(new), " | items expected: ", nrow(key))
miss <- setdiff(key$item, new$item)
if (length(miss)) msg("  MISSING from the re-annotation: ", paste(miss, collapse = ", "))

d <- merge(key, new[, .(item, n_infl2, n_link2, n_foreign2, n_register2)], by = "item")
d[, `:=`(register = fifelse(c_link == 0L, "none", register))]
msg("  scored items: ", nrow(d), "\n")

## ---------------------------------------------------------------- kappa -----

# Cohen's kappa. Chance-corrected, so it does not flatter a lopsided axis such as
# `foreign`, where almost everything is domestic and raw agreement is high by default.
kappa2 <- function(a, b) {
  lv <- union(unique(a), unique(b))
  tb <- table(factor(a, lv), factor(b, lv))
  n  <- sum(tb)
  po <- sum(diag(tb)) / n
  pe <- sum(rowSums(tb) * colSums(tb)) / n^2
  if (isTRUE(all.equal(pe, 1))) return(c(agree = po, kappa = NA_real_))
  c(agree = po, kappa = (po - pe) / (1 - pe))
}

rule("Agreement, June labels against the blind re-annotation")
axes <- list(
  list(nm = "is it about the cost of living", a = d$c_infl,    b = d$n_infl2,    sub = rep(TRUE, nrow(d))),
  list(nm = "is religion genuinely linked",   a = d$c_link,    b = d$n_link2,    sub = d$c_infl == 1L),
  list(nm = "domestic or foreign inflation",  a = d$c_foreign, b = d$n_foreign2, sub = d$c_link == 1L),
  list(nm = "what the post is about",         a = d$register,  b = d$n_register2,
       sub = d$c_link == 1L & d$register != "disputed")
)
ag <- rbindlist(lapply(axes, function(x) {
  s <- x$sub & !is.na(x$b)
  k <- kappa2(x$a[s], x$b[s])
  data.table(axis = x$nm, n = sum(s), agreement = round(k[["agree"]], 3),
             kappa = round(k[["kappa"]], 3))
}))
print(ag)
fwrite(ag, file.path(OUT, "reannotation_agreement.csv"))

msg("\n  The axes are scored where they are defined: linkage only on items both runs could")
msg("  reach, foreign and register only on items the June run judged linked. Register")
msg("  excludes the disputed cases, which are adjudicated separately below.")

## ------------------------------------------------------------ confusion -----

rule("Register — where the two runs part company")
cf <- d[c_link == 1L & register != "disputed" & !is.na(n_register2),
        .N, by = .(june = register, reannotation = n_register2)]
cm <- dcast(cf, june ~ reannotation, value.var = "N", fill = 0L)
print(cm)
fwrite(cf, file.path(OUT, "reannotation_confusion.csv"))

## ------------------------------------------------------------- strata -----

rule("Agreement by stratum — which parts of the pipeline are solid")
st <- d[, .(n = .N,
            infl_same    = mean(c_infl == n_infl2, na.rm = TRUE),
            link_same    = mean(c_link == n_link2, na.rm = TRUE),
            foreign_same = mean(c_foreign == n_foreign2, na.rm = TRUE),
            reg_same     = mean(register == n_register2, na.rm = TRUE)), by = stratum]
st[, (2:5 + 1) := lapply(.SD, function(x) round(x, 3)), .SDcols = 3:6]
print(st[order(-n)])
fwrite(st, file.path(OUT, "reannotation_by_stratum.csv"))

## ---------------------------------------------- the disputed register cases -----

rule("The disputed register cases, adjudicated")
dp <- d[stratum == "disputed", .(item, rid, reannotation = n_register2)]
msg("  disputed cases carried into the re-annotation: ", nrow(dp))
res <- dp[, .N, by = reannotation][order(-N)]
print(res)
msg("\n  resolved to a substantive register: ", sum(dp$reannotation != "disputed"),
    " of ", nrow(dp))
msg("  still disputed after adjudication  : ", sum(dp$reannotation == "disputed"))
fwrite(dp, file.path(OUT, "reannotation_disputed.csv"))

## ------------------------------------------------------------ error audit -----

rule("Error audit — where the disagreements sit")
err <- d[c_infl != n_infl2 | (c_infl == 1L & c_link != n_link2) |
         (c_link == 1L & c_foreign != n_foreign2) |
         (c_link == 1L & register != "disputed" & register != n_register2)]
msg("  items on which the two runs differ on at least one axis: ", nrow(err),
    sprintf("  (%.0f%%)", 100 * nrow(err) / nrow(d)))
ea <- err[, .(n = .N), by = .(stratum)][order(-n)]
print(ea)
fwrite(err[, .(item, rid, stratum, c_infl, n_infl2, c_link, n_link2,
               c_foreign, n_foreign2, register, n_register2)],
       file.path(OUT, "reannotation_errors.csv"))

rule("What this changes for the headline counts")
# How much would the measured core move if the re-annotation replaced the June labels on
# the sampled items? Reported as a rate, since the sample is stratified and not a random
# draw from the pool.
core_j <- d[c_infl == 1L & c_link == 1L & c_foreign == 0L]
core_n <- d[n_infl2 == 1L & n_link2 == 1L & n_foreign2 == 0L]
msg("  in the sample, core under the June labels     : ", nrow(core_j))
msg("  in the sample, core under the re-annotation   : ", nrow(core_n))
msg("  agreeing on core membership                   : ", length(intersect(core_j$item, core_n$item)))
msg("\n  The sample is stratified, so these are not estimates of the pool. They say how")
msg("  stable the core boundary is on the items chosen to stress it hardest.")

msg("\ndone.")
