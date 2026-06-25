---
name: check-lexicon
description: Sanity-check DigiKat's religious-term regexes (R/religious_terms.R) and the sentiment/emotion lexicons (CroSentilex, CroSentilex Gold, lilaHR) against a Croatian fixture — every regex compiles, encoding is intact, inflected forms are covered, false positives are scanned, and lexicon join keys are valid. Use when the user says "check the lexicon", "validate the terms", "test the religious filter", "are we missing word forms", or after editing the term list or a lexicon. Read-only; recommends fixes, does not edit.
argument-hint: "(no args — or a specific term/lexicon to focus on)"
---

# /check-lexicon — validate terms + lexicons

## Instructions
1. **Compile check.** Read `R/religious_terms.R`; confirm every regex compiles (test in R if available, else
   statically). Confirm the `term`/`root`/`regex` vectors are equal length and UTF-8.
2. **Coverage.** Against a small Croatian fixture (or a corpus sample), check inflected forms match:
   biskup/biskupa/biskupi/biskupu; misa/mise/misi/misu; hodočašće/hodočašća/hodočašću; papa/pape/papi/papu.
   Flag roots whose alternations look incomplete (silent under-match).
3. **False positives.** Scan for over-broad patterns that would match secular words (e.g. `red…` → "redovito",
   `gosp…` → "gospodarstvo", `put…` → "putovanje"). Report risky patterns.
4. **Lexicon integrity.** For CroSentilex / CroSentilex Gold / lilaHR: confirm they load from
   `resources/lexicons/` (NOT `./Codes/`), are UTF-8, and that join keys (lemmas) align with the corpus
   normalization. Report estimated join coverage.
5. **Encoding.** Confirm diacritics survive end-to-end; flag any mojibake with file + byte signature.
6. **Report** a prioritized list of recommended fixes. Do NOT edit files. If R is absent, do the static checks
   and hand the runtime coverage test off (see `CLAUDE.local.md`).

## Note
Changing the term list or the ≥2 rule redefines the corpus — that's a plan-first / HARD-GATE change.
For deep linguistic review, escalate to the `croatian-nlp-reviewer` agent.
