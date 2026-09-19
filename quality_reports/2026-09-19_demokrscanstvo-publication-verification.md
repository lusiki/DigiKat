# Publication verification: reports and findings presentation

Date: 2026-09-19. Author: Luka Šikić, https://www.lukasikic.info/.
This record is separate from the public PDFs and website narrative.

## Reviewed publications

| Publication | Pages | SHA-256 of reviewed PDF |
|---|---:|---|
| Demokršćanstvo u medijskom prostoru | 14 | `04776182eb3663918822e2d0710d3d1ffe7d22ed871b283a32a793fdcd6bdad3` |
| Demokršćanstvo: od riječi do argumenta | 12 | `8bc603616b34ad49d550b8b20628619a58ee9a81152035dc5eaaf24068554bac` |
| Demokršćanstvo u medijima: 12 ključnih nalaza | 15 | `e33be8e8eba86a353f423f35d61d7d06a2a91ff832f3daf2c4a995c71d8de786` |

All three PDFs have visible Croatian authorship, personal-site link annotations
and author metadata. Every rendered page was visually inspected with Poppler:
14 overview pages, 12 textual pages and 15 slides. The four changed chart slides
were inspected again after removing misleading full-width background tracks and
narrowing the expression-comparison headline. No clipping, missing diacritics,
overlapping labels or footer collisions remain. Colour, type, whitespace and
hierarchy follow the reference report. Report previews are compressed thumbnails;
the downloadable PDFs retain their full quality.

The overview's pages 2–14 are pixel-identical to the previously published PDF at
commit `1e75a10`. Only its cover attribution, links, language and author metadata
changed. A comparison is saved in `output/demokrscanstvo-presentation/overview-comparison.json`.

## Evidence and counts

- The overview verifier passes: every retained series reconciles to the public
  thematic release, text bounds are valid and Calibri/Georgia fonts are embedded.
- The textual report passes 19 checks and has a 256-row numerical claim register.
  Its delivered aggregate-only builder reproduces the reviewed PDF byte for byte.
- The presentation reconciles 134 numerical claim entries to public aggregate
  tables. Its PDF text, dates, names, source links, page ratio, diacritics and
  margins pass checks. The editable slide source generates the public HTML.
- Publication counts (2,306) and distinct-text counts (2,253) stay separate.
  Political groups total 1,153 / 2,306 = 50.0% in the overview and presentation.
  Vocabulary, phrases and topic clouds use distinct-text denominators.
- Reused case evidence is linked to the textual report's separate passage audit:
  Haj Barakat's exit announcement on 29 August 2024 (print issue 30 August),
  Mrak-Taritaš and Plenković in Parliament on 20 April 2022, Stier's European
  campaign statement on 7 June 2024 and Žižić's interview on 28 February 2021.
  Contested statements and interpretations remain attributed to their speakers.
  Cases are examples, not estimates of semantic prevalence or monthly totals.

## Website and accessible formats

The touched page rendered from the repository root with Quarto 1.9.38 and R 4.6.0.
No data files changed. Existing renv synchronisation and Windows locale warnings
remain; rendering completed successfully without chunk errors.

- Site quality: 127 active HTML pages pass, including local links, headings and
  images. The barometer resource weight is 1,443 KiB against a 1,465 KiB budget.
- Existing barometer browser tests pass at 320, 375, 390, 768, 1024, 1366, 1440
  and 2048 px, including keyboard interaction and static fallback.
- The barometer, new report HTML and presentation HTML pass WCAG A/AA checks with
  axe at 390 and 1366 px. All image resources decode. Desktop and mobile findings
  and publication sections were inspected with loaded thumbnails.
- Presentation tests pass for arrow navigation, focus, Escape, slide bounds and
  mobile layouts at 320, 390 and 768 px. HTML provides semantic headings and
  textual alternatives for all word-cloud values. PDF text is selectable.
- The all-platform and thematic verifiers pass against the rendered barometer.
  Existing interactive filters and aggregate data are preserved.

Review was performed by Codex AI. No independent human double coding,
screen-reader user study or PDF/UA certification is claimed. Verification data,
technical documentation and source materials are kept outside the public PDFs.

## Delivery and deployment

The combined local ZIP contains public artifacts, editable HTML/JSON/Markdown
sources, aggregate-only inputs, website copy and a separate verification folder.
No private article bodies or row-level corpus exports are included. The new report
also retains its standalone publication ZIP. The presentation's portable HTML
builder must reproduce the public HTML byte for byte before packaging succeeds.

Deployment targets the existing GitHub Pages source, `main:/docs`. Live artifact
hashes and deployment status are recorded separately after the scoped push.
