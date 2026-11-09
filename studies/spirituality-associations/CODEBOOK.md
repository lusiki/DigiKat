# Exploratory data codebook

## Register and profiles

One row in `output/private/register.csv` is one supplied UDR ID. All original rows remain.

| Field | Meaning and provenance |
|---|---|
| association_id | UDR ID reconstructed from the first PDF column; string, not an inferred OIB |
| county | PDF county of registered seat |
| name | Complete PDF name with line-break whitespace collapsed |
| registered_seat | PDF address; private, may be a personal residence |
| locality_candidate | Text after final comma in the address; unverified, not a geocode |
| email_present | Nonempty PDF email cell; personal emails are not copied into this CSV |
| website_raw | PDF website cell with wrapping whitespace removed; may be outdated, malformed or shared |
| pdf_page | One-based source page |
| name_normalized | Casefolded, accent-folded name with alphanumeric token boundaries |
| cue_* | Boolean regex cue in name; multiple true values allowed; no identity or activity classification implied |
| cue_count | Number of lexical cue families matched |
| sampling_stratum | First matching cue in the published priority order, else no_lexical_cue; sampling only |
| declared_orientation | Starts not_yet_verified; use documentary self-description rather than inferred belief |
| existence_in_2025 | Starts not_yet_verified; requires historical evidence |
| recent_activity | Starts not_yet_verified; registration status is insufficient |

`profile_evidence.csv` adds official source URLs, AI-assisted evidence notes, candidate orientation/activity codes, website-to-ID mapping status and historical evidence. These are dated development records. They do not overwrite the unverified baseline register. Scope codes distinguish a legal entity, a named branch, and a network whose generic mentions cannot be assigned to every listed member.

## Geography

`county_inventory.csv` uses the full reconciled frame. `county_population_adjusted.csv` joins all 21 counties exactly to DZS table 1. `associations_per_100000 = associations / population_mid2025 * 100000`. `representation_ratio = association share / population share`. Values describe seats. They are not percentages of residents involved and do not control for national headquarters.

## Media and retrieval

`media_coverage_2025.csv` has one month/platform row. `monitored_rows` is the raw vendor record count; `days` is distinct date strings; `rows_with_body` and `rows_with_search_text` measure availability, not article relevance. `i_filtered_rows` is stored filter provenance. The complete merged snapshot is pinned by file size/mtime, counts and date bounds, not a claim of a content hash for the 91 GB source file.

`matching_rules.csv` has one organisation/normalized phrase/route row. `full_registered_name` is mechanical discovery; `curated_alias` is a selected discovery variant. Neither route is validated by construction. Alias inflection is finite, not a general Croatian lemmatizer.

`candidate_matches.csv` has one deduplicated organisation/item/route row. Multiple routes can refer to the same organisation-item pair. `record_key` is canonical URL, vendor ID fallback or content hash fallback. `context` is a normalized development window and `title` is original vendor text. No sensitive field leaves private storage.

`organisation_screen.csv` retains every association. Its statuses have distinct meanings:

| Status | Interpretation |
|---|---|
| unvalidated_candidate | At least one item matched a discovery rule; relevance still needs review |
| not_observed_under_rules | The name was screened and no candidate was retrieved; absence from the monitored public sphere is not established |
| not_yet_searched | Short/generic name held until defensible identity rules exist; count zero is not a substantive result |

`candidate_items`, `candidate_months`, and `candidate_web_domains` count distinct values among candidates only. A web domain is not necessarily an independent outlet. Branch-specific attribution is not borrowed from a shared domain. `human_review_queue.csv` samples up to two candidates per observed organisation using a deterministic hash. Human fields begin blank. Any `ai_development_review.csv` is a separate exploratory reading and must never populate those fields.

## Filter diagnostic

`filter_sensitivity_12days.csv` has one fixed date/platform row. `raw_rows` is all records in that export; `retained_rows` passes the documented `i` rule; `candidate_rows` matches the same title/body identity phrases before filtering; `retained_candidate_rows` passes both. Counts use raw records, with no cross-date URL deduplication. This is a 12-day diagnostic and supports no annual extrapolation.

## Missingness and validation

Empty strings denote absent source cells or unfilled annotation fields. False lexical flags mean no match to that particular expression, not absence of that activity. Unknown religious orientation, activity, historical eligibility, independence and operation are explicit unknowns. All counts and graphs are generated from their named input files. The run manifest records code hashes and dependency versions.
