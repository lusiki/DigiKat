# Topic validation protocol

The numerical run is complete only as an exploratory audit. Publication, promotion, and client use remain blocked until the topic assignments pass this protocol.

## Coding decision

Before coding, the researcher must approve a short codebook defining the central subject, inclusion, exclusion, and closest-category distinction for every topic. The keyword list alone is not a human codebook.

Code the article from its title and the first 3,000 body characters—the same window used by the primary classifier. Assign:

1. one primary topic from the canonical 16-topic dictionary;
2. an optional secondary topic when the article substantively covers two themes; or
3. `none/unclear` when no topic is sufficiently central.

Do not infer a topic from the outlet, author, engagement count, model prediction, or URL. Boilerplate mentions do not determine the code.

## Files

- `output/private/topic_validation_coder_sheet.csv`: prediction-free sheet for human coding.
- `output/private/topic_validation_answer_key.csv`: model predictions; keep hidden until coding is frozen.
- `output/private/high_interaction_coder_sheet.csv`: prediction-free sheet for the mandatory high-interaction audit; it also hides outlet, interaction, URL, and audit-scope metadata.
- `output/private/high_interaction_answer_key.csv`: hidden model and audit metadata for the high-interaction sheet.
- `output/private/high_interaction_topic_audit.csv`: combined high-interaction worksheet for use only after coding is frozen.
- `output/private/high_interaction_audit_coverage.csv`: row-to-estimand coverage map for the headline and lag-panel high-interaction audit.
- `output/private/topic_validation_sample.csv`: combined audit worksheet; do not use it for blinded coding.

## Procedure

- The main coder codes the prediction-free sheet without seeing the answer key.
- A second coder independently codes a random 25% of rows, stratified by sampling topic.
- Resolve disagreements only after both coding passes are frozen; retain original and adjudicated codes.
- Separately review every row in `high_interaction_coder_sheet.csv` without opening its answer key because ordinary random sampling does not protect an interaction-weighted vector from a few high-leverage errors. The audit is drawn from the actual analytical cells: the top five contributors to every retained headline product-topic, the top classified post in every retained headline product-month, and the top contributor to every non-empty product-topic-month in the lag panel.
- Join each frozen human-label sheet to its separate answer key by `row_id`.

## Preregistered acceptance thresholds

These thresholds were fixed on 2026-08-13 before the prediction-free coder sheet was labelled or joined to the answer key.

- Coding completeness: at least 95% of the random audit sample must have a usable primary or `none/unclear` decision. Missing sampled cases must be replaced where eligible cases remain. Every row in `high_interaction_coder_sheet.csv` must be coded.
- Intercoder reliability: on the independently double-coded 25%, exact primary-topic agreement must be at least 80% and nominal Krippendorff's alpha must be at least 0.70, counting `none/unclear` as a category. Failure requires codebook revision, retraining, and a fresh blinded reliability round.
- Article-level agreement: the adjudicated human primary topic must appear in the model's co-winner set for at least 75% of audited posts overall.
- Topic precision: for topic `k`, precision is the model allocation weight assigned to `k` on posts whose adjudicated primary is `k`, divided by all audited model allocation weight assigned to `k`. Every topic reported separately must have precision of at least 70% and at least 30 audited posts with a positive predicted allocation; otherwise it is grouped or omitted. The macro-average across separately reported topics must be at least 75%.
- High-interaction stability: replace each audited high-interaction post's model allocation with its adjudicated one-hot primary label, or exclude it when adjudicated `none/unclear`, and recompute the relevant field and product gaps. The provisional claim fails if any separately named gap changes by 2 percentage points or more, or reverses direction.
- Headline stability after rule revision: rerun the complete pipeline. A provisional headline gap may be retained only if it keeps its direction and moves by less than 2 percentage points. The lag conclusion must be rewritten whenever the sign or the 95% interval's inclusion of zero changes; it is never protected merely because the provisional point estimate was small.

Primary agreement and precision are intentionally strict: optional human secondary topics are reported diagnostically but do not count as correct primary predictions. Threshold failures invalidate the current provisional claim; they do not authorize changing a threshold after looking at the labels.

## Acceptance report

Report the number coded, missing decisions, model precision by predicted topic, confusion matrix, `none/unclear` rate, primary-topic agreement, and intercoder agreement before adjudication. Small categories that do not reach a defensible validation sample remain grouped rather than individually interpreted.

Revise only study-specific matching rules; do not silently edit the project-wide canonical dictionary. Rerun the complete analysis after revision and compare the headline gap and lag coefficient with the current provisional version.
