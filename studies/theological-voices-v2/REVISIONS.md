# Development record

All article coding uses the installed local Qwen3 14B. Superseded configurations
and their raw outputs remain in `output/private/configs/` and `coding.sqlite`.

- v2.1: initial full-text extraction plus verification. Long-article benchmark
  revealed malformed evidence IDs; some fields failed despite otherwise useful
  responses. Interrupted after two completed development articles and stored
  task attempts on the third. These are not part of the eventual frozen main run.
- v2.2: separated evidence validity by field so a failed group field does not
  discard good speaker extraction. The first synthetic case showed a verifier
  inventing voices for people who were merely present. The diagnostic run was
  interrupted after two completed examples. Source articles were untouched.
- v2.3: constrained passage IDs in the output grammar; verification is restricted
  to indexed candidates, with explicit topic-relatedness and attribution checks.
  This fixed the attendance-as-speech error on constructed examples. The complete
  diagnostic round found remaining errors with institutional capacity, unstated
  capacity, interpretation by an unknown speaker and predicted affected groups.
  Its main sample was never started.
- v2.4: enabled local reasoning mode after a saved comparative benchmark improved
  relevance and thematic interpretation of a constructed institutional statement.
  Clarified institutional vs individual roles, unresolved vs other, interpretation
  without credentials, and predicted consequences vs personal experience. A new
  diagnostic round and new development/fresh-challenge results are required.
  The diagnostic budget was expanded from 24 to 30 constructed cases to cover
  statements near the end of long texts, distant source identity, headline/body
  mismatch, expert experience, appended recommendations and a religious sister.
  The assignment embedded in the frame freeze records the earlier 24-case plan;
  this development-only expansion changes no frame or sample selection.
  The experience-only constructed case initially also expected a described
  affected group. That expectation was removed: the example explicitly states
  one person's experience, not a group-level consequence. This corrects an
  ambiguous diagnostic expectation; it is not evidence that group detection is
  accurate. The separate prediction and institutional cases still test groups.
- v2.5: a reasoning-mode diagnostic still confused an ordinary parishioner's own
  experience with a content-creator capacity. Added explicit role boundaries and
  contrasting examples. The partial v2.4 diagnostic round is retained; no main
  articles were coded under it. Also corrected a dependency check: when candidate
  extraction fails, an empty verifier response cannot count as a valid no-speaker
  article. Unnamed role labels are kept distinct when their identity passages
  differ. Assignment and diagnostic source hashes now travel with the configuration.
- v2.6: v2.5 completed all 30 diagnostics, with 29 passing. The remaining example
  contained an explicit appended-recommendation heading but was labelled complete.
  Added a deterministic, logged source-boundary safeguard for explicit headings;
  original text is retained and flagged sources are excluded from complete-article
  rates. This changes no frozen frame or sample. Restart the development workflow
  under a new configuration; do not overwrite the failed diagnostic history.
  A read-only local progress page reports actual counts and stopped states.

- v2.7: v2.6 passed the appended-recommendation case but stopped at 29/30 because
  the second paywall variant was treated as an attributed theological statement.
  The supplied text announced an explanation without providing its content.
  Clarified the announcement/proposition distinction in both tasks. Verification
  now records an explicit proposition status and short audit summary, and only
  stated propositions with supported attribution can enter the voice counts.
  Actual statements visible before a paywall remain eligible as partial-source
  evidence. New contrast probes and the full diagnostics are required; no main
  sample result is reused or counted from an earlier configuration.
  Verification must account for every candidate. Explicitly ambiguous statement
  decisions remain auditable and exclude an article from speaker-rate denominators;
  they cannot be relabelled as a successful zero-speaker finding. Structural task
  success is recorded independently of this substantive uncertainty.

- v2.8: v2.7 was stopped after 24 of 30 diagnostics, with 22 passing. The verifier
  wrongly demanded a theological thesis from an attributed Mass timetable, and
  one unknown-capacity variant became `other`. Clarified that factual information
  and concrete plans count as speech without necessarily interpreting faith.
  Capacity now has an explicit basis decision; an unresolved basis cannot acquire
  a substantive role, and any normalization preserves the model's original proposal.
  Corrected additional probe B02: its former "organisers announce" wording could
  itself establish an attributed event statement. The revised negative is plainly
  unattributed editorial narration. This corrects an ambiguous constructed input;
  it is not evidence of real-article accuracy. The unchanged 30-case suite now
  schedules recent failure cases first. Completed v2.7 calls and its interrupted
  request metadata remain saved; the main sample has not started.

- v3.0: v2.8 passed the Mass-timetable and paywall cases, but the unknown-capacity
  case exposed a contradictory decision: the model correctly identified the
  quotation and unknown role, then denied attribution because the occupation was
  unknown. Stopped that round and separated attribution verification from capacity,
  interpretation and experience classification. The latter receives already-verified
  voices and cannot reject them; missing capacity remains a legitimate unresolved
  role. Classification failures have their own saved task record and invalidate
  speaker-rate use without deleting other valid tasks. Tests cover both unknown
  capacity retention and classification failure. This is a new three-pass candidate,
  requiring fresh diagnostics and development under its own configuration hash.

Synthetic examples are rule tests, not empirical accuracy labels. The main run
cannot begin until its exact configuration passes the recorded development gates.


## 3.1.0 ? 18 October 2026
Version 3.0 completed 30 diagnostics: 28 passed, D031 failed the role rule after an overbroad capacity normalization, and X03 failed structural verification because both attempts retained and rejected the same candidates. Replaced competing retained/rejected lists with one exhaustive decision per candidate. Refined personal-experience normalization without requiring occupation, retained unknown-capacity handling, and clarified identity/title duplication in extraction. No main articles had been processed. All prior raw responses remain in SQLite. New version must pass fresh full diagnostics, development and challenge before main coding.
## 3.2.0 — 18 October 2026: bounded runtime revision

The first 19 main results under v3.1 averaged 128.3 seconds, including retries
and brief queue time during a separate benchmark. The four-case synthetic
`think=false` probe used 87.65 seconds of generation time versus 319.28 seconds
for the same cases under v3.1 (about 3.6 times faster). D041 still missed an
expected affected group. This is performance evidence, not accuracy evidence.
The active worker was stopped at an article boundary, with completed articles
and raw requests preserved. Its review files were archived under the old hash.

Version 3.2 changes only the thinking setting and the fresh challenge input
bundle; prompts, schemas, segmentation and substantive rules remain unchanged.
All 100 development articles, 30 constructed tests, four extra probes and both
readings of 30 newly selected challenge articles run again. All 2,000 main
articles are then coded under the new hash. A fresh challenge avoids reusing the
previous challenge after a configuration choice. The same withdrawal policy
applies to any remaining semantic failures. No speed or quality is inferred
from agreement alone, and the final runtime estimate uses actual main articles.
