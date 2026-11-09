# Reader-report review, 22 September 2026

Both final PDFs have 16 pages. Final hashes, word counts, sizes and checks are in `tables/verification.json`.

## Editorial revision

The manuscripts now interpret indicators and results directly. The previous limitation, collection-break, validation-warning and future-work sections were removed from the reader reports. Concise indicator definitions, source credits and the 10 September 2026 endpoint remain. No collection-driven change is described as a causal increase in public interest, and the wording does not convert appearances on outside sites into organisational authorship.

Both reports include all ten leading organisational/programme names in the new comparison. The overview provides their ranked publication counts, domain breadth, top outlets, source concentration and substantive profiles. The language report provides their topic composition, selected word frequencies, article-count denominators and detailed interpretation. Existing seven word clouds and six-topic map are retained.

## Numerical and source checks

- The original 23,436 publication-days, platform/annual totals and 18,938 text contexts reconcile to the frozen release.
- The new comparison reconciles to 7,219 unique web URLs, 7,283 name-URL pairs and 333 names. Its top ten account for 2,373 pairs (32.6%).
- Leading counts are SKAC Palma 390, Udruga slijepih Međimurske županije 352, Moje mjesto pod suncem 256, Hrvatsko društvo katoličkih novinara 251 and Hrvatsko katoličko liječničko društvo 246.
- Every outlet total reconciles to its organisational count. Each organisation's topic shares sum to 100%; word frequencies stay within the organisation-specific retained-text denominator.
- All manuscript fields expand from the same aggregate facts, and the PDF builder rejects unresolved fields or page overflow.
- Source evidence, topic-assignment and rule-file SHA-256 hashes remain unchanged. No database scan, topic refit, source mutation or human label was introduced. Context rules and membership are documented in README.md and organisation_method.json; row-level membership remains private.
- Representative archived passages were read for the activity descriptions. Existing C2-C5 attribution and programme/publication distinctions are preserved through direct descriptions.

## Visual review

Poppler rendered all 32 pages at 100 dpi. Every page was inspected in eight contact sheets. Tables, captions, figures, Croatian characters, headings and footers were checked. The organisation-topic figure was revised to shorten labels and enlarge the readable chart area. Language pages 8 and 15 were then inspected individually at full rendered-page size.

Both PDFs were rebuilt and all pages rendered again. Pixel hashes confirm that the other 30 final page images are identical to the inspected versions. The two changed pages were inspected after the final render. No overflow, clipped text, overlapping cloud words, missing glyphs or unresolved template markers remain. Automated text-boundary checks pass on every final page.

## Repository checks

The Python modules compile and the final report verifier passes. The disclosure guard passed, inspecting 342 trackable study/public-barometer artifacts. It ran with `Rscript --vanilla` and an explicit existing project renv library, matching the previously documented local workflow; R emitted its existing locale/additional warnings. No package, lockfile or startup configuration changed. New exported organisation tables contain aggregate counts and terms, with no article URL, text, title, contact or row key. No website publication or commit was performed.
