# Independent morphology and actor regression review

Date: 2026-09-18. Pre-G2 development review only.

The separate suite `tests/barometar_definition_review_tests.R` uses invented sentences and definition metadata. It reads no source articles and supplies no empirical precision, recall, period indicators, or human coding. The reviewer did not modify the engine or definitions.

## Verified baseline

Definition: `1.0.0+3bcf6612ef83`. Engine SHA256: `9f2610ac1ae0d9fab06c7a520a94d66ee1e74fd9c17a4edbcbdb120c2ebe55e0`.

The bounded suite ran 102 checks: 91 passed and 11 failed. These counts describe deterministic synthetic regressions, not model accuracy. Four failure families require correction before G2:

| Failure family | Failed checks | Invented representative | Expected correction |
|---|---:|---|---|
| Incidental reading with newly enumerated public officials | 4 | Premijerka je rekla da je pročitala socijalni nauk Crkve. | No B or C: the statement attributes reading, not policy application. Extend the actor-only safeguard consistently to premijerka, zastupnica, gradonačelnica and kancelarka. |
| Competing speaker in a relative clause | 5 | Biskup je upozorio ministricu koja ističe da supsidijarnost zahtijeva poreznu reformu. | No B or C: the argument belongs to the official. The competing-speaker matcher must cover ministra, ministricu, zastupnicu, gradonačelnicu and kancelarku. A masculine prefix misses both irregular oblique forms and feminine counterparts. |
| Invitation with a nonpolitical complement | 1 | Ministrica je pozvala na izložbu o socijalnom nauku Crkve. | No B or C: inviting somebody to an exhibition is not policy application. A connector plus an incidental officeholder is insufficient without the political complement. |
| Feminine Franciscan office | 1 | Ministrica Franjevačkoga svjetovnog reda kaže da socijalni nauk Crkve zahtijeva molitvu. | No B or C: extend the ecclesial-office exclusion to the newly active feminine form and its cases. |

The current implementation correctly handles the reviewed inflections in explicit licensed constructions, including načelima, učenjima, Crkava, pobačajem, odgojem, Europom and analitičarem. The five female officeholder party-cue controls resolve to A2. Bound policy-action controls and unbound predložila/new-cover controls pass. Positive attribution to a bishop remains available; minister nominative or suitably covered rival forms are not globally excluded.

All 11 pending actor records lack their own active compiled actor entry and fail to create D. A pending church entity can independently overlap generic church-role vocabulary; that is not registry activation.

All eight active actor records pass start/end inclusion and one-day-before/after exclusion checks. HDZ D applies only within its documented interval and is absent for a missing date. HDZ BiH never becomes domestic D, including outside its own documented interval. Unverified aliases remain intentionally inactive and are not a new blocker.

## Reproduction

From the repository root, run Rscript on `tests/barometar_definition_review_tests.R` under a UTF-8 locale. It loads the current definition once and reports every failed assertion before exiting nonzero. Rerun after correcting the four families; do not delete or relax the expected negative decisions to obtain a pass.

This bounded review does not establish the empirical validation required by G2.

## Resolution and independent rerun

The implementation owner corrected the four failure families using the shared public-actor matcher, an actor-only invitation safeguard, and feminine Franciscan-office exclusions. The reviewer independently reran the original 102 checks and nine added HDZ-only sensitivity checks: **111/111 passed**.

Verified definition: `1.0.0+d45554b66786`. Engine SHA256: `1d52a3a864d69dabae938b378921a82c5b92662c57bdb40482de37803f60a85a`.

The new checks confirm that `hdz_only` is true for an attributed, date-valid HDZ argument without other recognised roles. It becomes false when the article also names a premijerka, zastupnica, bishop, HBK, CDU or journalist, while D remains available for the separate HDZ argument. Mere HDZ mention and an HDZ record outside its documented interval do not set the flag. This is a sensitivity flag for the declared organisation/role vocabulary across the article, not proof that no other real actor is present.

No additional critical defect was found in this bounded inspection. The original reported defects are resolved; this conclusion does not expand the actor registry, establish complete grammatical parsing, or replace empirical G2 validation. No further corpus review or implementation edits were performed by the reviewer.
