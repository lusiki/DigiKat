# Execution of the approved analytical protocol

User request, 19 September 2026: run the analysis in the supplied PDF and produce a checked, well-interpreted report.

Input: `output/pdf/demokrscanstvo-plan-analize.pdf` (protocol 2.0). Preserve it. Output: `output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf`, Croatian, with aggregate replication files under `output/demokrscanstvo-analysis/v1/` and code under `studies/demokrscanstvo-barometar/report/`.

1. Verify public SHA256 manifests and reconcile the 2,306 selected keys to private candidate/classification/context data, without querying or changing the archive.
2. Reconstruct field-specific evidence passages and original normalized offsets. Compute exact stored-text groups separately from exact contextual repetition; do not call either unique stories. Inspect near-copy candidates, retaining exact copies as the conservative main analysis.
3. Reproduce the fixed topic model and assignments, run 8/10/12 and random-start checks, review typical and boundary cases. Test A1, stored-body, web, time and longer-text sensitivity.
4. Annotate original evidence segments with UDPipe, preserving sentences, lemmas, verbs and negation. Calculate sentence-based pair support/NPMI and 5/10/20 group sensitivity, with shared-sentence control. Treat these as lexical relations, not argument or endorsement.
5. Inspect principle/application candidates and contrasting cases. Apply the protocol's stated fallback when two independent human readers are unavailable: descriptive aggregates and transparent AI-assisted qualitative review; no unvalidated prevalence, application matrix, speaker percentages or human-validation claim. Preserve private coding evidence, review decisions, and a blinded evaluation pack for later human use.
6. Create aggregate tables, figures, claim register, provenance manifest, and a self-contained report. Independently recalculate headline values, verify identities and bounds, check every rendered page and Croatian encoding. Record unfinished human validation explicitly.

No source database/master overwrite, corpus redefinition, site publication or downstream public-release overwrite is part of this task. Existing unrelated work is preserved. A missing second human reader is an analytical scope limit already anticipated by protocol page 11, not a reason to stop the authorized computation and report.
