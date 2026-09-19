# Real-data barometer across all archived platforms

Authorized by Luka Šikić on 2026-09-19: “Let's collect this data and then we're going to implement this on the page.” The preceding discussion explicitly expands retrieval beyond the 115-outlet panel and beyond web. The supplied merged DuckDB is sufficient; do not seek additional vendor material, archive confirmation, human exports, or licence paperwork as prerequisites for this provisional edition.

## Scope and decisions

- Read the merged DuckDB without modification. Search every platform, source and available date, with no 115-outlet, language-detector or religious-corpus filter.
- Produce a separately versioned, provisional empirical release. Preserve the frozen panel pipeline, definition, validation forms and gate records. Human validation remains incomplete; the 55-item assistant review is disclosed as AI review, not independent human validation.
- Reuse the frozen contextual A1/B/C inclusion rules without training on the 55 review items. Adapt text eligibility for short posts and missing bodies. Title and body are evaluated separately; snippet substitutes only when full text is absent. Record text availability and fallback counts. Search full stored text without the original 32,000-character processing cap.
- Deduplicate repeated captures using vendor platform plus item ID where available. For legacy records, collapse only identical capture identities including platform, source, URL, capture date/time and text hashes. Do not collapse separate comments by parent URL, cross-platform reposts or syndication.
- Report archive record counts and within-platform monthly rates. Keep platform composition visible; do not label pooled counts as a platform-neutral index. Show missing collection days, platform start dates and the April 2024 collection break. Never imply an exhaustive census of Croatian media.
- Restricted texts, evidence and record identifiers stay in the external work directory. The repository and rendered page receive only aggregate counts, methods and reproducibility metadata.

## Execution

1. Inspect schemas and existing rules, write reproducible extraction and classification adapters, and verify identity/text-policy fixtures.
2. Extract all-platform denominators and candidates into private checkpointed files; classify contextual matches and reconcile counts.
3. Build aggregate release with checksums, definition provenance, collection coverage, validation status and method documentation.
4. Replace the synthetic page with the expanded provisional empirical page, including platform controls, static fallback and aggregate downloads.
5. Verify release invariants and privacy, render only the changed page, inspect the rendered result and record exact run counts and limitations.

No change to the official DigiKat master/corpus and no full-site render is required.

## Publication authorization

On 2026-09-19 the PI explicitly authorized: “You can commit and push this to the page.” Publish the aggregate edition to the existing GitHub Pages source (`main`, `/docs`), preserving unrelated local files. Render the homepage separately to expose the new navigation link, align the browser release check with the new platform controls, verify the staged files, then commit and push without rewriting history. Check the Pages deployment and the live page against the committed aggregate manifest.

## Outcome

Completed on 2026-09-19. All 69 months were extracted and classified. The page now reads the real all-platform aggregate release, with 2,306 qualifying records out of 41,397,670 searchable archived records. The former synthetic outputs were archived outside `docs/`. Data reconciliation, the 338-record exact-engine software audit, targeted regression checks and the single-page Quarto render pass. Although the browser connector was unavailable during extraction, the publication pass successfully ran the repository's automated Chrome checks for the homepage and barometer at all eight required viewport widths. See the [execution report](../2026-09-19_barometar-all-platforms.md) for final counts and evidence.
