# Brief and measurement plan, v3.0

The intended reader researches theology and public religious communication. The
question is who receives an attributed voice on faith in captured web coverage,
and when that voice actually interprets faith. An academic theologian is a
text-supported speaking capacity, not a credential inferred from ordination.

## Six questions

1. Where and when do the captured Catholic-topic web publications appear?
2. Which aspects of faith and Church life are central or secondary in the readable material?
3. Who is mentioned, who speaks on the topic, and in which capacity?
4. Who interprets faith and which text-supported roles perform that interpretation?
5. Which affected groups are described, and when do sources describe their own experience?
6. How much exact text reuse is observed, and what can well-supported contrasting cases show?

## Measures

| Result | Unit and numerator | Denominator and source |
|---|---|---|
| Captured supply | Deduplicated publication, by month/source | Entire frozen web frame |
| Topic classification | Article carrying a model-coded category | Task-valid, complete-source sample articles; raw and weighted |
| Actor-role share | Distinct article/actor/capacity appearances | All such appearances in complete, valid speaker-task articles |
| Role-presence share | Distinct article/capacity pairs | All such pairs in that same base |
| Article prevalence | Article with at least one speaker in capacity | All complete, valid speaker-task articles, including successful zero-speaker cases |
| Interpretation | Verified speaker explicitly explains/applies faith | Complete, valid speaker-task articles with resolved interpretation flags for all voices |
| Experience overlap | Described affected group yes/no x own-experience voice yes/no | Articles complete and valid for groups and speakers, with resolved presence or absence of own experience |
| Exact reuse | Article sharing cleaned-body hash with another publication | Full frame with at least 400 text characters |

Weighted estimates use the actual quarter-stratum N_h/n_h. Complete-case weights
do not correct model error or differential text/task failure. No precision,
recall, F1, accuracy, population coverage, causal impact or public agreement is
claimed. No confidence intervals or fine subgroup trends are planned.
Speaker rates exclude articles with explicitly unresolved candidate attribution
or statement decisions. A clearly attributable voice with unresolved capacity
remains eligible in that separate role category. For experience, a known positive
establishes presence; otherwise any unresolved flag prevents a negative finding.

## Optional / unsupported

Near-duplicate story-family detection, origin/copying direction, audience reach,
all-content topic share, and comprehensive rankings of unique people are not
supported by this run. Exact reuse is a conservative textual measure. Illustrative
cases are purposefully selected, not an additional probability sample.

## Retrieval and missingness

The topic query is SOURCE_TYPE == web, the specified date bounds and membership
in the frozen official corpus. The inherited v4 inclusion rule and source hash
travel in source_audit.json. No extra first-3,000-character query is applied here.
This broad retrieval includes institutions/events and false positives. Development
diagnostics examine incidental/no-relevance captures and synthetic near-matches;
they cannot establish recall outside the official corpus. The supplied language
and location tags are retained, never converted into a person's nationality.

Titles and entire archive bodies are preserved. Cleaning removes only NULs,
normalizes line endings, decodes entities and trims outer whitespace. Suspected
teasers, truncation and appended material are diagnosed by the coder; they are
not silently removed. Missing or partial sources remain in sample accounting.

## Frozen operational criteria

Before the main run: at least 95% structurally valid results for each essential
development task (content/topic, mentions, speakers, affected groups); all supplied
passage IDs resolve; all intended text segments are covered. Evaluate long texts
separately. The target is processing success, not correctness. A second local
configuration challenges fresh articles and diagnostic expectations. Repeated
clear semantic failures trigger revision or withdrawal of the affected numerical
claim. Save all revisions; never mix versions under one label.
