---
paths:
  - "studies/annual-report/**"
---

# Annual & Mid-Year Report Writing Guide

How DigiKat's flagship annual report and mid-year "puls" brief are WRITTEN and DESIGNED.
Division of authority: `studies/annual-report/CHARTER.md` governs structure, cadence,
independence, and change control — on structural conflict, the charter wins.
`INDICATORS.md` governs measures. THIS file governs prose voice, visual system, and
conversion design. Production mechanics live in `PIPELINE.md`.

## Identity and purpose

Two products from one pipeline: the annual flagship (~25–30 pp, World Communications
Day) and the mid-year puls brief (8–12 pp, ~November, strict subset, no special chapter
or annex). The report is simultaneously (a) an independent public benchmark and (b) the
top of the observatory's engagement funnel. Its measurable KPI is BRIEFING REQUESTS
(the free 45-minute institutional briefing), not downloads. Both purposes survive only
if the findings prose reads as uncompromised analysis — see The Wall, below.

## Reader-question framing

Chapters keep the charter's anatomy and controlled-vocabulary names, but each opens
under a plain lead question, and sections answer sub-questions:

- **Mapa ekosustava** → *Koliki je prostor?* (dashboard spread), *Tko vodi?*
  (league tables, typology), *Gdje se razgovor seli?* (platform/format shifts).
- **Tematske struje** → *O čemu se govorilo?* (profile, validated movers).
- **Atmosfera diskursa** → *Kakvim se tonom govori?* (tone, conflict index).
- **Fokus na događaje** → *Što je obilježilo godinu?* (timeline, event boxes).
- Roadmap chapters, added only via charter change control when capability matures:
  *Nosi li se glas?* (voice-carry / message penetration) and *Tko sluša?*
  (audience survey module; until then engagement-as-proxy, honestly labeled).

The rotating special chapter is also the frame for "the year's most interesting
finding": promote it there and to the cover; never disturb the recurring canon for it.

## Writing rules

1. **Three-minute rule.** The sažetak alone must deliver the year; full read ≤45 min.
   Methods appear only as plain-Croatian boxes at point of use plus pointers to the
   online methodology — credibility by transparency pointer, not in-text statistics.
2. **One number per finding.** ≤10 findings (annual) / ≤5 (puls); each finding is one
   generated number plus one plain sentence. Two numbers = two findings, or cut one.
3. **Voice: "službeno, ali toplo."** Short sentences, active voice, verbs over
   nominalizations ("analizirali smo", never "provedena je analiza"). Every technical
   term explained at first use; no untranslated English in body text. Distinguish
   observation from interpretation (charter rule). Honest uncertainty in plain words
   ("procjena", "u ovom uzorku") — no hedging chains, no false precision. The uvodnik
   may use first person and warmth; findings prose stays measured. Humor no, humanity yes.
4. **Numbers in prose:** at most one per sentence; Croatian formatting (decimal comma,
   thin-space thousands); anchor comparisons to familiar magnitudes where possible.
5. **Honesty guards:** snapshot vs trend claims respect the collection-stream seam;
   unratified labels shown only as indicative with classified coverage; missing
   measures appear as gap panels, never simulated findings.

## Visual system

1. **One chart FORM per recurring topic, identical every edition** — only the numbers
   change. Recognition is what lets readers follow year to year.
2. Restricted vocabulary: horizontal ranked bars; time lines; slope charts (two-point
   change); dot/lollipop comparisons; small multiples; simple share stacks. No pies
   beyond binary shares, no dual axes, no 3D, no radar.
3. Figure title states THE FINDING; subtitle states the measure; footer states source
   + period. Every figure must work standalone as a screenshot.
   **The words are never inside the image.** A title baked into a PNG is rasterised in
   the wrong font, clips silently when the face is wider than expected, and cannot be
   selected or searched. Each figure registers its words (`register_fig()`), and they
   are installed as text, so a figure title and a table title are the same object.
4. Direct labels on marks instead of legends wherever possible.
5. All figures through `R/theme_digikat.R` tokens (cream paper, white panel, fixed
   platform colors, blue=+/red=− diverging). Color is never the only encoding; all
   figures legible in grayscale print. Load the `dataviz` skill before writing chart code.
6. **Tables as ranked cards:** rank · name · one key number · ▲▼ change vs previous
   edition · optional sparkline; ≤5 columns; each table answers one question stated in
   its title. Movement arrows are measured reporting, not ranking theatre: ties and
   trivial movements stay visually quiet.

## Typeset design — fixed across editions

The report is a designed object, not an export. These are settled and change only the way an
indicator changes: deliberately, and recorded.

1. **Two faces, everywhere, including inside the charts.** Palatino Linotype for anything
   carrying meaning, Segoe UI for labels and furniture, Consolas only for code and the
   fingerprint. The R figures re-register the same two families, so a chart and the
   paragraph beside it read as one document. Nothing sits in a monospace face because it
   happens to be a number.
2. **One modular scale, ratio 1.333:** 8,4 · 9,4 · 10,5 (body) · 12,5 (figure/table title) ·
   14 (section) · 19 (chapter) · 25 · 33 (cover). Nothing is sized by eye. When a heading
   feels weak, it takes more space, not more points.
3. **Figures behave by their job.** Old-style figures in prose so a number sits inside the
   sentence; lining + tabular figures in tables so a numeric column forms a straight edge.
4. **Asymmetric grid.** Text block left of centre, the wider outer margin carrying the page
   number at the bottom outer corner. White space is structure, not padding.
5. **Chapter openers.** A rule, a large ghost numeral in the page's own pale tint, then the
   title. The numeral is what the eye navigates by at flip-through speed.
6. **Cover: one dominant element.** Kicker, rule, title, and the year's hero number, separated
   by as much air as the page allows — plus the generated spark line of the daily series, which
   shows the shape of the argument before a word is read. No summary box competing with the
   title. A back cover closes the object with the wordmark and the corpus fingerprint.
7. **Exactly two box species.** A filled petrol box for what must not be missed (method,
   caveat, "mit i podaci" — which takes the alert rule); an unfilled hairline box for asides
   that may be skipped. Never a third.
8. **Boxes and tables stay breakable, with sticky titles.** Forbidding the break only trades a
   stranded title for a nine-tenths-empty page.
9. **The grid is the quietest ink on the page.** Hairline tone, 0,25 weight, no minor grid. The
   marks are the only dark thing in a figure.
10. **Both formats are driven by the same two hooks.** A level-4 heading is a figure or table
    title; a block quote is its source note. Pandoc's Typst writer drops a fenced div's class,
    so a `:::` block cannot be styled in the PDF — never rely on one for anything that must
    look right in both.

## Standing furniture (every edition)

The composite headline index with movement · a "10 brojeva godine" spread · league
tables with change arrows · the year timeline with a named "moment godine" · one
"mit i podaci" box (a common belief tested against the data) · and, from edition 2
onward, "što smo rekli prošle godine" (previous edition's key numbers revisited — the
accountability page that makes editions serial).

## Public-interest boundary

1. **No commercial direction — PI decision, 2026-08-17.** The report contains no commissioned-
   analysis teaser, product demonstration, service menu, price or sales-oriented call to action in
   either language. The colophon keeps one neutral line for questions about data and method.
2. **"Pitanja koja podaci otvaraju"** boxes may close chapters with two or three genuine research
   questions. They point toward inquiry, not something to buy.
3. **The boundary is absolute.** If a passage could reasonably be read as advertising, rewrite or
   remove it. `05_report_checks.R` enforces the decision in both language editions.

## Per-edition derivatives (produced WITH the report)

A 10-slide briefing deck (built from the sažetak and the
strongest figures), a 1-page shareable infographic, and a 3-number press release.
Figures are designed so IKA and others can lift them unaltered.

## Definition of done (per edition)

- [ ] Every scalar in prose present in the generated derived CSV; checks script passes.
- [ ] Every figure/table regenerated this edition; no hand-edited artifacts.
- [ ] Disclosure screen passed (named profiles = institutional outlets only;
      small cells suppressed; nothing row-level outside `output/private/`).
- [ ] Croatian diacritics intact end-to-end; the full English edition uses the same generated
      scalar registry and independently labelled figures.
- [ ] numeric-claim-verifier and religion-media-domain-reviewer runs clean.
- [ ] The Wall audit: findings prose read once specifically for promotional leakage.
- [ ] Deck, infographic, and press release produced from the same generated assets.
- [ ] Embargo pre-brief sent; no post-brief change except verified factual error.
- [ ] Published: both formats copied to `assets/izvjestaji/godisnji-pregled-<year>.{html,pdf}`
      and linked from the landing-page hero beside the database and the maps. The render
      chain never writes there — publication is a separate, deliberate act after sign-off.
