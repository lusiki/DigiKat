# Theological voices v2: local 2,000-publication study

User authorization: 17 October 2026, run a new version of the existing report using
the attached MASTER INSTRUCTION v1.0. Preserve the earlier study and all source data.

## Final status: complete, 20 October 2026

All 2,000 main outcomes are saved under the frozen v3.2.0 configuration: 1,950 structurally complete, 50 partial, zero wholly failed and zero missing text. Full body/headline delivery is confirmed for all 2,000. The 18-page Croatian PDF is complete; 31,775 analysis/evidence checks and mechanical PDF checks passed, and every final page was visually inspected by Codex AI. Review timestamp: 2026-10-19T22:44:00.007358+00:00. PDF SHA-256: `501eaec872bfaac0c98d7448b55f57e9a2d1e3abf86ea5ac17f868d88c8fc723`.

The report remains limited exploratory under the pre-main publication policy. Failed semantic checks and the long-text processing target are disclosed; numerical content claims and model-selected positive cases are withheld. No empirical accuracy or human validation is claimed. Earlier checkpoint notes below are historical. Final output: `studies/theological-voices-v2/output/private/report/tko-dobiva-rijec-o-vjeri-v2.pdf`.

## Assignment and decisions

- Question: who is given a topic-related voice, and who interprets faith, in the
  Catholic-topic editorial web material captured by DigiKat?
- Input: hash-verified official 413,985-row corpus, read through DIGIKAT_CORPUS_PATH.
- Period: its full 2021-01-01 to 2026-06-11 window. Partial 2026 and the 2024 capture
  gap/collection change are explicit; no cross-break attention-growth claim.
- Frame: all web articles already retrieved by the official Catholic-topic rule.
  This intentionally includes incidental/irrelevant captures, to be estimated by
  the coder. Do not preselect a list of theologians or doctrinal keyword hits.
- Language/geography: inherit the Croatian/Bosnian regional collection and audit
  metadata; do not equate the collection with all Croatian journalism or assert
  country from a person's name. Report the actual source/language scope.
- Main sample: 2,000 publications, proportional calendar-quarter strata, fixed seed.
  Development and fresh challenge sets are separate and never enlarge its base.
- Inference: existing local Ollama Qwen3 14B only; paid API budget zero. Corpus and
  article text remain local. Python scheduler and resumable SQLite audit trail.
- Output: studies/theological-voices-v2/output/private/. New report only; no site
  render, publication, corpus rewrite, repository commit, or shared-aggregate edit.

## Execution

1. Audit schema/runtime; export read-only web records with all text and provenance.
2. Freeze deduplicated frame, row crosswalk, source/time/quality tables and sample.
3. Write topic-specific brief, measures, label definitions, schemas and diagnostics.
4. Benchmark and develop on varied articles and targeted synthetic diagnostics;
   revise if needed, then freeze config and run a disjoint automated challenge.
5. Run all 2,000 sample articles locally with full-text segmentation, task-specific
   validity, stable evidence IDs, bounded retries and raw-response retention.
6. Compute weighted complete-case results and all three speaker-role measures;
   save cases, claim records, denominators, failures and exact-reuse analysis.
7. Build the Croatian PDF from saved tables; verify numbers and evidence links,
   render every page and inspect layout before calling the PDF complete.

## Guardrails

No machine review is human validation. Numerical claims for a repeatedly unreliable
task are withdrawn, not rebranded as findings. All attempted articles stay in the
sample accounting. No paid service or remote article classification. Existing
uncommitted workspace changes belong to the user and remain untouched.

## Execution checkpoint

The verified source export contains 286,662 web rows; the frozen frame has 282,701
publications after 3,961 duplicate exports. The 2,000-publication main sample,
100-article development set and disjoint 30-article challenge set are frozen.
The constructed diagnostic suite expanded to 30 cases without changing sampling.

Local-coder development identified and corrected attendance-as-speech, field
validity, citation-ID and capacity-boundary problems; see the study REVISIONS.md.
Configuration v2.5 uses Qwen3 14B reasoning mode, constrained evidence IDs and
candidate-only verification. The unattended controller was launched locally
17 October 2026; pipeline_status.json and pipeline.log are authoritative for its
current stage. It must pass diagnostics and development/fresh challenge before
starting main coding. There is no new analytical PDF at this checkpoint.

The report builder, analysis/evidence verification and reproduction instructions
are implemented. Two explicitly synthetic layout pages were rendered and visually
inspected, including Croatian glyphs. This is not visual review of the eventual
report. Every page of the completed analytical report still requires inspection.

## Continued execution, 17 October

The v2.6 diagnostic round stopped at 29/30: an announced paywalled interview was
mistaken for a visible statement. v2.7 now requires an explicit proposition decision
and summary, accounts for every extracted candidate, and preserves unresolved
attribution separately from failed processing or successful zero-speaker findings.
Four additional constructed contrasts passed before the new full diagnostic round.
They do not enlarge the frozen 2,000-publication sample. The controller continues
through development, fresh challenge and the main sample only if its gates pass.

Analysis now gives interpretation and experience their own uncertainty-aware
denominators. A synthetic end-to-end table test checks these against complete,
partial, missing and ambiguous records. The PDF builder records actual challenge
disagreements and full cited passages in cases. Two new layout-test pages were
rendered and visually inspected; these are not the analytical report.

The live read-only progress page is http://127.0.0.1:8767/ on this computer.
Authoritative current status remains output/private/pipeline_status.json. No main
results or completed analytical PDF are claimed by this checkpoint.

The subsequent v2.7 and v2.8 diagnostics exposed a distinction that the combined
verification/classification task did not preserve reliably: a source can be
explicitly quoted while their occupation remains unknown. The current v3.0 coder
therefore separates extraction, attribution verification and capacity/flag
classification. The classification task cannot veto verified attribution. Earlier
failed runs, exact coding sources and interruption metadata remain private and
auditable. Main coding still requires passing the gates under this new version.

The v3.0 four statement-boundary probes passed. Its prioritized diagnostic cases
D101 (Mass timetable), D110 (unknown capacity), D081 (paywall) and X05 (appended
recommendation) also passed. The rest of the suite is still running at this
checkpoint; do not infer that development, fresh challenge or main coding passed.


### 18 October ? completion rather than repeated quality-gate stops
- v3.0 finished 28/30 synthetic rules. D031 exposed an overbroad capacity
  normalization; X03 exposed competing retained/rejected lists. v3.1 fixes these
  structures. Thirteen pipeline tests pass. No main data existed before v3.1.
- Added a separate, pre-main report policy and completion supervisor. A complete
  failed quality check now leads to explicit withdrawal of model-derived content
  estimates in a limited exploratory PDF, as permitted by the master instruction.
  Incomplete readings, changed inputs/configurations and technical errors still
  block. All 2,000 original sampled articles are required in either mode.
- Five policy tests pass. The 15-page fallback template rendered and was visually
  inspected using clearly marked synthetic values. Fixed a monthly plot reader
  expecting `month` when the frozen CSV stored its month index as `Unnamed: 0`;
  the frozen file and coder configuration remain unchanged.
- Actual analytical PDF and its visual inspection are still pending.

- Full template also exercised end-to-end on six isolated synthetic analysis records (21 pages, no selected case pages), rendered and visually inspected. Both template routes now have actual visual layout checks; final empirical pages still require fresh inspection.

- v3.1 finished all 30 diagnostics: 29 passed; D041 misclassified an explicitly identified sociologist as priest_religious instead of research_expert. All four statement probes passed. No further prompt revision was made. The completion supervisor resumed the exact saved configuration and began development automatically.
- Development checkpoint: 31/100 articles saved; all four tasks structurally valid in all 31, including all 20 completed multi-segment long-text cases. Two output-budget retries and two verification-structure retries succeeded; original failed attempts remain preserved. These figures are processing checks, not accuracy.
- The final limited report now explains a concrete role-classification failure in Croatian, and the final PDF build archives its exact source programs with hashes. Actual main reading and final PDF remain pending.

- 18 October 08:38 UTC: all 100 development articles completed under v3.1.0 / 8b436ead349d42ef897c6c5a95eaa0ef49fc3480c8c8b394bb99518c40394e2c. Each of topics, mentions, speakers and groups is structurally valid in 100/100, including 23/23 multi-segment articles. Source-status outputs: 82 complete, 15 partial, 3 unresolved. These are machine processing results, not accuracy. Candidate configuration frozen at 08:37:22 UTC before fresh challenge; the primary 30-article challenge is now running. Main count remains zero.

- During fresh challenge, added an explicit source-completeness diagnostic page to the limited report, bringing its template to 16 pages. It separates partial/missing source text from structural processing success. Rendered the synthetic template; visually inspected the new source page and revised diagnostic-explanation page. This does not substitute for final empirical-page review.

- 18 October 10:10 UTC: both fresh challenge configurations completed all 30 articles, with 100% structural validity for each essential task. No challenge article needed segmentation. There were 9 primary and 8 alternative zero-speaker results. Configurations disagreed on relevance in 3/30, role sets in 13/30, and source completeness in 2/30; these are sensitivity counts, not accuracy.
- report_policy.json and coder_freeze.json were saved before main coding. Mode is limited_exploratory due to D041's role-rule failure; no failed rule was relabelled as passed. Policy source and pre-main decision archived under configs/<hash>/. Main coding began at 10:10:55 UTC, controller PID 44744, worker PID 24636. It will retain all 2,000 outcomes, then calculate, verify, build and render the PDF; actual visual page review remains required before delivery.

- 18 October 10:57 UTC: an isolated four-case performance probe with think=false used 87.65 seconds of generation time versus 319.28 seconds in v3.1. D041 still failed the affected-group rule; no accuracy claim was made. The v3.1 worker stopped safely at an article boundary after 21 main records. Every old result remains in SQLite; review files and logs were archived under its configuration hash.
- Performance-only v3.2.0 / e6fd76c460624f02f7fe91f574ebe3bfcad0bbff62a0050f9ce625b01d00c9b4 changes think to false while retaining prompts, schemas, segmentation and role rules. All checks are repeated. A new probability-selected challenge of 30, seed 2026101801, excludes the original 2,130 main/development/challenge IDs; its own immutable bundle and selector are included in the configuration hash. Original frozen files remain unchanged. All 2,000 main articles will be recoded under v3.2 without mixing versions.
- Thirteen pipeline, one analysis and five publication-policy tests passed after the change. The completion controller is PID 17632. This is still ongoing research; no final report PDF or final visual review exists yet.

- 18 October 13:20 UTC: v3.2 completed all 100 development articles. Topics, mentions and groups are structurally valid in 100/100; speakers in 97/100. Of 23 segmented articles, speaker structure is valid in 21/23 (91.3%), below the predeclared 95% target. Source labels: 87 complete, seven partial, six unresolved. These are machine processing outputs, not accuracy. All 30 synthetic outcomes were saved: 27 passed, D021 admitted an unrelated voice, and D040/D041 missed an affected group. Two of four additional statement contrasts passed. These failures require the limited report under the existing policy, not another prompt loop.
- Paired development runtime, including retries, was 7,967.65 seconds under v3.2 versus 13,638.46 under v3.1 (1.71 times faster). This is less improvement than the four-case synthetic probe. Candidate frozen at 13:19:40 UTC before the newly sampled challenge. Fresh primary challenge now running; main v3.2 count remains zero. Updated synthetic method-page layout was rendered and page 16 visually inspected; actual final pages remain pending.

- Added two deterministic circulation illustrations from full-frame metadata, independent of withdrawn semantic labels. Selection requires exact body hashes, at least 1,000 characters and 3–5 source IDs; first lexicographic eligible hash supplies a same-date example, and another a different-date example. An initial >=30-day screen found none, so no long recurrence is claimed. Actual cases: five publications/five sources on one date; three publications/three sources across consecutive dates. All family members and displayed IDs/metadata/URLs are saved. Claims distinguish these eligible deterministic examples from withheld model cases. Final verification checks counts, IDs, dates and every displayed metadata field against the frozen frame.
- The limited layout now has 18 pages. Its two new example-page layouts were rendered and visually inspected with clearly synthetic values. The reuse-case provenance test and existing analysis test passed. The full empirical report still requires all 2,000 main outcomes and actual final-page review.

- 18 October 14:19 UTC: both fresh v3.2 challenge readings completed 30/30, with 100% structural validity for all essential tasks, including two segmented articles. Between configurations, relevance differed in one article, roles in four, and source completeness in one. Separately, extraction and verification differed on segment relevance in 28/30 articles within each configuration; both fields use the same enum, so this is recorded disagreement, not an enum-comparison bug or measured error rate. The report now explicitly includes that internal inconsistency.
- Frozen publication policy at 14:19:12 UTC remains limited_exploratory, with six recorded withdrawal reasons: long-text speaker processing below 95%, three synthetic failures, and two positive-statement boundary failures. Main v3.2 started at 14:19:27 UTC, controller PID 17632, worker PID 37000. First ten main records were structurally complete; their runtime implied about 35 hours remaining, stated as a rough estimate. Main inference continues without further configuration changes.

- 18 October 16:12 UTC: main checkpoint reached 100/2,000, with 99 structurally complete records, one partial-processing record, no wholly failed records and no missing texts. Dashboard estimate remained about 35 hours. Partial results are preserved with task-specific flags, not recoded as absence. Detailed checkpoint metadata is saved in main_runtime_checkpoints.json. The final PDF and its actual visual review remain pending.

- 18 October 18:45 UTC: main checkpoint reached 250/2,000, with 242 structurally complete and eight partial-processing records; no wholly failed or missing-text records. Frozen v3.2 remains unchanged and inference continues. Dashboard estimate is roughly 31 hours remaining. This checkpoint is processing accounting, not a substantive result or accuracy estimate.

- Added an analysis-only actual-input delivery audit. It checks literal body passages and the headline in saved requests for which Ollama returned generated tokens, rather than relying only on prepared segment IDs. Failed/unconfirmed delivery remains distinct from missing text. Final verification recomputes the audit and requires full delivery for structurally complete records. Tail-omission/absent-response tests and the analysis integration test passed. A read-only checkpoint confirmed all passages/headlines for all 314 saved main records, including partial task outcomes. Coder hash and inference were untouched. The revised synthetic processing page was rendered and visually inspected; final empirical-page inspection still awaits all 2,000 outcomes.

- 18 October 22:39 UTC (19 October local): main reached 500/2,000, with 487 structurally complete and 13 partial-processing records, no wholly failed records and no missing texts. The rough remaining runtime is 25 hours. Inference continues under the unchanged v3.2 configuration; no final empirical PDF exists yet.

- 19 October 02:41 UTC: main reached 750/2,000, with 727 structurally complete and 23 partial-processing records; no wholly failed or missing-text records. The rough remaining runtime is 21 hours. The actual-input audit confirms every saved body passage and headline in generated-response requests for all 750 records, including partial task outcomes. This confirms delivery, not semantic understanding or accuracy. Inference remains active under the unchanged frozen configuration; final empirical PDF and visual review remain pending.

- 19 October 07:21 UTC: main reached 1,000/2,000, with 967 structurally complete and 33 partial-processing records; no wholly failed or missing-text records. Dashboard estimate is about 17 hours remaining. The controller and worker remain active under the frozen v3.2 configuration. Final aggregation, numeric/evidence verification, PDF build/render and actual page review still follow the complete main sample.

- 19 October 11:06 UTC: main checkpoint is 1,251/2,000, with 1,211 structurally complete and 40 partial-processing records; no wholly failed or missing-text records. The actual-input audit confirms complete body/headline delivery for all 1,251 saved outcomes. The rough remaining runtime is 12.5 hours. The frozen coding configuration remains unchanged; the PDF and actual visual review are still pending.

- 19 October 12:13 UTC: investigated slower progress after the 1,250 checkpoint. NVIDIA reports 98% GPU utilization, 16.5 GB VRAM and 77 C. Recent requests take 29–55 seconds wall time while reported generation is approximately 6–22 seconds; other local client PIDs have established Ollama connections alongside worker 37000. Shared-runtime waiting is a plausible contributor, not a proven timing decomposition. No unrelated process was stopped, no configuration changed, and the main run continues. Process-command inspection through CIM was denied by the local environment; ordinary process and TCP inventories were available.

- 19 October 15:24 UTC: main reached 1,500/2,000, with 1,455 structurally complete and 45 partial-processing records; no wholly failed or missing-text records. Dashboard estimate is about 8.4 hours remaining. Inference continues under the same frozen configuration, followed automatically by aggregation and PDF checks; actual final-page visual review remains required.

- 19 October 19:00 UTC: main reached 1,750/2,000, with 1,702 structurally complete and 48 partial-processing records; no wholly failed or missing-text records. The rough remaining runtime is 4.1 hours. Inference remains active; final aggregation, PDF verification and actual visual review are still pending.

- 2026-10-19T22:44:00.007358+00:00: final analysis, PDF build, mechanical verification and actual inspection of all 18 final pages completed. `pipeline_status.json` is complete; `report/visual_review.json` binds the review to the PDF hash above. All source data and the original report remain preserved.
