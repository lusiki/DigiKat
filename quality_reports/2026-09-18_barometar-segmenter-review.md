# Barometer sentence segmentation: independent development check

Date: 2026-09-18. Status: the revised operational segmenter passes the same-sample development gate; the original failures and amendment evidence are retained below. No definition freeze or publication approval is claimed.

## Design and safeguards

The reusable check is `studies/demokrscanstvo-barometar/check_segmenter.R`. It selects 300 eligible article representatives from each source batch, within the stable 30% development split only. Selection uses seed 20260918 and deterministic hash order, without keywords, topic classification, route counts or period series. The sample uses the reviewed outlet registry and the common and outlet-specific URL eligibility rules, including the revised MojTV product boundary.

The 600 sampled document and article hashes are recorded privately and excluded from evaluation by their development assignment. Source input, sampled keys, per-document metrics and reference boundaries remain in the configured private work directory. No article text, title, URL, quotation or source identifier appears in this report.

Both algorithms receive the same title-stripped, NFC-normalized body with the common 32,000-code-point cap. This check precedes boilerplate masking. The reference is the local Croatian SET UDPipe model, with tagging and parsing disabled. Token ranges are checked against the source string to verify exact Unicode code-point coordinates. All 600 documents aligned successfully; none was dropped.

The metric compares exact internal next-sentence starts, after leading whitespace. Document beginnings and terminal document endings are omitted because they are trivial boundaries. Precision and recall are micro-averaged over all internal boundaries in each batch. The required precision and recall remain at least 0.93 in **each** batch.

Reference model: `croatian-set-ud-2.5-191206.udpipe`; package version 0.8.16; model SHA-256 `b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7`.

Original tested engine SHA-256: `42a4d394766d3d1785042fdaccd91c61d1735d54162e75aab22a55d2cead7299`. Original proposed definition: `1.0.0+437ed8d90cb4`.

## Original algorithm result

| Batch | Documents | Predicted boundaries | Reference boundaries | True positives | Precision | Recall | Gate |
|---|---:|---:|---:|---:|---:|---:|---|
| luka_opce | 300 | 6,099 | 5,419 | 5,202 | 0.852927 | 0.959956 | Fail |
| mediaspace_full | 300 | 6,246 | 5,338 | 5,082 | 0.813641 | 0.952042 | Fail |

Recall passes in both batches. Precision does not.

## Boundary diagnosis

318 of the 600 normalized documents contain at least one newline.

| Batch | Boundary type | Predicted | True positive | False positive |
|---|---|---:|---:|---:|
| luka_opce | Soft punctuation boundary | 4,260 | 4,077 | 183 |
| luka_opce | Newline without terminal punctuation | 729 | 77 | 652 |
| luka_opce | Newline after terminal punctuation | 1,110 | 1,048 | 62 |
| mediaspace_full | Soft punctuation boundary | 4,090 | 3,893 | 197 |
| mediaspace_full | Newline without terminal punctuation | 974 | 94 | 880 |
| mediaspace_full | Newline after terminal punctuation | 1,182 | 1,095 | 87 |

The brief's unconditional-newline sentence rule forces 714 false boundaries in luka_opce and 967 in mediaspace_full. Even a hypothetical algorithm recovering **every** reference boundary, with no other false positives, would have precision at most:

- luka_opce: 5,419 / (5,419 + 714) = **0.883581**.
- mediaspace_full: 5,338 / (5,338 + 967) = **0.846630**.

Consequently, retaining every newline as a sentence boundary is incompatible with the stated 0.93 precision gate on this sample. These are upper bounds demonstrating the conflict, not alternative passing estimates.

Among soft-punctuation false positives, the preceding token is a one-to-four-digit number in 103 old-batch and 105 new-batch cases. Other old-batch categories are no adjacent letter/number token (45), ordinary word (25), single capital (8), Roman numeral (1), and known abbreviation (1). The corresponding new-batch counts are 61, 21, 5, 5 and 0. Only 22 old-batch and 20 new-batch false positives lie within three code points of a reference boundary, so a permissive coordinate tolerance would not explain the main failure and is not used.

## Recommended amendment and next check

The executor recorded acceptance of the recommended pre-freeze amendment under the user's delegated decision authority: remove unconditional newline cuts and let terminal-punctuation detection accept spaces or newlines as whitespace. Newlines remain in the normalized text, offsets remain unchanged, and they never become window walls. The amendment changes the segmentation rule in brief §3.4; it does not lower the validation threshold.

Re-run the **same 600 documents**, using the cached unchanged UDPipe reference and the exact-boundary metric. Score every resulting boundary. Do not remove newline categories from the original denominator or describe such a subset as a passing validation result. Until that actual rerun completes, the result reported here remains **failed**.

For residual numeric errors, first examine explicit numeric date chains and recognized ordinal-plus-abbreviation constructions. Suppress only boundaries internal to a structurally verified construction. Preserve boundaries after an ordinary sentence ending in a year or number. Broadly suppressing every number followed by a capital would create avoidable false negatives and is not recommended.

This is algorithm development evidence, not human article coding, route precision, whole-panel recall or a claim about barometer results.

## Same-sample amendment check and narrow recovery proposal

The actual rerun after removing unconditional newline cuts recovered precision but remained below the recall criterion:

| Batch | Predicted | Reference | True positive | Precision | Recall | Gate |
|---|---:|---:|---:|---:|---:|---|
| luka_opce | 5,263 | 5,419 | 5,030 | 0.955729 | 0.928216 | Fail |
| mediaspace_full | 5,184 | 5,338 | 4,920 | 0.949074 | 0.921694 | Fail |

False-negative diagnosis then identified 195 old-batch and 167 new-batch missed post-terminal starts beginning with punctuation or symbols. Adding blank-line boundaries alone recovered only four and five true boundaries respectively and did not meet the recall gate. No additional samples or keywords were used.

A narrowly specified development proposal recognizes opening parentheses and dialogue dashes (`(`, `-`, `–`, `—`) as possible next-sentence starts after terminal punctuation and whitespace. For these newly admitted starts, the preceding period is not a boundary when it follows a one-to-four-digit number, a Roman numeral or a single capital initial. Existing abbreviation exclusions remain. Lowercase starts are unchanged. This preserves exact offsets and does not indiscriminately suppress numeric sentence endings.

Invented implementation fixtures, not source examples:

- `Prijedlog je odbijen. – O tome se raspravlja.`
- `To je zaključak. (Sljedeći je korak analiza.)`

The independently simulated proposal was scored on the **full same reference**, with every new false positive retained:

| Batch | Predicted | Reference | True positive | Precision | Recall |
|---|---:|---:|---:|---:|---:|
| luka_opce | 5,410 | 5,419 | 5,164 | 0.954529 | 0.952943 |
| mediaspace_full | 5,317 | 5,338 | 5,038 | 0.947527 | 0.943799 |

This proposal adds 134 true and 13 false boundaries in the old batch, and 118 true and 15 false boundaries in the new batch, relative to the whitespace-only amendment. A broader proposal also accepting lowercase starters had lower precision with only two and seven additional true boundaries, so it is not recommended. These proposal figures are not a claim that the operational engine has already passed: implementation and an actual engine rerun remain necessary.

## Operational rerun verification

The executor implemented the narrow dialogue/parenthesis change and ran the reusable checker again on the unchanged 600 documents and cached reference. The reviewer independently read the completed aggregate report. The operational result exactly matches the narrow proposal counts above:

- luka_opce: precision **0.954529**, recall **0.952943**, 300 documents: pass.
- mediaspace_full: precision **0.947527**, recall **0.943799**, 300 documents: pass.

The tested revised engine SHA-256 is `c924fb2c288d673cbe8c9f9049dd26bb3e1caaf76709a4548b0dc90da71bea4c`.

Both measures exceed 0.93 in both batches. No document or boundary category was omitted to obtain the pass; neither sample nor threshold changed. This is a development-set segmentation result. Because the same development sample informed the amendment, it is not an independent held-out estimate. It establishes this specified pre-G2 segmentation checkpoint only; route validity, human coding, definition freeze and publication gates remain separate.
