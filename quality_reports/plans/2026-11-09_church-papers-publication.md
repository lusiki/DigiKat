# Publish the two linked Church-and-dezinfo papers

The user requested both manuscripts at the supplied GitHub/githack URLs among
the thematic-study tiles, with HTML, PDF and editable Word downloads. Those
linked versions are the publication authority, even where local reruns differ.

1. Pin the upstream commit and verify the two rendered manuscripts and available
   companion files. Preserve their prose, computed results, authors and figures.
2. Produce Word and PDF editions from the same frozen rendered content, without
   rerunning analyses against the newer local corpus. Record source hashes.
3. Update the existing framing profile and tile to match that manuscript. Add a
   separate Christian-democratic discourse profile and tile. Use the existing
   site design and provide all three formats on both profiles.
4. Render only the affected pages from the repository root. Verify manuscript
   content, document layouts, Croatian encoding, links and generated site files.
5. Report the prepared files and publication status. Preserve unrelated dirty
   files and staged data exports; do not bulk-stage or push unrelated work.

The task authorizes these publication preparations. No corpus changes or full
site render are needed. A newer local analysis is not substituted for the
explicitly selected linked manuscripts.

## Completed locally

- Pinned both upstream HTML editions to commit
  `1475dd962a93f25c66b7747c60fa6be8305d0e8a` and recorded hashes in
  `assets/papers/church-and-dezinfo-release.json`.
- Converted the published content to editable Word and rendered PDF editions
  (framing 18 pages; Christian-democratic discourse 14 pages). Both retain all
  eight tables, three original figures and ten editable equations. Verified
  every table cell and image hash against the upstream HTML. Verified all
  substantive non-math prose paragraphs, accounting for native Word footnotes.
- Reviewed rendered document pages and corrected float wrappers, table widths
  and caption pagination. Word background PDF export stalled; the final PDFs
  were produced by an isolated official LibreOffice 26.2.7 extraction using the
  document skill's render_docx.py. No system-wide LibreOffice installation.
- Embedded KaTeX 0.19.1 formula rendering and fonts into both HTML editions.
  Browser checks confirm all figures load and equations render without a CDN.
- Updated the framing profile and tile, added the second profile and tile, and
  added direct links to all three formats on both cards. The overview has nine
  tiles. Preserved the framing review status and labelled the second manuscript
  as a working paper for Revija za socijalnu politiku.
- Rendered all three affected pages with the site theme. The formerly excluded
  framing profile is now static and included in site renders. Removed only the
  stray output generated when Quarto initially treated that excluded page as a
  standalone document. Confirmed docs/ remains intact.
- Verified local links, all six output hashes in assets/ and docs/, desktop
  layouts, and no horizontal overflow on the 390px mobile overview. git diff
  --check passed. The six previously staged public-data files remain staged.

Changes are uncommitted and have not been pushed. Raw corpora and unrelated
study work were not changed.
