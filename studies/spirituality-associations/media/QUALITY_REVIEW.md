# Quality review: full-period landscape

Completed 19 September 2026. The final report has 18 pages and ten figures.

## Numerical and analytical checks

`06_verify.py` passed 50 checks. The scan reconciles to 42,267,474 records,
69 months and all 2,079 dates from 1 January 2021 through 10 September 2026.
The source database's size/mtime fingerprint is unchanged. The full register
retains 1,325 distinct IDs; the complete panel contains 7,950 organisation-years,
with blank held-name counts distinguished from searched zeros.

Candidate publication-days, pairs, organisation totals, annual/platform/county
tables and raw-record search-yield denominators reconcile. Matching fixtures cover
field separation, word boundaries, Croatian inflections and URL content IDs.
No human labels are populated. Aggregate tables exclude item keys, URLs, titles,
contexts, full text, organisation IDs and personal contacts.

The directory's generated JavaScript was executed with a mock document and checked
for its 1,325-entry initial display, 450-name candidate filter, 282-name held filter
and case-insensitive Breza search. This is a functional script check, not a claim
of a full cross-browser accessibility audit.

## Text-model checks and interpretation

All initial 6/8/10/12-topic models converged within the iteration allowance.
Representative and weak examples were inspected for every eight-topic group.
Several groups clearly capture donation/contact templates, channel descriptions
or tags; the report makes this a measurement finding, not a substantive taxonomy.

A subsequent repeat-suppression sensitivity removes eight-token runs occurring
in at least 20 candidate items. It retains 18,938 of the 20,598 modelled items.
Representative and weak examples were inspected for all six displayed groups;
six/eight-topic two-start comparisons are saved. The adaptive choice and possible
removal of legitimate repeated announcements are explicit. Corpus candidate counts
do not change under this text-only sensitivity. No model share is called a human
frame, stance or public-role prevalence estimate.

## Visual review

The PDF was rendered with Poppler at 100 dpi. All 18 pages were inspected in three
six-page contact sheets; the dense topic table and organisational heatmap were
also inspected at individual-page scale. No overlap, clipping, missing glyphs,
broken table cells or unreadable chart labels were found.

The final cosmetic revision removed a future-year axis tick and made unnumbered
table-caption labels consistent. All pages were rerendered. SHA-256 image
comparison identified changed pages 2, 6, 10 and 17 only; those four final pages
were inspected again. The remaining 14 page images were byte-identical to the
previously inspected render. Programmatic text-boundary checks found no spans
outside the intended page bounds. Headers, footers and page numbering are intact.

## Remaining scientific limits

This is the first exploratory deliverable, not completion of every later-stage
package in the prospective plan. Historical eligibility, expanded identity rules,
unfiltered-export recovery, independent entity/relevance coding, historical source
affiliation, near-copy story adjudication and full investigative dossiers remain
uncompleted. Corpus-level name matches remain unresolved. All claims and captions
retain that distinction. The January 2024 collection change, partial 2026 period,
present-frame survivorship, mixed languages/countries and event-date discrepancies
are explained in the report. No public website release or outreach was performed.
