# Plan: "Tko govori o vjeri?" — names, voices and networks in the Catholic corpus, machine-only edition

**Date:** 2026-10-25 · **Owner:** PI (doc. dr. sc. Luka Šikić) · **Status:** proposed, awaiting PI go
**Study folder (to create):** `studies/catholic-voices-network/` · **Report:** Croatian PDF + HTML via the annual-report Typst chain
**Constraint set by the PI:** no human coding and no human validation. Every quality control below is a machine check.
**Input:** the official corpus, 611 583 rows × 55, sha256 `5d8b6959…`, read through `DIGIKAT_CORPUS_PATH`, never copied into the study.

---

## 0. Goal, and what "no humans" changes

Goal: say who is named, who is given a voice, who explains religion, and how these people connect across outlets and
platforms in the Croatian digital discussion of Catholicism, 2021-01-01 → 2026-10-16, as a flagship report.

Without hand coding, precision and recall of any layer are **unmeasured**. The design therefore (a) builds every layer from
components whose errors are at least *visible* to a machine, (b) replaces accuracy measurement with a fixed battery of
machine checks (grounding, agreement, known answers, stability), (c) pre-registers a publication policy that decides
*before the main run* which results may be printed and with what wording, and (d) says on every page of the report that
no human validated the recognition, exactly as the first theological-voices report did (PI decision 2026-10-13).

Two earlier runs set the baseline this plan improves on:
- `studies/theological-voices` (v1): regex role cues + closed list + speech-verb window; fast, unvalidated, closed list only.
- `studies/theological-voices-v2`: Qwen3 14B reading 2 000 whole web articles in three passes; **59 s per article measured
  over 1 750 articles** (18–19 Oct 2026); ended "limited exploratory" because its own semantic checks failed. Lesson: the
  LLM must read *passages*, not articles, and must be the last tier, not the first.

## 1. Decisions taken in this plan (defaults; the PI may overrule any of them)

| # | Decision | Default |
|---|---|---|
| D1 | Inference location | Local only (Ollama on this machine). No corpus text leaves the machine. |
| D2 | Second local model for cross-model agreement | `gemma3:12b` (≈8 GB pull). The only "independent reader" available without humans. |
| D3 | LLM reading unit | Paragraph window: mention sentence ± 2 sentences, capped at 1 200 characters. Never whole articles. |
| D4 | Corpus-wide role labels | Distilled classifier (XLM-R-base or BERTić) trained on LLM labels; LLM itself codes ≤ 100k passages. |
| D5 | Claims layer | Machine-only inductive module (propositions → embeddings → clusters), **exploratory level only**, appendix. |
| D6 | Naming policy | A person is named only if public by role (office register or Wikidata item) AND ≥ 20 documents AND ≥ 3 distinct outlets. Others aggregate into roles. |
| D7 | Era handling | Quarter slices within each collection era; no volume comparison across 2024-01-01; shares and ranks only. |
| D8 | Working storage | One DuckDB file outside Git and Dropbox, `DIGIKAT_VOICES_WORKDIR` (same pattern as the barometer workdir). |
| D9 | Platform scope | All nine platforms for mentions; speech/role only where text ≥ 300 chars (drops 58 % of Twitter rows by construction, stated in the report). |
| D10 | YouTube text | Treated as "available text" (descriptions/captions); the report never claims what was *said* in a video. |

## 2. Environment and storage

```powershell
# Python 3.11 (3.14 is the default here and has no torch/classla wheels)
py -3.11 -m venv C:\Users\lsikic\venvs\digikat-nlp
C:\Users\lsikic\venvs\digikat-nlp\Scripts\pip install torch --index-url https://download.pytorch.org/whl/cu124
C:\Users\lsikic\venvs\digikat-nlp\Scripts\pip install classla duckdb pyarrow pandas rapidfuzz requests datasketch `
    transformers datasets accelerate scikit-learn networkx
python -c "import classla; classla.download('hr'); classla.download('hr', type='nonstandard')"
ollama pull gemma3:12b            # D2; qwen3:14b and bge-m3 already present
setx DIGIKAT_VOICES_WORKDIR "C:\Users\lsikic\Luka C\DigiKat_voices_work"
# R (global library, --vanilla, because the clone's renv is unrestored):
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla -e "install.packages('backbone')"
```

Storage: `<WORKDIR>/voices.duckdb` with tables `docs`, `mentions`, `forms`, `entities`, `aliases`, `offices`,
`candidates`, `llm_calls`, `labels`, `statements`, `propositions`, `edges_*`. Every table carries `corpus_sha256`,
`config_hash`, `created_utc`. Parquet exports of identity-free aggregates go to `studies/catholic-voices-network/output/`;
anything with names, URLs or text goes to `output/private/` (gitignored by the `explorations/**/output/`-style rule — verify
with `git check-ignore` before the first write). `R/check_disclosure.R` scans `studies/**` and is the commit gate.

GPU rule: CLASSLA (torch) and Ollama **never run concurrently** — 20 GB VRAM holds one of them comfortably, not both.
Text hygiene before any model: strip NUL, U+FFFE, U+FFFF and C0 controls (six DetermDB rows carry U+FFFE; base R
`tolower` dies on them). Read everything as UTF-8 explicitly.

## 3. Pipeline stages

Scripts live in `studies/catholic-voices-network/`, numbered, each idempotent and resumable (checkpoint every 5 000
documents; rerun skips completed `doc_id`s). `00_common.py` / `00_common.R` resolve paths, assert the corpus sha256
against `data/digikat_corpus_manifest.json`, and write `config_hash`.

### S0 — Pilot and throughput (Days 1–2)
- `01_export_docs.R`: read corpus in place, write `docs` (dk_source_id, platform, date, FROM, AUTHOR, TITLE, text_clean,
  n_chars, era) to DuckDB. Compute exact-text hash and a MinHash signature (datasketch, 128 perms, 5-word shingles) for
  near-duplicate families — this replaces re-embedding the corpus for the circulation analysis.
- `02_pilot_ner.py`: stratified 10 000 docs (platform × era). Measure: chars/s for `tokenize,ner`; chars/s for
  `tokenize,pos,lemma,depparse` on quote-bearing sentences; PERSON spans per 1 000 chars by platform; share of spans whose
  lemma differs from surface (inflection load). Output `pilot_report.json`. **Gate:** projected full-corpus NER time ≤ 3 nights,
  else switch nonstandard platforms to `tokenize,ner` only and web to the full pipeline.
- `03_pilot_llm.py`: 300 pilot passages through Qwen3 14B with the S4 schema, `think=false`, `OLLAMA_NUM_PARALLEL=4`,
  `num_ctx=2048`. Measure seconds per passage (single and parallel) and JSON-validity rate. **Gate:** ≥ 97 % valid JSON;
  effective ≤ 4 s per passage, else move to `qwen3:8b` for the first tier.

### S1 — Entity detection, corpus-wide (Days 3–5, nights)
- `10_ner.py`: CLASSLA-Stanza, standard model for `web`, nonstandard for the other eight platforms; full text, not the
  3 000-character window; GPU; batch by length. Writes `mentions` (doc_id, start, end, surface, type ∈ {PER, ORG, LOC},
  sentence_id, paragraph_id) for PER and ORG.
- `11_gazetteer_recall.py`: regex pass for every name in the v1 closed list `studies/theological-voices/voices.csv` using its
  `inflect()` logic → `forms_gazetteer`. Machine check **M-REC-1**: share of gazetteer hits that NER also found, per platform
  (a recall proxy for *known* names; reported, not assumed).
- Compute budget: 1.66 billion characters. Planned 1–3 nights; the pilot replaces this guess.

### S2 — Identity resolution (Days 5–8)
- `20_forms.py`: normalise each PER span → strip titles (prof., dr., mons., fra, don, vlč., s., kardinal, nadbiskup, biskup,
  ministar …; keep the title as `cue`), lemma per token from CLASSLA, nominative candidate, gender hint from the title/verb
  agreement in the sentence where available.
- `21_cluster.py`: blocking key = surname lemma. Inside a block: merge if first-name lemma or initial compatible AND
  Jaro-Winkler(nominative) ≥ 0,90 AND cues not contradictory (a *biskup* and a *ministar* with the same surname split).
  Canonical name = most frequent full nominative form. Writes `entities`, `aliases` (form → entity, with evidence count).
- `22_offices.py`: build the **office register** from Wikidata SPARQL, no hand coding: P39 (position held) with P580/P582
  for all Catholic dioceses of Croatia and BiH, HBK and BK BiH officers, nuncios, popes, Croatian presidents, prime
  ministers and ministers 2021–2026; store `offices` (entity_qid, office_label_hr, place, start, end). Extend v1's dated pope
  rules to every office: a title-only mention ("zagrebački nadbiskup", "Sveti Otac", "ministar obrazovanja") resolves by
  date and place cue, else stays a role-only node.
- `23_wikidata_link.py`: for the top 1 500 entities by document count, query Wikidata search (hr labels/aliases), accept a
  match only if the description or P106/P39 contains a role token consistent with the entity's cues; store QID, P106,
  P39, P569, P570. Classes: **contemporary** (alive in the document's year), **historical** (P570 < document date, or
  canonised), **sacred** (fixed stopset: Isus, Krist, Marija, Gospa, Bog, Duh Sveti, apostles), **unresolved**.
- Machine checks: **M-ID-1** pope-by-date consistency (Franjo ≤ 2025-04-21, Lav XIV ≥ 2025-05-08; count violations);
  **M-ID-2** direct speech attributed to an entity after its P570 date (expected ≈ 0; printed); **M-ID-3** cluster
  stability — rerun clustering with threshold 0,88 and 0,92, report share of top-300 entities whose document count moves
  > 5 %; **M-ID-4** a 500-pair random sample of merged forms exported for *the PI's eyes only*, not scored, kept private.

### S3 — Speech layer, rule tier, corpus-wide (Days 7–9)
- `30_quote_rules.py`: on every paragraph with a contemporary PER mention: quotation marks („“ "" »« ''), the speech-verb
  lemma list from v1 extended (reći, kazati, izjaviti, istaknuti, naglasiti, poručiti, upozoriti, dodati, pojasniti,
  objasniti, napisati, smatrati, tvrditi, podsjetiti, zaključiti, komentirati, poručivati, izjavljivati, kazivati), and
  the patterns *prema riječima X*, *kako je rekao/rekla X*, *X za <outlet>*. Run CLASSLA depparse on those sentences only;
  speaker = nsubj of a speech verb if it is (part of) a PER span; content = ccomp/parataxis/obj clause or the quoted span.
- `31_first_person.py`: social platforms where AUTHOR or FROM resolves to a person entity and the text is first-person
  (1st-person verb forms / *ja*, *mi*) → `mode = first_person`, speaker = account holder.
- Writes `candidates` (doc_id, paragraph_id, entity_id, rule_mode ∈ {direct, indirect, first_person, none}, evidence span).
- Machine check **M-SP-1**: AUTHOR known-answer test — on first-person social posts, does the rule tier name the account
  holder as speaker? Report the recovery rate per platform.

### S4 — LLM passage coder (Days 9–12 development, Nights 12–16 main run)
- `40_llm_coder.py`: Ollama, `qwen3:14b`, `think=false`, temperature 0, JSON schema enforced via `format`. One call per
  (document, paragraph) window containing ≥ 1 contemporary PER or an ORG speaker. Schema:
  `speakers[]: {surface, entity_id|null, mode ∈ {direct, indirect, first_person, institutional, none},
  proposition_status ∈ {stated, announced_only, none}, proposition_summary (≤ 160 chars),
  function ∈ {explains_doctrine, explains_practice, pastoral, testimony, political_comment, institutional_info, other},
  authority_cue ∈ {office, academic, experience, scripture, none}, relation: {target_surface, type ∈ {criticizes, supports,
  cites, none}}, evidence: verbatim substring}`. The codebook text is lifted from v2's `CODEBOOK.md` (announcement vs
  stated proposition; attendance is not speech; quotation marks alone prove nothing).
- Selection for the LLM (≤ 100k windows): every window for the top 300 contemporary entities, capped at 300 random windows
  per entity per era; plus 15 000 random windows across all other entities; plus every window the rule tier marked
  `direct`/`indirect` but with an ambiguous subject.
- Hard grounding gates, applied in code to every response (**M-GR-1…4**): JSON valid; `evidence` is a verbatim substring
  of the window; every `surface` occurs in the window or equals AUTHOR; `entity_id`, if given, is a mention in that
  paragraph. Failing a gate → retry once at temperature 0,2 → else `task_failed` (counted, never silently dropped).
- Synthetic suite: reuse v2's 30 constructed cases + 4 probes (`diagnostic_inputs.json`, `statement_probe_inputs.json`),
  add 20 cases for first-person posts, title-only speakers, and historical quotations. **Gate before main run:** ≥ 52/54.
- Cross-model agreement (**M-AG-1**): a fixed 2 000-window sample coded by both `qwen3:14b` and `gemma3:12b`; Cohen's
  kappa per field (speaker identity, mode, proposition_status, function). Reported in the methods chapter. Policy use: §4.
- Determinism (**M-ST-1**): rerun 1 000 windows with the same configuration; share of identical outputs per field.
- Throughput target from the pilot; planning figure 2–4 s effective per window ⇒ 100k windows ≈ 3–5 nights.

### S5 — Distillation to a corpus-wide classifier (Days 13–14)
- `50_train_classifier.py`: fine-tune `xlm-roberta-base` (or `classla/bcms-bertic`) on LLM labels for three heads:
  `has_attributed_speech` (per window × entity), `function`, `authority_cue`. Hold out 15 % of LLM-labelled windows;
  report agreement with the LLM there (**M-AG-2**, a *model–model* agreement, labelled as such).
- `51_apply_classifier.py`: label every remaining candidate window (estimated 300–500k). GPU, ~minutes to an hour.
- If S4's measured throughput makes direct LLM coding of *all* windows ≤ 7 nights, skip S5 and code everything with the LLM
  (fewer moving parts beats speed). Decide at the end of Day 12 from the pilot numbers.

### S6 — Claims module, exploratory (Days 15–16, optional for edition 1)
- `60_propositions.py`: take `proposition_status = stated` summaries for the top 100 speakers; embed with `bge-m3` via
  Ollama (tens of thousands of short strings → minutes); cluster with HDBSCAN/Leiden on a kNN graph; label each cluster
  with Qwen3 from 10 sampled propositions (the `R/semantic/16_wiki.R` pattern, local). Output speaker × claim-cluster
  bipartite with per-speaker counts; congruence network = speakers sharing ≥ 2 clusters, backbone-filtered.
- Stance is **not** coded (no human to check it). The module describes shared *topics of assertion*, not agreement.

### S7 — Networks and measures (Days 15–17)
- `70_networks.R` (igraph, tidygraph, backbone, ggraph; `--vanilla`):
  1. Person–outlet bipartite, two layers (*mentioned*, *speaks*); projections through `backbone::sdsm()` (α = 0,05, FDR);
     persons = contemporary entities passing D6.
  2. Person–person co-mention within **paragraph** windows; same backbone; Leiden communities; betweenness brokerage.
  3. Directed relation network from S4 `relation` (criticizes / supports / cites), edges with ≥ 3 independent documents.
  4. Temporal: quarter slices within era; rank stability of the top 20 (Kendall τ between adjacent quarters).
- Measures per person: mentions, speaking appearances, interpretive appearances (function ∈ explains_*), breadth
  (distinct outlets, distinct platforms), confessional–secular E-I index from `resources/dictionaries/source_labels.csv`
  (`label ∈ {confessional, secular}`; unlabeled outlets reported as such), top-10 share of all speaking appearances,
  persistence (quarters active ≥ 1 appearance), originating vs circulating (MinHash families: one contribution, n copies).
- **M-ROB-1** error propagation: perturb the *speaks* edge list by dropping and adding edges at rates 10 % / 20 % / 30 %,
  200 replicates; report how often each top-20 person stays top-20 and the community partition's NMI. This is the
  substitute for "would the finding survive the unknown error rate", printed in the methods chapter.
- **M-ROB-2** strict vs lenient: all rankings under (rule tier only) vs (rule ∪ model tier); both printed.

### S8 — Report (Days 18–20, buffer to Day 25)
- Scaffold via `/new-study` (README with RQ, slice, status; refs.bib). Report chain copied from `studies/annual-report`:
  `report_lib.R`-style registry (every printed number from `report_data.json`), `register_fig()` for figure words, generated
  tables synced into `REPORT_TEMPLATE.qmd`, `05_report_checks.R`-style gates (byte-identical fragments, every scalar
  present, UTF-8 intact, ≥ N titles/source notes), Typst PDF + HTML via `C:/Program Files/Quarto/bin/quarto.exe` (1.9.38; the
  per-user 1.6.43 must not win). Figures through `R/theme_digikat.R` and `theme_digikat_void()`; U+00A0 thousands separator.
- Running footer on every findings page: *Imena i izjave prepoznati automatski; nije provedena ljudska provjera.*
- Chapters: 1 Tko se spominje · 2 Tko dobiva riječ · 3 Tko tumači vjeru · 4 Mreže: izvori i osobe · 5 Vrijeme i
  događaji · 6 Dodatak: tvrdnje (exploratory) · Metodologija (all machine checks with their numbers) · Ograničenja.

## 4. Machine-only quality framework and pre-registered publication policy

| Check | What it measures | Threshold → consequence |
|---|---|---|
| M-GR-1…4 grounding | evidence verbatim, names present, ids valid | failure > 2 % of calls → the field is **withdrawn** for that run |
| M-REC-1 gazetteer recall proxy | NER finds known names | < 90 % on a platform → that platform's person counts labelled *lower bound* |
| M-ID-1/2 known answers | dated offices, speech after death | violations > 1 % → resolution reworked before networks |
| M-ID-3 cluster stability | sensitivity to merge threshold | > 10 % of top-300 move → report counts as ranges |
| M-SP-1 AUTHOR recovery | first-person speaker attribution | < 85 % → first-person mode excluded from "speaks" |
| M-AG-1 cross-model kappa | Qwen3 vs Gemma3 per field | κ ≥ 0,70 → field publishable as *model-coded*; 0,50–0,70 → appendix only; < 0,50 → withdrawn |
| M-AG-2 distillation agreement | classifier vs LLM on hold-out | < 0,85 accuracy → use LLM labels only, shrink scope |
| M-ST-1 determinism | identical reruns | < 95 % identical → temperature/prompt fixed before main run |
| M-ROB-1/2 robustness | ranking survival under perturbation | printed; a top-20 member surviving < 80 % is marked unstable in the table |

Publication levels, fixed now:
- **Level A (findings chapters, counts):** mentions of public figures, outlet and platform distribution, co-mention
  backbone, circulation families. Wording: *automatsko prepoznavanje imena*.
- **Level B (findings chapters, model-coded shares):** speaking appearances, interpretive appearances, E-I index, relation
  network — only for fields with M-AG-1 κ ≥ 0,70. Wording: *prema modelskom kodiranju, bez ljudske provjere*.
- **Level C (appendix, exploratory):** claim clusters, any field with κ 0,50–0,70, YouTube/Twitter speech.
- Nothing in the report states accuracy, precision or recall. Nothing is inferred about belief, trust or influence.

## 5. Disclosure

- Named in print: contemporary persons passing D6 only. Role-only nodes ("župnik", "vjeroučiteljica") are never resolved to
  a private individual. Accounts not in `source_labels.csv` with `publish = yes` and not a domain are shown as a platform
  aggregate, matching the „Moj medij" policy.
- `output/private/`: DuckDB, mention table, evidence spans, LLM raw responses, any list of names with counts below D6.
- `output/`: aggregate CSV/JSON only; `R/check_disclosure.R` must pass before any commit; small cells (< 5) suppressed.

## 6. Schedule (working days; start Monday 2026-10-26)

| Day | Work | Machine (nights) |
|---|---|---|
| 1–2 | §2 environment; S0 pilot; DuckDB schema; study scaffold | pilot NER + LLM timing |
| 3–5 | S1 NER launch; gazetteer recall; S2 forms + clustering v1 | NER corpus-wide, nights 3–5 |
| 6–8 | S2 office register (SPARQL), Wikidata link, classes; S3 rule tier | depparse on quote sentences, night 7 |
| 9–12 | S4 coder: schema, codebook, synthetic suite ≥ 52/54, cross-model sample, determinism | M-AG-1 + M-ST-1 runs |
| 12–16 | Decide S5 vs all-LLM (Day 12); main LLM run | LLM nights 12–16 |
| 13–14 | S5 train + apply classifier (if chosen) | ~1–2 h GPU |
| 15–17 | S7 networks, measures, robustness; S6 claims module | HDBSCAN + cluster labelling, minutes |
| 18–20 | S8 report assets, template, checks, PDF/HTML, disclosure gate | — |
| 21–25 | Buffer: rework after check failures; PI read-through | — |

Calendar: **report draft by 2026-11-20, buffered to 2026-11-27.** Engineering effort ≈ 15–18 working days. The GPU is busy
roughly 10 of 25 nights and is never shared between CLASSLA and Ollama.

## 7. Deliverables

1. `studies/catholic-voices-network/` with numbered scripts, `README.md`, `CODEBOOK.md`, `refs.bib`, `config_hash` log.
2. Open-data by-products (tracked, no PII): `offices.csv` (dated Catholic and state offices for Croatia/BiH 2021–2026),
   `aliases_public.csv` (surface forms → canonical names for persons passing D6), aggregate network edge lists (public nodes).
3. `output/private/report/tko-govori-o-vjeri.pdf` + HTML, 25–35 pages, Croatian; machine-check table in Metodologija.
4. `report_data.json` — every printed number; `claims.json`-style evidence trail; Level A/B/C tags per claim.
5. Optional site page `pages/studije/tko-govori-o-vjeri.qmd` after the PI's read-through (separate decision).

## 8. Risks and fallbacks

- **NER too slow** → nonstandard platforms `tokenize,ner` only; or spaCy `hr_core_news_lg` on CPU for social text.
- **LLM too slow** (> 4 s/window) → `qwen3:8b` first tier, 14B only for rule-ambiguous windows; or shrink the top-K to 200.
- **Cross-model κ < 0,70 on `function`** → interpretive-role results drop to the appendix; the report still carries A-level
  chapters 1, 4, 5 in full. The plan does not depend on Level B surviving.
- **Wikidata coverage of Croatian clergy is thin** → office register completed from diocesan websites by rule-based scraping
  of "biskup" pages (still no coding); gaps listed in Ograničenja.
- **Dropbox file locks** → workdir outside Dropbox (D8); only small aggregates written into the repo.
- **Python 3.14 default** → every script shebang/launcher uses the 3.11 venv path explicitly.
- **GPU contention** → a single `run_all.ps1` sequences stages; no stage starts while another holds the GPU.

## 9. What the report can and cannot say (fixed wording for Metodologija)

Can: how often names are recognised, where they appear, which outlets print which voices by model coding, how stable those
patterns are under perturbation, how two independent local models agree. Cannot: accuracy of any layer, what was said in
videos, who audiences trust, whether a voice is influential, any stance a speaker holds on a claim. The 2024 collection
change forbids cross-era volume comparison; all cross-era statements are about shares and ranks.

## 10. Rejected alternatives

- LLM reads every article (v2 design): 611k × 59 s ≈ 418 days of GPU; also unvalidatable. Rejected.
- Regex-only on a closed list (v1 design): cannot discover new names, cannot attribute speech. Kept only as a recall probe.
- Cloud API for passages: faster, but contradicts the standing local-only handling of corpus text (`R/semantic/README.md`)
  and the v2 master instruction; would need an explicit PI data-handling decision. Not the default.
- Raw co-mention networks without a null model: ubiquitous actors (the pope) connect everyone; rejected in favour of SDSM backbones.
- Re-embedding the corpus for near-duplicates (≈ 7 h): MinHash on shingles does the same job in minutes for this purpose.
