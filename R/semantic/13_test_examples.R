#!/usr/bin/env Rscript
# R/semantic/13_test_examples.R  —  Three intuition-building tests for the meaning-search store.
# Each test is designed to teach ONE thing about what "meaning search" actually does, so you can
# generalize to your own queries afterward. Run interactively (source it) or as a script.
#
#   Rscript R/semantic/13_test_examples.R
suppressPackageStartupMessages({ library(ragnar); library(here) })
source(here::here("R/semantic/12_query.R"))
st <- dk_store()

cat("\n################################################################\n")
cat("# TEST 1 — THE SYNONYM TEST\n")
cat("# Does it match MEANING, or just matching words? Search using a word\n")
cat("# that should NOT literally appear in a good result. If the top hits\n")
cat("# use DIFFERENT words for the same idea, that's semantic search working.\n")
cat("################################################################\n")
r1 <- dk_retrieve("djeca uče o Bogu u razredu", top_k = 5, store = st, snippet_chars = 130)
# Note: we searched "djeca uče o Bogu u razredu" (children learn about God in the classroom) —
# a plain-language description, NOT the technical word "vjeronauk" (religious education).
print(r1[, intersect(c("platform","date","similarity","snippet"), names(r1))], right = FALSE)
cat("\n>> LOOK FOR: do the results mention 'vjeronauk' or 'vjeroučitelj' even though\n")
cat(">>  the query never used that word? If yes, it matched the CONCEPT, not the string.\n")
cat(">>  A keyword search (Ctrl+F) would have returned ZERO results for this query.\n")

cat("\n\n################################################################\n")
cat("# TEST 2 — THE NEIGHBOR TEST\n")
cat("# Pick ONE real post and ask: 'what else in the corpus is like THIS?'\n")
cat("# This is the building block for finding syndicated copies, near-duplicates,\n")
cat("# and topic clusters — not a query you TYPE, but a query FROM a document.\n")
cat("################################################################\n")
seed <- dk_retrieve("papa Franjo bolestan", top_k = 1, store = st)
cat("Seed post (platform:", seed$platform[1], "| date:", as.character(seed$date[1]), "):\n")
cat(" ", seed$snippet[1], "\n\n")
neighbors <- dk_retrieve(seed$snippet[1], top_k = 6, store = st, snippet_chars = 130)
neighbors <- neighbors[neighbors$snippet != seed$snippet[1], ]   # drop the seed matching itself
print(neighbors[, intersect(c("platform","date","similarity","snippet"), names(neighbors))], right = FALSE)
cat("\n>> LOOK FOR: are the neighbors genuinely about the SAME specific event\n")
cat(">>  (not just 'the Pope' in general)? Tight neighbors = good candidates for\n")
cat(">>  'who syndicated this story' or 'find every post about this one event'.\n")

cat("\n\n################################################################\n")
cat("# TEST 3 — THE BOUNDARY TEST\n")
cat("# Ask a question that sits BETWEEN two topics on purpose. Meaning-search\n")
cat("# doesn't 'know' categories — it just finds nearest neighbors in meaning-space.\n")
cat("# This shows you where it draws a fuzzy line, and warns you it CAN blend topics.\n")
cat("################################################################\n")
r3 <- dk_retrieve("pobačaj i stav Crkve", top_k = 6, store = st, snippet_chars = 130)
# "pobačaj i stav Crkve" = "abortion and the Church's position" — a query that could pull
# EITHER theological commentary OR political/news coverage of abortion debates.
print(r3[, intersect(c("platform","date","data_source","similarity","snippet"), names(r3))], right = FALSE)
cat("\n>> LOOK FOR: a MIX of religious/theological posts AND political/news posts in\n")
cat(">>  the same result list. That mix is not a bug — it's the tool honestly showing\n")
cat(">>  you that 'abortion' sits between two discourses in your corpus (this is exactly\n")
cat(">>  the 'vocabulary migrating' finding the roadmap describes: theological -> political).\n")
cat(">>  Remember MEMORY.md: colour/filter by data_source + platform before reading any\n")
cat(">>  TREND into this — meaning search finds RELATED posts, it doesn't fix the corpus confound.\n")

cat("\n\n################################################################\n")
cat("# NOW TRY YOUR OWN — copy this line and change the query:\n")
cat("################################################################\n")
cat('  dk_retrieve("your question here", top_k = 10, store = st)\n\n')
