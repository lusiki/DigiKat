# Stage-A findings — preliminary detection of Catholic *lieux de mémoire* (education spine)

**Date:** 2026-07-06 · **Status:** first pass on the full master (verified run) · **Owner:** memory-studies researcher
**Run:** [`slice.R`](slice.R) (full 710k master, read-only) → [`correct_stageA.R`](correct_stageA.R) (isusov + per-entity
fixes) → [`stageA_checks.R`](stageA_checks.R). Outputs in [`output/`](output/). **All numbers below are computed, not typed.**

> **Provisional, not yet hand-validated.** These are *auto-detected* signals on a recall-first probe; precision is
> fixed by the §6 hand-validation pass. Read every share as indicative. Two signals only (recurrence +
> past-anchoring); temporal-peaking and affect are the next `/data-analysis` step.

---

## 1. Is there a corpus? — Yes, abundantly

**176,312** education-spine posts (2021–2025) after correcting the `isusov` homonym (see §5). No "empty-corpus"
risk of the kind that reframed the sister inflation study. The education strand is a large, real presence in the
Croatian Catholic digital mediaspace.

## 2. The ranked candidate table (corrected, per-entity genuine past-anchoring)

`past_anchor_doc` = share of the entity's posts with a past-reference token *anywhere*; `past_anchor_genuine` =
share with a past token **within ±160 chars of that entity's own mention** (windowed linkage); `incidental` = the gap.

| entity | recurrence | doc-level | **genuine** | incidental |
|---|---:|---:|---:|---:|
| odgoj / vrijednosti | 82,025 | 0.427 | 0.098 | 0.329 |
| redovi / orders | 79,962 | 0.329 | 0.096 | 0.233 |
| rituali *(secondary)* | 24,463 | 0.392 | 0.088 | 0.304 |
| katolička škola | 22,233 | 0.368 | 0.071 | 0.297 |
| vjeronauk | 14,918 | 0.307 | 0.065 | 0.243 |
| **stepinac** | 9,831 | **0.561** | **0.239** | 0.322 |
| strossmayer | 5,172 | 0.374 | 0.064 | 0.311 |
| stadler | 728 | 0.427 | 0.063 | 0.364 |
| petković (Marija) | 302 | 0.487 | 0.050 | 0.437 |

## 3. The headline — two results that make the paper

**(a) Stepinac is the *singular* genuine site of memory.** His windowed-genuine past-anchoring (**0.239**) is
**2.4–3.7× every other entity** (next: odgoj 0.098, redovi 0.096; the rest 0.05–0.07), and his doc-level (0.561) is
also by far the highest. Among all education-related Catholic anchors, **only Stepinac's mentions are genuinely,
tightly bound to the communist/1991/žrtva past.**

**(b) Catholic education itself is mediated *present-tense*, not as memory transmission — the falsifiable Q2
answer, and the non-obvious one.** The *institutions and practices* of Catholic education — vjeronauk (0.065),
katoličke škole (0.071), odgoj/values (0.098) — are all **low** on genuine past-anchoring. They recur heavily but
are argued as **current value-politics** (curriculum, values, parental rights), not anchored to a remembered past.
**Memory transmission runs through the figure (Stepinac), not through the schools/curriculum.** So Q2's answer, at
first pass, is: *Catholic education functions as a present-tense value-political field that becomes a site of memory
mainly where it attaches to a commemorative figure.* This is exactly the kind of result the design was built to be
able to reach — it could have come out the other way.

## 4. Construct validity — the screen works (and survived the review)

Pre-declared gate (PROPOSAL §3): positive control `stepinac` vs policy-dispute foil `odgoj/kurikul/vrijednost`.
**stepinac genuine 0.239 ≫ odgoj foil 0.098 — a 2.44× separation.** The four-signal screen *does* separate a memory
anchor from a policy-dispute term. This held **after** fixing an r-reviewer-flagged bug (genuine anchoring was
computed against the OR of *all* spine bundles, confounding per-entity numbers); the per-entity recomputation
*sharpened* the separation (2.2× → 2.44×) rather than dissolving it — evidence the finding is not an artifact.

## 5. Methods result — co-occurrence ≠ activation, replicated almost exactly

Slice-wide: doc-level **36.0%** of education posts carry a past token *somewhere*; windowed-genuine only **11.0%**
— **69.4% of the co-occurrence is incidental.** This lands right on the sister inflation study's ~68%. Reporting
whole-document co-occurrence would have **overstated genuine past-anchoring ~2.3–4.4×** per entity (odgoj 77%
incidental, stepinac the least at 57% — consistent with it being the one genuine anchor). The windowing was
essential, not decorative.

**Probe correction (the `isusov` homonym).** Bare `isusov` matched **63,297** posts — overwhelmingly the possessive
*"Isusov dar" / "Isusova braća"* = **of Jesus**, not Jesuits. Restricting to order-forms drops the true Jesuit count
to **10,095** and removes **32,430 posts (15.5% of the slice)** that had entered only via that false positive.
`redovi_orders` fell from 122,082 → 79,962, now genuinely driven by samostan (39,477), franjevci (35,839), časne
sestre (11,662), isusovci (10,095). **Never report the pre-fix numbers.**

## 6. Temporal — the collection-method confound is stark (do NOT read volume as attention)

Education-spine posts by year × collection stream ([figure](output/figures/spine_by_year_datasource.png)):

| year | original_dta | filtered_religious |
|---|---:|---:|
| 2021 | 31,149 | 0 |
| 2022 | 28,547 | 0 |
| 2023 | 29,317 | 0 |
| 2024 | 3,564 | 25,724 |
| 2025 | 0 | 58,011 |

The two streams are **time-segregated** with a clean handover in 2024 (MEMORY.md). The apparent jump to 58k in
2025 is a **collection-method artifact, not rising attention.** Consequence for signal #2: **temporal-peaking must
be computed WITHIN a stream**, and the commemorative-vs-news-cycle test restricted to within-stream year pairs —
you cannot compare across the 2024 boundary.

## 7. Limitations surfaced by the run (build into the paper)

- **The past-anchor probe is tuned to the 20c communist/1991 rupture**, so it **under-detects 19c memory**:
  `strossmayer` scores low (0.064) despite being a textbook *lieu de mémoire* — his memory operates on a
  cultural/national register the current token set doesn't capture. A second past-token register (19c
  national-revival / Josip Juraj) should be added before treating a low score as "not a site of memory."
- **The "kršćanski korijeni" frame is essentially absent** (n = 1 in the whole slice) — the "Christian roots of
  Europe/Croatia" trope, prominent in Western Catholic discourse, barely surfaces here. Worth a sentence.
- **The top-2 entities are broad bundles** (odgoj driven by the ubiquitous `vrijednost` 60,698 + `odgoj` 27,455;
  `kurikul` only 1,910). High recurrence, low genuine anchoring — the "recurs but flat = policy dispute, not site
  of memory" pattern the proposal predicted, now empirically visible.
- **`stadler` is fine here** (728 hits, mostly Abp. Josip Stadler, not Stadler Rail — the ≥2-match religion filter
  pre-excluded the rail-company articles). `samostan` snippets are on-topic. Both stay hand-validation priorities.
- **Affect signal (#3) is a *second-pass* addition** (§10) — sampled, udpipe + lexicon; report coverage %, treat
  as indicative. The full four-signal composite decision is computable once affect lands.

## 8. Second pass — signal #2 (temporal peaking, within-stream)

Peakedness = coefficient of variation of monthly volume within a stream; recurrence = in how many years the modal
peak month is that entity's own annual maximum ([table](output/tables/temporal_peaking_by_entity.csv),
[Stepinac series](output/figures/stepinac_monthly.png), [seasonality](output/figures/seasonality_month_of_year.png)).

- **Stepinac is the *spikiest* entity** (CV **0.76** in `original_dta`, 0.62 in `filtered_religious`) vs the flat
  institutions (vjeronauk 0.48/0.28, katoličke škole 0.44/0.27, odgoj 0.44/0.26).
- **Its peak recurs commemoratively:** the modal peak month is **February — the annual maximum in 3 of 4 years** —
  matching the death anniversary (10 Feb 1960; beatification 3 Oct 1998). A **repeating calendar peak = memory
  ritual**, not a one-off news spike. **Signal #2 independently corroborates signal #4** — two of four signals now
  point the same way for Stepinac.
- The institutions peak in scattered school-year / news months without that recurrence (vjeronauk Mar, škole Apr,
  odgoj Dec). `rituali` peaks in **August 3/4 years** — expected (summer pilgrimages/SHKM are themselves calendar
  events). `strossmayer` shows no strong recurrence — consistent with the 19c-register under-detection (§7).

## 9. Second pass — Q2½ actor decomposition (the novel contribution)

The slice is **87% web** ([platform mix](output/tables/platform_mix_by_entity.csv)), so the reach×interactions
quadrant (Divovi/Megafoni/Graditelji zajednica/Specijalizirani akteri) is only weakly differentiating (Stepinac
leans slightly to **Divovi/Giants** — mean Stepinac-share 0.053 among Giants vs 0.03 among Megaphones). The
**named-outlet** signal is where the entities separate sharply
([top sources](output/tables/top_sources_by_entity.csv), [confessional/secular](output/tables/confessional_secular_by_entity.csv)):

- **Stepinac — a *shared national* lieu.** Top sources mix confessional (hkm.hr 1359, laudato.hr, zg-nadbiskupija.hr)
  with a distinctive **secular/nationalist cluster** (narod.hr, hercegbosna.org, dragovoljac.com, kamenjar.com) and
  mainstream (Večernji, Slobodna Dalmacija). Among *classified institutional* outlets he is the **most secular-shared
  memory anchor — only 62% confessional** (vs katoličke škole 80%, rituali 75%, vjeronauk 72%). A national memory
  figure co-produced by Church *and* secular press — the Nora dynamic exactly.
- **vjeronauk — present-tense contestation.** Uniquely among all entities its top sources include the **secular
  debate forums** `reddit/croatia` (417) and `forum.hr` (305) — appearing for *no other entity*. Religious
  instruction in schools is *argued*, not commemorated.
- **odgoj / values — broad secular value-politics.** The most secular-mainstream spread (Jutarnji, Index, Net.hr,
  24sata); only **51% confessional** among classified — the least Church-internal.
- **katoličke škole (80%) / rituali (75%) / redovi (67%) — predominantly Church-internal** (unicath.hr,
  redovnistvo.hr, radio-medjugorje, devotional YouTube/Facebook).

**Each entity has a distinct actor signature that maps onto the memory↔present-tense axis** — the empirical spine
of the Q2 argument, and the part no humanities essay or Catholic-outlet study could produce. *(Outlet labels are the
PI's `proposed` set — indicative; ~30–44% of posts are classified, forums/small sites unlabeled.)*

## 10. Second pass — signal #3 (affective charge)

Sampled (cap 800/entity → 5,548 posts), udpipe-lemmatized, joined to CroSentilex (polarity) + lilaHR (8 emotions),
the canonical `diskurs.qmd` approach. **CroSentilex token coverage 54.8%** ([table](output/tables/affect_by_entity.csv),
[figure](output/figures/affect_emotion_profile.png)). Indicative, not hand-validated.

**Polarity does NOT differentiate — do not use it as the affect signal.** Mean CroSentilex polarity is uniformly
≈ **−0.42** across *every* entity, with a ≈0.99 "non-neutral share." That uniformity is an artifact, not a finding:
CroSentilex-full contains only signed words (no neutral entries), so a share computed over *matched* tokens is ≈1 by
construction, and averaging signed weights over all matched tokens is dominated by shared news vocabulary (~71% of
matched tokens are negative-lexicon words — common in Croatian news regardless of topic). **Affect is the noisiest
signal, as the proposal anticipated (§3 downgraded it to *supporting*).**

**The lilaHR emotion *profile* is weakly differentiating and thesis-consistent.** Reading the 8 emotions (mean
per-doc share), three registers separate — modest magnitudes, indicative:

| entity | Ljutnja | Strah | Tuga | Gađenje | **Povjerenje** | Radost |
|---|---:|---:|---:|---:|---:|---:|
| **stepinac** | **0.068** | **0.102** | **0.079** | **0.043** | **0.302** ↓ | 0.145 |
| vjeronauk | 0.049 | 0.085 | 0.057 | 0.031 | 0.348 | 0.148 |
| katolička škola | 0.044 ↓ | 0.081 ↓ | 0.055 ↓ | 0.030 ↓ | **0.366** ↑ | 0.148 |
| rituali | 0.041 | 0.079 | 0.064 | 0.026 | 0.320 | **0.174** ↑ |

- **Stepinac → a conflict/persecution register:** the highest anger, fear, sadness *and* disgust of any entity, and
  the **lowest trust** — consistent with a memory of martyrdom/communist persecution.
- **The institutions (katoličke škole, vjeronauk) → a trust/pastoral register:** the highest trust, the lowest
  conflict emotions — a formative, in-group warmth.
- **Rituali → a joy register** (highest Radost) — celebratory pilgrimage/SHKM events.

So affect adds a **third weak-but-consistent** line of evidence: the memory anchor is affectively charged toward
*conflict*, the present-tense institutions toward *trust*. It should be reported as supporting, with its 54.8%
coverage and the polarity caveat stated plainly.

## 11. What this means for the paper / next steps

1. **The spine survives contact with the data, and the thesis now rests on FOUR converging signals** (all four are
   computed). Stepinac scores as the singular genuine *lieu* on **genuine past-anchoring (#4, 0.239 vs foil 0.098)**,
   **commemorative peaking (#2, recurring February maximum)**, a **shared-national actor signature (Q2½, most
   secular-shared)**, and a **conflict affective register (#3, highest anger/fear/sadness, lowest trust)** — while
   the educational institutions are, on all four, a present-tense value-political field with a trust register.
   That convergence across independent signals is the paper's backbone (affect is the weakest leg — report it as
   supporting, with its coverage caveat).
2. **Stage B corpus selection** from evidence: Stepinac as the anchor case; vjeronauk (with its reddit/forum debate)
   as the contrasting present-tense field; Petković (302) as a small rare-*lieu* probe.
3. **Before Stage C:** add the 19c past-token register (rescue Strossmayer), and **hand-validate** genuine-linkage
   on ~150 posts with Cohen's κ (converts every share above from indicative to measured).
4. **The actor decomposition (Q2½) is the novel *New Media & Society* contribution** — foreground it.
