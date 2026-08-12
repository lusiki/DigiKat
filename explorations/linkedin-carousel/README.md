# LinkedIn carousel — „Jednadžba odjeka"

**Question this serves.** Can the cross-layer finding (production, engagement and reach are three
different games with three different winners) be published as a general-audience LinkedIn artefact
without weakening it into a slogan?

**Status.** Edition 2, 2026-08-12. Restructured around McKinsey's *attention equation* at the PI's
direction; edition 1's „three maps" framing is retired.
**Kill-by.** 2026-09-12 — if it has not been posted or reused by then, flag for ARCHIVE.

## The frame

McKinsey's report *The attention equation* (2025) argues that the value of media time is not its
quantity but its quality, driven by **focus** and **intent**. Their model is
`revenue/hour = commercial quotient + (attention quotient)`, where the attention quotient is
`focus × job to be done`, together explaining 80 % of the variance in monetisation.

This carousel borrows the *form*, applied to the supply side of the Croatian public sphere:

```
ODJEK = GDJE × TKO × ŠTO
```

| Their concept | Our term | What we actually measured |
|---|---|---|
| medium / platform effect | **GDJE** | platform share of posts vs interactions vs reach |
| focus | **TKO** | interaction share migrating off institutional web publishing |
| job to be done | **ŠTO** | theme supply rank vs engagement-per-post rank |

The payoff is that the three things institutions invest in each *look* like a term and none of them
is one. Trud enters as GDJE but placement is what pays; autoritet enters as TKO but a person is what
pays; supstanca enters as ŠTO but the reader's job to be done is what pays. Sheer production volume
is not a term at all.

**The honesty line, and it is not optional.** McKinsey fitted a regression and reports r² = 0,80.
**We did not.** Ours is an organising form whose three terms are each measured independently, and the
copy says exactly that („istu zakonitost gledali s druge strane"). Never let it drift toward „our
equation explains X % of the variance". That claim is not in the data and it is the first thing a
methods-literate reader will attack.

## What is here

| File | What |
|---|---|
| `carousel.html` | The five slides as one print-targeted HTML page (tracked). Source of truth. |
| `make_pdf.ps1` | Renders `carousel.html` → the PDF and five PNGs via headless Chrome. |
| `output/digikat-karusel-objaviti-ne-znaci-biti-cut.pdf` | The deliverable, 5 pages, 810 × 810 pt square, fonts embedded (gitignored). |
| `output/slide*.png` | 1080 × 1080 PNGs, for a single-image post (gitignored). |

Upload the PDF directly to LinkedIn as a **document post**. The post copy (Croatian and English)
lives in the session artefact, not in this folder.

Slide order is load-bearing. Slide 1 states the equation, slides 2 to 4 are one term and one
measurement each, slide 5 solves it and closes on three questions. The three chart headlines are
fixed by PI decision and are not to be rewritten:

- *Gdje se proizvodi nije gdje odjekuje.*
- *Osoba s mobitelom pobjeđuje instituciju s redakcijom.*
- *Ono čega je najviše nije ono što se najviše traži.*

## Numbers on the slides and where they come from

All recomputed 2026-08-12 from the tracked aggregates, not carried over from prose.

- **Slide 2 (GDJE)** — `data/processed/platform_summary.rds`, summed over all years.
  Web 69,2 % of posts → 63,0 % of interactions → 40,6 % of reach.
  Facebook 15,3 % → 18,7 % → 47,4 %. YouTube 11,4 % → 15,8 % → 10,8 %.
- **Slide 3 (TKO)** — same file, web's share of interactions by year: 90,0 % (2021), 85,8 %,
  73,5 %, 50,8 %, 34,6 % (2025).
- **Slide 4 (ŠTO)** — `data/page-ready/mapa_stats.rds`. Supply rank from
  `thematic_intensity_data` document counts (Duhovnost i liturgija 18 486, rank 1; Digitalna
  evangelizacija i mladi 4 031, rank 10). Demand rank and per-post figures from
  `engagement_by_topic$avg_interactions` (187 / 156 / 126 / 8).
- The substance-penalty line on slide 4 is quoted from the Christian-democracy study. It is
  **not** recomputed here.

## Honesty note carried on slide 3

The 90 → 35 slope partly reflects the 2024 collection change (Instagram and TikTok enter, and the
instrument seam falls mid-2024), so the slide carries the footnote *„Od 2024. praćenje obuhvaća i
Instagram i TikTok."* and the post carries the same hedge in one clause. The direction survives
inside the pre-2024 stream alone (90 → 74 by 2023), which is why the claim stands. Do not remove
either hedge when reusing this material.

## Design notes

The slides reuse the DigiKat editorial system — cream paper, white chart panels, Palatino body, mono
labels, the blue/red/teal series colours — so they sit beside the annual report and the site. Term
colour is wayfinding: GDJE is blue, TKO is red, ŠTO is teal, and each slide's eyebrow carries its
term in that colour. The three-series chart palette passes the categorical colour checks (lightness
band, chroma floor, CVD separation, contrast). House rules apply as they do to the report: no colons
and no em-dashes in the Croatian prose, and no noun typed after a generated number.

IBM Plex Mono is not installed on this machine, so the mono role falls back to Consolas and that is
what is embedded in the PDF. Install Plex Mono before regenerating if the report's exact face matters.

## Regenerate

```powershell
pwsh explorations/linkedin-carousel/make_pdf.ps1
```

Rendering is verified by eye, not just by exit code — the script writes five PNGs precisely so each
slide can be inspected for label collisions and clipping before the PDF is uploaded anywhere.
