# Moral-economy / RSP paper pipeline

**Current status (11 August 2026).** The paper was rerun on the official 413,985-row DigiKat corpus
(SHA-256 `15473a615bf301c02b5d4149d662a4db282927d3b3e98308c5ff54cbe1de520a`), covering
1 January 2021–11 June 2026. The main generic-religion/economics frame contains 66,374 posts and
79,439 post–subject pairs. The corrected same-domain Tier-1 core contains 1,093 posts and 1,290 pairs.
`PAPER_RSP_v2.md` is the authoritative public manuscript.

The analysis is complete **with a reported failed measurement gate**. The fresh R1 genuine-invocation
estimate is 79.6%, below its predeclared 80% threshold; the R2 subject gate fails or is unevaluable; and
the repeat-pass R1 economic-referent axis reaches 76.7% agreement (κ = .420), below 80%. These failures
are results, not pipeline errors. They require conditional claims and prohibit presenting the one-sided
denominator calculations as corrected prevalence.

All row-level text, URLs, source identities, keys and annotation sheets remain under the gitignored
`output/private/` tree. Only disclosure-reviewed aggregates, manifests, tables and figures are public.
The corpus and semantic store are read-only.

## Official input contract

`rsp_input.R` defines every official path and the fail-closed input checks. Step 29:

- verifies the official corpus file against its manifest;
- proves exact stable-ID identity for URL, date, trimmed full text, actor, platform and collection stream
  across all 413,985 rows;
- proves exact title and current outlet-label identity for all 79,439 retained candidate pairs;
- verifies the compiled economic and religion regexes and the 220-character window;
- records that the religion source file's hash changed while its compiled Stage-A regex remained identical;
- writes content hashes for the official prepared corpus and Stage-A derivative.

The official database is an exact stable-ID subset of the earlier accumulator. Stage A is a row-independent
transform, so restricting the accumulator result is algebraically equivalent to a fresh pass after the
compiled regexes and retained-row identities have been proved equal. The run does not claim that a changed
compiled lexicon could be handled this way.

## Current RSP stages

| Step | Purpose | Principal public output |
|---|---|---|
| `29_prepare_official_rerun.R` | install and hash the official prepared/frame derivatives | `rsp_input_manifest.json` |
| `cst_core.R` | same-domain Tier-1 adjacency, pair gaps and pair-specific terms | restricted `cst_core_official.rds` |
| `12_cst_census.R` | Tier-1/Tier-2 corpus census | `cst_census_*.csv` |
| `14_cst_core_profile.R` | pair-safe era, term and language profiles | `cst_core_*.csv`, profile figures |
| `15_propose_source_labels.R` | unratified outlet-group proposal | restricted review sheet |
| `17_cst_robustness.R` | 25 fixed-lexicon corpus/outlet specifications | `cst_robustness_*.csv` |
| `18_gold_reanalysis.R` | exploratory legacy register reanalysis | `gold_*.csv`, `gold_reanalysis_summary.csv` |
| `30_refresh_rsp_audits.R` | draw entirely fresh R4 and R1 probability samples | sheets, keys, prompts, provenance manifest |
| `31_assemble_rsp_annotations.R` | verify and assemble blind main-pass classifications | `rsp_coding_manifest.json` |
| `20_r4_recompute.R` | R4 domain precision and denominator-only sensitivity | `r4_linkage_precision.csv`, `cst_gradient_adjusted.csv` |
| `22_r1_recompute.R` | R1/R2 weighted post audit and nearest-domain gate | `r1_numerator_precision.csv`, `r1_precision_by_domain.csv` |
| `32_rsp_reuse_stability.R` | separate blind repeat pass and 80% agreement gate | `rsp_annotation_stability.csv`, stability manifest/diagnostics |
| `33_cst_frame_sensitivity.R` | independent full-corpus Tier-1-as-religion reconstruction | `cst_frame_sensitivity.csv` |
| `34_cst_lexicon_sensitivity.R` | leave-one-marker-out and ecology-marker construct tests | `cst_lexicon_sensitivity*.csv` |
| `24_rsp_figures.R` | four greyscale, 300-dpi paper figures | `figures/rsp_fig{1..4}_*.png` |
| `26_rsp_tables.R` | seven deterministic paper tables and prose scalars | `tables/tab*.md`, `rsp_derived.csv` |
| `27_sync_tables.R --v2` | mechanically install generated fragments | `PAPER_RSP_v2.md` |
| `35_rsp_coder_context_diagnostics.R` | aggregate-only main-context and coder-specific sensitivity diagnostics | context diagnostic CSV/manifest |
| `36_rsp_final_run_manifest.R` | seal inputs, private-file hashes, outputs, tables, figures and prose | `rsp_final_run_manifest.json` |
| `25_paper_checks.R --v2` | verify sealed hashes, gates, journal limits, tables, figures and claims | read-only pass/fail |
| `28_render_paper.R --v2` | typeset the checked manuscript | paper HTML/PDF |

The R4 main sample is a fresh simple random sample of 60 pairs per subject (660 total) from the full
79,439-pair frame. The R1 sample contains 150 fresh core posts, proportionally allocated across
adjacent-term era category × current outlet-concentration band. No earlier annotation was reused.
Both were blind Codex-model workflows rather than human coding; the exact backend identifier and decoding
settings were not exposed. The coding manifest preserves prompts, batch mapping, restricted output hashes
and the limits of procedural blinding.

## Reproducible run order

Run from the repository root with the project R environment active.

```powershell
Rscript studies/moral-economy/29_prepare_official_rerun.R
Rscript studies/moral-economy/12_cst_census.R
Rscript studies/moral-economy/14_cst_core_profile.R
Rscript studies/moral-economy/15_propose_source_labels.R

Rscript studies/moral-economy/30_refresh_rsp_audits.R
# Fresh blind coding: fill only the declared R4/R1 batch TSVs in output/private/.
Rscript studies/moral-economy/31_assemble_rsp_annotations.R
Rscript studies/moral-economy/20_r4_recompute.R
Rscript studies/moral-economy/22_r1_recompute.R

Rscript studies/moral-economy/32_rsp_reuse_stability.R
# Fresh blind repeat coding: fill only the three declared stability TSVs.
Rscript studies/moral-economy/32_rsp_reuse_stability.R --score
# Current run exits non-zero after preserving the failed R2 axis. Review it, then continue with
# downgraded claims explicitly:
Rscript studies/moral-economy/32_rsp_reuse_stability.R --score --allow-failed-gate

Rscript studies/moral-economy/17_cst_robustness.R
Rscript studies/moral-economy/18_gold_reanalysis.R
Rscript studies/moral-economy/33_cst_frame_sensitivity.R
Rscript studies/moral-economy/34_cst_lexicon_sensitivity.R
Rscript studies/moral-economy/35_rsp_coder_context_diagnostics.R
Rscript studies/moral-economy/24_rsp_figures.R
Rscript studies/moral-economy/26_rsp_tables.R
Rscript studies/moral-economy/27_sync_tables.R --v2
Rscript studies/moral-economy/36_rsp_final_run_manifest.R
Rscript studies/moral-economy/25_paper_checks.R --v2
Rscript studies/moral-economy/28_render_paper.R --v2
```

For the public site, run the thematic-paper publisher with
`-Only socijalni-nauk-i-gospodarstvo`. Because `_quarto.yml` deliberately excludes thematic-study QMD
files from the normal project render set, render this landing page to a temporary `--output-dir` and copy
only the resulting HTML to `docs/pages/studije/`; rendering the excluded target directly against the
project output directory can clean `docs/`.

Step 32's first mode must begin with fresh prompt/key/annotation locations. Its score mode must consume
exactly the declared repeat sample. A failed agreement gate may be accepted only after inspection and only
with downgraded claims; `--allow-failed-gate` does not turn failure into passage.

## Interpretation gates

- **Identified estimand:** 1,290 / 79,439 = 1.62% detected same-domain Tier-1 marker pairs in the observed
  official corpus. It is a census ratio; no binomial interval is attached.
- **R1:** 79.6% [72.4, 85.3], below 80%. The paper may report the raw detection rate and explicitly
  conditional post-level diagnostics, not a validated pair correction.
- **R2:** taxes fall below 70% and three domains are unsampled; the climate main-pass result is unstable in
  the repeat subset. The subject gate fails or is unevaluable.
- **R4:** 52.7% codebook and 44.0% strict layer-weighted denominator precision. The resulting 3.08% and
  3.69% values assume every numerator pair qualifies and are denominator-only sensitivities.
- **Repeatability:** R4 codebook, R4 strict and R1 invocation exceed 80%; R1 economic referent does not.
- **Composition robustness:** climate is first in 25/25 fixed-marker specifications.
- **Construct robustness:** climate loses first place when *Laudato si'* alone or the three ecology-specific
  markers are removed. This construct dependence is the central finding.
- **Outlet groups:** automated and unratified; descriptive association only, never a causal media boundary.
- **Legacy register:** 555 original rows → 296 in the official database → 268 in the corrected frame →
  148 genuine links; 126 displayed at n ≥ 10. The codebook does not measure rights or entitlements.

## Older dual-lens workflow

Scripts `05`–`10`, the 555-row gold workflow (`08`, `09a`, `09b`) and the inspection viewers belong to the
earlier accumulator-era dual-lens study documented in `PAPER_v1.md` and
`quality_reports/plans/2026-08-04_moral-economy-dual-lens-run.md`. They are retained for provenance but are
not inputs to the corrected RSP headline. Historical samplers `19` and `21` are likewise superseded by the
fresh official-corpus sampling in step 30.

The public manuscript names DigiKat and the authors' institution. It is therefore a public/site version,
not a double-blind submission file. An anonymised export must mask those identifiers and strip document
metadata before journal submission; `25_paper_checks.R` does not certify anonymity.
