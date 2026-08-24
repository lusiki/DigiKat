# DigiKat editorial guide

Status: ratified for Site improvement Run 1  
Owner: project editor  
Applies to: reader-visible Croatian copy, labels, metadata, captions, downloads, and navigation

This guide records the short controlled vocabulary needed across the site. The fuller voice and punctuation rules remain in `.claude/rules/voice-and-style.md`. When the two documents differ, the more specific and more recent project decision must be ratified here before prose is changed site-wide.

## Canonical purpose

The approved formulation is:

> DigiKat je otvoreni opservatorij koji pokazuje tko u Hrvatskoj objavljuje o katoličkim temama, o čemu govori i što privlači pozornost.

`_quarto.yml` under `website.description` is the technical source of truth for shared site metadata. Use the sentence unchanged on the homepage, in project descriptions, and in metadata where space permits. Supporting research questions may follow it but must not replace it.

## Controlled vocabulary

| Term | Required public meaning | Editorial rule |
|---|---|---|
| **interakcije** | Recorded platform actions such as reactions, comments, and shares | Preferred term for raw recorded actions. Name the included actions when the distinction matters. |
| **angažman** | A defined measure calculated from interactions | Use only when the calculation is named or linked. Do not use as a loose synonym for interactions. |
| **doseg** | An estimate supplied by the monitoring-service provider | On first relevant use write `procjena dosega` or `procjena pružatelja usluge`. Never imply confirmed unique viewers. |
| **izvor** | The recorded publishing source or account | Use for the observed account, outlet, or channel in the data. |
| **akter** | A participant defined by an analytical rule | Do not use automatically as a synonym for source. State the rule that turns a source into an actor. |
| **platforma** | The technical or publishing environment | Keep platform and source distinct. A brand present on two platforms may be two recorded sources. |
| **korpus** | The official research collection selected by the documented inclusion rule | Public pages describe one official corpus. Internal accumulators and old snapshots are not a competing public dataset. |
| **objava** | A media item as the unit of public analysis | Preferred reader-facing unit. |
| **zapis** | A database row | Use only when row structure, duplication, or storage makes it materially different from an objava. |

## Required Croatian replacements

| Avoid | Use |
|---|---|
| `vendorska procjena` | `procjena pružatelja usluge` or `procijenjeni doseg` after definition |
| `kick off` | `početni sastanak` |
| `seminalni rad` | `utjecajan rad`, `temeljni rad`, or a context-specific Croatian description |
| `R & Python` | `R i Python` |
| `web scraping` on public pages | `automatsko prikupljanje objava` |
| `dataset` | `korpus`, `skup podataka`, or `baza podataka`, according to the controlled distinction |

## Status vocabulary

Every substantial page or publication has exactly one current status.

| Status | Use when |
|---|---|
| **Radni prikaz** | The page is public for inspection but its structure or content is still being developed. |
| **Preliminarno** | The analysis is complete enough to report, but a stated validation, review, or data step remains. |
| **Ažurira se** | The page is a maintained view whose values are expected to change with scheduled data updates. |
| **Stabilno izdanje** | The version has passed its review gate and is suitable for citation as published. |
| **Arhivirano** | The item is retained for provenance but is no longer the current public version. |

Do not use decorative status badges. A status belongs in the shared freshness strip and must explain a scholarly state, not create urgency.

## House checks for Croatian copy

- Use literal UTF-8 Croatian diacritics `č ć ž š đ`.
- Use sentence case in headings, labels, captions, and navigation.
- Write dates as `24. kolovoza 2026.` and year ranges as `2021.–2026.`.
- Use a full stop as the thousands separator and a decimal comma. Write `400.000` and `12,3 %`.
- Use `R i Python`, Croatian quotation marks `„…"`, and one full stop at the end of a sentence.
- Remove duplicated full stops and avoid colon, semicolon, and em dash in running prose.
- Prefer short declarative sentences and evidence-led verbs. Avoid sales language and unqualified superlatives.

## Public corpus rule

Reader-facing copy uses one stable formulation for scale.

> Službeni korpus DigiKat obuhvaća približno 400.000 zapisa.

Exact changing counts must come from the tracked corpus manifest. Use exact counts only where they help a reader verify a result. Do not build a public narrative around the accumulator or superseded snapshots.
