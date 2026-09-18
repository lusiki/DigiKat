# Pre-G2 near-miss, cache and June bridge review

2026-09-18. Independent R review; source inspection and invented evidence only.
No source article, empirical human label or period series was read. No engine or
pipeline implementation was changed. The existing R3 implementation plan covers
this bounded review. Line numbers below identify the reviewed snapshot and may
move as fixes are applied.

## Findings and fix verification before the fresh evaluation draw

1. **Near-miss membership does not establish exactly one failed condition.**
   `R/lib/barometar_engine.R:241-265` counts missing lexical components inside
   arbitrary suffix windows, without checking attachment when one component is
   absent. Invented hits with a strong doctrinal anchor and a connector in
   different clauses, but no public anchor, return `B:political_anchor`: both the
   political object and grammatical application fail. A strong anchor at token 1
   in clause 1 and public/connector hits at tokens 82/83 in clause 2 return
   `B:strong_anchor`: both distance and attachment fail. The same-clause
   distance-only control is retrieved but incorrectly described as missing the
   strong anchor. A relation-only complete trio also acquires extra
   missing-component reasons from smaller suffix windows.

   Share condition evaluation with the inclusion engine. Evaluate coherent
   supporting bundles and retain a bundle only when exactly one declared route
   condition is false. If a lexical component is absent, attachment among the
   remaining components must still pass. Distance/window membership needs an
   explicit condition, evaluated outside the inclusion window as well. Do not
   create an absent condition by deliberately cropping an available supporting
   component out of its coherent bundle. Declare whether this frame intentionally
   covers B/C only; A? has its own separate diagnostic stratum.

   **Fix verified during this review:** the parent implemented an explicitly
   narrower diagnostic stratum: a complete sentence/clause's relevant hits fit
   80 tokens, attachment holds, exactly one lexical condition is absent, and that
   condition is not merely present elsewhere in the field. Distance-only and
   attachment-only failures are outside this amended frame. The three original
   two-failure fixtures are now rejected and the missing-public-only control is
   retained. This is a declared sampling amendment under the user's delegated
   recommendations, not comprehensive near-miss recall. Record it in the
   definition README and DEVLOG before G2. The independent recall probe may
   reveal some excluded failures; doctrinal-only B cases need not meet that
   probe's separate concept-family criterion.

   One follow-up defect was sent to the parent and fixed: the actor-only matcher used
   `gradona?elnik`, which does not match `gradonačelnik`. An invented mayor plus
   attribution verb without a strong anchor then has two failures but enters as
   one. The corrected `gradonačelnik` Unicode spelling passes the added regression.
   Also, the field-wide `application` presence uses any attribution although
   actor-only attribution is disallowed locally; this is a conservative omission
   of some genuine missing-application cases. Align the local/global predicates.

   Reproduction: source `tests/barometar_near_miss_audit_tests.R` and call
   `run_barometar_near_miss_audit_tests(strict=FALSE)`. Expected membership now
   follows the explicitly amended bounded frame. All eight checks now pass and
   the helper is wired into `tests/run_tests.R`. These are invented regression
   probes, not empirical precision estimates.

2. **Bind classification reuse to candidate retrieval and the extraction
   contract.** `04_classify.R:21-25` correctly now includes the definition,
   engine, input digest, panel, mask version and development flag. It omits
   `candidate_manifest$retrieval_hash` and the classification extraction/output
   contract. A changed candidate transport contract can produce a new candidate
   folder under the same input, panel and prefilter, then reuse the old
   classification folder. Include retrieval identity and a classifier-output
   contract/hash, persist this identity inside each chunk, and check it before
   reusing an existing chunk (`04_classify.R:35`). Store the boilerplate version
   and identity explicitly in the classification manifest as well.

   **Follow-up:** the parent added `retrieval_hash`, a versioned output contract,
   and the `04_classify.R` file hash to classification identity, and exported
   retrieval/boilerplate versions in the manifest. These changes were confirmed
   by source inspection after the invented import tests passed. Chunk reuse
   remains guarded chiefly by its containing hash-named directory.

3. **Bind the coding package to the exact frozen classifications and instrument.**
   `05_validation_draw.R:11-16,29-31,44-50` checks definition/input/panel but does
   not verify current classifier engine identity or the mask table against the
   classification manifest. Its draw ID omits `classification_hash`, the complete
   eligible-frame digest, the boilerplate version, sampling code/seed, context
   helper and HTML template. The loaded definition fingerprints engine/text
   files, but changes to matcher implementation in `barometar_rules.R` need not
   change its compiled-rule fingerprint; the explicit engine check remains
   necessary. Persist a package manifest covering these identities and the
   generated HTML hashes. The score/import wrapper must verify that manifest.
   This prevents labels from being joined to classifications or context that
   differ from what humans actually received.

4. **Preserve all exclusion-log provenance.**
   `05_validation_draw.R:25` uses `basename(path)` as a list key. The two root
   `agent_reads.csv` paths already share that name; different development folders
   can also contain identically named logs. Their IDs are correctly unioned, but
   the last hash overwrites earlier hashes. Use sorted, distinct normalized paths
   (private manifest only), or a sorted array of path/hash pairs. Hash the final
   excluded-ID set too. Reject empty IDs as well as NA, and retain all historical
   development folders in the exclusion union.

5. **Finalize the package only after all material is complete.**
   `05_validation_draw.R:33-35` writes `draw.rds` before fetching raw context or
   creating either coder HTML. Any later error leaves a partial package and the
   existing-draw guard prevents ordinary retry. Stage and validate the whole
   package, then atomically install it. Alternatively, support explicit resume
   using the identical saved draw and frozen package identity; never redraw or
   overwrite a package that has received human labels.

The broad classification flags remain raw until human validation. These review
findings are not grounds to infer precision or to publish a period series.
Global cache invalidation also remains coarser than R3's per-day refresh contract;
that is an operational refresh issue rather than a scientific G2 blocker.

## Human import and package follow-up verification

`tests/barometar_human_import_tests.R` sources the actual importer into an isolated
test environment and replaces only its workdir/definition resolvers. Its 58
invented checks passed under R 4.6.0 and are wired into `tests/run_tests.R`.
Temporary fixture files contain invented IDs, labels and coder names only.

- Wrong draw, definition or role; missing/blank coder names; duplicate, foreign
  and missing IDs; and wrong row-level roles are rejected. Shuffled answers are
  reordered by item ID.
- PI and second-coder names matching after case/edge-space normalization are
  rejected. Only the named PI can submit the adjudicated export.
- Missing, false, string or numeric `human_review_complete` values are rejected.
  Generated templates explicitly use FALSE, create no validation result, cannot
  be scored before completion, and cannot overwrite an existing template.
- The audit requires every second-coder disagreement and every separate PI
  revision, including each changed field. Missing log rows, fields or reasons
  and foreign IDs are rejected. Order changes in set-valued labels are ignored.
  Even an all-agreement review requires the empty header-only audit file.
- A completed invented review writes a private result with the draw ID and
  fingerprints of both coders' exports, the adjudicated export and the audit log.
- The real package guard is exercised without mocking: each of the four package
  files is altered and rejected. Manifest identity/required-entry failures,
  classification/input/panel/mask identity changes, and altered assignments,
  membership, complete frame, design, seed, exclusions and definition are
  rejected. Recomputed package identities with stale sampler/context/template
  hashes are also rejected against the current instrument.

The subsequent `05_validation_draw.R` repair was checked by source inspection:
the builder writes to a unique pending directory, creates both coder HTML files,
writes `draw.rds` last, then renames the directory to its final versioned location.
An existing final folder is protected. Read-log hashes now use normalized full
paths, removing basename collisions. Classification, mask and instrument hashes
are recorded in the draw identity. The parent also added current
engine/mask/retrieval comparisons and a four-file package manifest.

Two defects found during follow-up were repaired: the manifest originally
serialized a named hash vector as an unnamed JSON array, and the draw identity
omitted the complete population frame, design and seed. The writer now serializes
an explicit named list, and 05/06 share `barometar_draw_identity()`, covering the
sorted complete frame and all these fields. The expanded tests use that real
helper and real manifest files. The original pre-draw package provenance
findings are therefore resolved for the tested contract.

## Pure bootstrap module verification and reconstruction follow-up

`tests/barometar_bridge_audit_tests.R` passed 31 invented checks and is wired into
`tests/run_tests.R`. Tests exercise the actual `R/lib/barometar_bridge.R` module,
including the fixed `(1,1,2)` draw, both-scope pairing, ratio of pooled rates,
repeated-cluster breadth multiplicities, instrument reversal, identical captures,
frozen zero-count outlets, coverage rejection, undefined ratios, matching outlets
exceeding active outlets, determinism and restoration of both RNG kind and seed.
Input validation rejects fractional/nonfinite counts, different denominators
across scopes, malformed/duplicate panel IDs, duplicate rows and fractional
replicate counts. A one-outlet panel retains a matrix of draws. Panel ordering is
canonicalized before sampling. These guards were added by the parent after the
initial probes exposed the corresponding boundary defects.

The first `07_bridge.R` implementation was inspected only; no empirical bridge
was run before G2. Essential reconstruction concerns sent to the parent:

1. June-only deduplication differs from the full-history contract's earliest
   body-eligible representative across the whole source batch. A canonical URL
   first eligible in May and recaptured in June enters a June-only reconstruction
   but not the final June series. Reconstruct global batch representatives before
   month filtering, or explicitly declare and test a June-only bridge estimand.
2. The first bridge `doc_key` used literal `old`/`new` batch labels and omitted
   source type, unlike 02/03. Different hashes can select different representatives
   when capture timestamps tie. Reuse the final pipeline's exact identity and
   tie-break rules.
3. Existence of `validation-result.rds` is insufficient to certify the bridge.
   Require `human_validation_complete`, the current definition/draw/package
   identity, the validated scope gates and the exact accepted-route set.
4. The bridge cache should include registry and reconstruction-helper identities,
   alongside source/definition/panel identity. Persist June daily input
   fingerprints; source file size/mtime is a coarse invalidation aid, not the
   input digest required by R3.

## Final source-to-series and worker audit

The parent addressed the four reconstruction findings above: the bridge now
checks prior body-eligible captures before assigning an article to June, uses the
standard document identity/tie-break, verifies the completed human coding package
before certification, and records source fingerprints, snapshots, registry and
reconstruction code in cache identity. Whole-period synthetic reconstruction
groups boilerplate by outlet and calendar month.

The final review found four additional defects, all repaired and verified with
invented inputs:

- The native old source has no `ITEM_ID`; it now supplies the empty ID component
  corresponding to NULL in the merged old rows. The source fixture deliberately
  omits both `ITEM_ID` and `SOURCE_BATCH` from its old table.
- The selected-period new-source query now applies the same `mediaspace_full`
  filter as its fingerprint and prior-history query.
- SQL lookback eligibility now strips the transported TITLE/FULL_TEXT, matching
  R's NUL-to-U+FFFD conversion. A raw title ending in NUL and a body prefix ending
  in U+FFFD become equal after transport; the test checks that its 199-character
  remainder cannot displace an eligible June capture.
- Fingerprinting verifies nonmissing DATETIME and DATE=date(DATETIME) across the
  entire relevant source batch, including dates after the bridge horizon. This
  documented source invariant makes the bounded prior-history search sound.
  Later-DATE/earlier-DATETIME and NULL-timestamp fixtures are refused. A final
  snapshot assertion runs after lookback and classification.

`tests/barometar_bridge_source_tests.R` passed **11** checks covering those cases,
Unicode whitespace/punctuation equivalence, earlier noneditorial representatives,
and tied timestamps. Windows refused timestamp mutation while the invented
DuckDB file was open; the final-guard test therefore injects a stale expected
timestamp after classification and calls the real snapshot checker. It does not
claim to have bypassed the file lock or modified a live source database.

The actual `barometar_sample()` run also passed: **3,206 invented raw rows**, the
49-column merged schema and a separate native old table, with source eligibility,
canonical deduplication, month-specific boilerplate, classification and
monthly/weekly/rolling-28 aggregation checked against fixture facts. Rejected
short/title-only/homepage rows sit in January 2021 and are exercised. No empirical
bridge was run.

`tests/barometar_worker_tests.R` passed **7** checks against the real month
classifier and the production PSOCK initialization pattern. For two invented
monthly parquet chunks, serial and two-worker runs yielded identical decisions,
evidence and version metadata, including Croatian UTF-8 text. Development-only
filtering also passed. All new tests are wired into `tests/run_tests.R`.

No further material blocker was found in the inspected bridge/source/worker
contracts. Human validation and release prerequisites remain unmet; synthetic
passing tests do not authorize empirical precision claims or release.

## Precise paired outlet-bootstrap protocol for `07_bridge.R`

1. Run the final eligibility, canonicalization, within-batch deduplication,
   preparation, boilerplate procedure and frozen classifier separately on June
   1-30, 2024 in the old and new sources. Read both databases read-only; check
   loader activity and snapshot fingerprints. Rebuild old-batch representatives
   independently: the merged representative table cannot supply the old June
   denominator. Keep the same frozen 115-outlet membership and definition.
   Record separate source and mask identities. Equal procedures need not yield
   equal mask keys when the captured documents differ.
2. Form a private table with exactly one row per frozen outlet, sorted by
   `outlet_id`, including outlets with zero June documents. Columns include
   `N_old`, `N_new` and `D_old_s`, `D_new_s` for each requested scope. Assert unique
   IDs, complete panel membership, integer nonnegative counts, and `D <= N`.
   Scope membership uses the accepted routes for the final validated definition.
   Before human validation, any run is explicitly provisional and cannot set
   `comparable_bridged`.
3. Point estimates are pooled: `vis_b_s = 10000 * sum(D_b_s)/sum(N_b)`;
   `R_s = vis_new_s/vis_old_s`; `M_b_s = sum(D_b_s > 0)`;
   `delta_breadth_s = 100 * (M_new_s-M_old_s)/P`. Do not average outlet ratios.
   P remains the frozen panel denominator. Monthly active coverage is
   `sum(N_b >= 5)/P`, while matching breadth uses `D_b_s >= 1`: M can exceed
   `panel_active`, so an `M <= panel_active` assertion is invalid. Both actual
   runs must have usable June day/outlet coverage before bridge certification.
4. Predeclare `seed=20260918`, `R=2000`, and
   `RNGkind("Mersenne-Twister", "Inversion", "Rejection")`, preserving/restoring
   the caller's RNG state. Each replicate samples P integer row indices uniformly
   with replacement. Use the **same index vector for both batches and both
   scopes**, then calculate the same pooled formulas on those sampled rows.
   Repeated outlet draws retain multiplicity. In particular,
   `delta_breadth_star = 100/P * sum(I(D_new_s[index]>0)-I(D_old_s[index]>0))`;
   never apply `unique()` to the sampled outlets. An ordinary multivariate-row
   bootstrap implements precisely this pairing. [R `boot` documentation](https://stat.ethz.ch/R-manual/R-devel/library/boot/html/boot.html)
5. Return marginal 95% percentile intervals for both R and the breadth difference
   using `quantile(replicates, c(.025,.975), type=7)`, recording this exact method.
   Type 7 is an explicit interpolation choice; do not silently mix its output
   with `boot.ci`'s differently interpolated percentile endpoints. [R `quantile`
   documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html)
6. Predeclare zero-denominator handling. An original zero N or zero old-scope D
   makes that ratio unestimable and blocks certification. Never add pseudocounts,
   discard undefined replicates or redraw until a finite ratio appears. A simple
   conservative implementation records counts of nonfinite bootstrap ratios,
   returns an unavailable ratio interval if any occur, and leaves D9 at
   `not_comparable_seam`. This deliberately conservative numerical policy is a
   recommendation, not a new threshold stated by R3. It must be documented before
   inspecting bridge results. Breadth intervals remain computable separately.
7. D9 is unchanged: both scope-specific ratio intervals must lie within
   `[0.90,1.10]`, and both **point** absolute breadth differences must be at most
   2 pp. Report breadth intervals descriptively; requiring their containment
   within +/-2 pp would change the brief. Require validated scope definitions,
   usable coverage and estimable ratios as prerequisites. Persist the automatic
   numerical recommendation separately from the authorized final D9 decision.
8. Define overlap on the frozen outlet plus the approved canonical article key,
   after each batch's eligibility and within-batch deduplication. For each scope,
   classify both copies of a shared URL separately. Report old-shared,
   new-shared, old-only and new-only D contributions, with
   `D_old = D_old_shared + D_old_only` and
   `D_new = D_new_shared + D_new_only`. Shared URLs can have different text,
   masking or classifications. Retain the row-level bridge table privately;
   publish only aggregate reconciliation and interval summaries.

These intervals describe sensitivity to resampling outlets in the panel, with
both capture systems paired within each outlet. They do not make the panel a
probability sample of all Croatian media or quantify human-classification error.

## Invented bootstrap acceptance fixtures

- Identical old/new outlet data produce R=1 and delta breadth=0 in every
  estimable paired replicate; unrelated bootstrap draws for the two batches fail
  this check.
- Three outlets have `N_old=(100,200,50)`, `N_new=(100,200,100)`, narrow
  `D_old=(10,0,0)`, narrow `D_new=(0,20,0)`, broad `D_old=(10,20,0)`, and broad
  `D_new=(20,20,10)`. For the fixed replicate indices `(1,1,2)`, narrow R=1,
  delta breadth=-100/3 pp, broad R=1.5 and broad delta breadth=0. Deduplicating
  sampled outlets incorrectly changes the narrow breadth difference to zero.
- Include a frozen zero-count outlet in P and all bootstrap draws. A document
  absent from one batch must contribute zero there rather than disappear from
  the paired table. Test all-zero old D explicitly and verify no passing D9.
- Swapping old/new data negates each paired breadth difference and reciprocates
  each finite positive ratio when the same stored replicate indices are reused.
- Same seed, sorted panel rows and input identities reproduce byte-identical
  numeric summaries; adding/reordering input rows without first sorting must not
  silently change the declared resampling frame.
