# Catholic news-gap analysis plan

**Date:** 2026-08-13
**Status:** approved for execution by the PI
**Study workspace:** `studies/news-gap/`

## Goal

Measure, for Catholic media actors over time, the difference between the thematic mix they publish and
the thematic mix that receives recorded interactions. Use the same panel to test whether an unusually
rewarded topic in one month receives a larger production share in the next month, and whether the gap
narrows during the April-May 2025 papal transition.

## Why this design

The analysis joins four existing DigiKat strengths without changing the official corpus: stable post
metadata, a canonical 16-category dictionary, recorded engagement, and reviewed source labels. It adds a
reusable audience-response layer for research, the annual report, and a later `Moj medij` extension.

Rejected alternatives:

- Do not join `data/processed/*.rds` to the existing 5% NLP sample: their levels do not align and the
  sample is too sparse for an outlet-month panel.
- Do not pool raw interactions across platforms: a view, reaction, and web interaction are not directly
  comparable.
- Do not treat engagement as pure audience preference or as an editorial instruction: it is recorded
  attention shaped by platform affordances, distribution, and audience size.
- Do not modify the canonical dictionary or production data pipeline for this study. Study-local scoring
  consumes the dictionary read-only and records its hash.

## Scope

1. Read the official corpus through `digikat_corpus_path()` and verify it against its manifest.
2. Use a conservative study-local registry of Catholic editorial web products. The global source sidecar
   remains provisional and is not silently ratified by this study.
3. Split the raw `FROM == "hkm.hr"` source by URL host into HKM, IKA, and HKR. Their editorial mixes and
   interaction capture differ enough that pooling them would confound the gap. The primary set therefore
   contains six web products belonging to four organisations: HKM, IKA, HKR, Laudato, Bitno.net, and Glas
   Koncila. Treat broader Catholic actors and cross-platform accounts as future secondary analyses.
4. Preserve all 16 categories. Assign dominant topics with explicit fractional allocation of unresolved
   top-score ties; retain an unclassified flag and all score diagnostics.
5. Use only months with adequate calendar coverage for inferential work. Never bridge a missing or partial
   month when constructing a lag.

## Estimands

For outlet-platform `i`, month `t`, and topic `k`:

- production share: topic-assigned post mass divided by all classified post mass;
- reward share: interaction-weighted topic mass divided by all interactions on classified posts;
- gap: reward share minus production share, in percentage points;
- reward multiplier: reward share divided by production share;
- total gap distance: one half of the absolute topic gaps, summed across topics.

The supply-response model predicts next month's production share from the current engagement premium,
current production share, outlet-platform-by-topic fixed effects, and topic-by-month fixed effects. Results
are descriptive/associational, with multiway clustered uncertainty where estimable.

## Coverage and eligibility

- Mark an interaction as observed only when `INTERACTIONS` is finite and non-negative.
- Require at least 95% finite, non-negative engagement values and at least 5% of posts with a positive
  recorded signal. Finite zeros alone are not treated as evidence of valid measurement.
- Require at least 30 classified posts per editorial-product month.
- Use the `filtered_religious` stream from July 2024 onward; never pool the overlapping July rows from the
  older stream. Exclude September 2024 and January, March, April, May, and September 2025. The daily coverage audit found
  primary-source outages on 29 March-10 April and 28 April-10 May 2025, so transitions never use or bridge
  March, April, or May. End the headline engagement window in December
  2025 because web interactions collapse toward universal zero from March 2026; January 2026 may be used
  only as the next-month production outcome for December 2025.
- Use time-HAC uncertainty as the primary interval. Because the usable calendar is fragmented and has only
  ten current months, use an IID whole-current-month cluster bootstrap as a transparent robustness check;
  do not label it serial-correlation-robust or use false adjacent blocks across exclusions.
- Estimate pre- and post-collection-change periods separately; do not interpret the 2024 break as a real
  change in supply.

## Event analysis

The planned comparison tracks total gap distance around Pope Francis's death on 21 April 2025 and the
election of Leo XIV on 8 May 2025. Primary-source collection is nearly absent on 29 March-10 April and
28 April-10 May, including the conclave and election. The pipeline therefore preserves weekly coverage
diagnostics and visible gaps but marks the event contrast as not estimable; observed weeks must not be
presented as evidence of narrowing.

## Outputs

- `README.md`: question, scope, commands, and limitations.
- `source_registry.csv`: study-specific entity mapping and primary/secondary flags.
- `analysis.R`: single reproducible entry point with deterministic seed.
- `output/tables/*.csv`: disclosure-safe aggregate panels, diagnostics, coefficients, and robustness.
- `output/figures/*.png`: flagship produced-versus-rewarded chart, outlet comparison, event convergence,
  and supply-response coefficient plot.
- `output/analysis_results.json`: the single machine-readable numerical source for prose and future UI.
- `output/manifest.json`: input and code hashes, parameters, run environment, and generated-file hashes.
- `FINDINGS.md`: concise evidence-backed interpretation after a successful run.

### Approved extension, 2026-08-13

Prepare a produced-versus-recorded-reward profile for each of the six covered editorial products and
wire the profile shape into `Moj medij`. Keep the product-level table and comparison figure under
`output/private/` while topic validation is pending. The public lookup must fail closed. It may embed
these profiles only when the news-gap results explicitly carry a `validated_for_publication` status.
HKM, IKA, and HKR remain separate products even though the broader source aggregates use the shared
`hkm.hr` label. Products and sources outside the six-product study are not assigned a synthetic profile.

### Publication decision, 2026-08-13

The PI subsequently authorised publication of the six profiles before manual topic validation and
asked for the private-preview warning to be removed. The implementation therefore uses a distinct
`published_provisional_pending_manual_dictionary_validation` status. This permits the public aggregate
and `Moj medij` integration without falsely recording the study as validated. The page retains the
measurement qualification that interactions represent recorded attention rather than deep preference.

No row-level text, URL, post title, or private source audit may enter tracked output. Replaceable post-level
scores, if cached, belong only in gitignored `output/intermediate/`.

## Verification gates

1. Registry keys are unique and every analyzed raw source maps exactly once.
2. Topic production and reward shares each sum to one for eligible cells; gaps sum to zero.
3. All lagged rows are true consecutive calendar months and both months pass coverage gates.
4. Main conclusions are checked against tie-exclusion, 95% engagement coverage, 30-post cells, winsorized
   engagement, removal of the largest outlet, and web-only specifications.
5. Run `R/check_disclosure.R` on study outputs and inspect small cells manually.
6. Run the full study entry point from the repository root twice and verify deterministic aggregate output.
