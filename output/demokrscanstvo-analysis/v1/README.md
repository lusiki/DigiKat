# Christian democracy: standalone analytical report

Input protocol: `output/pdf/demokrscanstvo-plan-analize.pdf`, preserved.
Final report: `output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf` (Croatian, 20 pages).
Public aggregate package: `output/demokrscanstvo-analysis/v1/`.
Private row-level work: `$DIGIKAT_BAROMETAR_WORKDIR/analytical-report-v1/`.

The analysis uses the existing two frozen releases and their private checkpoints. It does not query or mutate the source DetermDB, reclassify the archive, change inclusion criteria, or modify the barometer website. Code, content decisions, checks, chart sources, and a claim register accompany the PDF.

## Reproduction on this machine (PowerShell, repository root)

R uses the project renv activation. Its startup reports an out-of-sync library; no global-library bypass or lockfile update was performed. The actual loaded R/UDPipe runtime is recorded in the private preparation metadata, and relevant versions are exported into the final manifest. The existing thematic Python environment supplies the exact scikit-learn/numpy versions of the frozen model. Plot/PDF tools use the system Python; `svglib` was added for vector embedding.

```powershell
$reportR = 'C:/Program Files/R/R-4.6.0/bin/Rscript.exe'
$reportPy = 'C:/Users/lsikic/Luka C/DigiKat_barometar_work/nlp-venv/Scripts/python.exe'
& $reportR studies/demokrscanstvo-barometar/report/prepare.R
& $reportPy -X utf8 studies/demokrscanstvo-barometar/report/analyze.py
& $reportR studies/demokrscanstvo-barometar/report/long_text.R
& $reportPy -X utf8 studies/demokrscanstvo-barometar/report/lexical.py
& $reportPy -X utf8 studies/demokrscanstvo-barometar/report/controls.py
& $reportPy -X utf8 studies/demokrscanstvo-barometar/report/evaluation_pack.py
python -X utf8 studies/demokrscanstvo-barometar/report/figures.py
python -X utf8 studies/demokrscanstvo-barometar/report/render_report.py
& $reportPy -X utf8 studies/demokrscanstvo-barometar/report/verify.py
```

On another authorized machine, configure `DIGIKAT_BAROMETAR_WORKDIR` to the private cache, use corresponding R/Python executables, and retain the specified model and input release hashes. The report builder uses Windows Calibri and Georgia fonts. Source text is necessary to repeat the private steps; the public aggregate package suffices to redraw charts and render the report. Copy `README.md` and `qualitative_review.md` into the aggregate output before final manifesting. PDF creation also follows the environment's artifact-operation marker contract.

Render all final PDF pages using Poppler, inspect every page, run `python -X utf8 studies/demokrscanstvo-barometar/report/verify_pdf.py`, then rerun `verify.py --finalize`. This writes final content hashes and QA results. Read `qualitative_review.md` before interpreting output: computed checks are not human-coded accuracy.

## Table contracts

- `topic_sensitivity.csv`: counts and shares, one primary fixed-model topic per unit, explicit scope and denominator. Exact groups and distinct contexts are different units. `topic_profiles.csv` uses year, regime, platform and platform-in-2025 scopes.
- `timeline.csv`: monthly numerator/eligible denominator; rate is 10,000 times their ratio. `groups_with_presence` is not additive across months. `annual.csv` flags the collection-break year and incomplete final year. `platforms.csv` contains full-span counts plus 2025 coverage; body-word lengths exclude any stripped title, so a zero does not imply no selected text.
- `near_copy_sensitivity.csv`: exploratory 5-word-shingle Jaccard groups, thresholds .85/.90/.95; minimum 80 words and length ratio .80. Every pair in a group meets the threshold. No accuracy claim.
- `model_stability.csv`: ARI on 1,730 nonempty contexts, not accuracy. Alternative top terms and component cosine matches are in JSON. `long_text_summary.json`: purposive 140-case same-model projection, not a population sample. Original context reprojection reproduces all 140 labels.
- `lexical_pairs.csv`: support and NPMI on the same sentence universe. Undefined NPMI is null, not zero. `groups` is distinct exact-text representatives. `distinct_sentence_forms` is normalized surface text; `largest_shared_sentence_groups` and the remaining-group count remove all groups containing the most widespread identical sentence. The word-sequence table repeats this control ignoring punctuation. Distinct-sentence sensitivity retains one occurrence per sentence form; its `groups` describes only retained representatives and is not the original cross-text support.
- `lexical_adjacent_pairs.csv`: adjacent selected original sentences within one field, not arbitrary neighboring evidence fragments. `lexical_short_sentence_pairs.csv`: omit sentences over 120 whitespace words. `lexical_thresholds.csv`: number of positive pairs meeting each support threshold, before/after the shared-sentence control.
- `flagged_case_sensitivity.csv`: excludes four inspected risk contexts and their exact-context counterpart (five records). It is not a cleaned census or a classifier error estimate.
- `content_review_summary.json`, `topic_content_review.csv`, `human_validation_status.json`: actual review scope and absent human metrics. `claim_register.json`: rendered numeric/interpretive blocks, table source, unit, denominator, control and alternative explanation.
- `manifest.json`: exact public artifacts, report hash, inputs, code hashes, runtime versions. All row keys, source text, evidence spans and prospective human-coder packages stay private.

## Limits of completion

All feasible descriptive analysis, sensitivity controls, reviewed examples and PDF are delivered. The protocol's independent two-reader validation remains unperformed. Its fallback is used explicitly: no quantitative new principle/application/voice claims. No human precision, recall, kappa or gold labels are implied by AI review or by a passing numerical check.
