# Release calculation audit — 2026-09-18

Independent bounded review of `R/lib/barometar_release.R`, `08_aggregate.R`, and the source-to-release integration in `sample.R`. This review used invented data only. No empirical series or bridge was run; no human coding was inferred. Initial review changes were limited to tests and this report. A later explicitly authorized follow-up repaired only `08_aggregate.R` and `12_update.R`, as recorded below.

## Verification

`tests/barometar_release_audit_tests.R`: **48/48 checks passed** after the implementation owner's fixes. The fixture has four invented outlets, a full January, an unobserved February, a fully observed zero-positive March, and distinct A1/B/C passages on overlapping articles. A separate twelve-outlet fixture verifies that the top-ten calculation truncates at ten contributions.

- Broad article union is 4; narrow union is 3; both share January N = 1,240. Outlet breadth is 4/4 and 3/4 respectively.
- A1+B and A1+C articles retain only A1-passage themes, principles and speaker evidence in the narrow scope. A church speaker confined to a B passage does not remove the article from the narrow church-exclusion sensitivity.
- Exact route combinations partition the included articles; themes and principles remain overlapping indicators. A repeated theme within an article counts once.
- Removing an outlet segment changes N, D and P. Church/registered-HDZ-only sensitivities change the numerator while retaining common N and P.
- Unobserved theme rates are unavailable; observed absence is zero. Pooled broad theme certification is not reused for narrow themes without scope-specific evidence.
- Narrow-only releases contain no broad rows in the scoped tables or reloaded period files. Synthetic summaries never claim human validation and cannot load through the production gate.
- The weekly headline is the trailing-28-day row ending on the latest complete week's end. The separate comparison row remains weekly.
- Denominator duplicates, missing/zero/nonfinite/fractional counts, positives outside the denominator, D > N, duplicate article IDs, and narrow publication without accepted A1 are rejected.
- Public outlet inventory contains annual N only. Aggregate disclosure inspection passes. Public definitions preserve enumerated forms and phrase slots/order/gaps. CSVs have UTF-8 BOMs, all artifacts use LF, and modified artifacts fail hash verification.
- Anonymous concentration equals HHI = 1/4 for four equal broad contributions and 1/3 for the narrow scope. The larger fixture gives top-ten share = 11/13 and HHI = 15/169; zero-positive concentration is undefined. No named outlet numerator is exported.
- Public batch/theme/missed-formulation/route-set validation exports and aggregate agreement/precision summary are present. Scope-specific downloads preserve narrow-only availability, and invented results retain `human_validation_complete = FALSE`.

The complete `sample.R` run also passed: **3,206 invented raw rows, 49 merged-schema columns**, native old schema without ITEM_ID, actual eligibility and canonical deduplication, monthly boilerplate masking, classification, all release tables, manifest reload and rolling-28 weekly headline. All generated artifacts remained in R's temporary directory. The full repository runner was not run as part of this bounded audit.

## Findings repaired during review

1. The weekly summary originally used the raw weekly row for its headline. `barometar_release_summary()` now selects its trailing-28-day counterpart.
2. Theme confirmation originally matched theme ID alone and copied broad certification to narrow themes. Scope-aware matching now preserves narrow uncertainty.
3. `barometar_daily_facts()` accepted infinite and fractional N; it now requires finite positive integers. `barometar_build_tables()` now requires accepted A1 for narrow publication.
4. The public definition writer looked for forms on the compiled rule's outer object. The compiler stores them under `rule$entry`; the writer now reads that object and retains phrase semantics.
5. JSON writing used a Windows text connection and generated CRLF. The barometer-specific writer now uses an atomic binary UTF-8/LF write; BOM CSV and byte-level checks pass.
6. Aggregation could combine evaluated classifications with a newer denominator. Current population identity now checks proposal/metadata signature, registry, URL policy, retrieval identity and readiness digest. The original source snapshot is checked before/after aggregation. The classifier engine hash is also checked against current code. These provenance repairs were reviewed in source; the empirical aggregate entry point was not executed.
7. The release identifier now uses the required date format rather than date-plus-classification-hash.
8. Bridge cache identity now includes the engine, text and rules files. Aggregation verifies bridge definition/panel/registry/method hashes and both source snapshots, and requires its new-source snapshot to equal readiness. This delta was verified in source; no empirical bridge or aggregate was invoked by the reviewer.
9. The release now exports anonymous concentration, the computed validation diagnostics and bridge shared/exclusive contributions. The validation and concentration outputs were exercised by the invented release fixtures; bridge contribution wiring was inspected in source.

## Final pre-classification verification

The final bounded runner passed **108 checks**: worker 18, release 48, bridge source 11, pure bridge bootstrap 31. Only invented files were read. The worker fixtures directly read the new private evidence Parquet and compare every row and column against the RDS evidence and the two-worker result. Development evidence contains only development article identifiers.

The implementation owner fixed two chunk-level recovery problems identified during this pass: an existing finalized Parquet no longer blocks recovery when its RDS did not finish, and missing Parquet is regenerated from an otherwise complete cached RDS. Both cases passed the actual invented file test.

One wrapper-level gap was then found: the scheduling function's pending list originally considered only missing RDS, so normal reruns could skip the missing-Parquet repair branch. The owner repaired scheduling and authorized a fresh worker run. The expanded suite now passes **20/20 checks**, including normal wrapper recovery of the incomplete cached pair. The regression uses actual invented caches, real classification and real Parquet I/O; only its panel/population resolvers use invented metadata adapters. The reviewer did not edit classifier source.

## Release history and validation certificate follow-up

The new history implementation passed **21/21 invented checks** in `tests/barometar_history_tests.R`: numeric and status revisions, row removals, CSV-round-trip-stable no-op refreshes, exact preservation of frozen edition bytes/findings, same-day version increments, new edition creation/collision refusal, retained history, definition/panel migration refusal, and byte-identical second releases from fixed inputs. The implementation compares both actual serialized CSVs, preventing round-trip numeric precision from creating false revisions.

The G3 acceptance implementation passed **12/12 invented checks** in `tests/barometar_certificate_tests.R`. The test runs in a separate temporary project with copied method files, invented databases, an invented coding package and invented result flags. It never reads or writes the real G3 gates or real human work. The accepted certificate binds the classifier body, result hash and original validation population. Changed classifier body, incomplete review, stale classification, either panel mismatch, stale bridge result/method code, and either changed source snapshot are rejected. G3 and aggregate construction now explicitly require the current panel to equal both the draw's and classification's panel.

The source suite now passes **13/13**. Its added malformed `%00` query key demonstrably fails in the unchanged shared canonicalizer; registered non-panel and unmapped records containing that key in June and earlier history are discarded before canonicalization for both source instruments. The exact expected panel article set is preserved.

These two new suites are wired into `tests/run_tests.R`. The full repository runner was not run during this follow-up; the separately authorized worker suite subsequently passed 20/20 as recorded above.

`12_update.R` now checks the current definition, panel, classifier engine/body, human-result hash and scorer before its no-new-data shortcut. Installed/preview reuse also checks release-building code hashes. The subsequent invented orchestration tests and authorized retry repairs are recorded below.

## Refresh guards and preview retries

`tests/barometar_update_tests.R` passes **27/27 invented checks**. A temporary project contains small metadata-only DuckDB files, copied method files, real release manifests and invented validation receipts. The actual refresh function runs with recording adapters for population rebuilding, classification, bridge computation and figure/check stages. Certificate guards, source probing, release hash validation and directory reservation execute their real implementations. The test never calls a real source, gate or installation.

The authorized repairs in `08_aggregate.R` and `12_update.R` address four verified reuse/retry gaps:

- A preview reserves a fresh directory before calculation. Its same-day revision exceeds the installed revision and every existing preview file/directory, including failed attempts. Existing bytes are retained; a retry cannot overwrite an unfinished preview or reuse a lower missing suffix.
- A completed preview must match current classification, validation-result, bridge and release-code identities and pass actual manifest loading before reuse. A corrupt or incomplete preview gets a fresh version. `08_aggregate.R` now records the bridge hash in its private completion receipt.
- The no-new-data branch verifies the installed receipt's release version and manifest hash against the actual installed package, and checks that its human-validation hash remains current. Pending G2/G3 or stale definition/panel/engine/body/result/scorer is rejected before source access.
- Both source instruments must remain current. Even when the merged-source cutoff and snapshot are unchanged, the standalone old-source snapshot and bridge method/definition/panel/registry/validation identity are checked before returning “nema novih podataka”. Old-source-only and bridge-method-only changes trigger rebuilding the bridge and release.

The existing release audit (**48/48**) and history audit (**21/21**) were rerun after these changes and passed. The reviewer did not edit the running `run.R`, `07_bridge.R`, classifier, frozen definition, engine, metrics or validation code, and did not edit `tests/run_tests.R` in this follow-up. The owner will wire the new update suite and CLI.

## Installer rollback follow-up

The owner repaired the reported post-swap failure gap. `11_checks.R` now prepares all three sidecars before mutation and delegates the generation/sidecar transaction to `R/lib/barometar_install.R`.

`tests/barometar_install_tests.R` passes **56/56 invented checks**. Failures injected before and after each sidecar replacement, for both first and replacement installs, restore the exact old generation and sidecar bytes/absence. The new generation remains staged and an unrelated sentinel is unchanged. A partially overwritten sidecar is restored, retry with freshly staged sidecars succeeds, successful first install leaves no phantom backup, and successful replacement retains the prior generation privately. Out-of-scope targets/backups and duplicate destinations are rejected before mutation. The new suite is wired into `tests/run_tests.R`.

These tests execute the real transaction helper and atomic file replacement with a test-only failure callback. They do not exercise a real installation or override the human-validation, licensing, disclosure or source-snapshot prerequisites in the public apply entry point.

These passing invented checks establish arithmetic and artifact behavior; they do not supply human precision, human agreement, source licensing, or permission to install an empirical public release.

## A1 publication-policy follow-up

Independent review confirmed a release-policy gap outside the frozen statistical calculations. Three invented, fully scored cases with A1 dropped (precision 0.00), experimental (0.70), or unvalidated still selected broad publication because B and C passed, their accepted union had precision 1.00, and qualification agreement had kappa 1.00. G3, aggregation and refresh previously trusted the resulting non-empty scope. The bridge only marked the seam non-comparable; it did not enforce the adopted plan's unconditional A1 publication prerequisite.

The owner added `barometar_apply_release_policy()` in the non-frozen human-export wrapper. It requires exactly one accepted A1 validation row, finite A1 precision at least 0.80, A1 among accepted routes, and a passing narrow flag. Otherwise it preserves statistical diagnostics while setting both publication flags false, release scope to `none`, and the policy reason to `no_go_A1`. Human-export scoring and G3 acceptance apply the helper; aggregation and refresh recompute it, with refresh rejecting before database access or its no-new-data shortcut. Installation requires accepted A1. The policy wrapper's hash is bound in G3, checked by aggregation and refresh, and included in release-code identities.

The reviewer executed **27/27 independent invented checks** against the actual frozen scorer and new policy helper. All three counterexamples are blocked. Passing-A1 broad publication and passing-A1 narrow fallback after poor agreement remain unchanged; a confirmed masking loss stays blocked. Route estimates, intervals, agreement, theme results and all other non-publication fields are identical before and after policy application. Reapplication is idempotent. Duplicate or missing A1 rows, nonfinite precision, absent accepted A1, and a false narrow flag fail closed. Hashes of the frozen scorer, engine and metrics files were unchanged during verification.

The 27 checks are retained in `tests/barometar_release_policy_tests.R` so the frozen-scorer counterexamples and passing controls remain reproducible. The reviewer did not edit the shared test runner; the owner will wire this suite.

**Verdict:** the reviewed release entry points now enforce the declared A1 no-go policy without changing G2 classification or frozen statistical estimates. This follow-up used invented labels only; reviewer changes were limited to the test artifact and this report. The owner's separate regressions report 13 certificate checks, including rejection of B/C-only evidence, and 29 refresh checks passing. No empirical result, human label, bridge, release or real gate was read or changed by this review.

## Final CLI routing review

The bounded read-only review of `run.R`, README and PIPELINE confirms that the no-argument command and `--stage=update` dispatch to the reviewed refresh helper with eight workers. Explicit worker counts are restricted to the canonical integers 1 through 12 and to update, classification or development. `--edition` reaches only update or aggregation; `--stage=accept-validation` dispatches to the existing G3 acceptance function. Installation remains the separate, solitary `--apply` command. The documented commands and prerequisite descriptions match this routing.

The reviewer identified one convention violation in the first patch: base-R regex was used to validate worker text. The owner replaced it with exact membership in `as.character(seq_len(12L))`, preserving strict argument acceptance without regex. No remaining material CLI defect was found in this bounded review.

After that repair, **22/22 metadata-only checks passed**: help output, fifteen invalid or incompatible argument combinations, default and explicit update with pending G3, the minimum/maximum worker options, and update with `--edition`. A temporary sentinel on `DBI::dbConnect` recorded **zero database connection attempts**; each valid update invocation stopped with the G3 prerequisite message. The real gate file's hash was unchanged. The test did not invoke classification, scoring, bridge computation, aggregate construction or installation. The reviewer edited this report only; the owner's separate isolated CLI dispatch suite reports 31 passing checks and is wired into the shared runner.

**Verdict:** the documented default now performs a checked refresh when prerequisites are met and demonstrably refuses before source access while G3 is pending. This verifies routing and refusal behavior, not empirical validation or authorization to publish.
