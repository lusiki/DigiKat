# Plan — make "Construct-dependent visibility of Catholic social teaching" read as a finished journal paper

**Date:** 2026-08-12 · **Study:** `studies/moral-economy` · **Manuscript:** `PAPER_RSP_v2.md`

## Instruction

The PI reports the paper "looks like a very unfinished thing with lots of mistakes and unprecise
spacings ... a mess", and wants it to look like a finished, published journal paper. The theoretical
and literature discussion must stay **as it is** — neither reduced nor extended. So this is a
presentation repair: no finding, number, argument or citation changes.

## Diagnosis (from the two rendered artefacts, not from the source)

Rendered `studies/moral-economy/output/paper/PAPER_RSP_v2.pdf` (Typst, 15 pp) and the published
`assets/papers/socijalni-nauk-i-gospodarstvo.pdf` (Chrome print of the HTML, 18 pp).

| # | Defect | Where it lives |
|---|---|---|
| 1 | **Display and inline maths render as literal garbage.** `\[ D_d = \frac{…}{…} \]` prints as `[ D_d = {d}. ]` and `\(\widehat p_d\)` as `(p_d)`. Pandoc markdown does not enable `tex_math_single_backslash`. Both formats affected. | `PAPER_RSP_v2.md` |
| 2 | **Every paragraph containing exactly one italic phrase is shattered into three blocks.** `p > em:only-child` counts *element* children, so `<p>text <em>Laudato si’</em> text</p>` matches. Both abstracts and the introduction break mid-sentence with a grey sans block and 2,4 rem of air. | `typeset/paper.css:234` |
| 3 | **Table 4 columns collide** — the header prints as `No era-assignedMixed`. | `typeset/paper.typ` table sizing |
| 4 | **References print as a bulleted list**, justified, so URL-bearing entries open enormous word gaps. | `typeset/paper.typ` |
| 5 | **"Unprecise spacings":** the thousands separator is an ASCII space, so `413 985` stretches under justification to look like two numbers and can break across lines. Same for `n = 660`, `1 January`, `≥ 10`. | typeset-time transform |
| 6 | **Table captions orphan from their tables** (Table 5's source note alone at the top of p. 10), and source notes are set at body size in italic, far too heavy. | `paper.typ` / `paper.css` |
| 7 | **Figure titles and source lines are baked into the PNGs** in Arial at 300 dpi, so they sit inside a bordered box in the wrong face at the wrong size. This is the repo's own recorded lesson (MEMORY, annual report). | `24_rsp_figures.R` |
| 8 | **No author block in the Typst PDF** at all. The published HTML gets one injected by the publisher. | `28_render_paper.R` |
| 9 | Em-dash appositives in two headings and one sentence break badly (a line begins `—reduces`). House style already bans them. | `PAPER_RSP_v2.md` |

## Constraints that bound the fix

- `25_paper_checks.R` gates: whole manuscript **< 50 000 characters** (measured 48 306, so
  **1 694 free**), seven table fragments byte-identical, 62 derived scalars printed verbatim,
  decimal comma, and a **sealed-hash manifest** over the manuscript, figures, tables and every study
  `.R`. Baseline today is 28/29 — the one failure is pre-existing drift in
  `pages/studije/socijalni-nauk-i-gospodarstvo.qmd` and `resources/dictionaries/source_labels.csv`,
  not caused by this work. Re-running `36_rsp_final_run_manifest.R` reseals.
- `rsp_int()` prints thousands with an **ASCII space**, and the checker greps those strings verbatim.
  So the thousands-separator fix must happen in the throwaway typeset copy, never in the manuscript.
- Two manuscript versions share the generated fragments; only v2 is published, so only v2 is synced.

## Work items

**A. Manuscript** (content-preserving only)
- A1 `\[…\]`/`\(…\)` → `$$…$$`/`$…$`.
- A2 remove the three em-dash appositives (headings §4.5, §5.1; the ecology-marker list → parentheses).
- A3 give each figure a real caption block — `**Figure N.** Title`, image, `*Source: …*` — mirroring
  the table pattern, so the words move out of the PNG and onto the page.

**B. `24_rsp_figures.R`** — stop drawing `title` and `caption` into the plots; register each
figure's words and emit `output/figures/figN_*.md` fragments (caption + image + source note).

**C. `27_sync_tables.R`** — install figure fragments as well as table fragments.

**D. `25_paper_checks.R`** — assert the four figure fragments appear byte-for-byte, as tables do.

**E. `28_render_paper.R`** — author/affiliation front matter; and transform the *build copy* only:
ASCII thousands space → U+00A0, caption paragraphs → level-4 headings, `*Source: …*` → block quotes.
Level-4 heading and block quote are the two constructs that survive Pandoc's Typst writer with their
own type, which is what lets one show rule reach them (MEMORY, annual report).

**F. `typeset/paper.typ` / `typeset/paper.css`** — style those two constructs; sticky captions;
hanging-indent unjustified references; wide-table sizing; drop `p > em:only-child`.

**G. Verify** — `24` → `27 --v2` → `25 --v2` → `36` → `25 --v2` clean, then `28 --v2`, read every
page of the PDF, then republish `assets/papers/` and mirror into `docs/assets/papers/`.

## Explicitly out of scope

Any change to the argument, the numbers, the theory sections (§2), the literature, the references,
the limitations or the conclusions. A full `quarto render` (HARD GATE) — the published paper assets
are refreshed directly by the publisher script instead.
