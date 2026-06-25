---
name: review-paper
description: Simulate a referee review of a DigiKat thematic-study manuscript by delegating to scholar-respond's peer-review simulation, calibrated to a DESCRIPTIVE methods tilt (sampling frame, measurement/lexicon validity, representativeness of the 2–5% sample, false-positive rate of the term filter, encoding integrity) — NOT DiD/IV econometrics. Use when the user says "review my paper", "referee this draft", "is this submission-ready", "mock peer review". For a website page use /review-page instead.
argument-hint: "<manuscript path>"
---

# /review-paper — simulated peer review (descriptive tilt)

## Instructions
1. **Load** `.claude/references/discipline-card-digikat.md` so the methods-referee uses the `descriptive` tilt
   and the right venues / citation style.
2. **Delegate** to `scholar-skill:scholar-respond` (peer-review simulation: editor + referees). Steer the
   methods referee toward DigiKat's real risks: sampling frame, lexicon/measurement validity, the ≥2-term
   selection into the corpus, false positives, platform-coverage gaps, encoding integrity, and the
   representativeness of the 2–5% sample.
3. **Augment** with the DigiKat agents where useful: `croatian-nlp-reviewer` (text-analysis methods),
   `religion-media-domain-reviewer` (substance), `numeric-claim-verifier` (every number traces to data).
4. **Output** a prioritized revision checklist. Do not rewrite the manuscript unless asked.

## Note
DigiKat studies are descriptive/interpretive — do NOT impose causal-identification machinery (parallel
trends, IV first-stage, etc.). Citation style is APA/Chicago, not AEA.
