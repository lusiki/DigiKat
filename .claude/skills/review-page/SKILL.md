---
name: review-page
description: Multi-lens review of ONE DigiKat website page before publishing — checks claims-vs-data, a clean render, Croatian prose + diacritics, and accessibility, using the verifier and numeric-claim-verifier agents (and the domain reviewers for substance). Use when the user says "review this page", "is this page ready to publish", "check the diskurs/mapa page before deploy". A WEBSITE page — NOT a manuscript (use /review-paper for papers). Read-only; produces a findings report.
argument-hint: "<page> (e.g. mapa, mapa_stats, diskurs, dogadaji, baza, or a path)"
---

# /review-page — pre-publish review of a website page

## Instructions
1. **Resolve the page** from `$ARGUMENTS` (same mapping as `/render-page`: mapa, mapa_stats, diskurs,
   dogadaji→događaji, baza, or a path).
2. **Render / build check.** Confirm it renders (or static-verify if data/R absent) — delegate to the
   `verifier` agent.
3. **Claims vs data.** Launch the `numeric-claim-verifier` agent on the page's numeric claims.
4. **Substance (optional, heavier).** For an analytical page making interpretive claims, launch the
   `religion-media-domain-reviewer`; for text-analysis methods, the `croatian-nlp-reviewer`.
5. **Croatian prose + diacritics.** Spot-check the rendered HTML: literal UTF-8 diacritics, no mojibake,
   readable Croatian.
6. **Accessibility.** Alt text on figures, sensible heading order, descriptive link text.
7. **Synthesize** a single prioritized report (Critical/Major/Minor) + a publish / fix-first verdict.
   Single pass — no auto critic⇄fixer loop. Read-only.
