# Plan: Update "Tematska istraživanja" nav with 5 live working-paper links

## Context

The "Tematska istraživanja" navbar menu (`_quarto.yml`) currently lists 5 thematic studies
(`pages/studije/*.qmd`), all identical "U pripremi" (in-preparation) placeholder stubs with
only a research question and corpus slice — no actual findings, because none of the 5 studies
has produced a draft yet.

Meanwhile, 5 *other* DigiKat sub-projects (separate GitHub repos, not yet folded into this
repo's `studies/` scaffold) already have substantive draft papers/analyses rendered as
self-contained HTML on raw.githack.com / GitHub Pages:

1. `https://raw.githack.com/lusiki/Redovnicke-zajednice/main/R/analysis_v3.html`
2. `https://raw.githack.com/lusiki/Mapping-Catholic-Digital-Media-Space/main/paper/hr/drafts/attention_markets_paper_hr_v7.html`
3. `https://lusiki.github.io/Katolicki_Influenceri/code/analysis_hr.html`
4. `https://lusiki.github.io/Memorijalni-okvir/manuscript/manuscript_one.html`
5. `https://raw.githack.com/lusiki/Church-and-dezinfo/main/papers/03_framing_paper_2.html`

The user wants the nav menu to point at real, current work instead of empty stubs, and is fine
with replacing the existing 5 entries so the menu reflects what's actually linked. I fetched and
read all 5 external documents in full (extracted text, not just titles) to write accurate,
non-hallucinated summaries — see content notes below.

**Outcome:** 5 updated `pages/studije/*.qmd` pages, one per external paper, each with an accurate
Croatian summary (RQ, corpus, method, key finding) + a real external hyperlink to the live
analysis/paper, replacing the "U pripremi" stub content. `_quarto.yml` nav labels/hrefs updated
to match new filenames/titles where the topic changed. Existing filenames are reused for
whichever new topic is the closest match, to minimize nav churn — full mapping below.

## Content notes per paper (verified by reading full extracted text, not just title)

1. **Redovnicke-zajednice** → *Medijska zastupljenost redovničkih zajednica u hrvatskom
   digitalnom prostoru*. Attention-economy analysis of Croatian religious orders' media coverage,
   2021.–2025. 9 hypotheses / 3 blocks: concentration (Gini/HHI), gender asymmetry (male vs.
   female orders), portal typology (mainstream/religious/regional/local editorial logic). Has full
   results + conclusion: attention highly concentrated, real gender asymmetry, 4 portal types
   differ in tone/topic. Published 10.2.2026. Renamed to `redovnicke-zajednice.qmd` — see
   file-mapping decision below.

2. **Mapping-Catholic-Digital-Media-Space** (`attention_markets_paper_hr_v7`) → *Tržišta pažnje u
   religijskim digitalnim medijima*. The flagship attention-economy paper on the full DigiKat
   corpus (608.879 objava, 8 platforms), authors Šikić/Palić/Kovačić, 5 hypotheses (power-law
   distribution, institutional attention modalities, sentiment-attention coupling, liturgical time
   structuring, platform-specific concentration). Full results table: H1–H4 confirmed
   (indicatively), H5 not confirmed. Published 9.3.2026. Still has one `[UMETNUTI...]` placeholder
   (Cohen's kappa) — genuinely a live draft (v7), say so honestly.

3. **Katolicki_Influenceri** → *Katolički influenceri i institucionalni deficit pažnje*. Compares
   Catholic influencers vs. institutional church actors on attention/engagement, 5 hypotheses
   (power-law inequality among influencers, institutional attention deficit, platform-strategy
   divergence, thematic niche differentiation via Jensen-Shannon divergence, success-factor model).
   Full results + conclusion. Published 3.2.2026.

4. **Memorijalni-okvir** → *Memorijalni okvir kao treći registar u medijskoj reprezentaciji
   hrvatskih marijanskih i drugih katoličkih odredišta (2021.–2024.)*. Authors Topić
   Crnoja/Palić/Šikić. Computational framing analysis of 13.921 articles about 10 Croatian
   Catholic pilgrimage sites; finds a third "memorial" frame (war memory/victims) beyond the usual
   religious/tourism dyad — 15,1% of articles, concentrated in Voćin (42%, site of a 1991 massacre).
   Chi-square + multinomial logistic regression + structural topic model for validation. Abstract
   field is literally "TBD" in the source but the body (through results) is complete — say the
   abstract is pending, not the whole paper. Published 28.4.2026.

5. **Church-and-dezinfo** (`03_framing_paper_2`) → *Tko govori iz katoličkoga medijskog prostora*.
   8 narrative frames (moral decay, external threat, institutional distrust, traditional values,
   sovereignty, conspiracy, faith defense, media criticism) across 443.138 web articles, comparing
   Catholic media to others AND distinguishing *official* church media (IKA, Glas Koncila) from
   *Catholic-aligned* portals (narod.hr, dnevno.hr) — finds the aligned portals build a political/
   antagonistic layer the official media don't, and (counter to public perception) official media
   invoke "traditional values" MORE than aligned portals. Author line is "(anonimizirano za
   recenziju)" — i.e. submitted/under-review, say so. Published 14.4.2026.

## File-mapping decision (old slug → new content)

All 5 existing files are equally generic ("U pripremi" stubs), so there's no topical overlap to
preserve in general — except one: `hodocasnicki-turizam.qmd` ("hodočasnički turizam") is genuinely
still an apt filename for the memorial-frame paper, since that paper's subject is exactly
hodočasnička/marijanska odredišta (pilgrimage sites). Keep that file, edit in place. The other 4
old slugs (self-help-youtube, demokrscanstvo, katolicko-obrazovanje, katolicki-sveci-i-svetice)
have no topical match to any of the remaining 4 papers, so keeping those names would mislabel the
new content in the URL — rename via `git mv`. Chosen mapping:

| Old file (nav label) | New content | New file | New nav label |
|---|---|---|---|
| `hodocasnicki-turizam.qmd` | memorial frame / pilgrimage sites | *(unchanged)* | "Memorijalni okvir hrvatskih katoličkih odredišta" |
| `self-help-youtube.qmd` | attention markets (flagship) | `trzista-paznje.qmd` | "Tržišta pažnje u religijskim digitalnim medijima" |
| `demokrscanstvo.qmd` | religious orders (redovničke zajednice) | `redovnicke-zajednice.qmd` | "Medijska zastupljenost redovničkih zajednica" |
| `katolicko-obrazovanje.qmd` | Catholic influencers | `katolicki-influenceri.qmd` | "Katolički influenceri i institucionalni deficit pažnje" |
| `katolicki-sveci-i-svetice.qmd` | Church & disinformation framing | `crkva-i-dezinformacije.qmd` | "Tko govori iz katoličkoga medijskog prostora" |

Execution: `git mv` old→new for the 4 renamed files, edit `hodocasnicki-turizam.qmd` in place,
then update all 5 `href:`/`text:` pairs under "Tematska istraživanja" in `_quarto.yml` to match.

## Page content template (per new/updated `pages/studije/*.qmd`)

Follow the site's existing external-link convention (`[Poveznica](url)` — see `pages/resources.qmd`,
`pages/schedule.qmd`) and voice-and-style.md's page-architecture rule (§9: title+informative
subtitle, `date: last-modified`, category badges, ≥1 framing sentence before any block). Structure:

```yaml
---
title: "<canonical Croatian title from the paper>"
subtitle: "<informative, non-duplicative — one-line hook, not a repeat of title>"
date: last-modified
categories: ["Tematsko istraživanje", "<status badge — see below>"]
---
```

Status badge per paper, honestly reflecting what I read (no overclaiming "gotovo" if a paper
literally has TBD/anonymized/placeholder markers):
- Redovničke zajednice → "Nacrt dostupan" (draft available; has full results+conclusion)
- Tržišta pažnje → "Nacrt u izradi" (v7, live draft, one placeholder value remains)
- Katolički influenceri → "Nacrt dostupan"
- Memorijalni okvir → "Nacrt u izradi" (abstract literally TBD)
- Crkva i dezinformacije → "U recenziji" (anonymized-for-review = submission stage)

Body sections (replacing the old "U pripremi" callout + Istraživačko pitanje + Isječak korpusa +
Status pattern with a "this now has real content" version):

1. Optional short lead sentence in third person (matches analytical-page register, voice-and-style §3).
2. `## Istraživačko pitanje` — the paper's actual RQ/hypotheses framing, in Croatian, paraphrased
   (not lifted verbatim beyond short quoted fragments), based on the extracted Sažetak/Uvod I read.
3. `## Podaci i metode` — corpus size + period + method, e.g. "13.921 članaka o deset hrvatskih
   katoličkih odredišta (2021.–2024.), rječničko označavanje registara + strukturalni model tema."
4. `## Ključni nalaz` — the one or two headline findings, paraphrased from the paper's own
   Zaključak/Rasprava section (this is the part the old stub never had, since nothing had results
   yet).
5. `## Status` — one sentence with the honest status badge context + the external link:
   "Pun nacrt dostupan je na [Poveznica](url)." Keep the existing internal cross-link style
   (`[Projektni raspored](../schedule.qmd)`) where a "part of the project" sentence still fits.

Numbers get period-grouping (`608.879`, `13.921`) and Croatian percent format (`15,1 %`) per
voice-and-style §7, matching the source since I'm quoting the papers' own reported figures, not
computing anything new from `data/processed/*.rds` (these are external papers — no local
recomputation expected or possible without their code/data).

## Files to change

- `_quarto.yml` — the 5 `text:`/`href:` pairs under `- text: "Tematska istraživanja"` (lines ~40–51).
- `pages/studije/hodocasnicki-turizam.qmd` — rewrite in place (memorial-frame paper).
- `pages/studije/self-help-youtube.qmd` → `git mv` to `pages/studije/trzista-paznje.qmd`, rewrite.
- `pages/studije/demokrscanstvo.qmd` → `git mv` to `pages/studije/redovnicke-zajednice.qmd`, rewrite.
- `pages/studije/katolicko-obrazovanje.qmd` → `git mv` to `pages/studije/katolicki-influenceri.qmd`, rewrite.
- `pages/studije/katolicki-sveci-i-svetice.qmd` → `git mv` to `pages/studije/crkva-i-dezinformacije.qmd`, rewrite.

No `data/`, no R pipeline, no lexicon — pure content/nav — so this is NOT a HARD-GATE item and
doesn't need the numeric-claim-verifier (no local corpus numbers being asserted) or r-reviewer.

## Verification

1. `git mv` the 4 renamed files first (preserves history) — from repo root.
2. Edit all 5 `.qmd` bodies + `_quarto.yml` nav block.
3. Render each touched page individually from repo root (per quarto-verification.md §1):
   ```
   export PATH="/c/Program Files/R/R-4.4.1/bin:$PATH"
   QUARTO="/c/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe"
   "$QUARTO" render pages/studije/hodocasnicki-turizam.qmd
   "$QUARTO" render pages/studije/trzista-paznje.qmd
   "$QUARTO" render pages/studije/redovnicke-zajednice.qmd
   "$QUARTO" render pages/studije/katolicki-influenceri.qmd
   "$QUARTO" render pages/studije/crkva-i-dezinformacije.qmd
   ```
   These are plain content pages (no R chunks reading `data/`), so they render anywhere — this
   machine has R+Quarto, so actually render, don't just static-check.
4. Post-render sanity per quarto-verification.md §8: confirm `docs/` changed only for these 5 pages
   (+ their `_files/` if any). User confirmed: clean up the 4 stale old-slug outputs by directly
   deleting `docs/pages/studije/{self-help-youtube,demokrscanstvo,katolicko-obrazovanje,katolicki-sveci-i-svetice}.html`
   (and matching `*_files/` dirs if Quarto produced any for these no-code pages) rather than a full
   site render — targeted deletion, no HARD-GATE needed. Check `git status` shows no other scatter
   outside `docs/`.
5. Confirm the nav renders correctly by checking the rendered `_site.yml`-derived navbar HTML in
   one output page (grep for the 5 new `text:` labels).
6. Spot-check Croatian diacritics survived in each rendered HTML (č ć ž š đ literal, not entities).
7. Do NOT run a full-site `quarto render` (would touch `docs/` broadly and is a HARD-GATE action) —
   page-by-page render + targeted deletion of the 4 stale files is sufficient and user-approved.
8. Hand off to `/commit` only after user reviews rendered output (not auto-committing).
