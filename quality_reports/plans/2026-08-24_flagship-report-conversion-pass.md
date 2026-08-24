# Flagship report conversion pass — „Kako se govori o Crkvi?"

**Date:** 2026-08-24 · **Decision owner:** PI · **Status:** approved by the PI in-session

## Goal

The flagship public report establishes credibility and delivers a headline finding, but it stops one
step short of letting an interested reader in a Church communications role see what the project is and
what it could answer for them. Three additions close that gap. No new data, no new model, no new claim
that is not already computed in `analysis-data.js`.

## Target artifact

`assets/izvjestaji/kako-se-govori-o-crkvi/` is the flagship. It is the reviewed static package that
`index.qmd` links and that GitHub Pages serves from `docs/assets/izvjestaji/kako-se-govori-o-crkvi/`.
`explorations/okvir-katolicanstva-prototype/` remains the reproducible ANALYTICAL source
(`analysis.R` -> `output/analysis-data.js`); its own `index.html` / `prototype.js` / `styles.css` are the
pre-promotion prototype and have already diverged. This pass does not back-port presentation work into
the exploration folder. See "Open item" below.

`analysis-data.js` is byte-identical between the exploration output and the published package, so the
data layer is untouched by this pass.

## The three changes (all in chapter 6, „Sto to znaci?")

1. **Three environments as the closing frame.** Import the conceptual frame from chapter 7 of
   „Tko nosi, a tko siri razgovor o Crkvi?" (everyday conversation about faith / big-event conversation /
   conflict-and-attention conversation) WITHOUT its per-group prescriptions. Each card carries one metric
   recomputed in `prototype.js` from data the flagship already loads:
   - `DATA.categoryGap` row `DUHOVNOST_I_LITURGIJA` -> `catholic_share`
   - `DATA.eventComposition` non-baseline rows -> min/max of `shares.public`
   - `DATA.sharpByActor` -> summed sharp post share and sharp interaction share
   These are the same three derivations `tko-nosi/report.js` lines 112-125 already perform.

2. **State the unique asset plainly, in the honest form.** One block after the verdict box saying what the
   corpus is (one continuous measurement, one inclusion rule across the whole span, so periods, themes and
   source groups are directly comparable) and what it measures (recorded presence and echo), followed by
   what it does NOT measure (audience reach, trust). Corpus size and span are injected from
   `DATA.meta.corpusRows` / `dateMin` / `dateMax` -- not typed.

3. **Link „Moj medij".** The report names no individual outlet by design. Self-recognition is what turns a
   reader into a contact, and `pages/moj-medij.html` already resolves 356 sources under the PI's disclosure
   policy. Add a noun-phrase link in the analytical register, parallel to the existing metodologija link.

## Constraints honoured

- `.claude/rules/voice-and-style.md` SS8 plain-sentence rule (no colon, semicolon or em dash in running
  prose), SS7 number canon (`413.985`, `12,3 %`, `2021.-2026.`), SS2c commerce boundary (no usluga / ponuda /
  klijent / naruciteljem / price / case study; the capability register stays at the existing one sentence),
  SS3 impersonal third person and no CTA, `„...”` quotes.
- Project rule 3: no hand-typed numbers. Every figure in the new prose is injected from `DATA`.
- The new block must not restore method detail that the 2026-08-11 field-first decision moved to
  `pages/metodologija.qmd`. It states what is measured, not how the cut was made, and links onward.

## Verification

- `qa-browser.mjs` gains a `--root` argument so it can QA the published package rather than only the
  stale prototype. Existing expectations unchanged (9 svg / 9 chart / 9 figure / 1 table / 8 rows, no
  overflow, no mojibake, no runtime exceptions, desktop + mobile).
- The harness caps `articleWords` at 1 900. The additions must stay inside that ceiling or the ceiling
  must be raised deliberately and recorded here.
- Copy the verified package to `docs/assets/izvjestaji/kako-se-govori-o-crkvi/` so Pages serves it.
- Confirm `data/processed/*.rds` and `analysis-data.js` are unmodified.

## Rejected alternatives

- **Promoting „Tko nosi" to a second public report.** Rejected. It is internal v1.0, adds no new data by
  its own README, and frames the field as positions held by named actor categories, which invites an
  institutional reader to feel assessed rather than served. It stays the second-stage briefing.
- **Importing the per-group practical readings too.** Rejected. Those are prescriptions addressed to one
  actor at a time and belong in a room, not on a public page.
- **Naming individual outlets in the report.** Rejected. Out of scope for the source-group design, and
  „Moj medij" already carries the disclosure policy that makes naming safe.

## Open item for the PI

The exploration folder's presentation layer is now two revisions behind the published package
(`index.html`, `prototype.js`, `styles.css` all differ; `analysis-data.js` does not). Either delete those
three files from the exploration folder so it is unambiguously the analytical source, or re-sync them.
Leaving both is the condition under which someone edits the wrong copy.

## Outcome (2026-08-24)

All three changes are in `assets/izvjestaji/kako-se-govori-o-crkvi/` and copied to
`docs/assets/izvjestaji/kako-se-govori-o-crkvi/`. Version bumped 1.1 -> 1.2 in all five places the
version string appears (citation meta, JSON-LD, hero byline, imprint, suggested citation), because the
published artifact is citable and 1.1 must keep naming the content it was.

Values injected into the new blocks, each reconciled against the independently generated
`output/analysis-summary.txt`:

| Block | Value | Reconciles with |
|---|---|---|
| Environment 1 | 58,6 % katolickih objava | F3 gap -14,2 pp (58,6 vs 44,4), chapter 2 read-out |
| Environment 2 | 75,5-89,0 % javnih izvora | max = 89,0 % (death of Pope Francis); min 75,5 % > 60,7 % baseline |
| Environment 3 | 3,8 % objava / 5,3 % reakcija | F4 and "Sharp-language interaction share: 5,3 %" |
| Scope note | 413.985 objava, 2021.-2026. | corpus manifest rows and span |

`articleWords` ceiling raised 1 900 -> 2 050 in `qa-browser.mjs` (measured 1 820 -> 2 006, +186). The
reason is recorded in a comment at the assertion. Nothing else in the harness's expectations moved.

`qa-browser.mjs` also gained `--root` and now snapshots `.mode-guide` and `.scope-note`
(`output/qa-modes.png`, `output/qa-scope.png`).

Verification run:
- `qa-browser.mjs --root=assets/...` and `--root=docs/assets/...` both exit 0. Desktop and mobile:
  9 svg / 9 figures / 1 table / 8 rows, 0 mojibake, no horizontal overflow, 0 runtime exceptions,
  all charts rendered, mobile menu and chart controls still pass their touch-target checks.
- `R/check_site_links.R`: 135 HTML files, no missing local targets or anchors. This is what confirms
  the new `../../../pages/moj-medij.html` resolves in the deployed tree.
- `R/check_sources.R`: 4 pre-existing failures in files this pass did not touch
  (`R/check_discarded_coding.R`, `R/check_pre2024_coding.R`,
  `studies/catholic-education/paper_checks.R`, `studies/filter-validation/11_check_holdout_coding.R`),
  the same guard-flags-the-guard class already recorded in `MEMORY.md`. Not introduced here, not fixed here.
- `analysis-data.js` byte-identical to `explorations/okvir-katolicanstva-prototype/output/analysis-data.js`;
  `git status data/` clean. No aggregate was read or written.

A typographic detail worth keeping: the year range and the min-max pair are joined with U+2060 WORD
JOINER so they cannot break across a line at the en dash. U+2060 is zero-width and carries no glyph, so
it cannot tofu the way U+2009 does in IBM Plex Mono.
