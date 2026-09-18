# Barometar: fixed-sample morphology audit

Date: 2026-09-18. Independent assistant development review for brief §3.7; not human validation or a G2 freeze.

The verifier processed the existing 217-case purposive development sample without resampling or changing its purpose × source-batch strata. It used normalized title and prepared, capped, boilerplate-masked body as separate fields. No corpus queries, document classifications, route counts or period indicators were computed.

Audited proposed definition: `1.0.0+745f6b2b1f5e`. Definition SHA256: `745f6b2b1f5ec418442576ad08913978e1ac0c52500f56cc7477d8f3bf18b9bf`. The fixed ordered sample, source RDS, builder and verifier hashes are recorded privately. Subsequent implementation changes require a documented comparison against this snapshot.

The audit declared 299 stems/allomorph probes, including the builder's literal paradigm stems and explicit seed-family, sibilarisation, fleeting-vowel and near-homonym probes. NFC-normalized Unicode word tokens are counted at left boundaries, with Croatian case folding for inventory comparison. Hyphenated compounds are retained as a separate inventory type so actor clitics can be inspected. Compound and component counts overlap and must not be added as independent occurrences.

| Inventory status | Unique units |
|---|---:|
| Existing enumerated token or phrase-slot component | 945 |
| Existing excluded-phrase component only | 2 |
| Absent from those enumerations | 1,467 |
| Total | 2,414 |

The total comprises 2,334 word forms and 80 compounds. “Absent” is not an engine miss: many forms are unrelated derivatives or homonyms, and some compounds are already handled by the production phrase matcher. The full token inventory was inspected and explicit assistant decisions recorded; zero units remain marked review-required.

| Decision for absent units | Units |
|---|---:|
| Add a missing case/number inflection in its appropriate entry | 47 |
| Add a feminine role form in the appropriate role/cue function | 30 |
| Add an attribution or argument verb form with existing binding requirements | 42 |
| Add a complete, bound application-predicate pattern | 38 |
| Add an explicit party-cue variant, retaining the five-token window | 34 |
| Add an explicit idea-cue variant, retaining the five-token window | 21 |
| Add a local publication/anniversary variant, retaining application exceptions | 38 |
| Add only inside the brief-licensed phrase or theme | 22 |
| Review an exact organisation alias against dated registry evidence | 41 |
| Keep out as a derivative, homonym, malformed form or unlicensed slot case | 1,093 |
| Keep out as an explicitly named false friend | 19 |
| Keep out as an ambiguous code alone | 8 |
| Do not add a whole-compound rule; use constituent/phrase handling | 34 |
| Total absent units reviewed | 1,467 |

These decisions are scoped lexical recommendations. They are neither instructions to add every item as a unigram nor to place every rejected token in a global article exclusion. Existing enumerated words are retained only with their existing phrase, role and context restrictions.

The clearest inflection gaps include the instrumental forms `odgojem` (2 occurrences), `pobačajem` (1) and `analitičarem` (1), plural `načelima` (10), and geographic forms `Europu` (29) and `Europom` (4). Generic noun-generation routines currently append endings that do not cover all of these paradigms. Feminine office-holder variants and plural/reporting predicates are another systematic gap: `ministrica` occurs 12 times, `rekli` occurs 20 times, and `kažu` occurs 16 times. These are token counts in this fixed development inventory, not article frequencies or population estimates.

Complete each lexical paradigm explicitly and test both the added and rejected forms. Keep required complements and clitic order when expanding application verbs. For example, adding a form of a verb meaning “call” must not make every telephone call or event invitation a doctrinal application. An office-holder form must not bypass the speaker-attribution checks. Grammar matters at phrase level: a valid Croatian case form is not necessarily licensed in every slot following “dignity,” “rights” or “teaching.”

False-friend decisions include personalisation forms, apprenticeship vocabulary, animal-life forms and “dignified” adjectives/titles. The broader inventory also exposes many unrelated proper names and derivatives. This confirms why wildcard stem expansion must not become the production dictionary.

Private artifacts under `manifest$folder/morphology/`:

- `token_form_review_private.csv`: every unit, matching stems, overall/body/title/document counts, stratum count, existing entry membership, explicit decision and reason.
- `token_counts_by_stratum_private.csv`: form counts by the unchanged purpose and source-batch strata.
- `review_decisions.csv`: explicit decisions for all 1,467 absent units.
- `stem_catalog.csv`, `sample_strata.csv`, `snapshot.rds`, `definition_snapshot.rds`, and `summary.json`: reproducibility and audit metadata.
- `actor_registry_schema_review.csv`: static actor-record field check.

The reusable verifier is `studies/demokrscanstvo-barometar/audit_morphology.R`. Its `--finalize` mode joins private decisions to the saved inventory without re-reading passages or replacing the definition snapshot. It verified 2,414 nonempty decisions/reasons and no unresolved review rows.

Actor completeness and bounded official-source findings are recorded separately in [the actor inventory review](2026-09-18_barometar-actor-inventory-review.md). The reviewed snapshot has only two registry records for five actor matcher entries. Named organisation matchers require complete aliases and dated records; unverified entities should be explicitly pending and inactive.

The morphology inventory review is complete. Definition implementation, corresponding synthetic fixtures, and independent human evaluation remain separate work; none is implied by these counts.
