# Tko dobiva riječ o vjeri? — local 2,000-article edition

New study authorized on 17 October 2026 under the attached MASTER INSTRUCTION v1.0.
The original theological-voices report is preserved. This directory owns all new
code and derived work; nothing is published or committed automatically.

## Completed: 20 October 2026

The final Croatian report is [tko-dobiva-rijec-o-vjeri-v2.pdf](output/private/report/tko-dobiva-rijec-o-vjeri-v2.pdf), 18 pages. All 2,000 main articles have saved outcomes: 1,950 structurally complete and 50 partial, with no wholly failed or missing-text records. Actual request records confirm delivery of every body passage and headline for all 2,000; this does not establish semantic understanding.

All 31,775 analysis/evidence checks passed. Every page of the final PDF was rendered and visually inspected by Codex AI. The review is recorded in `output/private/report/visual_review.json`, bound to PDF SHA-256 `501eaec872bfaac0c98d7448b55f57e9a2d1e3abf86ea5ac17f868d88c8fc723`. This is not human article validation.

The frozen publication policy selected **limited exploratory** reporting because primary semantic and long-text checks failed. The PDF reports deterministic corpus results, processing diagnostics, definitions and limitations. It does not provide a defensible ranking of theologians or numerical estimates of their media presence. Model-derived content tables remain private and their claims are marked withdrawn.

The progress page now records completion. Historical checkpoints below describe earlier states; they are not the final status. No further inference is needed to view or rebuild this report from the saved results.

## Scope

The official 413,985-row corpus supplies 286,662 web export records in the window
2021-01-01 to 2026-06-11. Deduplication yields 282,701 publications. The main sample
contains 2,000 publications selected proportionally by calendar quarter. Separate
sets contain 100 development articles, 30 fresh challenge articles, and 24
constructed core diagnostics plus six targeted long-text/edge cases (30 total).
Four additional statement/announcement contrasts were added during v2.7 development;
they are saved separately and do not enlarge the analytical sample.
No human article coding or measured accuracy is claimed.

`assignment.json`, `BRIEF.md` and `CODEBOOK.md` define questions, labels and bases.
The inherited corpus covers Croatian/Bosnian regional material; source language
and location tags are retained. It is not all Croatian journalism. The 2024 gap,
collection change and partial final year prohibit naive attention-growth claims.

## Run and inspect

From the project root, using the installed Python and existing Ollama service:

```powershell
python studies/theological-voices-v2/finish_pipeline.py
python studies/theological-voices-v2/run_pipeline.py status
python studies/theological-voices-v2/coder.py status
```

The controller runs statement-boundary contrasts, synthetic diagnostics, development, a fixed candidate's fresh
challenge under two local configurations, the freeze gate, the main 2,000 articles,
aggregation, numeric/evidence verification, PDF construction and page rendering.
It stops for incomplete checks or technical failures. A failed semantic rule
withdraws the affected publication claims under the frozen policy described below.
It does **not** label the report visually reviewed.
The final step requires actual inspection of every rendered page.
From coder v3.0 each passage group uses extraction, attribution verification and,
when a statement is verified, a separate capacity/interpretation/experience pass.
The last pass cannot discard an established voice because its occupation is unknown.

Inference uses only `http://127.0.0.1:11434`, with the already installed Qwen3 14B
model. The model digest, settings, prompts, schemas and source hashes are saved.
No cloud inference, paid API, model download or external publication is used.

Results are committed to SQLite after each request and article. Re-running resumes
the same configuration. Changes produce a distinct configuration hash. A `STOP`
file in `output/private/` stops after an article boundary; remove it to resume.
Never delete an active controller's `pipeline.pid`; inspect its process first.

## Live progress page

Open <http://127.0.0.1:8767/> on this computer. The page refreshes every five
seconds and shows the workflow stages, saved article counts, current model task,
diagnostic failures, run history and PDF availability. It reads the private audit
records without changing them and serves no source article text. A controller
heartbeat older than 90 seconds is shown as unconfirmed progress.

The page and the research process run independently. Closing a browser tab does
not stop either process. After restarting the computer, start the page again:

```powershell
python studies/theological-voices-v2/progress_server.py
```

Use the separate pipeline command above to resume research. The progress page
does not start inference or revise coding rules. Its tests use temporary data:

```powershell
python studies/theological-voices-v2/test_progress.py
```

## Rebuild the report from saved results

```powershell
python studies/theological-voices-v2/analyse.py
python studies/theological-voices-v2/verify.py analysis
python studies/theological-voices-v2/build_report.py
python studies/theological-voices-v2/verify.py pdf
```

Completed PDF: `output/private/report/tko-dobiva-rijec-o-vjeri-v2.pdf`.
Pages render to `output/private/report/pages/`. Any rebuilt PDF requires a new
visual review bound to its actual file hash before it replaces the reviewed edition.

## Evidence package (all private, git-ignored)

- `source_audit.json`, original web export, `frame.parquet`, `freeze.json` and
  `export_publication_crosswalk.csv`: source, cleaning, deduplication and hashes.
- `*_manifest.csv`, `*_inputs.parquet`: immutable selection probabilities, weights,
  publication IDs and complete raw/cleaned input texts.
- `configs/`, `candidate_freeze.json`, `coder_freeze.json`: frozen local settings.
  From v2.7, `configs/<hash>/source/` also preserves the exact coding program,
  preparation program, diagnostics, codebook and assignment, with matching hashes.
- `coding.sqlite`: requests, raw responses, retries, errors, elapsed times, input
  passage coverage, article results and evidence links, including superseded runs.
- `diagnostic_review.json`, `development_review.json`, `challenge_disagreements.json`:
  machine-only checks; not human validation or accuracy estimates.
- `statement_probe_inputs.json`, `statement_probe_review.json`: four additional
  constructed contrasts distinguishing announced speech from visible statements.
- `tables/`: full-frame counts, articles, mentions, speakers, affected groups,
  raw/weighted results, exact reuse, processing failures and task attempts.
- `tables/input_delivery.csv`: checks that recorded requests with actual model
  output contain every saved body passage and the headline. This is distinct
  from planned segmentation and from semantic understanding. `input_delivery.py`
  can run a read-only checkpoint while inference continues; the final verifier
  recomputes this audit and requires full delivery for structurally complete
  records. `test_input_delivery.py` detects missing endings and requests that
  never received a model response.
- `claims.json`, `cases.json`, `denominators.json`: claim/evidence trail and bases.
- `deterministic_reuse_cases.json`: two purposeful full-frame examples selected
  solely by identical archived text hashes and publication metadata. One family
  has five publications on one date; another has three across consecutive dates.
  `reuse_cases.py` preserves every member and the displayed selection. No extra
  model readings or copying-direction claims are involved.
- `pipeline_status.json`, `pipeline.log`, `status.json`: execution state.

## Source preparation

`export_source.R` reads through `DIGIKAT_CORPUS_PATH`, checks the official SHA256,
and writes only inside this study. It deliberately uses a standalone `--vanilla`
R session with installed global packages because the clone's renv is unrestored;
the environment and shared files remain unchanged. `prepare.py` refuses to
overwrite a frozen frame. Exact body reuse is measured across publications;
near-duplicate copying direction and all-content topic shares are not claimed.

## Engineering checks

```powershell
python studies/theological-voices-v2/test_pipeline.py
python studies/theological-voices-v2/test_analysis.py
python studies/theological-voices-v2/test_progress.py
```

The analysis test uses temporary synthetic data, including uncertain, partial and
missing records; it does not modify the real results. `layout_smoke.py` writes
clearly labelled synthetic layout pages under `tmp/pdfs/theological-v2-layout/`.
Those pages are never the analytical report and do not replace its final review.

Full-text segmentation preserves every non-whitespace character, including final
passages. Evidence IDs are constrained in the local decoding grammar and checked
again in code. A failed field does not erase a valid separate task. Three speaker
measures use distinct denominators. No unknown actor aliases are ranked as a
complete list of people; residual surface-form splitting remains a limitation.
Explicitly ambiguous candidate decisions are kept in the audit and excluded from
speaker-rate denominators. They remain distinct from structurally failed tasks
and from resolved articles without a confirmed speaker.

Required packages already available: pandas, numpy, pyarrow, matplotlib,
reportlab, pypdf and PyMuPDF; R data.table, jsonlite and digest. Report fonts are
local Palatino Linotype and Segoe UI. No network downloads are required.


## Completion policy (18 October 2026)

The initial controller stopped whenever any synthetic expectation failed. The
master instruction also permits withdrawal of unreliable numerical claims.
`finish_pipeline.py` implements that option while still requiring all 100
development articles, both readings of the fresh 30, all 30 synthetic tests,
four supplementary probes, and all 2,000 main outcomes. Nothing is labelled as
passed merely to continue. `report_policy.py` freezes the publication policy
before main coding: a failed primary semantic check or an essential structural
rate below 95%, including segmented-text rates, selects a limited exploratory
PDF. That PDF omits all model-derived content percentages and model-selected positive
cases, retaining deterministic frame results and explicit processing diagnostics.
Audit tables remain private and claims.json marks withdrawn claims.

The legacy strict controller is retained as `run_pipeline.py run`; it stops on
any failed synthetic expectation. For the documented handoff, a single hidden
`finish_pipeline.py --after-current` supervisor waited for its lock to disappear;
it resumes only a completed quality-gate stop, never an unexplained technical
failure, a changed configuration, or a STOP request. It reuses exact-version
saved results. It does not claim visual review or silently publish anything.

After that handoff, use `finish_pipeline.py` without `--after-current` to resume
an interrupted completion run. Do not launch it while `pipeline.pid` identifies
a live controller. The current performance revision is v3.2.0, using the same
prompts and schemas with local `think=false`. All checks run again before main
coding. Completed v3.1.0 results and reviews remain archived separately.

The v3.2 challenge uses `challenge_v32_inputs.parquet` and its matching manifest
and freeze file. `prepare_fresh_challenge.py` selected 30 new publications with
seed 2026101801, excluding all 2,130 original main, development and challenge IDs.
The original frame, main sample, development sample and challenge files were
not changed. The new challenge hashes are part of the coding configuration and
are checked again before final delivery.

`benchmark_no_thinking.py` is a separate, four-case synthetic performance probe.
It writes to `output/private/performance_probe_no_thinking/`, including its own
configuration hash, requests, responses and checks. It neither alters nor
authorizes the production run. Queue time is recorded separately from the
runtime's generation-time measurements for comparison with the frozen run.
`compare_runtime.py` reproduces the paired 100-article timing comparison and
saves `performance_comparison.json`. The observed development speedup was about
1.71, smaller than the synthetic probe; it is not an accuracy estimate or a
forecast for the main sample.

`test_report_policy.py` checks that semantic and long-text failures withdraw
claims, while incomplete samples and mismatched configurations still fail.
`limited_layout_smoke.py` builds 18 clearly marked synthetic pages under tmp,
not an actual report. The original layouts and the added source-completeness page
were visually inspected as examples; the final PDF requires its own complete page inspection.
The two added exact-text example layouts were also rendered and visually inspected.
`test_reuse_cases.py` checks date contrasts, the length threshold, stable selection
and publication provenance. These examples do not supply a representative rate.
