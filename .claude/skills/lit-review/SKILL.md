---
name: lit-review
description: Run a literature review for a DigiKat thematic study by delegating to the scholar-lit-review skill with DigiKat's discipline card (sociology of religion / communication studies / digital humanities; APA/Chicago; Croatian + English venues), augmented with web search via the perplexity MCP. Use when the user says "lit review", "find related work", "what's been written about X", "map the literature on digital religion / Catholic media". Produces a structured literature map + gap statement.
argument-hint: "<topic> (e.g. 'Catholic influencers on YouTube', 'pilgrimage tourism online')"
---

# /lit-review — literature review (DigiKat-calibrated)

## Instructions
1. **Load context.** Read `.claude/references/discipline-card-digikat.md` so the field, venues, and citation
   style are correct (NOT econ/AER defaults). Read any local `references.bib` / `studies/<slug>/refs.bib`.
2. **Delegate** to `scholar-skill:scholar-lit-review` for the structured search + synthesis.
3. **Augment with web** via the perplexity MCP (`perplexity_research` / `perplexity_search`) for recent and
   Croatian-language sources the local library may miss.
4. **Verify** — do NOT invent citations; mark anything unconfirmed as `UNVERIFIED`. Prefer items that can be
   added to `references.bib` with a stable key (Better BibTeX).
5. **Output** a literature map + a precise gap statement naming the closest prior work. Save under
   `studies/<slug>/` if tied to a study.

## Graceful degradation
If the perplexity MCP is unavailable, proceed with the local library and say web augmentation was skipped.
