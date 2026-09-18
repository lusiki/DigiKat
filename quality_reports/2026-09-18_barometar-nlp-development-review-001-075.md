# Barometar: independent assistant development review

Date: 2026-09-18. Status: development review, not human evaluation or release approval.

The reviewer inspected 75 cases from the private 217-case purposive development sample: 50 selected for direct labels and 25 for doctrinal terms. The stored review results use proposed definition `1.0.0+0b9148a121ce`. Review used bounded body windows of at most 80 tokens and selected additional bounded windows where early boilerplate obscured relevant context. Private read logs and one row per reviewed case are retained in the configured development folder as `nlp_review_001_075.csv`. Titles, URLs, source prose, document identifiers and period indicators are not reproduced here.

| Development finding | Cases |
|---|---:|
| No correction supported by the inspected windows | 52 |
| Possible definition or cue extension | 15 |
| Possible theme-vocabulary extension | 1 |
| Insufficient body context for a confident correction | 1 |
| Residual listing/related-content preprocessing risk | 2 |
| Priority B recall candidate | 2 |
| Prospective contextual exclusion needed | 2 |
| Total reviewed | 75 |

These categories describe development findings, not correctness labels. The sample is purposive and the reviewer is an assistant. No precision, recall, prevalence, period comparison, human agreement or validation-gate estimate can be derived from this review. Bounded windows cannot establish that every unshown passage is irrelevant.

The main direct-label pattern is conservative unresolved classification in party reporting. Common office-holder forms, coordinated party references and narrow local context can leave a mention unresolved even when a reader would understand it as a party label. The brief deliberately requires every mention to have a local party cue before assigning A2. Proposed cue or alias additions therefore require explicit definition updates and tests; widening the whole article context would change that rule. These changes would affect the A2 comparison and unresolved counts, while neither category enters either scope. One theme candidate concerns missing case forms of Europe.

The two strongest B recall candidates concern a doctrinal argument about wage/work-condition duties and explicit incorporation of doctrine into a party programme. Wage and programme objects are named in the brief but are incompletely represented in the current public-context recognition path. Any additions should bind the normative or incorporation predicate to the relevant object and include inflectional and conditional constructions. Generic economic-model discussion remains insufficient under Revision 3. A union/labour appeal and a political-leader environmental appeal are additional definition candidates, not automatic inclusions.

No false broad-scope inclusion was established in the inspected source windows. The two contextual risks nevertheless produced reproducible false B inclusions in invented probes. A third invented probe exposed a doctrinal phrase inside an organisation name being mistaken for doctrinal application. All three were run against the on-disk engine during this review, with neutral padding to meet minimum body length; all returned B and should return no B/C:

| Invented regression | Required distinction |
|---|---|
| “Socijalni nauk Crkve kaže da se Posljednji sud odnosi na svakog čovjeka.” | Theological judgment is not a public court. |
| “Ministra Franjevačkoga svjetovnog reda kaže da socijalni nauk Crkve zahtijeva molitvu.” | An ecclesial office is not a government ministry. |
| “Centar za promicanje socijalnog nauka Crkve navodi da će ministar govoriti na otvaranju izložbe.” | A doctrinal phrase inside an organisation name plus an incidental minister does not apply doctrine to a political question. |

Suggested positive controls should retain ordinary judicial policy and government-minister applications. An organisation may still make a qualifying argument when it separately states a doctrinal basis; excluding the organisation-name occurrence must not erase that independent evidence.

Residual programme listings, repeated introductions and related-story material appeared in some negative windows despite partial masking. This supports a preprocessing diagnostic, not a claim that those documents were falsely included. It does not justify arbitrary removal of all conference, book or media-programme articles: a substantive qualifying argument in such coverage must still be assessed locally.

The next development step is to resolve the three invented false positives, test the two priority recall constructions, and rerun stored development cases with recorded definition/version changes. Independent human coding and the prescribed evaluation remain outstanding.
