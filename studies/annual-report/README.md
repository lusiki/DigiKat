# Study: DigiKat annual report

- **Slug:** `annual-report`
- **Owner/editor:** Luka Šikić
- **Status:** two editions built and mechanically checked (2025, 2024); awaiting PI sign-off before publication
- **Created:** 2026-08-07

## Editions

The chain is parameterised by reporting year, not copied per edition. `AR_YEAR` selects the edition
and everything derives from it — output directory, calendar length, comparison mode, special chapter
and manuscript template. Default is 2025.

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/01_report_aggregates.R   # 2025
$env:AR_YEAR = '2024'; & 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/01_report_aggregates.R
```

| Edition | Year | Posts | Collected days | Special chapter | Checks |
|---|---:|---:|---:|---|---:|
| 1 | 2025 | 124 346 | 351 of 365 | `moral-economy` | 72/72 |
| 2 | 2024 | 56 923 | 207 of 366 | `inflation-salience` | 72/72 |

## Product question

Can DigiKat sustain a recurring, decision-maker-first annual report whose stable indicators remain
comparable, whose special chapter can rotate, and whose empirical claims are fully generated and
reviewable?

## Edition 1 — reporting year 2025

- Dataset: `data/digikat_corpus.rds` (413 985 posts, one inclusion rule across both collection eras),
  read-only. **Not** the accumulator, which is what the completed papers stay pinned to.
- Reporting year: 124 346 posts across 351 collected days. Collection stopped for fourteen days,
  1–14 September 2025; the interruption is absent from the accumulator too, so it is a collection
  outage rather than a corpus-rule artefact. It is disclosed in the report, excluded from every
  average, drawn as a break in the year line, and removed from both halves of the one comparison the
  report makes.
- Reading layers: the NLP generation of 2026-08-10 (and the `data/page-ready/` summaries rebuilt from
  it), which is drawn from the corpus itself — 6 203
  documents for themes (5,0 % of the corpus year) and 2 479 for tone (2,0 %). Stage 02 still matches
  every document against the corpus before using it; that check now passes at 100 % and stays in place
  as a guard against a future run against an older generation.
- One instrument-comparable movement: second half of 2024 against second half of 2025, entirely
  inside the post-2024 collection stream, with the source count reported beside the volume so a
  widened watch list cannot be read as a livelier debate.

## Method

Descriptive analysis, generated tables and figures, an explicit indicator codebook, and a
Croatian-language report with an English executive summary. Every prose scalar is installed from
`output/annual_report_derived.csv`; every table is installed as a generated fragment and re-verified
byte-for-byte.

## Outputs

- Product contract: `CHARTER.md` · measures: `INDICATORS.md` · build: `PIPELINE.md` · gaps: `GAPS.md`
- Voice, visual system and conversion design: `.claude/rules/annual-report-writing.md`
- Tracked aggregates, figures and fragments: `output/`
- Manuscript template: `REPORT_TEMPLATE.qmd` (prose and tokens only, no numbers)
- Typeset: `typeset/report.css` (HTML) and `typeset/typst-template.typ` + `typst-show.typ` (PDF)
- Rendered report and named profiles: gitignored `output/private/`

Publication runs through `/deploy` after PI sign-off, per the charter. Until then the study is not in
`_quarto.yml` and writes nothing to `docs/`.

## Publication

Both formats are copied to `assets/izvjestaji/godisnji-pregled-2025.{html,pdf}` and linked from the
landing-page hero beside the database and the maps. The render chain never writes there: publication
is a separate, deliberate act after sign-off, so a rebuild cannot silently change what is published.

## Open editorial questions for the PI

1. **Uvodnik.** The writing guide refers to an editor's note; the charter's permanent anatomy does not
   list one. The charter won, so edition 1 has none.
2. **Composite headline index.** Standing furniture in the writing guide, but a measure, and
   `INDICATORS.md` has none. It appears as a gap panel rather than as an invented number.
3. **Annex depth.** The charter says one page per approved outlet; edition 1 prints six compact
   profiles spanning four quadrants and five platforms, because 51 outlets clear the publish gate.
4. **Label ratification.** The source sidecar is still `proposed` and covers 34,5 % of annual volume;
   every confessional/secular figure is labelled indicative until that changes.
5. **No commercial direction.** On PI instruction (2026-08-17), the remaining commissioned-analysis
   teasers and the boxed demonstration were removed. Both language editions now contain only neutral
   contact information for questions about data and method.
6. **English edition.** The complete report, including tables and word-bearing figures, is generated
   in English from the same checked aggregate and scalar registries as the Croatian edition.

## Environment note

R 4.6.0 and Quarto 1.9.38. `renv::status()` reports the broader project missing `lmtest` and
`sandwich`; neither is imported by this study, so the waiver is scoped and stage 00 verifies the
packages actually used. Stage 06 refuses any Quarto older than 1.8 — this machine also carries a
per-user Quarto 1.6 whose bundled Typst cannot compile the report template.

## Edition 2 — reporting year 2024 (back-edition, built 2026-08-10)

2024 is the year the collection instrument changed, and the corpus shows it twice over.

- **56 923 posts on 207 collected days of 366.** Two interruptions: **9 January – 31 May** (144 days)
  and **16 – 30 September** (15 days). The first swallows **Easter, 31 March 2024** — the year's
  largest Catholic event is absent from the data, and the report says so in the summary, in the
  methods box, on the year line and in the events chapter.
- **The seam falls mid-year.** H1 is 6 710 posts on 38 collected days in the `pre2024` stream; H2 is
  50 213 on 169 days in `post2024`. The annual total is therefore a lower bound, not an estimate of
  the year.
- **No year-over-year movement exists.** The post-2024 stream begins 2024-07-01, so H2 2023 sits on
  the far side of the seam and edition 1's one comparison has no counterpart here. The recurring
  chapter instead publishes a within-year step, **Q3 2024 → Q4 2024 inside the stream, in posts per
  collected day**, so the September interruption cannot read as a fall. The Advent-and-Christmas
  confound is named in the prose, the caption and the table note, and the missing year-over-year
  measure is printed as a gap panel.
- **Both attention arcs are fixed feasts** — Christmas (24–25 December, peak 1 050 posts at 7,2 sd)
  and Assumption (15 August, 806 posts at 4,9 sd). No peak in the year comes from a dispute.
- **Reading layers:** 2 839 theme documents (5,0 % of the corpus year) and 1 134 tone documents
  (2,0 %), both matched to the corpus at 100 %.
- **Special chapter:** `inflation-salience`, whose window covers 2021–2024 and whose repricing
  coverage peaks in 2024. Its values come from the accumulator, not the corpus; the table note says
  so, because its denominators do not match the rest of the report.

## Log

- 2026-08-07 — pilot plan approved; workspace scaffolded; reporting year fixed to 2025.
- 2026-08-07 — Izvještaj 0 produced from accumulator-vintage aggregates; independent review returned
  **revise and re-pilot**.
- 2026-08-10 — typeset redesign (Palatino, modular scale, asymmetric grid, chapter openers, cover
  spark, back cover, two box species); figure and table words moved out of the PNGs into real text;
  the service menu removed; the edition published to the site. Design settled in
  `.claude/rules/annual-report-writing.md` under "Typeset design — fixed across editions".
- 2026-08-10 — the official corpus was cut and `data/processed/` rebuilt from it, which made every
  Izvještaj 0 figure stale (2025 is 124 346 posts, not the accumulator's 236 166). The chain was
  rebuilt end to end against the corpus, the September collection outage was found and handled, and
  edition 1 was produced: 9 figures, 10 generated tables, 52 scalars, 57 mechanical checks passing,
  HTML and PDF rendered outside the repository.
- 2026-08-10 — the chain was parameterised by reporting year and edition 2 (2024) built as a
  back-edition. Outputs moved to `output/<year>/`; edition 1 was re-run afterwards and reproduces
  **byte for byte** (every aggregate, all 55 scalars and both summaries identical). Both editions now
  pass 72/72 mechanical checks and render to private HTML and PDF.
