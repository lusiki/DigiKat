# EMIP execution brief — sector framing

> **V2 status 2026-08-05.** The PI-approved economic reframe in
> [`PROPOSAL_EMIP_v2.md`](PROPOSAL_EMIP_v2.md) has been executed. The manuscript is
> [`PAPER_EMIP_v2.md`](PAPER_EMIP_v2.md); scripts `14_v2_sheets.R` to `16_v2_event.R`
> implement the attention-object recode, institutional-unit match and dated event analysis.
> `RUN_ALL.R --v2 --no-network` completed 15 scripts in 7.4 minutes, the v2 manuscript passed
> 33 of 33 checks, and full and blinded Word files plus a 61-file screened replication bundle
> were rebuilt under `output/`. The v1 record below is retained as provenance, not as the
> current manuscript status.

> **Status 2026-08-05, end of day.** Steps 1 to 8 are built and run end to end
> (`RUN_ALL.R`, 13 scripts, ~7 minutes). The manuscript is `PAPER_EMIP_v1.md`, typeset to
> Word in full and blinded versions under `output/paper/`, and `10_paper_checks.R` passes
> 31 of 31. Read [`RECONSTRUCTION.md`](RECONSTRUCTION.md) before acting on anything below:
> four of this brief's assumptions turned out to be wrong, three findings changed, and two
> requirements are unmet.
>
> Corrections to this brief, in order of consequence.
> **`rid` is the master row index**, not a lost key, so the collection stream is exact for
> all 520 core posts rather than only the 88 dated 2024 (§ Data inventory, point 2).
> **Six posts dated 2022-12-31 were booked to 2023** by the June run, so the register-by-year
> figures in §2.1 are wrong by that much; corrected, 2022 → 207 and 2023 → 94, and the
> seam-free anchor in §2.3 is 30.3% → 47.9% rather than 28% → 51%.
> **The monitoring validation window is 37 months** (2021-01 to 2024-06 with a four-month
> hole), not the "39 contiguous" of §3, which is also arithmetically impossible for 2021–2023.
> **`prc_hicp_manr` is closed** at 2025-12; current data is in `prc_hicp_minr` under ECOICOP
> ver.2, and the food series is `CP01`, not the `FOOD` aggregate.
>
> Unmet requirements. §3's hope that both streams would independently validate the
> instrument **does not hold** — the backfill window contains almost no variation in
> inflation (sd 0.60 against 4.03) and cannot validate anything; the paper reports this
> rather than hiding it. And §4's **cross-family** recoding was not possible on this
> machine; the recoding is blind and independent but same-family, and needs a PI decision.
>
> Steps 1's fixtures: `03` hits every one exactly. `01` and `02` do not, by 0.27% and 17.5%
> respectively, which under this brief's own rule is an escalation and not something to
> retune. Nothing published depends on them.

**Decided 2026-08-05 (PI).** The paper is reframed from media/religion to **the religious sector as an
economic sector**. Target: *Ekonomska misao i praksa*, **30 September 2026** deadline (December 2026 issue).
Journal constraints and rationale: [`quality_reports/plans/2026-08-05_inflation-salience-emip-submission.md`](../../quality_reports/plans/2026-08-05_inflation-salience-emip-submission.md).

---

## The paper in one paragraph

Croatia's religious sector is a large non-market service provider — masses, weddings, funerals, pilgrimages,
plus a charity network — and **no statistical office collects its prices**. There is no administrative data on
it. We use media coverage as the observation instrument, a standard approach for sectors without official
statistics, and measure how the sector adjusted across the **full January 2021 – June 2026 span**: the
inflation shock, the January 2023 euro changeover, and the three-year adjustment period that followed. It did
three things: its leaders entered economic debate during the acute shock, its services were repriced with a
long delay, and its charities absorbed demand. It did not do a fourth thing its stated doctrine commits it to
— name who bears the burden.

**Title (EN):** *The religious sector in an inflation shock: pricing, public voice, and charitable response in
Croatia, 2021–2026*
**Naslov (HR):** *Vjerski sektor u inflacijskom šoku: cijene, javni glas i dobrotvorni odgovor u Hrvatskoj,
2021.–2026.*
**JEL:** E31 · L31 · Z12 · L82
**Category:** original scientific paper (izvorni znanstveni rad) · **Language:** English + required Croatian
title/abstract/keywords

**Why the sampling frame is no longer a problem.** The unit of analysis is the religious sector. The corpus is
religion-salient content. The frame matches the target population by construction — there is no external
quantity being estimated, so no selection argument is needed. Do not reintroduce claims about "Croatian media"
anywhere in the text; that is what created the problem in the first place.

**Data span — use all of it (PI, 2026-08-05).** The master covers **2021-01 → 2026-06** (710 307 rows) and the
coded core spans the whole of it (2021→12, 2022→201, 2023→100, 2024→88, 2025→66, 2026→53). Analyse the full
span. The 2024 collection-instrument seam is handled by **conditioning on `data_source` throughout**, never by
truncating the window — stream conditioning is therefore a required step (§2.3), not an optional robustness
check. The adjustment period after the shock is where the pricing story actually lives, so truncating at 2023
would discard the paper's most interesting years.

**HICP must be extended.** `output/hicp_hr.csv` currently ends 2025-12. Re-pull Eurostat `prc_hicp_manr`
(all-items, food, energy) through **2026-06** so the price series covers the full corpus span. Validate the
re-pull against the existing file's overlapping months (2021-01 → 2025-12) before replacing it.

### Data inventory — verified on this machine 2026-08-05

R 4.6.0 present, Croatian UTF-8 locale, master loads in 24 s. Everything needed is on disk.

| Asset | Verified |
|---|---|
| `data/merged_comprehensive.rds` | 710 307 × 47, **2021-01-01 → 2026-06-11**, 0 NA dates |
| `data_source` | present on every row |
| `FULL_TEXT`, `MENTION_SNIPPET`, `TITLE`, `URL` | present — tagging and linkage are rebuildable |
| `output/private/analysis_core_coded.rds` | 520 × 11; register and year match `PAPER_v1` exactly |
| `output/private/coded_pool_full.csv` | 1 450 × 10; `c_infl`, `c_link`, `c_foreign`, `c_register`, `n_ann` |

**Rows per year × stream (from the master):**

| Year | original_dta | filtered_religious |
|---|---:|---:|
| 2021 | 90 388 | 0 |
| 2022 | 84 535 | 0 |
| 2023 | 83 836 | 0 |
| 2024 | **10 824** | **103 407** |
| 2025 | 0 | 236 166 |
| 2026 (to June) | 0 | 101 151 |

Three consequences, all of which the steps below already reflect:

1. **The monitoring stream effectively ends in early 2024** — 10 824 rows against 103 407 backfill. It is not a
   "2021–2024" stream; it is 2021–2023 plus a stub, which is why February–May 2024 are missing from the
   attention series. Never describe it as running to 2024.
2. **`rid` does not exist in the master.** The coded core's join key was generated by the missing script and
   cannot be reconstructed blind. **Join on `URL`** to attach `data_source` to the coded core. This matters for
   only the **88 posts dated 2024** — every other year is single-stream, so its label is unambiguous.
3. **Volume is asymmetric across streams** (~85 k rows/year in 2021–2023 vs 236 k in 2025). Confirms the
   shares-not-counts rule in §2.3; raw counts across the seam are meaningless.

`DATE` is stored as character — parse explicitly, and read text as UTF-8 (`MEMORY.md`, CP1250 hazard).

---

## Step 1 — Rebuild the pipeline (blocks everything)

`PAPER_v1` Appendix A names `10_rerun_fixed.R` … `17_h1_hicp.R` under a `scratchpad/` directory that does not
exist in the repo or in git history. The **annotation survives** (`output/coded_labels.csv`,
`output/private/coded_pool_full.csv`) — nothing needs re-coding. Only the code is missing.

Write these as numbered study scripts, spec recoverable from `PAPER_v1.md` §3 and `VALIDATION.md` §v3
(lexicons, metaphor guard, ±220-char window, foreign gazetteer, homonym exclusions):

| Script | Rebuilds | Must reproduce exactly |
|---|---|---|
| `01_tag_inflation.R` | inflation tagging on the master | 8 105 raw → **8 019** clean |
| `02_linkage_candidates.R` | ±220-char proximity filter | **1 450** candidates |
| `03_finalize_coded.R` | measured core from surviving labels | **652** linked / **132** foreign / **520** core |

Run from the repo root with the R path in `CLAUDE.local.md`. **Acceptance test:** each script hits its number
to the digit. A mismatch means the reconstruction is wrong — stop and escalate rather than adjusting the
target. These numbers were independently verified in June.

---

## Step 2 — The sector analyses (`04_sector_profile.R`) — NEW, this is the paper

Recut the coded core into **three response series** and their timing.

**2.1 The three responses.** Map registers to sector responses and report counts and shares by year across the
full span. Mark the collection stream on every column: **2021–2023 = monitoring stream · 2024 = both ·
2025–2026 = backfill stream** (2026 is a half-year, January–June — never compare its raw count to a full year).

| Response | Register | 2021 | 2022 | 2023 | 2024 | 2025 | 2026 |
|---|---|---:|---:|---:|---:|---:|---:|
| Public voice | Church-as-institution | 8 | **105** | 38 | 9 | 16 | 3 |
| Repricing | Cost of religious life | 0 | 41 | 39 | **61** | 13 | 40 |
| Charitable response | Charity / relief | 0 | 34 | 11 | 12 | **26** | 4 |
| Normative response | Structural / justice | 2 | 1 | 5 | 4 | 2 | 1 |

**2.2 The sequencing result — the paper's spine.** Public voice peaks with the shock (2022); repricing peaks
long after it. That is delayed, lumpy adjustment in a non-market sector, and it is what makes this economics.

**2.3 Stream conditioning — REQUIRED, and it is what lets the full span be used.** Per `REVIEW_RESPONSE.md`
C1, the corpus changes collection instrument at 2024 (confirmation rate 0,86 vs 0,21 at the overlap), so raw
counts are not comparable across the seam. The repricing peak sits directly on it. Handle it properly rather
than by truncating:

- Carry `data_source` on every coded row and report **every temporal series split by stream**. Two panels, not
  one pooled line.
- Report **composition shares within stream**, not raw volumes, as the primary temporal quantity. Shares are
  comparable across streams in a way counts are not, because the confirmation-rate difference scales the whole
  stream.
- The seam-free anchor, which needs nothing extra: within the 2021–2023 monitoring stream alone, repricing goes
  from 41/146 = **28%** of voice-plus-repricing in 2022 to 39/77 = **51%** in 2023. State this first, then show
  the full-span stream-split series carries the same direction through 2026.
- Report the 2024 overlap year **both ways** (monitoring rows only, backfill rows only) as the bridge between
  the two panels. This is the check that makes the full span defensible; budget real time for it in week 2.

**2.4 The missing normative response.** Justice register 15 posts (2,9%; ≤8% broad). Frame as **stated mission
versus observed behaviour** — an institutional-economics comparison, not a theological judgement. Keep Catholic
Social Teaching to one paragraph in the Introduction and one in the Discussion as the source of the stated
commitment. Delete every occurrence of "prophetic".

**2.5 Who reports it.** 85% secular outlets, 14% Catholic. Under the sector framing this is a statement about
the *observation instrument*, not about outlet behaviour: the sector's economics is reported from outside it.
Drop the outlet division-of-labour hypothesis entirely (it was already demoted — `REVIEW_RESPONSE.md` C2).

---

## Step 3 — Instrument validation (`05_instrument_validation.R`)

The attention series is now **validation that media coverage tracks the real shock**, not a headline claim.
This is a much lighter burden than an attention index would carry.

Build the monthly series across the **full 2021-01 → 2026-06 span**, then validate it **once per stream** —
two independent validations are stronger than one, and they double as the stream-comparability evidence §2.3
needs.

| Window | Stream | Months | Status |
|---|---|---|---|
| 2021-01 → 2023-12 | monitoring | 39 contiguous | already computed: r = 0,73 / 0,72 / 0,44 |
| 2024-01 → 2026-06 | backfill | ~30 | **new — build it** |

- The existing series file stops at 2024-07 and the monitoring stream is **missing February–May 2024
  entirely**, with January at n = 1 911 and July at n = 436 against a normal ~7 000. Drop those partial
  monitoring months; the backfill stream covers 2024 properly and is the right source for that year onward.
- `PAPER_v1` describes the validation window as "2021–2024". It is **2021–2023**. Correct every statement of it
  in the manuscript.
- Report per stream: Pearson/Spearman vs headline, food, energy, plus the threshold contrast (monitoring
  stream: 0,49% below 4% HICP vs 1,17% at or above). If both streams independently track HICP, the instrument
  is validated twice on different collection methods — a genuinely strong result, and worth saying plainly.
- Two robustness lines, briefly, to pre-empt a spurious-correlation objection: the relationship **in first
  differences**, and **Newey–West** standard errors on the levels specification. One small table. Do not build
  the ADL/threshold-regression battery — it belongs to the framing we dropped.
- Note in passing that monthly corpus volume ranges 4 970–12 860, and show the correlation survives a count
  specification with `log(n_total)` offset.

**Optional, only if time permits:** Google Trends "inflacija" (Croatia, monthly) as a second external anchor.
Not required under this framing.

---

## Step 4 — Annotation validation, model-based (no human coding)

**PI decision, 2026-08-05: no human will read a validation set.** Validation is therefore model-based, and the
manuscript states that plainly rather than implying a gold standard it does not have.

- **Cross-family re-annotation.** Re-code a stratified slice of ≥150 items with a model from a **different
  family** than the three original annotators, blind to the existing labels, using the same fixed codebook.
  Report cross-family agreement next to the existing inter-model agreement (0,975 infl / 0,967 link / 0,992
  foreign; register 0,46). Agreement across independent model families is a materially stronger claim than
  agreement among three runs of one family, and it is the best instrument available under this constraint.
- **Resolve the 12 disputed register cases** with the same cross-family adjudicator; report how many flipped.
- **Error audit.** Sample the disagreements and characterise the failure modes in a short table. `VALIDATION.md`
  already documents the recurring collisions (`Papa-test`, `posveć`, `dostojanstv`, landmark and juxtaposition
  cases) — extend that taxonomy rather than starting fresh.
- **Publish the codebook** in an appendix so a referee can replicate the coding without the corpus.

**State the residual limitation explicitly** in Methods and Limitations: agreement here is inter-model
reliability, not a human gold standard, and register remains the low-agreement axis (0,46). `PAPER_v1` already
says this — keep it, do not soften it. Combined with the full AI-use disclosure EMIP requires, honest labelling
is the defence; overclaiming validation is what would get the instrument rejected.

---

## Step 5 — Generated tables and the numeric gate

Port the moral-economy discipline so no number is ever hand-typed into the manuscript:

- `06_tables.R` — every table as a markdown fragment under `output/tables/` plus `derived.csv` carrying every
  scalar the prose quotes.
- `07_sync_tables.R` — installs fragments into the manuscript. Never edit a table by hand.
- `08_paper_checks.R` — fails unless each fragment appears byte-for-byte and each scalar is still printed in
  the text. Add a **page/length gate** for EMIP's 25-page ceiling.
- `09_render_paper.R` — build to `.docx` in a temp directory **outside the repo** so a stray render cannot
  touch `docs/`.

---

## Step 6 — The rewrite

Use `scholar-write` in **review-only** mode over the reframed sections, then **single-section** redrafts where
the panel flags problems. Do **not** use full-draft — it would discard June's referee-hardening.

Target structure, ~25 pages including references:

1. **Introduction** (~2 pp) — the sector, the absence of price statistics, the shock, what we do
2. **Background** (~3 pp) — non-market and administered pricing; non-profit sector economics; the religious
   sector in Croatia; media as an observation instrument for sectors without official statistics
3. **Data and methods** (~4 pp) — corpus and frame, inflation tagging, linkage not co-occurrence, coding and
   validation, HICP, **AI-use statement inside Methods**
4. **Results** (~5 pp) — 4.1 instrument validation · 4.2 the three responses · 4.3 sequencing · 4.4 the missing
   normative response · 4.5 measurement note (co-occurrence ≠ engagement: only 45% of flagged candidates
   survive coding; precision ceiling ≈ 0,4)
5. **Discussion** (~2 pp) — sticky non-market prices; stated mission versus observed behaviour
6. **Conclusion** (~1 p)

Cut to fit: drop Table 5 (auto-sentiment — vendor labels, indicative only, weakest evidence) and merge Tables 3
and 4.

**Citation pool.** Build and verify with `scholar-citation`'s five-tier check before drafting — there is no
Zotero library on this machine. Keep ~10 of the existing references, drop the media-framing tail, add
non-market/administered pricing and non-profit sector economics. Two items in `LITERATURE.md` remain
UNVERIFIED; resolve or drop them. APA 7 throughout.

---

## Step 7 — Journal format and submission

- Word, 16,6 × 24 cm, Times New Roman 10; tables/figures **black and white**, title above 10 pt, source below
  9 pt. **Email `ekon.misao@unidu.hr` to confirm** — the UNIDU page says A4 double-spaced, the EMIP site says
  16,6 × 24; they conflict.
- Abstract **≤150 words in Croatian and English**, third person, stating method and results. Title and keywords
  in both languages.
- Title page: academic title, name, institution, email, ORCID — journal requirement, filled in by the author at
  submission.
- Required blocks: Author Contributions · Funding (DigiKat / HKS) · Conflict of Interest · **AI tool
  acknowledgment** · Notes · References.
- **Two files**: full and fully blinded. The blinded version must also strip the DigiKat/HKS funding line and
  all repository URLs — they identify the author immediately.

---

## Step 8 — Archive

- Replication package via `scholar-replication`: numbered scripts under a master script, generated tables,
  `derived.csv`, `hicp_hr.csv`, non-identifying coded labels, AEA-style README, clean-room rerun, paper-to-code
  audit.
- `/disclosure-check` on every file that ships. `output/private/**` never leaves the machine (URLs, outlet
  identities, text excerpts). Re-verify the tracked `output/coded_labels.csv` carries no URLs or excerpts.
- `/capture-environment` → refreshed `renv.lock` + `ENVIRONMENT.md`.
- Zenodo DOI for the package, cited in the Data Availability statement.
- Add a `[LEARN]` block to `MEMORY.md`: the reconstruction, the corrected 2021–2023 window, the sector reframe.

---

## Timeline to 30 September 2026

| Week | Work |
|---|---|
| 1 (Aug 5–11) | Step 1 — scripts 01–03 hit their fixtures. Re-pull HICP through 2026-06. Confirm format spec with the editor. |
| 2 (Aug 12–18) | Step 2 — sector profile over the full span, sequencing, stream conditioning incl. the 2024 bridge. |
| 3 (Aug 19–25) | Step 3 instrument validation, both streams · Step 5 table generator and gate. |
| 4 (Aug 26–Sep 1) | Step 4 cross-family re-annotation and error audit · citation pool built and verified. |
| 5 (Sep 2–8) | Step 6 — Introduction, Background, Methods rewritten to the sector spine. |
| 6 (Sep 9–15) | Step 6 — Results and Discussion recut; review panel; Croatian abstract, title, keywords. |
| 7 (Sep 16–22) | Step 7 format · Step 8 archive, DOI, declarations, disclosure check. |
| 8 (Sep 23–29) | Blinded version, final numeric verification, mock referee pass (`/review-paper`), submit. |

**Go/no-go: 18 August.** If Step 1 has not reproduced 8 019 / 1 450 / 520 by then, target the 31 March 2027
deadline for the June 2027 issue rather than compressing validation.

---

## Open items

1. **Croatian abstract and title** — drafted here, approved by the author at submission.
2. **Format spec** — confirm with `ekon.misao@unidu.hr` (the UNIDU and EMIP pages conflict).

Everything else in this brief runs without further input.
