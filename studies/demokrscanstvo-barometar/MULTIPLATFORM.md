# All-platform provisional empirical edition

This is a separately versioned expansion approved by the PI on 2026-09-19. It searches all platforms, sources and dates in the supplied merged archive. It is not the original 115-outlet fixed-panel study. The frozen panel's gates and human forms remain unchanged. No independent human validation is claimed. The earlier 55-item AI review concerns web-panel contexts and cannot estimate this edition's accuracy.

## Unit and denominator

The unit is a deduplicated archived record with searchable text, not necessarily a unique article. Vendor IDs are namespaced by collection and platform. Legacy records lack IDs, so only identical capture identities (platform, collection, source, URL, date/time, title/body/snippet hashes) are collapsed. Repeated IDs retain a text-eligible capture, preferring full text over snippet over title, then greater body length, then the earliest capture date and row. Distinct comments sharing a parent URL survive. Syndication, separately captured legacy versions and reposts may remain. Neither platform counts nor their sum measure distinct people, reach or support.

Every platform is searched. There is no 115-outlet restriction, news-domain restriction, inferred language restriction or preliminary religious-corpus filter. A record is text-eligible if its title or selected body has a Unicode letter or digit. The selected body is stored FULL_TEXT, falling back to MENTION_SNIPPET only when FULL_TEXT is blank. The title is always evaluated separately. Availability tables distinguish full text, snippet, title-only and no text. The label full text names a database field; it does not guarantee an unabridged article or a complete audiovisual transcript. No audio, video or image recognition was performed.

Monthly rates equal included records / text-eligible records on that platform × 10,000. Full-text sensitivity rates use only records with nonblank FULL_TEXT in both numerator and denominator. Months without eligible records have an unavailable rate, not a zero. The pooled total is a count accompanied by platform composition, not a platform-neutral trend index. Observed days count dates with any archived record, not proof of complete monitoring on those dates.

## Search and classification

The base dictionary and contextual engine are frozen at the definition version in summary.json. Inflected Croatian terms and explicitly enumerated ASCII variants retrieve a superset of candidates. A1 names Christian democracy as an idea/tradition; B applies a strong Catholic-social-teaching anchor to public policy; C requires Christian grounding, a policy object, an argument connector and sufficiently distinctive or multiple concept families. Party labels alone (A2) and unresolved labels (A?) do not independently enter the numerator. D is only an attribution diagnostic, never an independent reason for inclusion. A1/B/C overlap and must not be added together.

The adapter changes text eligibility and removes the original 32,000-character processing cap, while preserving contextual distances, exclusions and attribution rules. All stored selected text is examined. Title/body evidence cannot be joined to invent an argument. A vectorized necessary-condition check can reject impossible candidates but never declares a positive. Regression fixtures check it against the exact contextual engine. The dictionary was not tuned on the 55 AI review items.

For web records, trigger-containing boilerplate is masked when the same normalized segment occurs in at least five distinct records on at least three dates for the same source label within a month. It is learned from the candidate superset, which contains every trigger-bearing segment. The original normalization/split/hash contract is reused. Repeated social posts are not masked as web boilerplate. This heuristic can remove repeated substantive passages or leave unrecognized templates; provisional status is substantive.

## Time and collection limits

Dates describe archive capture, not necessarily original publication. The merged archive switches collection on 2024-04-01, and its newer part has an upstream standalone-word “i” filter. Platform coverage, particularly comments, changes sharply. New platforms start mid-series. The charts break at the collection switch and at missing months; partial months/days are marked. Changes across the break, or through missing collection, must not be interpreted as changes in public discourse alone. The archive is not an exhaustive census of Croatian media or online discussion. The Croatian dictionary does not imply that every stored record is Croatian or that other-language discourse is comprehensively recognized.

## Files and reproducibility

Only aggregate CSV/JSON, this method note and file hashes are public. Source texts, titles, URLs, authors, account names, record IDs, evidence passages and source-level counts stay in the external private work directory. No licence certificate is created or represented as verified by this build. The PI authorized preparing this provisional aggregate edition without making new vendor paperwork a prerequisite.

Run from the repository root in the locked R environment with Python DuckDB 1.5.5 available:

```
Rscript studies/demokrscanstvo-barometar/multiplatform_prepare.R
python studies/demokrscanstvo-barometar/multiplatform_collect.py
Rscript studies/demokrscanstvo-barometar/multiplatform_classify.R
python studies/demokrscanstvo-barometar/multiplatform_release.py
quarto render pages/demokrscanstvo/index.qmd
```

The source database is attached READ_ONLY. Extraction checkpoints are bound to source size/mtime, retrieval contract and collector hash. Classifications are additionally bound to adapter and definition hashes. The source file metadata is verified unchanged after extraction. Public release checks reconcile every candidate, denominator and monthly total, enforce numerator ≤ denominator, and hash every downloadable artifact. Rendering only reads these aggregates. Source/archive byte hashes are not implied by a metadata fingerprint.
