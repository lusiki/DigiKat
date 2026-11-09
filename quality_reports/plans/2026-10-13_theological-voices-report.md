# Tko je preuzeo ulogu teologa? — report in the "Glasna tema, tiha većina" method

Approved by the PI 2026-10-13 ("please run it on the 413,000-row corpus … named top 50 … names inside
the articles … model-code it, no check against a hand-coded subset … go on to create this kind of report").

## Goal
A Croatian PDF report that answers *Tko je preuzeo ulogu teologa u hrvatskom javnom prostoru?* and the
three practical questions a researcher asked (actor-type breakdown, open aggregates, top 50 by
engagement + room for mandate / education / authority / theme / tone coding), built with the
analytical and editorial rules reverse-engineered from the Merkat Media report "Glasna tema, tiha većina".

## Input
The OFFICIAL corpus, 413 985 × 54, read in place from the Dropbox project copy via
`DIGIKAT_CORPUS_PATH` (sha256 15473a61… verified equal to `data/digikat_corpus_manifest.json`).
Read-only. The accumulator and the local 612k snapshot are NOT used. Nothing is copied into the repo.

## Method (rules taken from the reference report)
- Three evidence tiers, each finding labelled: **korpus** (all posts), **zatvoreni popis** (closed list
  of named theological voices), **pregledani uzorak** (model-coded sample of doctrinal posts).
- Fixed vocabulary: spomen (name in a post), izjava (statement attributed to that person, once per post
  and person), glas (a speaker given voice in a coded post), objava (one post), priča (one story).
- Volume vs voice, mention vs statement, post vs story, concentration, absence; within-platform
  comparisons; same-months comparisons across years; the 2024 instrument change named; small bases
  flagged; leave-one-story-out robustness; cover numbers reconcile with inner pages.
- One finding per page: kicker question, numeric headline, contrast deck, one chart, two columns
  (what it shows / what limits it), source line, progress footer.

## Steps
1. `studies/theological-voices/01_prepare.R` — load corpus, schema audit, actor classification
   (reuse `studies/catholic-influencers/actor_classification.R` + registries), doctrinal dictionary
   flag (`R/lib/thematic_dictionaries.R`), story keys (normalised title).
2. `02_sources.R` — named top 50 by engagement (overall and within platform) with actor group and
   blank coding columns; actor-type aggregates; concentration.
3. `03_voices.R` — discover candidate names via role cues (biskup, nadbiskup, kardinal, papa, don, fra,
   vlč., mons., p., s., teolog, prof. dr.), curate a closed list with role categories, count mentions
   vs attributed statements per person and per year.
4. `04_sample.R` — draw a random sample of ~300 doctrinal web posts (+ story ids); model-code with
   Claude subagents for: who interprets doctrine (role), authority invoked, theme, tone, whether the
   interpreter has a formal mandate / is an academic theologian. No human validation (PI decision);
   the report says so in Metoda.
5. `05_report` — Typst report in the reference design (navy/cream/teal/red), charts in ggplot2 or
   native Typst; all numbers from generated tables; verification script.

## Outputs
Code in `studies/theological-voices/`. Named tables, coded sample and the PDF stay in the ignored
`studies/theological-voices/output/private/`. Identity-free aggregates in `output/`. No site render,
no publication, no change to tracked `data/**`.

## Completed 2026-10-13
All stages ran against the hash-verified official corpus (409 007 posts after duplicate handling).
117-person closed list; 300-post sample and the top 50 coded by Claude subagents per CODEBOOK.md,
without human validation. 34-page PDF built by `build_report.py` from `report_data.json` only.
Checks: all 50 names present, diacritics intact, no stray markup, disclosure guard passed, private
outputs git-ignored, every page rendered and visually reviewed. Nothing committed or published.
Deviation: fonts are Palatino Linotype + Segoe UI (the reference's Source Serif / IBM Plex download
was declined; Sitka Text is a variable font Typst cannot set reliably).

## Rejected
- Using the local 612k snapshot (what `studies/theological-authority` used): not the official corpus.
- Copying the corpus into `data/`: unnecessary; the env var reads it in place.
