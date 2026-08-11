# Study: Catholic *lieux de mémoire* — education as a site of memory transmission

- **Slug:** `catholic-education`
- **Owner:** memory-studies researcher (asistentica, *Mjesta sjećanja*; disertacija povijest × komunikologija)
- **Status:** working paper refreshed from the official corpus (2026-08-11); accumulator-era findings are historical
- **Created:** 2026-06-30

## Research question
**Descriptive / interpretive** (memory studies × sociology of religion × media studies — see the discipline card).

- **Q1 (detection):** Which candidate Catholic anchors in the *education* field behave like *lieux de mémoire* —
  i.e. score jointly on **recurrence × temporal peaking × affective charge × past-anchoring** (the four-signal
  construct) — and which are flat present-tense topics?
- **Q2 (falsifiable core):** When *Catholic education* is invoked (`vjeronauk`, katoličke škole, HKS, SHKM, the
  teaching orders), is it **anchored to the past** (Stepinac, komunizam, 1991., kršćanski korijeni) — *memory
  transmission* — or framed as a **contemporary value/curriculum dispute** with no memorial anchoring?
- **Q2½:** Which actors (Giants / Community-Builders / Megaphones / Specialists) activate these anchors, and with
  what emotional register?

Full design, theory, and guardrails: [PROPOSAL.md](PROPOSAL.md).

## Corpus slice
- **Input:** official `data/digikat_corpus.rds`, verified against its tracked SHA-256 manifest; 367,146 posts fall
  in the paper's 2021–2025 window and 117,180 enter the education strand.
- **Platforms:** all nine official-corpus platform types; web portals account for 84.1% of the strand.
- **Terms / theme filter:** the official corpus inclusion rule is unchanged. The study adds a local
  education-and-memory entity probe and a separately fingerprinted proximity register. It does not redefine the corpus.
- **Date range:** 2021–2025.
- **Analysis set:** full-corpus census for recurrence, proximity, timing and sources; deterministic 5,526-post
  union sample for lemmatized affect analysis.

## Method
The paper compares recurrence, coverage-aware temporal peaking, affective register and anchor-specific local
past linkage. The ±160-character measure is reported as a proximity proxy rather than semantic validation.
The February–May 2024 vendor text gap is excluded from temporal exposure, and collection streams are checked
separately. A two-coder semantic validation remains future work and is stated as a limitation.

## Outputs
- Working files live in this folder. Aggregate figures and tables are under [`output/`](output/); row-level slices
  remain ignored.
- Manuscript: [`PAPER_v2.md`](PAPER_v2.md). Public profile:
  [`pages/studije/katolicko-obrazovanje-i-stepinac.qmd`](../../pages/studije/katolicko-obrazovanje-i-stepinac.qmd).
- Re-run from the repository root with `Rscript studies/catholic-education/run_analysis.R`.

## Declarations (on publication)
- Data availability: see `/DATA_AVAILABILITY.md`
- AI-use disclosure: OpenAI Codex used for pipeline audit, execution, consistency checks and language revision

## Log
- 2026-08-11 — Complete official-corpus rerun and manuscript rewrite. Input locked to the 413,985-row official
  corpus by path, dimensions and SHA-256. The 2021–2025 education strand is now 117,180 posts. The central
  separation survives: Stepinac local past linkage is 23.2%, compared with 5.6–9.0% for institutional anchors;
  February is the annual peak in all four eligible years. Source-boundary language was weakened to a conditional
  comparison because only 37.4% of Stepinac posts are classified. The inherited `rat*` ambiguity and missing-month
  treatment were corrected. Manuscript tables, figures, standalone formats and the Croatian profile were rebuilt.
- 2026-06-30 — Study scaffolded from a memory-studies proposal. Spine fixed to **education-as-memory-transmission**
  (figures/orders + rituals kept as secondary signals). RQ sharpened via `/research-ideation`; four-signal
  operationalization of *lieu de mémoire* adopted as the measurable construct.
- 2026-06-30 — `croatian-nlp-reviewer` audited `slice.R`; fixes applied + verified (parse + recall spot-checks):
  **C1** DATE now parsed as real `Date` with a visible NA-drop count (no more silent date-drop bias);
  **C2** guard refuses the redacted disclosure sample (no false-empty table);
  **M3/M4/M5** past-anchor token now covers `komunist*`/`sekular*`/ASCII `zrtv*`/`rat*` inflections (the
  falsifiable-core signal); **m8** `katolička … škola` allows an intervening word; **M6** `redovi`→`redovi_orders`.
  Probe is SAFE TO RUN as a recall-first detection pass (precision fixed downstream by hand-validation).
- 2026-06-30 — 5-lens adversarial pressure-test of the PROPOSAL (memory-theory · religion-media domain ·
  measurement · devil's-advocate · feasibility), findings skeptically verified. Hardening applied:
  **slice.R** now computes **windowed** past-anchoring (±160 chars) with a genuine-vs-incidental split (verified:
  far-apart co-mention → not counted) + a `stepinac`/`odgoj` construct-validity control print + honest 2-of-4-signal
  framing; **PROPOSAL** Q2 reframed binary→**proportion** ("both, strategically blended" as a 3rd outcome); §3 decision
  rule now **operational thresholds + graded composite + pre-declared foil/positive-control**; §5 adds a **rare-*lieu*
  full-corpus allow-list** (sample is a speed gate, not a candidacy gate); §6 adds **circularity + secular-frame +
  κ/incidental-rate** limits; §7 hedges the "first" claim and promotes **actor-decomposition** as co-equal novelty;
  §9 adds a **scope-honesty** note (four signals measure memorial framing; identity/values via Stage C).
- 2026-07-06 — **Stage-A detection RUN on the full 710k master** (verified, exit 0) → [FINDINGS_STAGEA.md](FINDINGS_STAGEA.md).
  Headline: **Stepinac is the singular genuine *lieu de mémoire*** (windowed past-anchoring 0.239, 2.4–3.7× every other
  entity); **Catholic education itself (vjeronauk/škole/odgoj ≤0.10) is mediated present-tense, not as memory
  transmission** — the falsifiable Q2 answer. Construct-validity gate PASSED (stepinac 0.239 ≫ odgoj foil 0.098, 2.44×).
  Methods result: **69.4% of past co-occurrence is incidental** (≈ sister study's 68%) — windowing essential.
  `r-reviewer` caught a Critical per-entity-genuine bug → fixed + re-verified (finding survived, separation sharpened).
  `isusov` homonym fixed: 63k "of-Jesus" false positives → true corpus **176,312** (32,430 dropped). Temporal
  `data_source` confound confirmed stark (2025 = 100% filtered_religious artifact). Guardrail: `data/` untouched;
  454 MB slices gitignored. Next: add 19c past-token register (rescue Strossmayer), `/data-analysis` for affect +
  within-stream peaking + Q2½ actor map, hand-validate ~150 posts (κ). `/lit-review` in parallel.
- 2026-07-06 — **Second analysis pass** (signal2_actors.R, conf_secular.R, signal3_affect.R). **All four signals now
  computed; they converge on Stepinac as the singular *lieu*.** #2 peaking: Stepinac spikiest (CV 0.76) with a
  **recurring February maximum (3/4 yrs)** = commemorative. Q2½ actors: distinct per-entity signatures — Stepinac the
  **most secular-shared** memory anchor (62% confessional of classified; nationalist cluster narod/hercegbosna),
  **vjeronauk uniquely on secular debate forums** (reddit/forum), odgoj most mainstream-secular. #3 affect (udpipe +
  lexicons, 54.8% coverage): **polarity non-differentiating/artifactual — don't use it**; the **lilaHR emotion
  profile** weakly separates — Stepinac = conflict register (highest anger/fear/sadness, lowest trust), institutions
  = trust register, rituali = joy. See [FINDINGS_STAGEA.md](FINDINGS_STAGEA.md) §8–11. Guardrail: `data/` untouched.
