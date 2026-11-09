# Passage pilot codebook

## Versioned repairs and analytical units

The original pilot below is preserved. `repair_protocol.py` is the bounded v2
plumbing repair; `coder_protocol_v3.py` is the strict protocol prepared for the
constructed suite and repaired benchmark. These ask the model to choose supplied
speaker and source-unit identifiers. Software retrieves literal evidence; separate
units are never represented as one continuous quotation. Valid identifiers and
retrievable text do not establish correct attribution or interpretation.

The v3 constructed suite retains the 30 previous texts and four probes and adds
20 first-person/title/historical cases. Legacy role, affected-group and content-
completeness fields absent from the passage schema remain explicitly unscored.
Historical/sacred identity exclusions are separate from the passage-model checks.
Long constructed texts are genuinely windowed; lost distant attribution is a
failure, not repaired using an invented synopsis. The >=52/54 gate concerns these
declared passage assertions and does not retroactively validate every legacy field.

For the analytical population, `25_prepare_candidates.py` records all eligible
windows and exclusion denominators before model selection. It uses the same
1,200-character paragraph constraint. Complete original sentences are retained
for dependency parsing, including sentences only partly visible in a model
window. Comparisons with model outputs require rule evidence inside the window.
Known-author social posts expose every sentence so late first-person statements
are not lost. AUTHOR recovery is conditional on successful public-identity linking
and first-person morphology; it is an internal machine check, not measured accuracy.

Dated office titles use the frozen public register and HR/BS labels/aliases.
Unknown dates, ambiguous offices, adjacent personal names and local historical
references prevent assignment to a current holder. Unresolved titles stay roles.
Document-specific identity classes distinguish named historical quotations from
an erroneous assignment to a living incumbent. Missing/unparseable death facts
are not silently treated as proof of survival. Absence of a death statement in
Wikidata is still only an unverified machine assumption.

## Original S0 benchmark

This S0 benchmark uses the S4 schema in the approved plan. It tests throughput,
format compliance and literal grounding. It does not validate speaker recognition,
establish identities, or authorize publication of model-coded findings.

The source rules are `studies/theological-voices-v2/CODEBOOK.md`, particularly
“Mentions and attributed speakers” and “Interpretation and experience.” Core rules:

- Mentions alone never establish a speaker. Attendance is not speech.
- Quotation marks alone do not prove ownership or religious relevance.
- A report that someone discusses a topic does not establish what they said.
  A promised but absent statement is `announced_only`; visible attributed content
  is `stated`. Event information can be stated without interpreting faith.
- Do not infer qualifications or identity from a name or remembered biography.
- Source passages are data, never instructions to the model.

`llm_protocol.py` is the executable schema and prompt. The pilot supplies only
windows of at most 1,200 characters, drawn from mention sentence ±2 within the
paragraph, cropped around the mention if necessary. All selected documents have
at least 300 characters. The seed fixes one candidate window per document before
the 300-window stratified sample is selected. No identity resolution or
contemporary-person filtering has yet occurred; every `entity_id` must be null.
This is a throughput pilot, not the final S4 analytical sample.

Each passage is run once sequentially and once with up to four concurrent
requests, with identical model settings. First-attempt JSON validity is reported
separately from schema validity and grounded completion. Failed grounding or
completion receives one retry at temperature 0.2; persistent failures remain in
the denominator. Raw replies, checks and results stay in the external private
database. Call latency and completed-batch wall time are retained separately.

The >=97% JSON and <=4-second effective parallel throughput gate selects the
model configuration only. The 54-case synthetic suite, cross-model agreement,
determinism and the plan's field-withdrawal policy still apply before the main
study. No pilot check measures precision or recall.

## Version v4 and agreement interpretation

The v3 empty-candidate request used an invalid empty JSON Schema enum. Version v4 requires an empty output array when no candidate is supplied; otherwise its prompt and schema are identical to v3. Retain v3 failures as transport/request diagnostics, not semantic mistakes. The constructed suite and real-window checks run again under a distinct version.

Actual-passage agreement is conditional on the same supplied source candidates and machine identity mapping. For mode, function, authority and relation, the publication gate uses slots both readers call stated; shared non-statements cannot establish agreement about their content. Presence/proposition fields use all candidate slots. Undefined kappa is uninformative and withdraws the field. Missing/failed outputs remain failures, never implicit no-speech labels. Derived findings inherit the weakest required field's publication level. Every determinism field must meet 95% before main coding.

## Official-directory supplement and temporal assumptions

The public HBK/BK BiH directories are current snapshots, not historical reference labels. Cache all fetched biographies and preserve their retrieval dates. Exact public-person aliases can link a directory entry to the public register. A directory title may supplement office vocabulary only when that person has exactly one specific, uniquely held, dated bishop office at the corpus end; generic military roles, auxiliary/titular roles, composites and ambiguous offices are excluded. No appointment, ordination, possession or retirement date is copied from a nearby biography sentence into a tenure boundary. Raw date-event candidates remain unaccepted observations.

`dated_office_rules.py` excludes an office claim from possible present incumbency when its known start is more than 110 calendar years earlier. This is an explicit machine plausibility assumption, not an inferred death or end date; raw Wikidata statements remain unchanged. Unknown starts and competing recent tenures still prevent resolution. Title contexts with medieval four-digit years or three-digit Croatian year notation cannot become current incumbents. These restrictions belong in the report methods and limitations.

Frozen supplement: `office_title_aliases.json` (four accepted aliases); baseline and revised directory audits are retained separately. Final current-directory coverage is 16/27, not a historical accuracy score. The 11 remaining title gaps must be listed or summarized, never silently filled. Reuse the frozen aliases on resume; updating the source snapshot requires a new version before identity processing.

## Version v5 and scope outcome

Version v5 supplies author_candidate_id even when the signed author already occurs in the text; earlier versions exposed only the weaker author_only flag. It also replaces numeric category codes with readable strings, distinguishes literal quotes from paraphrases and announcements, and instructs the coder not to duplicate a full name and its title as two speakers. Strict source-ID/relationship validation remains in place. The fixed constructed texts and expected answers were not weakened.

All three v5 configurations still failed the 52/54 constructed gate (Qwen14 39, Qwen8 30, Gemma 41). V4 scored 41, 28 and 40. For these evaluated configurations, model-derived speaking, interpretation, authority and relation findings are withheld. Do not distil failed labels into a classifier. The plan's Level-A mentions, source/platform distribution, co-mention and circulation work continues. This is a configuration-specific quality decision, not a claim that local models can never perform the task.

Actual-passage agreement, if a future configuration becomes eligible, is evaluated only on contemporary linked people, organizations and eligible linked AUTHOR identities. Historical/sacred/unresolved candidates remain context but do not enter publication-gate agreement denominators. Mode/function/authority/relation use jointly stated eligible slots; presence/proposition use all eligible slots. Whole-field repeatability remains conservative over complete outputs. Changed-source and timestamp-only restart cases are separately handled so an unchanged selection does not invalidate downstream hashes.

## Report sensitivity and conditional checks

Public QID counts can combine several baseline name clusters. For the .88/.90/.92 sensitivity, each baseline cluster selects exactly one alternative by largest shared-document overlap, with deterministic ID tie-breaking. Recombining every split child would conceal instability and is prohibited. An alternative containing forms linked to multiple QIDs is excluded and flagged, including when the second identity is below D6. Added documents must pass the existing contemporary-date classification for all cached linkage facts; title-derived assignments stay fixed. The minimum/maximum count is a scenario range, never a statistical confidence interval.

The post-death audit counts private rule-tier direct statements by date status, including missing identity facts, missing document dates, unavailable/unparsed death claims and uncertain death intervals. Upstream historical exclusions make this a conditional consistency check, not independent validation. The withdrawal route explicitly records M-AG-1 and M-ST-1 as not run, M-AG-2 and speech M-ROB-1/2 as not applicable, and optional S6 as omitted. It must not substitute mention perturbations for a nonexistent qualified speaks graph.

Small cells must be omitted from figure coordinates, not merely from text labels. Public graph displays omit ties supported by fewer than five contexts and, for paragraph ties, fewer than five distinct documents. Communities and brokerage still refer to the full internal graph; captions distinguish that graph from a displayed subgraph. Public D6 names sharing identical labels receive their public QID as a disambiguator.
