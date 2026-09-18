# DigiKat implementation brief — Medijski barometar demokršćanstva

**Revision 3 · reviewed 18 September 2026 · supersedes Revision 2 (same date)**
Prepared for Luka Šikić (PI). Executor: an AI coding agent working in the DigiKat repository.
Status: **awaiting PI decisions (§0.2)**. After they are answered, execute this brief end to end, stopping only at the gates in §9.

This revision is the result of a multi-lens review of Revision 2. Seven independent reviewers covered data, reuse, governance, design, concept, Croatian NLP and measurement, and adversarial verifiers then re-checked their findings. The review was run against the **current** repository (`origin/main`, ed19000) and the live DetermDB files. Every number below was measured on 2026-09-18 unless marked otherwise. Appendix A lists the measured facts and Appendix B records how the review was done.

---

## 0. Read this first

### 0.1 What changed from Revision 2, and why

| Area | Revision 2 | Revision 3 | Why (short) |
|---|---|---|---|
| Where the brief lives | `docs/tasks/…` | `studies/demokrscanstvo-barometar/BRIEF.md` (copy of this file); the plan goes in `quality_reports/plans/` | `docs/` is the generated, publicly served site. A full render deletes hand-placed files, and local paths would be published. |
| Repository state | "local checkout, path unknown" | `C:\Users\lsikic\projects\DigiKat`, **69 commits behind `origin/main`**. Branch from `origin/main`. | The stale checkout predates the official corpus, the site governance, CI budgets and the design system. |
| Instructions file | AGENTS.md | CLAUDE.md, MEMORY.md, `.claude/rules/`, `site-governance/` | AGENTS.md does not exist. |
| Autonomy | "execute, don't plan; resolve routine choices" | One plan, one PI approval, then execution with six hard stops (§9) | Plan-first rule and HARD GATES. Panel and definition freezes are PI decisions. |
| Page source | `pages/demokrscanstvo/index.html` | `pages/demokrscanstvo/index.qmd`: a Quarto page with a custom layout, vanilla JS and inline SVG | `/pages/**/*.html` is gitignored and outside the render list. OJS and chart libraries break the page budget and the network check. |
| Aesthetics | "ink/navy or deep teal … FLI-like" | DigiKat design system: ink #0F1419 opening, petrol #0F4C5C accent, cream #F5F4F0 canvas, Source Serif 4 / Source Sans 3 / IBM Plex Mono. FLI supplies the page *sequence* only. | The ratified palette is petrol-on-cream. Navy #1e3a8a is orphaned. Your request that the page read as DigiKat. |
| Place in the site | nav link somewhere | Navbar **Istraživanja → "Medijski barometar demokršćanstva"**, a homepage publication entry, a "Pokazatelji" section on the studies index, and a method section on Metodologija | "Istražite" and the maps are built on the official corpus. The barometer is a different population. |
| Text used | TITLE + FULL_TEXT, snippet fallback | Title stripped from body (FULL_TEXT starts with TITLE on ~99% of rows); **no snippet fallback**; day-level text mask; common 32,000-character cap | A snippet of ≤250 characters changes the detection regime mid-series. 118 web days have body text on fewer than 90% of rows. |
| Matching | prefix families, `mir*`, `supsidijar*` … | Enumerated, frozen surface-form lists with exclusions. DuckDB (RE2) only retrieves candidates; **every decision runs in R/stringi (ICU)**. | RE2 `\b`/`\w` are ASCII-only (`\bživot` finds 273 docs where the true count is 7,783). Naive prefixes measure pensions, animal protection, asylum status and marketing. |
| Window | adjacent sentences within one paragraph | Sentence window (s−1…s+1) plus an ≤80-token span. Newlines are soft, not walls. | Major outlets deliver text with no newlines, and several change format at the 2024-04 break. |
| Route A | any direct reference | **A1**: the tradition named as an idea (counts). **A2**: party label only (e.g. "njemački demokršćani (CDU)"), a comparison series outside both scopes. | ≈25–40% of direct-term articles are foreign-party reporting even with tight markers. Only ~11% use the term as an idea. |
| Route D | actor + programme | Speaker facet and diagnostic series by default; an inclusion route only if the PI chooses it (D4) | As specified, D is a near-subset of B, and it risks turning into an HDZ-coverage index. |
| Composition | not specified | Route set, speaker type, reference geography, outlet segment and register are recorded for every article, plus three sensitivity series | 63.5% of doctrinal-anchor articles in the panel come from confessional hosts, 61.7% from hkm.hr and laudato.hr alone. |
| Breadth denominator | frozen P | P stays the headline denominator. P_t (active outlets) is exported, and breadth is null if P_t/P < 0.9. | A collection gap must not read as "media stopped talking". |
| Weekly cards | week-over-week change | Weekly view leads with the trailing-28-day value. A change is shown only if both counts are ≥10 and the difference is not within noise. | Weekly route counts are often in single digits. |
| 2024-04 break | "comparability check" | A required **June 2024 bridge** (the one month where both instruments have full text), with a decision rule | Measured: 94% URL overlap, identical text on 99.9% of shared rows, per-outlet ratio median 0.9965. |
| Text access by the AI | "do not send full texts to an external model" (while asking the agent to inspect passages) | Capped, logged window reads (≤80 tokens, masked title/URL/author, ≤400 items), kept out of the validation draws. Humans assign every reported label; the AI proposes Nalazi only as candidate claims. | The executing agent is itself an external model. Site principle: labels, interpretations and final decisions stay human. |
| Refresh | "weekly rerun when fresh data exist" | An explicit refresh contract (§7.5): upstream imports are PI-run; the command detects new data, fails cleanly on a DuckDB lock, and commits data only | DetermDB is extended by hand-run scripts writing in place, and it is being curated right now. |
| "Done" | self-verification plus a URL | Three levels (§11): L1 ready for review, with fresh-context reviewer verdicts; L2 approved by the PI; L3 live and verified | Some reviewers cannot self-confirm by design; the manual release matrix belongs to the editor. |
| Validation | 120–200 cases, no gate | A development set, then a **definition freeze**, then a fresh PI-adjudicated evaluation draw (≈430) with a second human coder on 25%, and a precision gate per route | 30 cases per route give ±15 pp intervals and cannot decide anything. Project precedent: keyword layers were 39.5% genuine. |
| Theme rows | six rows mixing principles and policy domains | Rows are policy **domains** (Compendium Part II); principles become a separate facet (D6) | Principles drive inclusion, so principle rows would restate the inclusion rule. |
| Public data | `assets/data/demokrscanstvo/` | Built in `studies/…/output/`, then installed with `--apply` into `data/barometar/demokrscanstvo/` (a project resource), with the disclosure scan extended to it | `R/check_disclosure.R` scans `studies/**` only. `data/processed/` is a closed 14-file generation. |
| CI | "follow release rules" | Commit 0 fixes the pre-existing red CI (viewport string). The page is added to the browser/axe gate. | CI on `origin/main` is red at step 2, so nothing after it (render, links, a11y) has run. |

### 0.2 Decisions for the PI

Answer these once, before execution; the executor records them in the plan. **Recommended** options are marked. Each is a decision that changes what the barometer measures or publishes. None of them is a routine engineering choice.

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | **Public population and name.** The barometer adds a third public data population, the DetermDB general web feed, beside the official corpus and the accumulator. | (a) Ratify it as „stalni panel hrvatskih mrežnih medija" and add a named exception to the EDITORIAL_GUIDE "one official corpus" rule. (b) Do not publish. | **(a)**. Also choose the title: keep „Medijski barometar demokršćanstva" with the clarifying subtitle and the required opening sentence (§2.4) (**recommended**), or „Medijski barometar demokršćanskih i kršćansko-socijalnih ideja". Note that „barometar" evokes party-rating polls in Croatian politics, which is why the opening sentence is mandatory. |
| D2 | **Panel segments.** Confessional news publishers (hkm.hr incl. ika.hkm.hr, laudato.hr) and political portals (narod.hr, dnevno.hr, direktno.hr …) where they pass continuity | in / out, per segment | **Both in**, each tagged as a segment, with the sensitivity series „bez konfesionalnih medija" and „bez političkih portala". Diocesan, parish and institutional sites stay out as non-news. |
| D3 | **Scopes** | Širi = A1 ∪ B ∪ C (routes that pass §6); Uže = A1; A2 in neither | **As stated.** Scope labels: „Šire: demokršćanske i kršćansko-socijalne ideje" (default) and „Uže: demokršćanstvo kao tradicija i ideja". |
| D4 | **Route D** | (a) Speaker facet and diagnostic series only: included articles whose qualifying passage is attributed to a `cd_self_identified` actor. It adds no articles. (b) Experimental inclusion route: `cd_self_identified` speaker + political-institutional anchor + a distinctive principle (social market economy, subsidiarity, common good, dignity of work) in that speaker's argument, gate-tested before it enters Širi. | **(a) for v1.** The D-specific evidence is rare: "socijalno tržišno gospodarstvo" appears in 152 web articles over 2021-01…2026-08, 32% of them co-mentioning HDZ. Loosening D to generic solidarity, family or reform language would make it track the governing party's communication. Under (b): <br>• EU-treaty terms never count as doctrinal because of who the speaker is; <br>• `cd_self_identified` needs a cited statute or programme clause per party; <br>• D's evidence list is exactly route C's distinctive-principle list without the Christian anchor; <br>• the actor's government or opposition status at the article date is recorded, and the D-only share is reported per period. |
| D5 | **Identity register and route C.** Your prior paper treats the cultural-identity register as the second base of Christian democracy. | (a) Identity-register families can never satisfy C; the register is reported as a facet. (b) Family/life identity terms may count as one principle family; migration/Islam and "enemies" terms never count. | **(b)**, with the register facet and the substance/identity split published. Record the choice in the definition README. |
| D6 | **Theme rows** | (a) Policy domains from the Compendium (Part II), with principles as a separate facet: Obitelj, život i odgoj · Rad i dostojanstvo rada · Gospodarski život i socijalna država · Politička zajednica, demokracija i vjerska sloboda · Europa, međunarodna zajednica i mir · Okoliš i briga za zajednički dom · Nerazvrstano. (b) Revision 2's six rows | **(a)**. Verify the labels against the Croatian edition of the Kompendij (2005). Check where migration belongs: the Compendium treats it under human work (§297–298). |
| D7 | **Validation coding budget** | Full: ≈430 PI decisions plus a second human coder on 25%. Reduced: ≈290 decisions (±12–13 pp per route). | **Full**, if the conference date allows. Name the second coder. The AI may pre-code only as a blind third opinion, never as a reported label. |
| D8 | **Passage access by the executing AI.** Rule development needs the agent to read short passages, but Revision 2 forbids sending full texts to an external model, and the agent *is* one. | (a) **Text-access rule:** the agent reads match windows only, through a helper: at most 80 tokens, one per item, with title, URL and author masked. The helper logs item_id, purpose and date to `output/private/agent_reads.csv`, capped at 400 windows for development. No full texts, bulk exports or candidate-DB browsing. Logged items are excluded from every validation draw. Any agent-coded diagnostic is headed „CODER: Claude (assistant), not the PI" and is never reported as precision. The agent proposes Nalazi only as candidate claims bound to `summary.json` fields, and the PI writes or approves the wording. The page and the PDF carry the AI-use sentence used in Godišnji pregled 2025. (b) The AI sees only tokens and counts, and the PI reviews all passages. | **(a)**. Under (b), development takes several PI sessions longer. |
| D9 | **2024-04 break policy** | Set from the June 2024 bridge result (§5.5) | If the bridge meets the criterion, mark cross-break comparisons `comparable_bridged`. Otherwise `not_comparable_seam`. |
| D10 | **Eligibility threshold** | Body text of at least 200 characters (after title strip) | **200.** It is a choice, not a derived value. |
| D11 | **Where the rule inventory lives** | Metodologija section `#method-barometar` plus expandable families on the page; or everything on the page | **Metodologija + a short expandable summary on the page**, with the definition files as downloads. |
| D12 | **Study status** | Declare the barometer descriptive, or preregister "Study 3" on OSF before the freeze (discipline card) | **Descriptive barometer.** Keep preregistration for a later confirmatory study. |
| D13 | **Actor registry scope** | Organisations only, or also named public persons | **Organisations only** for v1. |
| D14 | **Vocabulary** | Ratify „članak" and „medij u panelu" in EDITORIAL_GUIDE, or use „objava"/„izvor" | **Ratify „članak"** for this page (web news articles). |
| D15 | **Conference** | Name, date, language, format | The executor needs it to size the work and choose the release split (§9.3). |
| D16 | **April 2024 re-download.** Raw exports were re-downloaded on 2026-09-18 (3 rows added to raw files, not yet in the DB). The seam month may change. | Import before the panel freeze, or declare the current DB snapshot final for v1 | **Decide before G1.** The panel freeze and the bridge wait for it. |
| D17 | **Seed dictionaries from a co-authored working paper** (Šikić & Sršen, „Sadržaj ili identitet?", written for Revija za socijalnu politiku). Is it the "background document" of Revision 2? | (a) Credit line on the page, README and definition files: „Početni rječnik preuzet je iz rada Šikić i Sršen (u pripremi)", with the co-author's consent to release the derived dictionaries under CC BY 4.0. (b) Co-authorship of the barometer. Also decide whether the barometer may publish before the paper. | **(a)**, with consent obtained before G4. If the paper is under anonymous review, do not name it publicly until acceptance, and do not reuse its substance-versus-identity framing in the Nalazi. |
| D18 | **Per-outlet results** | Publish per-outlet numerators/rates or not | **Not published.** No outlet-level table or chart; that would be a league table of named media. Concentration is reported anonymously on Metodologija (top-10 share of D, HHI). Per-outlet numerators stay private. |
| D19 | **Licence of derived aggregates** | Confirm that the vendor terms of the „My company/dump" export allow publishing derived aggregates under CC BY 4.0 | **Confirm before G4.** Add a DetermDB row to DATA_AVAILABILITY.md (restricted source) and a `data/barometar/**` row (open aggregates). |
| D20 | **Indicator name.** The site already defines vidljivost as what doseg (reach) estimates, and uses „medijska zastupljenost" for a share of coverage. | „Medijska zastupljenost" or „Medijska vidljivost" | **„Medijska zastupljenost"** (with „Širina prisutnosti"). Keep the internal column name `visibility_per_10000` and never show it in the interface. |

### 0.3 Operating mode

1. Follow §1 to set up.
2. Write **one** plan to `quality_reports/plans/2026-09-18_demokrscanstvo-barometar.md`. It restates the D1–D20 answers, the rejected alternatives and the gate list.
3. After the PI approves it, execute without writing further plans. Stop only at the gates G1–G6 (§9).
4. Never report "done" without the verification in §10. Never claim the page is live without opening the live URL.

---

## 1. Starting configuration

### 1.1 Repository

- Path: `C:\Users\lsikic\projects\DigiKat`. The Windows shell is Git Bash.
- Set up the branch:
  ```bash
  git fetch origin
  git switch -c feat/demokrscanstvo-barometar origin/main
  ```
- Leave the untracked `quality_reports/plans/2026-08-04_data-dictionary.md` alone.
- Copy this file to `studies/demokrscanstvo-barometar/BRIEF.md`. The copy is the executed brief. This file under `quality_reports/plans/` stays as the PI's review copy; the executor's own plan is a separate file (§0.3).
- Never stage with `git add -A`, `.` or `*`. Stage explicit paths.

### 1.2 Reading list

Nothing in this list is optional.

- `CLAUDE.md`, `CLAUDE.local.md` and `MEMORY.md`. In MEMORY.md, read at least these sections: "CI red on main", "Field-first register split and Moj medij", "Figure legibility on the mapa pages", "The content-hashed CSS trap fired locally", and the moral-economy denominator lessons.
- `.claude/rules/*.md`. The executor must know:
  - plan-first-workflow;
  - data-pipeline-protocol;
  - quarto-verification;
  - voice-and-style §2b (two registers) and §2c (commerce boundary);
  - croatian-encoding;
  - annual-report-writing, for the PDF.
- `site-governance/DESIGN_SYSTEM.md`, `EDITORIAL_GUIDE.md`, `METADATA_CONTRACT.md`, `RELEASE_CHECKLIST.md` and `METHODOLOGY_RELOCATION_MAP.md`.
- `data/EXTERNAL_DETERMDB.md`, `C:\Users\lsikic\Luka C\DetermDB\DATA_DICTIONARY.md` and `DATA_DICTIONARY_MEDIASPACE.md`. `missing-days-20260917-summary.txt` supersedes their totals.
- Patterns to copy:
  - `pages/moj-medij.qmd` + `R/06_moj_medij.R` + `assets/js/moj-medij-findings.js` (embedded JSON, fail-closed render, allow-list gate, UMD logic module);
  - `studies/annual-report/PIPELINE.md`, `INDICATORS.md` and `06_render_report.R` (recurring product, preview/`--apply`, Typst PDF built outside the repo);
  - `studies/filter-validation/README.md`, `coder_template.tpl` and `11_check_holdout_coding.R` (blinded coding);
  - `studies/moral-economy/CODEBOOK.md` (validation axes) and `cst_lexicon.R` (CST vocabulary).
- `.claude/skills/{deploy,render-page,commit,disclosure-check}/SKILL.md`.

### 1.3 Inputs

| Input | Location | Access | Notes |
|---|---|---|---|
| Merged general-media DB | `C:\Users\lsikic\Luka C\DetermDB\determDB_merged.duckdb`, table `main.media_data_all` | read-only | 41,748,837 rows after the 2026-09-17 backfill. Web: 19.4M rows, every day 2021-01-01…2026-09-10. An inventory figure only, never a page number. |
| Old DB (for the bridge only) | `…\DetermDB\determDB.duckdb`, table `main.media_data` | read-only | Used only for the June 2024 bridge (§5.5). |
| Mediaspace DB | `…\DetermDB\determDB_mediaspace.duckdb` | read-only | Fallback only. Use `union_media_data.sql` logic, `DATE < '2024-04-01'` from the old DB. |
| Dictionaries | `…\DetermDB\DATA_DICTIONARY.md`, `DATA_DICTIONARY_MEDIASPACE.md`, `missing-days-20260917-summary.txt` | read-only | The file names in Revision 2 carried download suffixes. |
| Predecessor CD dictionaries | `Church-and-dezinfo/papers/demokrscanstvo_paper.qmd`. Canonical copy: `C:\Users\lsikic\Dropbox\HKS\Projekti\Digitalni Kat\SHKM\DigiKat\Church-and-dezinfo\papers\` (sha256 `60a207e0…652d99`). A later copy under `C:\Users\lsikic\Luka C\Clanci\Lana dezinfo\papers\` differs only in its author block. | read-only | Šikić & Sršen, „Sadržaj ili identitet? …" (working paper). If neither copy can be read, stop and ask. Do not re-derive it. |
| Raw JSON | `C:\Users\lsikic\Luka C\Determ_mediaspace_full\` | not needed | — |
| Private work directory | `$DIGIKAT_BAROMETAR_WORKDIR`, suggested `C:\Users\lsikic\Luka C\DigiKat_barometar_work\` | read/write | Outside the repo and outside Dropbox. Holds candidates, evidence, caches and validation sheets. |

Never open a DetermDB file read-write. Never run while the DetermDB loaders are writing: check for recent `maintenance_import_log` or `load_log` activity first.

### 1.4 Local configuration

This follows the existing pattern of environment variables resolved in R.

- Add these functions to `R/lib/digikat_paths.R`:
  - `digikat_determdb_path()` reads `DIGIKAT_DETERMDB_PATH`. It has no default and stops with a pointer to CLAUDE.local.md.
  - `digikat_determdb_table()` reads `DIGIKAT_DETERMDB_TABLE`, default `main.media_data_all`.
  - `digikat_determdb_old_path()` reads `DIGIKAT_DETERMDB_OLD_PATH`, used for the bridge.
  - `digikat_barometar_workdir()` reads `DIGIKAT_BAROMETAR_WORKDIR`.
- Set the values in the user-level `~/.Renviron` and record them in `CLAUDE.local.md`.
- Commit `studies/demokrscanstvo-barometar/config/paths.example.Renviron` with placeholders. Add `/.Renviron` to `.gitignore`. Update the SETUP_NEW_MACHINE.md §3 table.
- **Toolchain:**
  - R 4.6.0 with renv: duckdb 1.5.4 (opens the merged file read-only, verified), stringi 1.8.7 (ICU 74), yaml 2.3.12, svglite and jsonlite. `ragg` is not in renv.lock: install it with renv and snapshot it (`/capture-environment`), or use `grDevices::png(type = "cairo-png")`.
  - No Python in the pipeline.
  - Quarto: `C:/Program Files/Quarto/bin/quarto.exe` (1.9.38). Resolve it the way `06_render_report.R` does and assert ≥1.8. Never use the 1.6.43 that wins on PATH.
  - Prepend `C:/Program Files/R/R-4.6.0/bin` to PATH for renders.

### 1.5 Where things live

| What | Path | Git |
|---|---|---|
| Brief and study docs | `studies/demokrscanstvo-barometar/{BRIEF.md, README.md, PIPELINE.md, INDICATORS.md, CHARTER.md}` | tracked |
| Pipeline scripts | `studies/demokrscanstvo-barometar/NN_*.R` + `run.R` | tracked |
| Shared libraries (no DB access) | `R/lib/barometar_text.R` (normaliser, segmenter, boilerplate key), `R/lib/barometar_rules.R` (loader, compiler, matcher). stringi only, never duckdb. | tracked |
| Definitions (frozen per version) | `resources/dictionaries/demokrscanstvo/v1/*.yaml` + `README.md`. Every file is registered in `resources/PROVENANCE.csv`. A new version goes in `v2/`. | tracked |
| Outlet registry, panel | `studies/demokrscanstvo-barometar/config/{outlet_registry.csv, panel_v1.csv, masked_days.csv}` | tracked |
| Test fixtures (invented text only) | `tests/fixtures/barometar_cases.csv`; tests in `tests/run_tests.R`; JS tests in `tests/barometar_core.test.cjs` | tracked |
| Private, small | `studies/demokrscanstvo-barometar/output/private/`, `output/intermediate/` | ignored |
| Private, heavy | `$DIGIKAT_BAROMETAR_WORKDIR/` (candidates parquet, evidence parquet, classifications, bridge, coding sheets, screenshots) | none |
| Preview of public files | `studies/demokrscanstvo-barometar/output/release/`, written by the `run.R` preview and screened by `R/check_disclosure.R` | untracked until reviewed; the release itself is `data/barometar/` |
| Public release (CC BY 4.0) | `data/barometar/demokrscanstvo/` (§7.3). Add `- data/barometar/` to `_quarto.yml` `project.resources`. | tracked |
| Page | `pages/demokrscanstvo/index.qmd` → `docs/pages/demokrscanstvo/index.html` | tracked |
| Page assets | `assets/css/barometar.css`, `assets/js/barometar-core.js` (UMD, pure), `assets/js/barometar.js` (DOM), `assets/images/barometar/` (figures, social card) | tracked |
| Conference PDF | Built in TEMP outside the repo (the `06_render_report.R` flow), then copied to `studies/…/output/<release>/`. After sign-off, copied to `assets/izvjestaji/demokrscanstvo-barometar/sazetak-<release>.pdf`. | tracked after copy |

**Never use:**
- `docs/**` by hand.
- `pages/**/*.html`.
- `data/processed/`: the closed 14-file generation owned by `R/03_aggregate.R`.
- `data/page-ready/`: not published.
- `assets/data/`: not disclosure-scanned.

**Never edit** a frozen study file (`studies/moral-economy/cst_lexicon.R`, guarded by the `expect = rsp_expected_core_posts()` population gate in `cst_core.R:109`), `R/religious_terms*.R` or `R/lib/thematic_dictionaries.R`. Copy entries, with provenance.

---

## 2. Construct and scope

### 2.1 What is measured

The barometer measures media **visibility**, in a frozen panel of Croatian online news outlets, of two things:
- **(a)** Christian democracy as a named political tradition or idea;
- **(b)** Christian social thought applied to political and public-policy questions.

Reporting, criticism and negation all count ("To nema veze s demokršćanstvom" counts). Visibility is not support, party strength, audience reach or doctrinal correctness. Inclusion classifies no article, outlet or speaker as Christian-democratic, and the barometer never infers a person's beliefs.

### 2.2 Components, routes and scopes

| Component | Route | In Širi | In Uže | Page label |
|---|---|---|---|---|
| The tradition named as an idea | **A1** | yes | yes | „Demokršćanstvo kao tradicija i ideja" |
| Party label only | **A2** | no | no | „Stranački nazivi (usporedba)", a thin comparison line and a download |
| Unresolved direct mention (neither idea cue nor party cue) | **A?** | no | no | count reported in composition |
| CST applied to a political question | **B** | yes, if gate passed | no | „Kršćanska socijalna misao"; sub-label „Socijalni nauk u političkom pitanju" |
| Christian-grounded principle argument | **C** | yes, if gate passed | no | „Kršćanska socijalna misao"; sub-label „Kršćanski utemeljen argument iz načela" |
| CD actor's programme speech | **D** | per D4 | no | „Programski govor aktera" (diagnostic) |

- A route enters Širi only by passing the precision gate (§6) for the current `definition_version`.
- A failed route is published as an „eksperimentalno" series with its precision. It is never silently kept.
- An article counts once in each scope, whatever its route set.

### 2.3 Outside the construct

State this in the definition README and on Metodologija.
- Coverage of HDZ, EPP, CDU or any other party as such.
- Church news, liturgy, pastoral appeals and charity notices without a political object.
- Christian identity or culture-war rhetoric without a social-principle argument, subject to D5.
- EU-law or decentralisation uses of subsidiarity, and treaty uses of the social market economy, without Christian grounding.
- Papal biography and naming news (e.g. Leo XIV and *Rerum novarum*), book launches, anniversaries and publication notices of encyclicals.

### 2.4 Public wording

These strings are Croatian, contain no em dashes, and use no second person on this analytical page.
- **Lead:** „Koliko su demokršćanske ideje prisutne u hrvatskim medijima i koliko se široko o njima govori?"
- **Subtitle:** „Prisutnost demokršćanskih i srodnih kršćansko-socijalnih ideja u hrvatskim mrežnim medijima". "Medijski prostor" overclaims: the barometer covers a panel of web news outlets.
- **Scope statement:** „Barometar prati koliko se u stalnom panelu hrvatskih mrežnih medija piše o demokršćanstvu kao političkoj tradiciji i o kršćanskoj socijalnoj misli primijenjenoj na politička i javnopolitička pitanja. Uključeni su izvještavanje, kritika i istupi crkvenih ustanova. Barometar ne mjeri potporu tim idejama, uspjeh stranaka ni stav autora ili izdavača."
- **Always visible under the indicator cards:** „Zastupljenost u medijima nije potpora: promjena pokazatelja ne govori o potpori demokršćanskim idejama ni o uspjehu bilo koje stranke."
- **One sentence in the opening:** „Barometar pokazuje koliko se o temi piše, a ne potporu strankama ni doseg objava." In a Croatian political context „barometar" evokes party-rating polls, so this sentence is required, not optional.
- **No source text anywhere public.** No article text, headline, quotation, snippet or article URL appears on the page, in tooltips, figure annotations, downloads, JSON values or the PDF. "Links" means links to DigiKat pages and method files only. Route explanations use the invented §3.10 examples, each labelled „izmišljeni primjer". Findings cite aggregates only. Original, unnormalised text is kept only in the private evidence store.
- **Population:** never „korpus". Use „analizirani članci iz stalnog panela hrvatskih mrežnih medija (P = {P})".

### 2.5 Facets recorded for every included article

Facets are recorded at passage level and aggregated per period and scope.

| Facet | Values | Source |
|---|---|---|
| `route_set` | any combination of A1, A2, A?, B, C, D | rule engine |
| `speaker_type` | crkveni govornik · demokršćanski akter · drugi politički akter · ostalo / nepripisano | attributed speaker of the qualifying passage, looked up in the actor registry |
| `reference_geography` | domaće · inozemno · EU · mješovito | registry actors, country names and ME_FOREIGN_HINT in the passage. demohrišćan*, HDZ BiH and foreign CD parties default to inozemno. |
| `outlet_segment` | national · regional · public_service · confessional · political_portal | outlet registry (PI-ratified) |
| `register` | supstancijski · identitarni · oba | predecessor Rječnik A vs a restricted Rječnik B (§3.1) |
| `themes` | 0..n domain rows, or Nerazvrstano | domain vocabulary in the qualifying window, never the term that triggered inclusion |
| `principles` | dostojanstvo osobe · opće dobro · opća namjena dobara · supsidijarnost · sudjelovanje · solidarnost | Tier-1/Tier-2 families in the window |

### 2.6 Sensitivity series

These are computed on every run and downloadable. They are not page toggles.
- „bez konfesionalnih medija"
- „bez političkih portala" (if D2 keeps them)
- „bez crkvenih govornika"
- „bez članaka u kojima je jedini akter HDZ"

A finding may describe a change only if the change holds in the relevant sensitivity series (§8.5, Nalazi).

---

## 3. Identification

### 3.1 Reuse sources

Copy entries into the v1 config with provenance (`source_file`, `source_object`, `source_line`, `source_sha256`, `added`, `reviewed_by`, `known_defects`). Never source the originals live and never edit them. For sources outside the repo, `source_file` is a citation id (e.g. `sikic-srsen-wp-2026`) plus `source_sha256`, never a local path.

| Source | Take | Do not take |
|---|---|---|
| **Predecessor paper** `demokrscanstvo_paper.qmd` (Šikić & Sršen). Extract with `extract_assignment()` + sha256, as in `explorations/ARCHIVE/glas-crkve-prototype/extra_measures.R`. | Rječnik A (`doctrine`, `encyclicals`, `rad`, `obitelj_policy`, `mirovine`, `stambeno_soc`, `zdravstvo_obraz`, `tradicija`) as seeds for doctrinal anchors, Tier-2 families and domain vocabulary. Rječnik C `samooznake` limited to demokršćan* and kršćansk* demokra*, plus `eu_cd` (full names) as actor-registry seeds. Rječnik B, restricted (next row). | The Latin-ASCII folding, the SPS index, `\bHrast…` (oak: 2 of 517 hits in party context), `narodnj…` (folk music), `\bDP\b`, `HDS` alone (also a composers' society), `centar-desn`, `umjerena desnica`, `politicari`, and the substring actor_map, which labels narod.hr and dnevno.hr as "Katolički mediji". |
| Rječnik B (identity register flag) | `rod_spolnost` without bare LGBT/Pride; kršćanski identitet / korijeni / civilizacija / Europa; `obitelj_identity`; islamizacija, "velika zamjena" | `domovinsk* rat*` (8,187 hits in 2025 Q1 against 600 for the gender items), branitelj…, hrvatstvo, domoljubn*, globaliz*, mainstream medij*, bare migrant forms |
| `studies/moral-economy/cst_lexicon.R` (frozen) | 16 document titles, the Tier-1 markers, `enciklik` as the generic tier, the Tier-2 terms (solidarnost, opće dobro, dostojanstvo rada, socijalna pravda) as contextual only, and the CST_ERA grouping | the live file. The `supsidijarn\w*` and `op[cć]\w+\s+dobr\w+` patterns unchanged (§3.7). |
| `studies/moral-economy/lexicon.R` | ME_ECON domains as `public_context`; ME_INFLATION_METAPHOR exclusion; ME_FOREIGN_HINT for geography | `me_build_religion_regex()`. It is built on v1 terms and repairs only 4 of the 9 leaky terms. |
| `studies/moral-economy/CODEBOOK.md` | Validation axes: 1 genuine/incidental, 2 domestic/foreign/mixed, 3 actor/commentator, 4 justice/charity/devotional/object, 6–7 principle/document | — |
| `R/religious_terms_v4.R` (v4-2026-08-10) | Christian-grounding subset, copied with term ids: kršćan*, katolička/rimokatolička crkva, evanđelje, papa/sveti otac, sveta stolica, biskup/nadbiskup, enciklika, and crkveni as ambiguous. Exclusions for the toponyms and idioms documented in `studies/filter-validation/RESULTS.md` (l.362–367, 503–505), not in v4 itself (Općina Biskupija, Sveti Križ Začretje, Vatikanska ulica, Općina Kapela, "oltar Domovine", "križni put" 1945, formulaic "Božji"). | Liturgical and devotional terms (misa, krunica, sakrament, korizma …), v1 `R/religious_terms.R`, `second_pass_v*.rds`, the ≥2 topic rule |
| `R/lib/thematic_dictionaries.R` | Provenance crosswalk plus phrase entries only: hod za život, pobačaj/abortus, eutanazij, medicinski potpomognuta oplodnja, palijativna skrb, istospoln, vjeronauk u školi, ugovor sa Svetom Stolicom, sekularnost | Bare stems ("rat" is a substring of "demokrat") |
| `studies/catholic-education/slice.R` | vjeronauk/vjeroučitelj and katolička škola/učilište/sveučilište probes (theme row 1) | `odgoj|kurikul|\bvrijednost` |
| `R/lib/digikat_utils.R` | `digikat_canonicalize_url()`. It strips known tracking parameters and the fragment, lowercases the host, strips www. and default ports, forces https, sorts the query and strips trailing slashes (`R/lib/digikat_utils.R:56-146`). Confirm this key for dedup., `digikat_hash_object()` | — |
| `R/lib/digikat_events.R` | `digikat_collection_gaps()` for the day mask cross-check | — |
| `R/lib/digikat_hr.R` | `digikat_hr_count()`, dates. Register the nouns članak, tjedan and mjesec (medij already exists). Port the plural rule to `barometar-core.js` for counts rendered in JS. | — |
| `studies/news-gap/analysis.R:219-252` | Copy the non-editorial URL rules (pagination, listing, section, homepage), rewritten with stringi, into `R/lib/barometar_url_rules.R` with provenance, and apply them to both numerator and denominator. Do not edit news-gap. | — |
| udpipe (`resources/models/croatian-set-ud-2.5-191206.udpipe`) | Offline only: proposing surface forms for review, and serving as the segmentation reference | Run-time lemmatisation: ~6.2k tokens/s, ~20 h per recompute, and wrong on the ambiguous forms (miru→mira) |
| Semantic store (Catholic-topic master only) | Optional vocabulary leads, scored with `studies/moral-economy/sem_lib.R`'s centred method. Every lead becomes an inspectable YAML entry. | Retrieval for the indicator. It does not cover general media. |

### 3.2 Definition files

Directory: `resources/dictionaries/demokrscanstvo/v1/`.

| File | Content |
|---|---|
| `direct_terms.yaml` | the CD label family (A); idea cues (A1); party cues (A2) |
| `doctrinal_anchors.yaml` | Tier-1 CST coinages, document titles, and the generic encyclical tier |
| `christian_grounding.yaml` | explicit Christian qualifiers and Church-attribution cues (C) |
| `concept_families.yaml` | Tier-2 principle families, each with a `family` id (the unit for "distinct families") and a `principle` |
| `domain_themes.yaml` | vocabulary for the six domain rows |
| `public_context.yaml` | the political-institutional anchor (law, government, parliament, minister, party, election, programme, budget, tax, pension, wage, court, EU institution, local-government decision). „Društvo", „zajednica", „javnost" or „svijet" alone does not count. |
| `identity_register.yaml` | restricted Rječnik B (§3.1) |
| `actors.yaml` | registry (§3.9) |
| `argument_connectors.yaml` | zahtijeva, protivi se, u duhu, polazeći od, na temelju, nadahnut*, poziva se na, pozivaju se na, pozivajući se na, pozvao se na, pozvala se na, prema nauku Crkve … |
| `exclusions.yaml` | homonyms, legal senses, toponyms, papal-naming and publication-notice patterns |
| `segmenter.yaml` | abbreviations, ordinals, month genitives |
| `rules.yaml` | routes, window parameters, thresholds |
| `README.md` | Croatian public explanation; also published as a download |

Rules for the files:
- **Entry schema:** `id`, `family`, `tier` (`strong` | `distinctive` | `generic`), `kind` (`token` | `phrase`), `forms` (an enumerated list), `slots`/`gap_max`/`order` for phrases, `case_sensitive`, `ascii_variants`, `exclude_if`, `excluded_forms`, `provenance`.
- **Single-quote every scalar.** R yaml reads unquoted `on`/`no`/`off`/`yes` as logical.
- **Loader** (`R/lib/barometar_rules.R`): it rejects duplicate ids, forms outside `^[\p{Ll}\p{Lu}\p{M}'’. &-]+$`, and entries without provenance.
- **Compiler:** it produces ICU `\Q…\E` alternations, longest first, and the RE2 trigger list (§3.6).
- **`definition_version`** = `'1.0.0+' + substr(digikat_hash_object(compiled_rules), 1, 12)`. The hash covers every v1 file and the text cap. `masked_days.csv` is versioned separately as `mask_version`: a new outage day changes the mask version and the affected periods, not the definition.

### 3.3 Text preparation (`normalizer_v1`, R, per candidate row)

1. `title = TITLE`. If `FULL_TEXT` starts with `TITLE` (≈99% of web rows), `body` is the remainder with leading whitespace and punctuation stripped; otherwise `body = FULL_TEXT`. The title is its own field and its own passage, and no window crosses fields.
2. **Eligibility:** `body` has ≥200 characters (D10). `MENTION_SNIPPET` is **never** used.
3. **Cap:** the first 32,000 code points of `body`, backed off to the last whitespace, in both batches. Old-batch text is truncated by the vendor at ≈32,003. Record `cap_applied`.
4. Map `\r\n`, `\r`, U+2028 and U+2029 to `\n`.
5. Normalise:
   - apply NFC;
   - map U+01C4–01CC to dž/lj/nj, U+FB00–FB06 and U+FF01–FF5E to ASCII, ð to đ, İ to I;
   - delete `\p{Cf}` (soft hyphen, zero-width characters, BOM, bidi marks);
   - map `\p{Zs}` and tab to a space, and collapse runs of spaces (never `\n`).
   - This deliberately diverges from the NFKC in `moj_medij_topics.R`; record the divergence.
6. Keep `txt` (cased) and `low = stri_trans_tolower(txt, "hr")`, and assert equal lengths.
7. **No ASCII folding.** ASCII twins are listed only where the twin is not an existing Croatian word (`demokrscan-`, `krscansko-demokratsk-`). Never `kriz-`, `puck-`, `opc-` or `zastit-`.

### 3.4 Segmentation and windows (`segmenter_v1`)

- **Hard boundary:** `\n`, but only for splitting sentences, never as a window wall.
- **Soft boundary:** `[.!?…]`, optionally followed by a closing quote or bracket, then whitespace, then an uppercase letter, an opening quote or a digit.
- **No boundary** after:
  - an abbreviation from `segmenter.yaml`: sv, dr, sc, mr, mons, o, don, vlč, preč, msgr, prof, doc, izv, dipl, ing, mag, univ, prim, npr, tj, br, st, čl, sl, itd, tzv, god, mil, mlrd, tis, kn, str, usp, v, gl, min, tel, ul, pok, al, engl, njem, lat, tal, hrv, pov;
  - an ordinal (1–4 digits or a Roman numeral + `.`) followed by a lowercase word, a month genitive, `stoljeća` or `st.`;
  - a single capital initial followed by a capitalised word.
- **Tokens** are runs of `[\p{L}\p{M}\p{N}]`; a hyphen splits tokens.
- **Window:** for a hit in sentence *s*, the window is sentences *s−1…s+1* of the same field, and all required hits must lie within `max_tokens` (initially 80) of each other.
  - 80 tokens is about 3 sentences.
  - Document any change to `max_tokens` before the freeze.
- **Gate:** sentence boundaries against udpipe (`parser = "none"`) must reach P ≥ 0.93 and R ≥ 0.93 on a seeded 300-doc sample per batch. The 2025 baseline for a first-cut splitter is P 0.938 / R 0.953. ICU's sentence iterator has no Croatian data and splits after "Sv.", "Dr. sc." and ordinals.

### 3.5 Boilerplate masking (`boilerplate_v1`)

1. Take all panel docs per (outlet, calendar month).
2. Split them in SQL with `regexp_split_to_array(FULL_TEXT, '\n|[.!?…]["”“»]?[ \t\x{00A0}]+')`.
3. Key each segment as md5 of the segment after these steps: lower-case, digits → `#`, every run of whitespace (NBSP and U+2000–200B included) → one space, trim.
4. Consider only segments of ≥40 characters that contain a trigger literal from T (§3.6).
5. A segment is boilerplate if it occurs in ≥5 distinct docs **and** on ≥3 distinct days of that outlet-month.
6. Store the table privately. Freeze it for complete months, and record `boilerplate_version`.
7. In R, apply the mask to the **raw** body before normalisation. Split it with the same pattern (stringi), compute the same key, and overwrite masked segments with spaces. Record `masked_chars`. An equivalence fixture asserts that SQL and R produce identical keys.
8. Apply the mask to numerator and denominator alike. The mask only removes matches; it never removes articles.
9. **Review check:** the validation sample must contain 0 true evidence passages that were masked.

Scale: in one week, repeated lines touch ~22% of docs, and "zakon" sits in boilerplate in 9–32% of the docs that contain it. Confessional portals carry Christian anchors in their templates.

### 3.6 Matching engine and the superset obligation

**Two engines, one semantics.**
- DuckDB (RE2) only **retrieves** candidates, using literal triggers.
- Every inclusion decision runs in R through **stringi/ICU**.
- No string sent to DuckDB may contain `\b`, `\B`, `\w`, `\W`, `\s` or lookaround.
- Barometer code must not use base-R regex (`grepl`, `regexpr`, `gregexpr`, `sub`, `gsub`, `regmatches`, `perl = TRUE`), which is ASCII-only in the same way.

**ICU semantics**
- Boundaries: `(?<![\p{L}\p{M}\p{N}_])…(?![\p{L}\p{M}\p{N}_])`.
- Phrase separators: a space, or a hyphen or dash (`[\-\x{2010}-\x{2015}]`) with optional spaces.
- `gap_max: k` allows up to *k* tokens between slots. A gap never crosses `[.!?;:,\n]`.
- `order: any` compiles both orders.
- `case_sensitive` entries match on `txt`; all others match on `low`.
- An excluded hit is kept in the evidence with its reason, and the exclusion wins.

**Stage-1 SQL**
- Filters: `SOURCE_TYPE = 'web'`, the date range, and `lower("FROM")` in the panel. Quote `"FROM"` and `"DATE"`.
- **Trigger literals T:** for every entry in a required slot of any route, take the lowercase common prefix of its most selective slot (e.g. `demokršćan`, `kršćansk`, `nauk`, `supsidijarnost`, `crkv`, `crkav`, `enciklik`, `enciklic`). Literals contain only `[\p{Ll}'-]`.
- Condition: `regexp_matches(coalesce(TITLE,'') || chr(10) || coalesce(FULL_TEXT,''), '(?i)(?:lit1|lit2|…)')`, OR a second arm that catches rows containing decomposed marks, soft hyphens, zero-width characters, digraph ligatures, full-width forms, ð or İ. The second arm exists so that normalisation can never create a match the prefilter missed.
- Materialise candidates once per `definition_version` with `COPY … (FORMAT parquet)` into `$DIGIKAT_BAROMETAR_WORKDIR/candidates/<definition_hash>_<panel_hash>/`.
- Cost: the full 2021-01…2026-09 web scan took ≈235 s with 12 threads. An RE2 alternation is 40–70× faster than `lower()` + `contains`. Expect ≈5–6% of web rows as candidates (~1M).

**Superset tests** (all required):
- (a) Static: the loader asserts that every required-slot form contains a literal from T.
- (b) Property test: for each fixture and its perturbations (UPPER, Title case, NBSP between phrase words, soft hyphen inside a word, NFD, en-dash compound, closed compound), engine hit ⇒ prefilter true. Evaluate with in-memory duckdb in a test that CI can skip; the pure-R part runs everywhere.
- (c) Empirical: 20,000 seeded prefilter-rejected panel rows per batch must give 0 anchor hits. Otherwise it is a hard stop.
- (d) Lint: fail on `\b`, `\w`, `\s` or lookaround in SQL-bound strings, and on base-R regex calls in barometer code.

### 3.7 Seed families

In this brief `*` means "enumerate the paradigm", never a regex wildcard. How forms are generated:
1. Expand stem + paradigm code: ADJ = i a o e u og oga om omu ome oj im ima ih; N_F = a e i u om ama o; N_M = ∅ a u om e i ima; N_N = o a u om.
2. Add every token that shares the stem at a Unicode left boundary in a fixed, stratified sample, with its count. This surfaces sibilarised forms (radnici, politici, enciklici, katolici, brizi) and fleeting-a forms (crkava, mišlju).
3. Review each form into `forms` or `excluded_forms`, then freeze.

Every exclusion and every sibilarised or fleeting-a form below becomes a fixture in `tests/fixtures/barometar_cases.csv`.

**Tiers.** Routes and entries use one vocabulary:
- `strong` (Tier-1): CST coinages and document titles. With a political-institutional anchor, one strong anchor is enough for route B.
- `distinctive`: principles specific to the tradition but also used in secular, EU-law or administrative senses: supsidijarnost, socijalno tržišno gospodarstvo, opće dobro, dostojanstvo rada. They count only with Christian grounding (route C), where one is enough.
- `generic` (Tier-2): e.g. solidarnost, ljudsko dostojanstvo, ljudska prava, socijalna pravda, siromaštvo, sudjelovanje, obiteljska politika. Never sufficient alone. In route C they count toward the "≥2 distinct families", as distinctive families do.

**Precedence for direct mentions:** an article is A1 if any CD-label mention carries an idea cue. Otherwise it is A2 if every mention carries a party cue or is a registered party's full name. Otherwise it is A?.

| Family | Enumerate | Exclude / must-not fixtures |
|---|---|---|
| **CD label (A)** | demokršćan-in/-ina/-inu/-inom/-i/-a/-ima/-e; demokršćanstv-o/a/u/om; demokršćansk+ADJ<br>kršćansk+ADJ / hrišćansk+ADJ + {demokrat-∅/a/u/om/e/i/ima, demokracij+N_F, demokratij+N_F, demokratsk+ADJ}, written with a space, hyphen, en dash or as a closed compound<br>demohrišćan-, demo-kršćan-<br>'christian democrat(s/ic/y)', christdemokrat-, christlich-demokratisch-, democristian-, 'democrazia cristiana'<br>ASCII twins of the above only<br>Separate flag: kršćansko-socijaln+ADJ (PI to decide whether it enters A) | 'demokratsk-' alone is not a label |
| **A1 idea cues** (±5 tokens) | the noun demokršćanstvo; načel*, vrijednost*, tradicij*, ideolog*, doktrin*, identitet*, nadahnuć*, baštin*, korijen*, svjetonazor*, orijentacij*, etik*, misao/misli/mišlju, koncept*, ideja*<br>Keep "program*", "politik*" and "pristup*" separate: they are ambiguous with party cues, so validate them | — |
| **A2 party cues** (±5 tokens) | strank*, unij*, CDU, CSU, ÖVP, EPP, klub*, koalicij*, kandidat*, čelni*, vođ*, kancelar*, premijer*, zastupni*, frakcij*, vlad*, izbor*, birač*; nationality adjective + "demokršćani" (njemački, austrijski, talijanski, bavarski, europski …) | An article with no A1 cue and no A2 cue is **A?** (unresolved): outside both scopes, count reported. |
| **CST Tier-1 (B strong)** | socijaln{i,og,oga,om,omu,ome,im} + nauk{∅,a,u,om} (masculine agreement, instrumental included)<br>crkven+ADJ / crkvin+ADJ + socijaln nauk<br>katoličk+ADJ socijaln{o,og,om} učenj{e,a,u,em}<br>socijaln+ADJ učenj- Crkv-<br>kršćansk+ADJ socijaln{a,e,oj,u,om} {misao, misli, mišlju}<br>kompendij- socijaln- nauk-<br>opć+ADJ / univerzaln+ADJ namjen- dobara<br>opredjeljenj-/opcij- za siromašn-; povlašten+ADJ ljubav prema siromašnima<br>integraln+ADJ ekologij+N_F<br>personalizam/-zma/-zmu/-zmom, personalist+N_M, personalističk+ADJ<br>document titles from `cst_lexicon.R` (apostrophe optional)<br>enciklik-a/e/u/om/ama + enciklici (generic tier, never strong alone) | socijalne/društvene nauke (social sciences); Nauković; naukovanj-; "nauk Crkve" without socijaln/društven<br>personaliz(acij/ir)- (marketing: 125,693 docs against 188 for personalizam)<br>supsidijarn+ADJ + zaštit- (asylum: 27–41% of supsidijarn hits); legal collocations with odgovorn-/primjen-/tužb-/jamč-; 'supsidijarno'<br>"Laudato" alone (outlet brand); papal-naming context for *Rerum novarum* (94% of 2024–26 mentions co-mention Leo XIV/XIII) |
| **Dignity, rights, freedom** | dostojanstv-o/a/u/om, with ljudsk+ADJ before, or osob-/čovjek-/rad-/radnik- after (gap ≤1); "dostojanstvo (ljudske) osobe"<br>vjersk+ADJ slobod+N_F; slobod+N_F savjest-i; prigovor savjesti<br>ljudsk{a,ih,im,ima} prav{a,ima} (generic tier) | dostojanstven- (adjective/adverb "dignified") |
| **Solidarity, justice, work** | solidarnost/-i/-ošću (generic)<br>socijaln+ADJ / društven+ADJ pravd+N_F<br>radničk+ADJ prav{a,ima,o}<br>prav{a,o,ima} + {radnika, radnica, radnicima, zaposlenika, zaposlenih}<br>dostojanstv- rad-; pravedn+ADJ plać-; neradn+ADJ nedjelj- | solidarn- with odgovor-/jam- (legal joint liability); the foundation name "Solidarna"; "pravnici, radnici" across punctuation |
| **Subsidiarity, participation** | supsidijarnost/-i/-ošću; načel- supsidijarn- (**distinctive**: needs Christian grounding, route C; exclusions in the CST row)<br>{političk, građansk, demokratsk, društven}+ADJ participacij+N_F<br>civiln+ADJ društv-; lokaln+ADJ samouprav- → `public_context` only | participacij- with plać-/iznos-/oslobođ-/dopunsk-/lijek-/vrtić- (co-payments) |
| **Social market, common good** | socijaln{o,og,oga,om,omu} tržišn{same} {gospodarstv-, ekonomij+N_F}; socijalno-tržišn-<br>opć{e,eg,ega,em,emu,im} dobr{o,a,u,om} (singular only)<br>zajedničk{o,og,oga,om,omu} dobr{o,a,u,om}<br>socijaln+ADJ partnerstv- | dobrobit-, dobrostanj-, "opća dobra", općin-, "općenito dobro"; legal sense (pomorsk+ADJ dobr-, "od interesa za Republiku")<br>Social market economy and opće dobro are **distinctive**: they count only with Christian grounding (route C), because they are also EU-treaty or everyday language. |
| **Family, life, education** | obiteljsk+ADJ / demografsk+ADJ politik- (+ politici); roditeljsk+ADJ dopust-/prav-; dječj+ADJ doplat-<br>zaštit- + {život-∅/a/u/om, nerođen-}, gap 0<br>slobod- odgoj-a<br>pobačaj-, eutanazij-, 'medicinski potpomognuta oplodnja', 'palijativna skrb', hod za život, vjeronauk u školi | životinj- ("zaštita životinja" outnumbers "zaštita života"); životn- ("životna sredina"); "života i imovine", "života i zdravlja"<br>Rescue verbs (zaštitili živote) need a PI call |
| **Democratic institutions** (`public_context` only, windowed, boilerplate-masked) | demokracij-/demokratij-; pluraliz-am/ma/mu/mom; vladavin- prava; ustav-, ustavn+ADJ<br>zakon: legislative forms only ("prijedlog/izmjene/donošenje zakona", zakonodav+ADJ, "zakon o …")<br>javn+ADJ politik-; izbori with a qualifier (parlamentarn/lokaln/predsjedničk/europsk), "na izborima" | footer laws ("zakon o zaštiti osobnih podataka / o medijima / o elektroničkim medijima / o igrama na sreću"); izbor = "choice" |
| **Europe, peace, stewardship** | mirovn+ADJ, mirotvor-, pomirenj-; "mir u svijetu", "kultura mira"; europsk+ADJ integracij-; "briga za zajednički dom" (all cases, incl. brizi); ekologij- (theme flag) | bare mir/mira/miru (the name Mira; "počivao u miru"), mirovin-, miris-, Miroslav/Mirko/Mirjana, mirn-, svemir, primirje |
| **Christian grounding (C)** | kršćansk-/katoličk- + (načel-, vrijednost-, etik-, nauk-, nadahnuć-, pogled-, antropologij-, savjest-); evanđelj-; "prema nauku Crkve"; attribution of the claim to a `church_body` speaker; the v4 subset (§3.1) | church buildings, feasts, place names, clergy merely attending; the toponyms and idioms in §3.1 |

### 3.8 Routes

All conditions of a route must sit in one window (§3.4).

| Route | Included when | Never sufficient |
|---|---|---|
| **A1** | A CD-label form with an A1 idea cue within ±5 tokens, or the noun demokršćanstvo. Includes negation, critique and historical tradition. | Navigation tags, boilerplate, party names |
| **A2** | Every CD-label instance in the article carries a party cue, or is a registered CD party's full name, and no A1 cue is present | Comparison series only |
| **A?** | A CD-label form with neither cue | Reported as a count only |
| **B** | A Tier-1 anchor + a political-institutional anchor, with the anchor applied to the question: same sentence, or linked by an argument/attribution connector within the window | Liturgy; publication, book or anniversary notices; papal naming; pastoral appeal without a political object. Revision 2's "social/economic arrangement" and "institutional principle" alternatives are removed as anchors. |
| **C** | Christian grounding + a political-institutional anchor + (one strong or distinctive anchor, or ≥2 distinct families of any tier), linked by an argument connector | Church term and principle in different windows; charity notices; identity-only passages (D5 decides the family/life case); one family repeated |
| **D** | Per D4 | Party or EPP affiliation; church bodies (they route to B/C) |

### 3.9 Actor registry (`actors.yaml`)

- **Fields:** `id`, `name_hr`, `aliases` (case-sensitive tokens plus clitic forms: HDZ-a, HDZ-u, HDZ-om, HDZ-ov…), `role`, `valid_from`, `valid_to`, `country`, `sources` (a URL or a document clause), `status: 'proposed'` until the PI ratifies it.
- **Roles:**
  - `cd_self_identified`: needs a cited statute or programme clause and dates.
  - `epp_affiliated`: affiliation is not ideology. HSS is agrarian and is never D.
  - `christian_conservative_non_cd`: each entry verified.
  - `church_body`: HBK, Iustitia et pax, Caritas/Karitas, dioceses. B/C speaker only.
  - `catholic_civil_society`.
  - `identity_civil_society`: e.g. U ime obitelji.
  - `historical_cd`: Hrvatska pučka stranka (1919), Hrvatski katolički pokret, HKDU, HKDS, HDS; dates verified.
  - `foreign_cd_party`: CDU, CSU, ÖVP, DC, CDA, CD&V, NSi, and HDZ BiH as a separate foreign entity.
- **Aliases that never match alone:** Merz (the blessed Ivan Merz appears in 2,882 articles, 841 of them on confessional hosts), Hrast, DP, HDS, "pučka stranka", narodnjak-, Laudato, EPP-like strings (EPPO outnumbers EPP ~20:1), EPS.
- Organisations only (D13). The registry is a retrieval aid and a facet, never an ideological classification.

### 3.10 Fixtures

These examples use invented text and double as unit tests. Revision 2's other negatives stay.

| Invented example | Expected |
|---|---|
| „Stranka se poziva na demokršćanska načela." | A1 |
| „To nema veze s demokršćanstvom." | A1 |
| „Njemački demokršćani (CDU/CSU) pobijedili su na izborima." | A2, excluded from both scopes; geography inozemno |
| „Komisija Iustitia et pax, pozivajući se na socijalni nauk Crkve, traži izmjene Zakona o radu." | B; speaker crkveni govornik |
| „U skladu sa socijalnim naukom Crkve, Vlada bi trebala povisiti minimalnu plaću." | B (instrumental form) |
| „Papa je podsjetio na Rerum novarum i dostojanstvo rada u doba umjetne inteligencije." | Excluded: no political object |
| „Zastupnik, pozivajući se na kršćansku etiku, brani ljudsko dostojanstvo i solidarnost u prijedlogu mirovinske reforme." | C |
| „Ministar govori o solidarnosti u mirovinskom sustavu." | Excluded |
| „Tražitelju je odobrena supsidijarna zaštita." | Excluded |
| „Načelo supsidijarnosti zahtijeva da općine same odlučuju o vrtićima, ističe biskup." | C (distinctive principle + political anchor + church-speaker grounding) |
| „Načelo supsidijarnosti zahtijeva da općine same odlučuju o vrtićima." | Excluded (no Christian grounding) |
| „Kršćanski identitet Europe ugrožen je migracijama." | Excluded; register identitarni |
| „Predstavljen hrvatski prijevod enciklike Laudato si'." | Excluded (publication notice) |
| A text about the blessed Ivan Merz | No actor match |
| „Personalizirana ponuda za vašu obitelj." | No match |
| „Zaštita životinja od zlostavljanja …" | No match |
| „Općenito dobro stanje ceste …" | No match |
| „Pučko otvoreno učilište upisuje polaznike." | No match |
| A long article with a church building in paragraph 1 and a council budget in paragraph 9 | Excluded (window) |
| A generic HDZ transport announcement | Excluded |
| The same A1 sentence with no newline, with NBSP, with a soft hyphen, and in NFD | A1 in every variant |

### 3.11 Evidence and determinism

- **Document key:** `doc_key = md5(concat_ws('|', SOURCE_BATCH, SOURCE_TYPE, coalesce(CAST(ITEM_ID AS VARCHAR), ''), coalesce(URL, ''), strftime(DATETIME, '%Y-%m-%dT%H:%M:%S'), md5(coalesce(FULL_TEXT, ''))))`, asserted unique among candidates.
- **Evidence rows** (private parquet), one per hit: doc_key, field, entry_id, family, tier, form, start/end (1-based code points in the normalised field), sentence_id, window_id, route flags, facet values, excluded_reason, masked, cap_applied, text_sha256, and the normalizer/segmenter/boilerplate/definition versions.
- **Order:** process in doc_key order, in fixed chunks. The only randomness is recorded seeds. Sort exports by (doc_key, field, start, entry_id).
- **Rerun check:** a rerun must reproduce the sha256 of every sorted export.
- **Viewer:** a private viewer re-derives excerpts from the raw text and asserts `text_sha256`. Excerpts never leave the work directory.

---

## 4. Article population and outlet panel

### 4.1 Eligibility

These steps are pushed into SQL where possible, in this order.
1. `SOURCE_TYPE = 'web'`, `"DATE"` in [2021-01-01, data_through].
2. **Observed-day mask.** A day is observed if it has web rows and ≥90% of **all** web rows that day have non-null `FULL_TEXT`. The mask is defined on all web rows because it is computed before the panel exists, and the panel rule depends on it.
   - Masked days are versioned in `config/masked_days.csv`. At release 1 there are 118 of them: 35 in 2021–2023 (32 near-total outages in pairs plus 3 partial days) and 2024-01-09…2024-03-31.
3. **Outlet:** `outlet_id` comes from the registry, keyed on `lower("FROM")` with a `url_host` override map. FROM is the registrable domain in both batches. A sub-host can be a separate outlet: `ika.hkm.hr` (IKA) inside `hkm.hr` is a PI registry decision.
4. **Article key** = (`outlet_id`, `digikat_canonicalize_url(URL)`). The canonicaliser strips known tracking parameters and the fragment, normalises scheme, host and port, sorts the query and strips trailing slashes. Query parameters that identify content are kept. m./AMP hosts are handled in the registry, not in the key.
5. **Dedup** within batch on the article key. The representative is the earliest capture with body ≥200 characters, and the article's day is that representative's `"DATE"`.
   - The main case is 2021-01, where web is double-loaded: 380,598 rows against ≈195.8k distinct (URL, DATETIME). Assert the post-dedup count.
   - The batches do not overlap by date in the merged file, so cross-batch dedup is needed only in the bridge run.
6. The standalone-"i" predicate is **not** applied as an eligibility rule. It is effectively a no-op on old web (18 of 269,248 rows failed in a 2023-06 probe) and was applied by the vendor loader to the new batch. Document this and assert that ≤0.01% of old-batch eligible rows would fail it.
7. The non-editorial URL rules (pagination, listing, section landing, homepage) exclude a row from both N and D.
8. **Eligible** = body ≥200 characters on an observed day, in a panel outlet, not non-editorial. By construction D ⊆ N.

### 4.2 Outlet registry

No suitable registry exists: news-gap has 6 Catholic products, `source_labels.csv` has 109 rows (all `proposed`), and `secular_outlets.csv` is a sandbox seed.

1. Build `config/outlet_registry.csv` with columns `outlet_id, from_values, url_hosts, display_name, segment, editorial, croatia_link, evidence_note, seed_source, panel_v1, status`.
2. `segment` takes the values `national`, `regional`, `public_service`, `confessional`, `political_portal`, `aggregator`, `non_news`, `institutional`.
3. **Seeds:**
   - `explorations/okvir-katolicanstva-prototype/secular_outlets.csv`;
   - the confessional labels in `resources/dictionaries/source_labels.csv`;
   - the host/product columns of `studies/news-gap/source_registry.csv`.
   - Do not edit any seed in place.
4. **Review list:** every web FROM with output in every month (409 by FROM at ≥1 row per month; 170 at ≥20).
5. **Explicit exclusions:**
   - non-news: bongacams.com, shops (namjestaj.hr, uzishop.hr, eljekarna24.hr, antikvarijat*, superknjizara.hr), betting (svijetkladjenja.com), google.com, lyrics and games sites, mirovina.hr, inmemoriam.hr;
   - institutional: gov.hr, morh.hr, unizg.hr, city and county sites, club sites (hajduk.hr, nk-rijeka.hr), diocesan and parish sites (e.g. biskupija-varazdinska.hr, djos.hr);
   - aggregators and mirrors: novine.hr, infokiosk.net, news.leportale.com, dailyadvent.com, crovijesti.com, stripovi.com, tvprofil.com.
6. The PI ratifies the registry (**gate G1**) **before any numerator is computed**. The executor may not look at Christian-democracy counts per outlet before G1.

### 4.3 Panel rule and freeze

- **Membership window:** all complete months from 2021-01 to the last complete month before the freeze, excluding the unavailable months 2024-01…03.
- **Rule:** an outlet enters if it has **≥20 eligible articles in every window month**. The probe gives ≈170 outlets before exclusions, holding ≈42–50% of web rows. Expect ~120–160 after exclusions, but do not target a number.
- **Confessional presence in a continuity panel:** only hkm.hr (with ika.hkm.hr) and laudato.hr qualify. bitno.net and glas-koncila.hr appear only in the new batch, so they cannot be in panel_v1. Say so on Metodologija.
- `panel_v1.csv` records the outlet list, k = 20, the window, the excluded months and `panel_hash`. Once frozen it never changes silently.
- An outlet with 8 consecutive complete weeks at zero eligible articles is flagged. Removing it requires `panel_v2` and a documented reason.
- Top-10 outlets hold ≈44% of N. Export the outlet-balanced visibility (§5.1) as a diagnostic.

### 4.4 Dates

- Day assignment always comes from the `"DATE"` string in SQL: `substr("DATE",1,7)` for months, and `strftime(CAST("DATE" AS DATE), '%G-W%V')` for ISO weeks.
- Never bin through R or Python datetimes. R's duckdb returns a naive TIMESTAMP as a UTC POSIXct, which shifts items near midnight into the next day.
- In the new batch the date is the vendor's `insertTime` in Europe/Zagreb; the June 2024 bridge shows identical DATETIME for shared URLs. On the page, describe it as „datum bilježenja u medijskom monitoringu", not „datum objave".

---

## 5. Indicators, time structure and statuses

### 5.1 Definitions (period *t*, scope *s*)

| Symbol | Meaning |
|---|---|
| N_t | eligible articles in the panel in *t* |
| D_t,s | eligible articles included in scope *s* |
| P | frozen panel membership |
| P_t | panel outlets with ≥1 eligible article in *t* (weeks, rolling-28) or ≥5 (months). Exported as `panel_active`. |
| M_t,s | panel outlets with ≥1 included article in *s* during *t* |
| c_t | observed days ÷ calendar days in *t* |

Indicators:
- **Medijska zastupljenost** (D20) = 10000 × D_t,s / N_t, with the unit line „na 10.000 analiziranih članaka".
- **Širina prisutnosti** = 100 × M_t,s / P, in „% praćenih medija" with „M od P medija". Breadth is **null** when P_t/P < 0.90. Note that breadth grows with period length, so never compare weekly with monthly breadth.
- **Theme rate** (per domain row *k*) = 10000 × D_t,s,k / N_t. Rows overlap and are never summed.
- **Diagnostic (export only):** `visibility_balanced` = mean over outlets with N_o,t ≥ 20 of 10000·D_o,t/N_o,t.
- **Rolling-28:** recomputed from the eligible articles and distinct outlets in the 28 days ending at each day. Its status is `published` if ≥24 of the 28 days are observed and P_t/P ≥ 0.90, and `unavailable` otherwise. The weekly card shows the window ending on the last day of the headline week (for W36: 2026-08-10…09-06), never a window ending mid-week. Never average weekly ratios, and never add weekly outlet counts.

### 5.2 Periods

- Calendar months and ISO weeks (Monday–Sunday, Europe/Zagreb, ISO week-year), both derived from one article-level classification and one private outlet × day aggregate.
- Months are never built from weeks.
- Boundary periods are `partial`: 2021-01-01…03 (ISO 2020-W53) and the running week or month.

### 5.3 Statuses

Statuses are set per indicator and per comparison, never once per period.

- **`visibility_status`**
  - `published`: a complete period with c_t ≥ 6/7 (weeks) or ≥ 0.80 (months).
  - `partial`: 0.5 ≤ c_t below that threshold, or a boundary period.
  - `unavailable`: c_t < 0.5. The value is NULL.
- **`breadth_status`**
  - `published`: a complete period, c_t = 1 (weeks) or ≥ 0.90 (months), and P_t/P ≥ 0.90.
  - `partial` or `unavailable` otherwise, with NULL when unavailable.
- **`comparison_status`**, evaluated in this order:
  - `unavailable`: either side is not published;
  - `not_comparable_version`: the definition or panel versions differ;
  - `not_comparable_seam`: the pair straddles 2024-04-01, unless D9 set `comparable_bridged`;
  - `too_few_cases`: min(D) < 10. The card reads „premalo slučajeva za usporedbu".
  - `within_noise`: the exact two-sided conditional binomial test D_a | (D_a+D_b) ~ Bin(D_a+D_b, N_a/(N_a+N_b)) gives p ≥ 0.05. The card reads „promjena unutar slučajne varijacije".
  - otherwise `comparable`.
- **Expected unavailable periods:** months 2024-01…03 and weeks 2024-W02…W13. 2024-W01 is published.
- **Provenance columns:** `backfilled_days` (the 2026-09-17 import) and `unmanifested_days` (every day since 2026-04-01) are exported per period.

### 5.4 Comparisons and cards

- **Monthly card:** the latest month where both statuses are `published`, compared with the same month a year earlier.
- **Weekly card:** the latest published ISO week. It leads with the trailing-28-day value; its comparison is with the previous complete week and appears only when `comparable`. Weekly breadth has no change badge.
- **When a change is not shown:** a card shows „promjena unutar slučajne varijacije" or „nije usporedivo" plus the reason. Numeric differences are always exported.
- **Units of change:** visibility changes are in „na 10.000", and breadth changes in „postotnih bodova". Indicators are never combined into a composite.
- **Derive the latest periods from the data; never hard-code them.** With data through 2026-09-10 (a Thursday in ISO 2026-W37), the first release should give **2026-08** (compared with 2025-08, same batch) and **2026-W36** (2026-08-31…09-06, compared with W35).
  - 2026-08 contains 16 backfilled days, and W36 contains 4.
  - Every day since 2026-04-01 is unmanifested. Record both facts in the provenance columns.

### 5.5 The 2024-04-01 break and the June 2024 bridge

- **What changes at the break:** the vendor query (Luka/opće → My company/dump, a broader crawl), a vendor-side "i" filter (a no-op for web), and some outlets' text formatting.
- **Measured so far** (on web rows, not on the panel): 94% of old June-2024 URLs are present in the new batch; FULL_TEXT is identical on 99.9% of the 281,942 shared URLs, and DATETIME and FROM are identical; the per-outlet ratio has a median of 0.9965 (p10 0.899, p90 1.044); a crude direct-term count is 394 vs 394 on shared URLs. The new-only URLs are mostly non-news (google.com, njuskalo.hr, facebook.com …), which the panel excludes.
- **Required step (`07_bridge.R`):** run the final pipeline on 2024-06-01…30 twice, with the same panel and definition: once on `determDB.duckdb.media_data` (read-only) and once on the merged new batch. Report:
  - N, D_s and M_s per run, per scope;
  - R_vis = vis_new/vis_old with a 95% outlet-cluster bootstrap CI (2,000 reps, fixed seed);
  - Δbreadth in pp;
  - D contributions from shared, old-only and new-only URLs.
- **Decision rule (D9):** if the CI of R_vis ⊂ [0.90, 1.10] and |Δbreadth| ≤ 2 pp for both scopes, the PI may set `comparable_bridged` for that `definition_version`. Otherwise cross-break pairs stay `not_comparable_seam`. Publish the bridge summary; keep the bridge table private.
- **On the page:** draw the series in segments with a marker labelled „Promjena prikupljanja · 1. travnja 2024." and a hatched NULL band for 2024-01…03. Never connect lines across NULLs or across the marker. One sentence beside the charts links to `#method-barometar-kontinuitet`.
- **Docs:** add a cross-reference to `data/EXTERNAL_DETERMDB.md` saying that June 2024 bridges luka_opce → mediaspace_full. Its §3.3, which compares DetermDB with DigiKat's filtered stream, is a different pair and remains correct.

### 5.6 Expected magnitudes

These are planning numbers from crude probes, not results.

| Series | Magnitude |
|---|---|
| Direct CD label in a ~171-outlet panel | monthly D ≈ 38–322 (3.5–31 per 10,000); weekly median ≈ 22 |
| A1 (idea use) | only ≈11% of direct-label articles, so weekly Uže counts will often be <10 and read as `within_noise` |
| Doctrinal-anchor articles | ≈90 a month on the whole web |
| Candidate prefilter | ≈1M articles (5–6% of web rows), 11–21k per month |

Plan the page and the text around sparse weekly Uže series.

### 5.7 Rounding and display

- hr-HR format: decimal comma and a period as the thousands separator, in prose, cards **and figures** (voice-and-style §7; `Intl.NumberFormat("hr-HR")` does the same). Record for the PI that MEMORY's no-break-space advice for figure axes conflicts with voice-and-style §7. The period also avoids the missing-glyph problem MEMORY describes.
- Visibility has 1 decimal, shown as „< 0,1" for 0 < x < 0.05 and „0" for a true zero. Breadth has 1 decimal and a %.
- Changes are signed with U+2212, 1 decimal.
- Counts are always printed next to rates. Exports keep full precision.

### 5.8 Versioning, reproducibility, revisions

- `definition_version`: a semver plus a hash (§3.2). `panel_version` + `panel_hash`. `release_version` = `YYYY.MM.DD[-n]`. `boilerplate_version`, `normalizer_version`, `segmenter_version`.
- `input_digest` = SHA-256 over the per-day (count, sum(hash(URL)), sum(hash(coalesce(FULL_TEXT,'')))) for web rows.
- Classifications are cached per (definition_hash, panel_hash, DATE). A changed day fingerprint invalidates that day and every period containing it; the 2026-09-17 backfill is the test case.
- **Definition changes:** a new major version, a full-history recompute and a fresh validation draw. Never splice a new rule onto an old series.
- `revisions.csv` logs every published value that changes between releases.
- **Metadata separation:** `summary.json` carries `data_through` (last source date), `latest_publishable_month`/`week`, `computed_at`, the code commit SHA and all versions. It contains no paths.
- **Determinism check:** two consecutive runs produce byte-identical public files. The only exceptions are `computed_at` and `code_commit` in `summary.json` and `manifest.json`, which the check blanks before comparing.

---

## 6. Validation and publication gate

**Roles**
- The PI is the adjudicating coder, and reported results use PI labels only.
- A second, independent human coder double-codes a random 25% (≥80 items) blind to the PI's labels.
- An AI may pre-code only as a blind third opinion, never as a reported label. The moral-economy model-coded audits were a disclosed limitation; do not repeat it.

**Steps**
1. **Development split, blind to the series.** Rules are developed only on articles with the first 7 hex digits of `md5(article_key)`, read as an integer, mod 10 < 3. It is computed once in SQL, stored with the candidate, and the conversion is tested by a fixture (the development split). During development the agent computes and inspects only per-item decisions and passage-level precision, **never period series, cards or trends**. This keeps rule tuning blind to the results it will report, which the project flagged for this study (discipline card, Study 3).
2. **Development set (not reported).** About 150 purposive cases from the development split: collisions, near-misses, both batches, confessional and other outlets, identity-only passages, matches beyond character 3,000, and papal-naming months (2025-05, 2026-05). Log every rule change with its reason in `studies/…/DEVLOG.md`. Window reads count toward the D8 cap.
3. **Freeze (gate G2).** Set `definition_version` before any trend, card or finding is viewed.
4. **Evaluation (reported).** Draw fresh, seeded samples from the frozen full-history output, restricted to the remaining 70% and excluding every item in `agent_reads.csv`. Never re-slice development cases.

| Stratum | n (full) | n (reduced, D7) |
|---|---|---|
| A1 / B / C, each; half pre-seam, half post-seam where the route spans it; all cases if fewer | 60 each | 40 each |
| D diagnostic or route (per D4) | 30 | 20 |
| A2 | 30 | 30 |
| A? (unresolved) | 30 | 20 |
| Near-misses (fail exactly one condition) | 60 | 40 |
| Recall probe: non-included panel articles with Christian grounding **and** a political anchor **and** a concept family anywhere in the text. It estimates misses within that frame only. | 100 | 60 |
| **Total** | **≈430** | **≈290** |

A simple random panel sample is **not** drawn. At a prevalence of ~9–16 per 10,000 it expects 0.1–0.2 positives.

5. **Coding sheet.** Adapt `studies/filter-validation/coder_template.tpl`: offline, keyboard-driven, answer key hidden.
   - Shown: the passage plus one paragraph of context, the outlet and the date.
   - Hidden: route flags, rule ids, matched terms, batch and facets.
   - Coded:
     - qualifies (da / ne; „nesigurno" counts as ne);
     - construct (A1 / A2 / B / C / D / ništa);
     - speaker type, geography and register;
     - domain themes;
     - CODEBOOK Axes 1–4.
6. **Agreement.** Report Cohen's κ and raw agreement for "qualifies" and for "construct". κ < 0.70 on "qualifies" blocks publication of the broad scope; the codebook is then revised and a fresh draw coded. The PI adjudicates disagreements after both codings, and every adjudication is logged.
7. **Estimates.**
   - Per-route precision with Wilson 95% intervals (the helper in `studies/filter-validation/02_analyse_coding.R`).
   - Broad-scope precision weighted by route-set population shares.
   - Per-batch precision reported descriptively (the gate is pooled).
   - Per-theme precision among included articles.
8. **Gate** (thresholds from `studies/moral-economy/PROPOSAL_v5_rsp.md` l.371–372). One deliberate difference: that rule reports the 0.60–0.80 band raw and precision-adjusted, whereas here the band is published only as „eksperimentalno", without adjustment.
   - point precision ≥ 0.80: the route is in Širi and in the cards, reported as measured;
   - 0.60–0.80: the route is published only as an „eksperimentalno" series with its precision, outside the cards;
   - < 0.60: the route is dropped for this `definition_version`;
   - the broad union is publishable only if its weighted precision is ≥ 0.80;
   - a theme row with precision < 0.70 is shown as „nepotvrđeno".
   - **No-go branch** (declared now, not improvised later): if the broad union fails, the page default and the headline cards switch to Uže (A1). The broad series is then withheld, or shown only as a labelled „probna serija", and the conference summary reports A1 plus the method. If A1 also fails its gate, nothing is published: the page is not added to navigation, and the conference summary presents only the method and the validation result. This is not a reversion "because it is easier" (Revision 2 §3.5); it is the documented consequence of a failed gate.
9. **Joins.** Join coded sheets back on `item_id` with an id assertion, as in MEMORY's mis-keyed-rid lesson.
10. **Outputs.** Public `validation.csv`: route, stratum, n, k, precision, lo, hi, κ, `definition_version`, coder type. Coding sheets stay private.
11. **Wording.** „Odziv (recall) nije procijenjen za cijeli panel; odbijeni kandidati i uzorak mogućih propusta pregledani su radi otkrivanja propuštenih formulacija." Never claim a corpus-wide recall, and never apply a precision correction to the headline.

---

## 7. Pipeline, outputs and commands

### 7.1 Scripts (`studies/demokrscanstvo-barometar/`)

| Script | Job | Reads |
|---|---|---|
| `00_readiness.R` | environment, read-only open, schema check, `input_digest`, masked days, latest periods, loader-activity check | DB (metadata only) |
| `01_outlets.R` | outlet inventory and a proposed registry for PI review | DB (counts by FROM/host/month only) |
| `02_panel.R` | apply the registry, build `panel_v1.csv` (**G1**) | DB (counts) |
| `03_candidates.R` | stage-1 SQL → parquet; superset tests (c) | DB |
| `04_classify.R` | normaliser → segmenter → boilerplate mask → rule engine → evidence + article classification | parquet |
| `05_validation_draw.R`, `06_validation_score.R` | coding sheets, scoring, gate table (**G2** precedes the draw) | private |
| `07_bridge.R` | June 2024 double run (§5.5) | both DBs |
| `08_aggregate.R` | outlet × day private aggregate → monthly, weekly, rolling28, themes, composition, sensitivity; statuses; comparisons | private |
| `09_figures.R` | SVG + PNG figures and the social card | public aggregates |
| `10_summary_pdf.R` | the conference PDF (Typst), built in TEMP outside the repo; fingerprint `docs/` before and after | public aggregates |
| `11_checks.R` | reconciliation, disclosure allow-list, determinism, payload size | public aggregates |
| `run.R` | orchestrator: preview by default; `--apply` installs to `data/barometar/demokrscanstvo/` after `11_checks.R` passes; `--definition=v2` recomputes the full history | — |

**Synthetic end-to-end run** (so that a teammate, CI-less, can run the whole pipeline and the page can be built before the data gates):
- A seeded script writes `data/sample/barometar_sample.csv.gz` plus a manifest: about 3,000 **fully synthetic** rows in the columns of `media_data_all`.
  - URLs on `example.invalid`, about 12 fictitious outlets.
  - Span 2020-12-28…2026-09-10, including a luka_opce/mediaspace_full seam, a text-empty 2024-02, a double-loaded month and ISO 2020-W53.
  - Bodies built from the §3.10 invented examples and the homonym fixtures.
- `run.R --sample` loads it into in-memory DuckDB, writes only to `tempdir()`, never touches `data/barometar/`, and asserts pre-computed expected counts per route and status.
- Register it in REPLICATION.md §2 and §4. Pages rendered from the sample carry a visible „SINTETIČKI PODACI" banner.

**Runtime and CI rules**
- **Runtime:** the stage-1 scan takes ≈4 minutes. Size the R rule engine on the first full month and log throughput. Chunk by month, and resume from the cache.
- **CI:** CI has no DetermDB and drops duckdb from its lockfile. The libraries in `R/lib/barometar_*.R` must not load duckdb, and their fixture tests run in `tests/run_tests.R` with stringi only. The JS tests need their own CI step (`node --test tests/barometar_core.test.cjs`), because `tests/moj_medij_findings.test.cjs` is currently not wired in.

### 7.2 Private outputs

Everything row-level stays in `$DIGIKAT_BAROMETAR_WORKDIR` or `output/private/`. That covers candidates, evidence, classifications, coding sheets, the bridge table, per-outlet numerators and screenshots of passages. Nothing row-level is sent anywhere, and passage excerpts are handled per D8.

### 7.3 Public release (`data/barometar/demokrscanstvo/`, CC BY 4.0)

| File | Content |
|---|---|
| `monthly.csv`, `weekly.csv` | one row per (frequency, scope, period). Columns: frequency, scope, period_id, period_start, period_end, is_complete, visibility_status, breadth_status, comparison_status, coverage_days_observed, coverage_days_calendar, backfilled_days, unmanifested_days, total_articles, matching_articles, panel_outlets, panel_active, matching_outlets, visibility_per_10000, breadth_pct, comparison_period_id, visibility_difference, breadth_difference_pp, test_p_value, visibility_balanced, panel_version, definition_version, release_version, data_through |
| `rolling28.csv` | the same fields for daily trailing-28-day windows |
| `themes.csv` | frequency, scope, period_id, theme_id, theme_label_hr, articles_with_theme, total_articles, rate_per_10000, theme_status, versions |
| `composition.csv` | frequency, scope, period_id, facet, value, articles. Covers route sets (with overlaps listed explicitly), speaker type, geography, segment and register. |
| `sensitivity.csv` | the monthly and weekly series for each sensitivity variant |
| `outlets.csv` | outlet_id, display_name, outlet_domain, segment, panel_version, in_panel, eligible articles per year (N only). **No per-outlet numerators or rates** (D18). Concentration appears anonymously on Metodologija (top-10 share of D, HHI). |
| `validation.csv`, `bridge_summary.csv` | §6, §5.5 |
| `definitions_v1.json` | the compiled public rule inventory: families, forms, exclusions, routes, window and versions |
| `summary.json` | the page payload source: latest periods, card values, labels, fixed matrix bins per (frequency, scope, definition_version), annotations[], releases[], file sha256 values |
| `manifest.json`, `releases.csv`, `revisions.csv` | provenance (§5.8) |
| `README.md` | Croatian codebook: statuses, definitions, units, versions and citation |
| `izdanja/<edition>/summary.json` | the frozen edition that the Nalazi are bound to (§8.5) |

**Writing and screening the files**
- **Encoding:** write every file through a binary connection with LF endings (the pattern in `R/06_moj_medij.R:695`), with a UTF-8 BOM for CSVs. Hash after writing, and verify the hashes on a fresh checkout. `.gitattributes` forces `eol=lf`.
- **Disclosure scan:** extend `R/check_disclosure.R` to scan `data/barometar/` as well as `studies/`.
- **Builder allow-list gate**, modelled on `R/06_moj_medij.R:624-630`:
  - no `http` in values;
  - no text columns;
  - no drive or user paths;
  - column names outside the check's blocked list (`url`, `title`, `description`, `text`, `content`, `excerpt`, `context`, `window`). Use outlet_domain, label_hr, definition_hr and study_href instead.
  - **text-overlap guard:** every public string (findings, labels, notes, JSON string values, PDF source) is checked for any 8-token sequence present in the private candidate texts. A hit refuses the apply. The disclosure checks inspect column names, not prose, so this is the only guard against republishing press text.
  - `--apply` refuses to install if any check fails.
- **Page payload:** a compact columnar JSON of display fields only, target ≤150 kB and asserted ≤200 kB.

### 7.4 Commands

Add these to the CLAUDE.md Key commands table.

```bash
export PATH="/c/Program Files/R/R-4.6.0/bin:$PATH"
Rscript studies/demokrscanstvo-barometar/run.R                 # preview into studies/…/output/release/ + check report (default); never touches data/barometar/
Rscript studies/demokrscanstvo-barometar/run.R --apply         # gated install into data/barometar/demokrscanstvo/
Rscript studies/demokrscanstvo-barometar/run.R --definition=v2 # full-history recompute under a new version
"/c/Program Files/Quarto/bin/quarto.exe" render pages/demokrscanstvo/index.qmd   # from the repo root only
```

### 7.5 Refresh contract and procedure

**Where new data comes from.** New days reach `determDB_merged.duckdb` only through dated maintenance scripts, run by hand, that write into the 91 GB file in place (e.g. `commit_missing_days_20260917.py`). There is no standing append command, and upstream curation is ongoing: the April 2024 raw exports were re-downloaded on 2026-09-18 (D16).

1. **Upstream refresh is a separate, PI-run step.** It covers the vendor download, `load_mediaspace.py` and extending the merged file. The barometer never writes to DetermDB.
2. **Nothing new, nothing done.** The update command first reads `max(DATE)`, `build_log` and `maintenance_import_log`. If nothing has changed since the last release manifest, it exits with „nema novih podataka".
3. **Locks.** DuckDB's file lock makes a barometer read and an upstream write fail against each other; this was verified on this machine. The command opens read-only and closes with `dbDisconnect(shutdown = TRUE)` in `on.exit()`. On a lock error it stops with „DetermDB se upravo zapisuje; ponovi nakon uvoza", with no retry loop. The study README warns never to leave an R session attached during an import.
4. **Owner.** The PI owns the refresh, per the study README, with the cadence "weekly when upstream has new days".
5. **Stale data.** If `data_through` is more than 28 days old, the page drops any „tjedno ažuriranje" wording and the weekly view reads „Tjedni prikaz zaključno s {data_through}".
6. **Keep git history small.** A weekly refresh is data-only. It commits these files, with the message `data(barometar): podaci do YYYY-MM-DD`:
   - every changed file under `data/barometar/demokrscanstvo/`, except `izdanja/`;
   - `pages/demokrscanstvo/_metadata.yml` (holds `data-cutoff`);
   - `docs/pages/demokrscanstvo/**`;
   - `docs/data/barometar/demokrscanstvo/**`, because Quarto copies project resources into `docs/`;
   - `assets/images/barometar/*` and its `docs/` copy;
   - any new `docs/site_libs/bootstrap/bootstrap-<hash>.min.css`.

   The PNG/SVG figures regenerate with every refresh, because the page's no-JS default shows them. The PDF and the Nalazi regenerate only with a monthly edition, and are checked against that edition's `summary.json`.

**Weekly procedure, when new DetermDB days exist; same definition and panel.** This is manual: there is no scheduler and no cloud CI.
1. `run.R` preview: new days are fingerprinted and affected periods recomputed.
2. Review the check report.
3. `run.R --apply`.
4. Render the single page.
5. Check assets: every href/src exists and is in `git -c core.quotepath=false ls-files`, including any new `docs/site_libs/bootstrap/bootstrap-<hash>.min.css`.
6. Commit exactly the files listed in item 6 of the refresh contract above.
7. Push after the PI's OK.

Weekly refreshes update the cards and series, **never the Nalazi**.

**Monthly edition:** freeze `izdanja/<YYYY-MM>/summary.json`. The PI reviews updated Nalazi and, if wanted, a new conference PDF.

**Definition or panel change:** plan-first, a new version, a full-history recompute, a fresh validation draw and a new edition.

---

## 8. The page: placement and design

### 8.1 Placement in the site

| Surface | Change |
|---|---|
| Navbar, **Istraživanja** menu | Add `- text: "Medijski barometar demokršćanstva"` / `href: pages/demokrscanstvo/index.qmd` directly after "Tematska istraživanja". Do not add it under "Istražite" or on the maps landing: both describe the official corpus. |
| Homepage, "03 — Istraživanja" | One `.publication-entry`: title, one edition-pinned sentence, date, status and existing formats. **No live number**, so weekly refreshes never re-render `index.qmd`. |
| `pages/studije/index.qmd` | A new `## Pokazatelji` section after "Dostupne studije" with one `.info-card` that names the population. |
| `pages/metodologija.qmd` | A new section `## Medijski barometar demokršćanstva {#method-barometar}`: rule families, window, panel rule, validation, and a `#method-barometar-kontinuitet` subsection on the break and the text gaps. Amend `#method-data-lineage` and `#method-reproducibility`, and add a row to `METHODOLOGY_RELOCATION_MAP.md`. |
| `EDITORIAL_GUIDE.md` | The D1 exception and the D14 vocabulary. |
| `pages/news.qmd` | Optional news item on first release. |
| `data/EXTERNAL_DETERMDB.md` | The merged and mediaspace files, 41.748.837 rows after 2026-09-17, the bridge cross-reference, and the barometer as the first R/ consumer. |
| `DATA_AVAILABILITY.md`, `REPLICATION.md` | Rows for the DetermDB general-media feed (not in the repo; restricted by source copyright and vendor terms), for `data/barometar/**` (open aggregates, CC BY 4.0, per D19) and for the synthetic sample with `run.R --sample`. |

The frozen study pages keep the old navbar until their next render. That is expected; do not re-render them.

### 8.2 Architecture

These choices are binding.
- A **Quarto page**: `pages/demokrscanstvo/index.qmd` with `page-layout: custom`, `title-block-style: none`, `toc: false`, following `index.qmd`. The slug is ASCII.
  - Rejected alternative: a standalone bundle under `assets/izvjestaji/` like „Kako se govori o Crkvi?". It has its own header and footer, loads no web fonts, keeps its version string by hand in five places, needs a manual copy to `docs/`, and gets only allow-listed quality checks.
- **Fail-closed setup chunk.** It reads only committed files (`summary.json`, `manifest.json`). It verifies the sha256 of every release file and checks that `data-cutoff` (from `pages/demokrscanstvo/_metadata.yml`) equals `summary.json` `data_through`. It reads from `data/barometar/demokrscanstvo/` unless `DIGIKAT_BAROMETAR_DATA_DIR` is set, e.g. to the `--sample` output. That override turns on the „SINTETIČKI PODACI" banner and is refused by the release gates. On any mismatch it calls `stop()` with the regenerate command. No chunk references DetermDB, the work directory, any gitignored path or duckdb.
- **Front matter** sets `execute: freeze: false` (the project uses `freeze: auto` and tracks `_freeze/`, so a data-only refresh would otherwise replay stale numbers).
- **Data delivery:** embed the payload as `<script id="dkb-data" type="application/json">` (the Moj medij pattern). Full-precision files are static relative `<a href>` downloads. JS may highlight a download link but never create one.
- **Interaction:** vanilla JS and inline SVG only. No OJS: its runtime is 449 kB and lazy-loads d3 and Plot from a CDN, which fails the browser gate's network check and the budget. No Chart.js, ECharts, Vega, plotly or htmlwidgets, and no CDN scripts.
  - Pure logic goes in `assets/js/barometar-core.js` (UMD): period selection, comparison, rounding, hr-HR formatting, segmenting and bin lookup. DOM code goes in `assets/js/barometar.js`.
- **Progressive enhancement.** The R chunk renders the default state (monthly, Širi) as static HTML: cards, a PNG figure with width, height and alt, the data table and the static matrix. JS replaces them with the interactive versions. There are no transitions or animations.
- **Paths:** relative only. No href, src or fetch may begin with `/`; the checkers do not catch it, and it 404s under `/DigiKat/`. `11_checks.R` greps for this.
- **Budget:** the standard page class is 1,500,000 B. The shared chrome already uses ≈977 kB, which leaves ≈0.5 MB for the page's HTML, CSS, JS and images. Add a page class only if the measured weight exceeds the budget, with a RELEASE_CHECKLIST row giving the reason.

### 8.3 Front matter

```yaml
---
title: "Medijski barometar demokršćanstva"
subtitle: "Prisutnost demokršćanskih i srodnih kršćansko-socijalnih ideja u hrvatskim mrežnim medijima"
description: "<one unique, evidence-led sentence, generated at first release>"
author: "Luka Šikić"
date: "YYYY-MM-DD"            # first publication, then fixed
date-modified: "YYYY-MM-DD"   # changes only with a monthly edition or a definition release, never on a data refresh
status: "Preliminarno"        # never "Stabilno izdanje" before editorial review
schema-type: "Dataset"
categories: ["Pokazatelji", "Otvoreni podaci"]
image: "../../assets/images/barometar/demokrscanstvo-kartica.png"
image-alt: "DigiKat, Medijski barometar demokršćanstva. Dva pokazatelja za posljednji objavljeni mjesec."
page-layout: custom
title-block-style: none
toc: false
smooth-scroll: false          # _quarto.yml enables it site-wide
css: ../../assets/css/barometar.css
# data-cutoff is NOT set here: the publish step writes it to pages/demokrscanstvo/_metadata.yml,
# and page front matter would override that value.
execute:
  freeze: false
---
```

- Never write `date: last-modified`: `tests/check_run6_site_quality.R` fails on it, even though voice-and-style §9 still prescribes it. Record that conflict for the PI.
- Do not create `_*.qmd` partials under `pages/`.
- Exactly one H1, in the opening. One H2 per section, H3 for panels, cards and findings, and no skipped levels.
- Hand-write the `.freshness-strip` (Objavljeno · Ažurirano · Podaci zaključno s · Status) inside the opening and do not set `show-freshness`, because the filter would insert it above the hero.
- Emit page-level Dataset JSON-LD from an R chunk, as in `baza.qmd`: name, description, url, inLanguage hr, creator, license, temporalCoverage `2021-01-01/{data_through}`, version, dateModified, a distribution entry per CSV, and variableMeasured.

### 8.4 Design tokens

These come from `assets/css/custom.scss` and DESIGN_SYSTEM.md. Consume `var(--dk-*)`, and never edit the shared bundle.

**Surfaces**

| Use | Token |
|---|---|
| Opening band | `--dk-color-ink` #0F1419, the same ink as the site footer |
| Indicator panels | `--dk-color-accent-deep` #0A3543 |
| Canvas | `--dk-color-paper` #F5F4F0 |
| Cards and tables | `--dk-color-panel` #FFF |
| Hairlines | `--dk-color-border` #E4E2DA |

**Text**
- Body text: `--dk-color-body`. Secondary text: `--dk-color-muted` #6B6F76 (4.59:1 on paper). Never use faint #9A9EA6 for text (2.44:1).
- On dark surfaces: main text #F5F4F0; muted #AEB4B8 (8.83:1 on ink); the eyebrow only may use #5A949F.

**Accent:** `--dk-color-accent` #0F4C5C, for the series, active states and links on paper.

**Derived tokens** (defined in `barometar.css`, each with a source comment: `--dkb-accent-300`/`-200` = the SCSS accent-300/200 values; `--dkb-grid` = `dk_col$grid` in `R/theme_digikat.R:43`. The ramp values #C9DCE0 and #8FB5BD are new, interpolated between accent-soft and accent-200, and are commented as such):
- `--dkb-accent-300: #2C6F7E`, `--dkb-accent-200: #5A949F`, `--dkb-grid: #E2DDD0`;
- matrix ramp #EAF0F2 · #C9DCE0 · #8FB5BD · #5A949F · #2C6F7E. Use ink text on the first four bins and white on the fifth.

**Excluded:** no navy #1e3a8a (it lives only in the orphaned `style.css`), no gradients except the hatch pattern, and no shadows beyond `--dk-shadow-raised`.

**Focus**
- On paper: the global petrol ring.
- On dark surfaces (`.dkb-on-dark :focus-visible`): `outline: 2px solid #F5F4F0; outline-offset: 3px; box-shadow: 0 0 0 4px rgba(15,20,25,.9)`. The petrol ring is 1.95:1 on ink.
- Put the frequency, scope and range controls on paper, not inside the dark panels.

**Type**
- Source Serif 4: H1–H3 and finding titles.
- Source Sans 3: prose, labels and controls.
- IBM Plex Mono with `font-variant-numeric: tabular-nums`: every numeral, period label, axis tick and status.
- Format with `Intl.NumberFormat("hr-HR")`. Dates look like „10. rujna 2026." and „kolovoz 2026.", with months in lower case.

**Layout**
- Inner column `width: min(100%, 1180px)`, with padding `clamp(1.25rem, 4vw, 2.5rem)`, or 1rem at ≤640 px.
- Spacing uses `--dk-space-1…7`. Radii: `--dk-radius-sm` for controls and cells, `--dk-radius-md` for panels.

### 8.5 Sections

The order follows the reference's sequence: opening, access, sticky contents, inspectable summary, findings, method, editions. The page does **not** take FLI's autoplay video background, logos, grades, rankings, press strip, expert panel, duplicate mobile DOM or centred long text.

**1. Opening** (`section.dkb-hero.dkb-on-dark`, full-bleed ink, left-aligned in the 1180 px column)
- **Contents, in order:**
  1. A credits eyebrow: „DigiKat · Hrvatsko katoličko sveučilište · Luka Šikić".
  2. The H1 (`clamp(2.25rem, 1.2rem + 4.6vw, 4.5rem)`, weight 600, line-height 1.04, letter-spacing −0.025em, `text-wrap: balance`, `max-width: 16ch`). The 36 px floor keeps „demokršćanstva" inside 320 px.
  3. The subtitle.
  4. The scope statement, in muted-on-dark.
  5. The population line: „Analizirani članci iz stalnog panela hrvatskih mrežnih medija · P = {P} · {first year}.–{last year}." (e.g. „2021.–2026.").
  6. The freshness strip plus „Izdanje {release_version}".
  7. **One** primary action, „Pregled pokazatelja" (→ `#pregled`), followed by the quiet links „Sažetak za konferenciju (PDF, {kB})", „Podaci (CSV i JSON)" (→ `#podaci-i-metoda`) and „Istraživanja DigiKat" (→ `../studije/index.html`). Use noun labels: this is an analytical page, so no CTA and no second person.
- **Background, CSS only:** a 48 px line grid at rgba(245,244,240,.05), and 3–5 faint serif fragments of the domain names (`aria-hidden`, opacity .06). No curve or line that could be read as data, no image, no video, no motion. Below 480 px, hide the grid.
- **Print:** white background, ink text, fragments hidden.

**2. Sticky sub-navigation** (`nav.dkb-subnav`, `aria-label="Sadržaj barometra"`)
- **Items:** Pregled · Kretanja · Tematska slika · Nalazi · Povezana istraživanja · **Podaci i metoda**. That label replaces „Izvori", which collides with the controlled term izvor.
- **Behaviour:**
  - `position: sticky; top: var(--dkb-subnav-top, 0px); z-index: 1020`.
  - JS sets `--dkb-subnav-top` to the height of `#quarto-header` while it is pinned, and to 0 when it has `headroom--unpinned` (listen to `quarto-hrChanged`).
  - Sections get `scroll-margin-top`.
  - The active item gets `aria-current="location"` through an IntersectionObserver.
- **Mobile:** one line with `overflow-x: auto`. **Print:** hidden.

**3. Pregled (`#pregled`)**
- **Controls** (on paper; hidden until JS runs; without JS the page shows the default plus „Prikaz: mjesečno, šire"):
  - two `<fieldset>`s, „Učestalost" (Mjesečno | Tjedno) and „Obuhvat" (Šire | Uže), each a native radio group ≥44 px tall;
  - a small `<details>` „Što znači obuhvat?";
  - a polite live region announcing the state;
  - state kept in the URL (`?ucestalost=tjedno&obuhvat=uze`, updated with `history.replaceState`).
  - The same selection drives the cards, charts, matrix and downloads.
- **Two indicator panels** („Medijska zastupljenost", „Širina prisutnosti"), equal columns at ≥800 px and stacked below. Each shows:
  - the value (mono, `clamp(2.5rem, 6vw, 4.5rem)`);
  - the unit line;
  - the counts line (D od N članaka / M od P medija);
  - the period · frequency · scope line;
  - the labelled change line or its non-comparability reason (§5.4).
- The sign is text (U+2212), with no red/green meaning. A partial period is never the headline.
- Under the cards: a one-line composition strip for the active period (e.g. share from confessional outlets, share inozemno, route split) and the always-visible line „Zastupljenost u medijima nije potpora …" (§2.4).

**4. Kretanja (`#kretanja`)**
- **Two stacked `.figure-card`s** (visibility, breadth) sharing an x-domain, crosshair and range. Each card has:
  - a generated takeaway;
  - a `.chart-accessible-summary`;
  - `details.reference-section` „Tablica podataka" with the full selection;
  - a `.download-group` with SVG, PNG and the current selection's CSV (a client-side Blob named `barometar_{ucestalost}_{obuhvat}_{definition_version}.csv`).
- **Range:** a radio group (12 | 24 | 36 | Sve), native `<select>`s for Od and Do, and a „Najnovije razdoblje" button. Default ranges: monthly, all history at ≥1024 px and 24 months below; weekly, 52 weeks at ≥1024 px and 26 below.
- **Readout:** a polite live region. Keyboard: ←/→ step, Home/End jump, Esc clears. No hover-only content.
- **Chart conventions** (§8.6). Weekly mode shows the raw weekly values as columns, with the trailing-28-day line clearly distinct and directly labelled „Zadnjih 28 dana". The A2 comparison series appears as a thin, labelled line in the Uže view only.

**5. Tematska slika (`#tematska-slika`)**
- The lead sentence says these are thematic views, not indices.
- **Table:** a real `<table class="dkb-matrix">` in its own `div.table-responsive[role=region][tabindex=0]`, so `site-end.html` does not double-wrap it.
  - `<caption>`: frequency, scope and the unit.
  - Rows: the domain rows (D6), then „Nerazvrstano" in italics after a hairline.
  - Columns: the last 12 periods of the current frequency.
  - First column: sticky.
  - Each cell prints its value in mono.
- **Colour:** 5 bins, with breaks fixed per (frequency, scope, definition_version) and shipped in `summary.json`; never rescaled per window. The legend covers the bins plus „0" (white), „nije dostupno" (hatch and „—") and „djelomično" (dashed outline).
- **Interaction:** a roving-tabindex grid. Enter, Space or a click selects a cell and fills a polite detail panel with theme, period, count, N, rate, status, scope, definition and the related study link.
- **Principles facet:** a small secondary table.
- **Print:** all 12 columns, with `print-color-adjust: exact`.

**6. Nalazi (`#nalazi`)**
- Three findings, or fewer if fewer are supportable, bound to the dated monthly edition `izdanja/<YYYY-MM>/summary.json`. Every number comes from it inline; never type a number. The render stops if the edition file is missing.
- Each finding names its route and composition. A change is stated only if it holds in the relevant sensitivity series. No finding compares across 2024-04-01 unless the comparison is `comparable_bridged`.
- Use description verbs (pojavljuje se, raste u zastupljenosti, koncentrirano je), never endorsement verbs. No party colours, rankings or per-outlet claims.
- Write the findings only after computing. The PI approves each edition's findings, and `/review-page` (numeric-claim-verifier + religion-media-domain-reviewer) runs first.

**7. Povezana istraživanja (`#povezana-istrazivanja`)**
- 3–4 `.info-card`s exactly as on `pages/studije/index.qmd`, each with a mono line „Populacija: …". No card quotes a number.

**8. Podaci i metoda (`#podaci-i-metoda`)**
- Four plain route sentences (A1 „Demokršćanstvo kao tradicija i ideja"; B and C together as „Kršćanska socijalna misao", with the sub-labels „Socijalni nauk u političkom pitanju" and „Kršćanski utemeljen argument iz načela"; D „Programski govor aktera", diagnostic only), the two scope definitions, and one sentence linking to `../metodologija.html#method-barometar`.
- `details` sections: per-family summaries, „Panel praćenih medija (P = {P}, verzija {panel_version})", per-route precision (`validation.csv`), „Povijest izdanja".
- A `.download-group` of every public file with type and size.
- A `.citation-block`: „Šikić, L. (2026). Medijski barometar demokršćanstva (izdanje {release_version}, podaci do {data_through}). DigiKat, Hrvatsko katoličko sveučilište." with the page URL as the identifier (no invented DOI), the version, CC BY 4.0 and a link to `summary.json`.

### 8.6 Chart conventions

The page JS and the R figures both implement these rules, and both read the same `annotations[]` array.

- **Axes:** y starts at 0, with units in the axis title. Mono ticks at 12 px in the muted colour; 1 px gridlines in `--dkb-grid`.
- **Series:** monthly values are straight segments with 3 px markers, never smoothed and never area-filled.
- **Segment breaks:** at every non-published period, and always at 2024-04-01.
- **Status styling:**
  - unavailable: a hatched band, no mark, and „—" in tables (screen-reader text „nije dostupno");
  - true zero: a filled mark on the baseline;
  - partial: a hollow, unconnected mark labelled „djelomično".
- **Break marker:** a dashed ink rule labelled „Promjena prikupljanja · 1. travnja 2024.", linking to `#method-barometar-kontinuitet`. This is the page's one required caution; there is no separate limitations section.
- **Mobile:** redraw on ResizeObserver with ≤6 ticks and a 220 px height. Charts never scroll horizontally; the matrix does.

### 8.7 Accessibility, mobile and print

- Native radios for the toggles.
- Every chart has an accessible table.
- Contrast ≥4.5:1 for text, including on dark panels.
- No transition, animation or smooth scrolling (the reduced-motion gate).
- Viewports 320–2048 px pass without horizontal page overflow.
- Keyboard reachability for toggles, range controls, chart readout and matrix cells.
- Print: a white hero; the sub-navigation and controls hidden; a printed line „Prikaz: {učestalost}, {obuhvat}".

### 8.8 Related studies

Use each study's current published title. Every card states its population. No card quotes a number.

| Card title (exact) | Authors | Route | Population line |
|---|---|---|---|
| Socijalni nauk Crkve u javnoj raspravi o gospodarstvu | Luka Šikić, Petra Palić | `../studije/socijalni-nauk-i-gospodarstvo.html` | korpus katoličkih tema DigiKat, do 11. lipnja 2026. |
| Tko govori iz katoličkoga medijskog prostora | Luka Šikić, Andreja Sršen | `../studije/crkva-i-dezinformacije.html` | katolički internetski mediji u korpusu DigiKat, 2021.–2026. |
| Kako se govori o Crkvi? | Luka Šikić | `../../assets/izvjestaji/kako-se-govori-o-crkvi/index.html` | korpus DigiKat, do 11. lipnja 2026. |
| Katoličke teme u digitalnom prostoru. Godišnji pregled 2025. | Luka Šikić | `../../assets/izvjestaji/godisnji-pregled-2025.html` | korpus DigiKat, 2025. |

- „Katolički influenceri i institucionalni deficit pažnje" is the least related study and is omitted.
- **3,73 %** (RSP v1, superseded, still printed in Godišnji pregled 2025) and **1,62 %** (RSP v2) are Tier-1 CST marker rates among religion–economy pairs in the Catholic-topic corpus. They never appear on this page and are never compared with visibility per 10.000.
- Flag the stale 3,73 % in Godišnji pregled 2025 to the PI, outside this task.
- If the Šikić & Sršen working paper „Sadržaj ili identitet?" is published on DigiKat later, it becomes the lead card, since its dictionaries seed this instrument. Until then, credit it (per D17) in „Podaci i metoda" on the page, in the definition README and on Metodologija.

### 8.9 Figures, PDF and social card

- **Figures:** `09_figures.R` uses `theme_digikat()` and the same annotations. It calls `systemfonts::require_font()` for Source Serif 4, Source Sans 3 and IBM Plex Mono, and stops if `match_fonts()` still returns arial.ttf, which it does on this machine today.
  - PNG: `ragg`, dpi 144, background #F5F4F0.
  - SVG: `svglite(web_fonts = svglite::fonts_as_import(...))`.
  - Figures carry marks only; titles and sources are rendered in HTML (MEMORY lesson). Output goes to `assets/images/barometar/`, which the raster guard covers.
- **Conference PDF:** `10_summary_pdf.R` follows the Typst template in `studies/annual-report/typeset/` and the `06_render_report.R` flow. It is one or two pages, uses the same `summary.json` and figures, and states its release. The hero link names that release.
- **Social card:** 1200×630, generated from `summary.json`.

---

## 9. Release sequence and gates

### 9.1 Commits

Stage explicit paths only.

0. **Fix the pre-existing CI failure** as a separate, PI-visible commit. The viewport string in `tests/check_run6_site_quality.R:92` should include 1366, matching `scripts/check_site_browser.mjs:11`, and `RELEASE_CHECKLIST.md:27` should be updated to match. Weaken no other check.
1. Libraries, fixtures, tests, `digikat_paths.R` functions, `.gitignore`, the study scaffold, the registry proposal.
2. **G1: PI ratifies the outlet registry and `panel_v1`.** This waits for D16, the April 2024 import decision. Commit the panel.
3. Definitions v1, development set, DEVLOG. **G2: PI freezes definition v1.** Commit it, with PROVENANCE rows.
4. Full-history classification, bridge, validation draw → PI coding → gate table. **G3: PI accepts the validation outcome and D9.**
5. `run.R --apply`, the first public release (**G4**). It requires D17 (co-author consent and credit) and D19 (vendor terms). Then the page, CSS, JS and social card; the metodologija, EDITORIAL_GUIDE, relocation-map and EXTERNAL_DETERMDB edits; the browser-gate entry with a `barometarExpression` that:
   - toggles Tjedno and Uže by keyboard;
   - asserts `data-frequency`/`data-scope` on `section#pregled`, the URL parameters and the live region;
   - asserts 12 matrix columns;
   - asserts that no line segment spans 2024-04-01;
   - asserts that unavailable cells read „—".
6. `_quarto.yml` navbar and resource line, homepage entry, studies index card. **G5: the full `quarto render` (HARD GATE).** Then:
   - `git checkout -- docs/pages/studije docs/studies docs/site_libs`, and confirm 9 study pages are present;
   - `Rscript R/check_site_links.R`, `npm run check:site`, `npm run check:browser`;
   - verify every href/src exists and is tracked (`git -c core.quotepath=false ls-files`), including new bootstrap bundles.
7. Push the branch and open a PR. Read the validate conclusion with `gh run view`, never with `gh run watch --exit-status`. **G6: merge only with PI confirmation**, because a push to `main` publishes `docs/` immediately.

### 9.2 Hard stops (the only points where the executor waits)

- **G1** panel freeze.
- **G2** definition freeze.
- **G3** validation outcome and break policy.
- **G4** first `--apply`.
- **G5** full render.
- **G6** merge or push to main.

The executor also stops, and asks, if an essential input is missing (§1.3).

### 9.3 Sizing and a fallback if the conference is close

The critical path is G1 → G2 → PI coding (≈430 decisions) → G3.

If D15 leaves too little time, release in two steps and never skip validation:
- **Release 1:** status „Preliminarno". Uže (A1) plus B, if B passes its gate, plus the page. C is withheld, or shown as „nije validirano" without any precision figure, and D appears only as the diagnostic facet.
- **Release 2:** C (and D, if D4(b)) after their validation.

Say which applies in the plan.

---

## 10. Verification checklist

"Done" requires every item below, checked and reported with evidence.

**Data and counts**
- [ ] N ≥ D and P ≥ P_t ≥ M in every row. Direct (A1) ⊆ Širi. Širi is the deduplicated union of accepted routes, and route overlaps are listed explicitly in `composition.csv`.
- [ ] Monthly and weekly article counts reconcile against their exact calendar days. Distinct outlet sets are recomputed per period. No monthly figure is built from weeks, and no breadth is summed or averaged. Rolling-28 is recomputed from days.
- [ ] ISO edges are correct: 2020-W53 = 2021-01-01…03 is partial; weeks across New Year are right; 2026-W37 is partial.
- [ ] Masked days produce `unavailable`/`partial` statuses, never zeros. True zeros stay 0.
- [ ] The 2021-01 dedup count is asserted. No article falls in two periods. Title hits are not double-counted.
- [ ] The June 2024 bridge has run and D9 is recorded.

**Rules and matching**
- [ ] Fixture suite passes: must-match and must-not, sibilarised and fleeting-a forms, NBSP/NFD/soft-hyphen/no-newline variants, window exclusion.
- [ ] Superset tests (a)–(d) pass. The lint finds no `\b`, `\w` or `\s` in SQL strings and no base-R regex in barometer code.
- [ ] Segmenter P and R ≥ 0.93 against udpipe on both batches. 0 true evidence passages masked as boilerplate.
- [ ] Validation gate table published. κ reported. Routes outside the gate are shown only as „eksperimentalno".

**Reproducibility and disclosure**
- [ ] Two consecutive runs produce byte-identical public files (except `computed_at`/`code_commit`). Hashes match on a fresh checkout. `revisions.csv` is updated.
- [ ] `run.R --sample` passes its expected counts on the synthetic sample and never writes outside `tempdir()`.
- [ ] Development used only the 30% split, and no period series was computed before G2. `agent_reads.csv` stays within the cap, and none of its items is in any evaluation draw.
- [ ] The text-overlap guard (8-token sequences) passes on every public string. No headline, quotation or article URL appears anywhere public.
- [ ] The update command exits cleanly with „nema novih podataka" when nothing changed, and stops with a clear message on a DetermDB lock.
- [ ] Public files contain no row-level text, URLs of items, titles, authors, local paths or per-outlet numerators. `R/check_disclosure.R`, extended to `data/barometar/`, passes, and so does the builder allow-list.

**Page**
- [ ] The page renders on a machine without DetermDB (CI conditions), with `freeze: false`, and stops on a sha or `data-cutoff` mismatch.
- [ ] Cards, charts, matrix, CSV, JSON, PNG and SVG show identical values for the same selection, and the PDF matches its own edition's `summary.json`. Both frequencies × both scopes were tested.
- [ ] One H1, a unique description, a freshness strip with a ratified status, og image with alt text, JSON-LD, citation block, relative paths only.
- [ ] Payload ≤200 kB; page within its budget class.
- [ ] check:site, check:browser (320–2048 px, axe, focus, reduced motion) and the link check all pass.
- [ ] Screenshots at 1440×900 and 390×844 for all four modes, saved to `quality_reports/`, never `docs/`.
- [ ] Croatian diacritics intact in the source and in the rendered HTML. Numeral agreement comes from `digikat_hr_count()` in R and its port in `barometar-core.js`. No em dashes in prose.
- [ ] RELEASE_CHECKLIST manual matrix: the page "reads as an academic research publication".
- [ ] The live URL opened and checked before anyone is told it is live.

---

## 11. What "done" means, and the final handoff

"Done" has three levels. The executor reports only **L1**, unless the PI has confirmed that the L2 or L3 actions happened.

- **L1 „spremno za pregled"** is the executor's done. It requires:
  - a branch and a PR, with CI green;
  - `RELEASE_CHECKLIST.md` automated gate (l.13–24) passing locally;
  - `/disclosure-check` on `data/barometar/` and `/review-page` on the rendered page;
  - attached verdicts from the fresh-context agents:
    - `verifier`: renders and outputs;
    - `numeric-claim-verifier`: every page and PDF number against `summary.json`. It cannot self-confirm by design.
    - `r-reviewer`: the pipeline;
    - `croatian-nlp-reviewer`: `R/lib/barometar_*.R` and the v1 definitions;
    - `religion-media-domain-reviewer`: routes, theme rows and the draft Nalazi.
- **L2 „odobreno"** is PI/editor sign-off, recorded in the plan. It covers the panel and definition freezes, the validation gate outcome, the wording of the Nalazi, D9, and the RELEASE_CHECKLIST manual matrix (l.44–57; WCAG judgement stays editorial).
- **L3 „objavljeno"** means the PR is merged and Pages has deployed, and the page, every download and the PDF return HTTP 200 on the live URL. Record the commit SHA.

At L1 the executor returns:
1. The page, as a local preview or a verified live URL, labelled accurately.
2. The two headline values for the latest publishable month in both scopes, with their counts and statuses, plus the weekly view.
3. The definition v1 summary, the route precision table, κ, the bridge result and the D-decisions as applied.
4. Panel size P, the panel and definition versions, `release_version` and `data_through`.
5. Links to every download, including the conference PDF.
6. The exact update commands (§7.4) and where the page sits in the navigation.
7. Desktop and mobile screenshots, and the §10 checklist with evidence.
8. New `[LEARN]` entries appended to MEMORY.md.

If DetermDB is inaccessible, complete the repository-side work (libraries, fixtures, page shell against a synthetic payload labelled as synthetic), name the missing file, and publish nothing.

---

## Appendix A. Measured facts (review of 2026-09-18)

All measurements are read-only queries on `determDB_merged.duckdb`, and for the bridge also `determDB.duckdb`, unless another source is named. They are aggregates only.

**Size, coverage and text availability**
- Web rows: 19,404,881 (luka_opce 10,299,168 for 2021-01…2024-03; mediaspace_full 9,105,713 for 2024-04…2026-09-10). Every calendar day has web rows. The merged table holds 41,748,837 rows after the 2026-09-17 backfill of 22 days (+1,299,947 rows).
- Null web FULL_TEXT: 76.8% in 2024-01 (from 01-09), 100% in 2024-02 and 2024-03. There are 35 more near-total or partial outage days in 2021–2023, making 118 days with <90% text in all. The new batch is 0% null.
- FULL_TEXT begins with TITLE on 98.8–99.9% of web rows. The old batch is truncated at ≈32,003 characters; the new batch reaches 60k–414k.
- Newlines: 66–75% of web texts contain at least one, but the structure depends on the outlet and the era. index.hr, jutarnji.hr and tportal.hr deliver bodies without line breaks: ≤4% of rows, and ≈100% of articles over 1,500 characters have none. hkm.hr and laudato.hr keep paragraph breaks. net.hr, dnevnik.hr, nacional.hr and story.hr change format at 2024-04 (net.hr goes from 100% to 0.5% no-newline). NBSP appears in 19–47% of rows.

**Keys and dates**
- FROM is the registrable domain, equal to the normalised host on 85–90% of rows, with the rest being subdomains. There are 19,788 distinct web FROM values. Outlets present every month 2021-01…2026-08: 409 at ≥1 row, 170 at ≥20, 76 at ≥100.
- 2021-01 web is double-loaded: 380,598 rows against 195,810 distinct (URL, DATETIME).

**The 2024-04 break**
- June 2024 bridge: 94% of old URLs are in the new batch, FULL_TEXT is identical on 99.9% of shared rows, and DATETIME and FROM are identical. The per-outlet new/old ratio has a median of 0.9965. The direct-family count is 394 vs 394 on shared URLs. New-only URLs are mostly non-news.
- The standalone-"i" predicate removes 18 of 269,248 old web rows (2023-06).

**Regex engines**
- DuckDB RE2 `\b` and `\w` are ASCII-only: `\bživot` matches 273 of 7,783 true documents, `\bkriž\b` 1,013 against a true 155. stringi/ICU is correct. Base R PCRE is ASCII-only.

**Collisions and homonyms**
- `supsidijarn*`: 26.5–41% are the asylum status "supsidijarna zaštita". `personaliz*` has 125,693 hits against 188 for personalizam. `zaštita životinja` outnumbers `zaštita života`. `mir*` is dominated by mirovina, names and miris. `pučk*` is dominated by "pučko otvoreno učilište". "Merz" is the blessed Ivan Merz in 2,882 articles. "Laudato" is also an outlet name.
- Forms that prefixes miss: crkava, mišlju, radnici, politici, enciklici, socijalnim naukom (79 articles match only that form).

**Direct-label and anchor volumes**
- Direct CD label: 11,704–16,731 web articles over the period, depending on the family definition. 45–84% co-mention German or other foreign markers, depending on window and quarter; with a German marker within ~80 characters the share is ≈24–41%. Only ≈11% use the term as an idea, ≈63% only next to party or election cues, and ≈26% neither.
- Doctrinal anchors: 6,251 articles in total. In a ~170-outlet panel, 63.5% come from confessional hosts (61.7% from hkm.hr + laudato.hr). *Rerum novarum* mentions in 2024-06…2026-08 co-mention Pope Leo 94% of the time.

**Cost and the site**
- The full web prefilter takes ≈235 s (12 threads) and returns ≈963k candidates.
- CI on `origin/main` is red at "Whole-site source-quality contract" (a viewport string without 1366), so render, link, budget and axe checks are skipped. The shared page chrome is ≈977 kB of the 1.5 MB standard budget. Quarto's OJS runtime is 449 kB and loads from a CDN.

## Appendix B. How this revision was produced

1. **Review lenses.** Seven independent lenses: data probe, reuse, governance and CI, design, concept validity, Croatian text engineering and measurement. Each read the current `origin/main` snapshot and the DetermDB files read-only.
2. **Verification.** Two adversarial verifiers re-checked every blocker and major finding by re-running queries and re-opening the cited files, and a completeness critic looked for gaps.
3. **Results.** The lenses produced 111 findings, 70 of them blocker or major. All 70 were verified and none was refuted: 46 were confirmed and 24 were confirmed with corrections, which are incorporated here (e.g. the socijalni nauk instrumental form, the supsidijarnost legal senses, "ljudsko dostojanstvo", P kept as the headline denominator, a pooled precision gate, the June 2024 bridge setting the break default, and no pre-emptive budget class).
4. **Critic.** The completeness critic contributed 11 further items, all incorporated: text access by the AI, a development split blind to the series, a declared no-go branch, the refresh contract, no source text anywhere public, co-author credit and timing, per-outlet results, licence rows, the indicator name, a synthetic end-to-end run and three-level "done". It also listed 15 contradictions between reviewers. They are resolved as follows: outlet key = FROM + host override; 90% day mask; the MEAS status schema; the MEAS bridge rule; `barometar` spelling; `data/barometar/`; the standard budget class; „Podaci i metoda".
5. **Probes.** The probe scripts ran in the review session's scratchpad and are not part of the repository. Everything here can be re-derived from the queries described.
