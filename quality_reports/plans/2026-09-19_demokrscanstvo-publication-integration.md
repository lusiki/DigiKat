# Integrate both reports and the findings presentation

Approved by the user's “Make that” instruction, including HTML and PDF slides
and attribution to Luka Šikić, linked to https://www.lukasikic.info/.

1. Retain the broad overview and textual interpretation as separate publications.
   Add linked authorship to their covers, metadata and available HTML/source.
2. Build an accessible, editable HTML presentation and matching landscape PDF
   around twelve supported findings. Use the reference report's typography and
   colours, selected word clouds, explicit denominators and attributed cases.
3. Put three findings and a presentation preview near the page introduction;
   provide both report cards and the presentation in one publication section.
   Preserve the existing interactive barometer and its fixed inputs.
4. Reconcile claims with frozen tables and passages, inspect every PDF page,
   check HTML keyboard/mobile/accessibility behaviour and rebuild the page only.
   Keep the verification record and editable publication package separate.
5. Commit only these sources and generated site assets, push to the existing
   main/docs publication target, and verify deployed resources and PDF hashes.

No corpus changes or full-site local render. Preserve all unrelated dirty files.
The HTML presentation source is editable without presentation software.

## Completed implementation

- Added separate report cards, three introductory findings, a presentation
  preview and HTML/PDF links. Linked authorship appears on all publications.
- Created 15 slides containing 12 findings with an overall word cloud, four
  topic clouds, charts and attributed cases. Added a mobile reading view and
  keyboard presentation mode. Public denominators remain explicit.
- Reviewed all 41 PDF pages; verified numeric claims, case references and links.
  Checked the unchanged overview content against the previously published PDF.
- Rendered the touched page only. Site quality, browser accessibility, responsive
  layout, keyboard, static fallback and both data reconciliation checks pass.
- Separate internal record: `quality_reports/2026-09-19_demokrscanstvo-publication-verification.md`.
  The editable publication package is assembled in `output/` and kept off-site.
