# Academic site plumbing and portable outputs

## Goal

Strengthen DigiKat as a public academic website without introducing a commercial layer. Add a neutral contact route, social-sharing metadata, useful homepage entry paths, downloadable outlet cards in *Moj medij*, and a complete English edition of the published 2025 annual report. Do not add a newsletter form or commercial calls to action.

## Scope and decisions

- Add a Croatian contact page with institutional/project contact routes and a clear privacy expectation.
- Add canonical, Open Graph, Twitter-card, favicon, and structured-data plumbing through Quarto's shared header where possible.
- Diagnose and fix the reproducible browser-console error at its source.
- Add audience paths on the homepage that terminate in existing public content or the neutral contact page.
- Generate one disclosure-safe, single-page PDF card for every outlet exposed by the public `data/page-ready/moj_medij.json` artifact. Link each selected outlet to its generated file.
- Translate the complete published 2025 annual report into English while preserving every generated scalar, figure, table, qualification, and the report's non-commercial boundary. Extend the isolated report build so Croatian and English editions are checked and rendered reproducibly.
- Do not add newsletter UI.
- Do not silently enable third-party analytics. Prepare and document a privacy-conscious GitHub Pages option, and enable it only if it is cookieless, does not require a consent banner for the intended setup, and has an explicit site identifier already available. Otherwise leave the site untracked and document the one remaining owner action.

## Implementation order

1. Inspect current Quarto metadata, generated HTML, JavaScript, annual-report pipeline, and public outlet-data contract.
2. Implement shared metadata/contact/homepage changes and test internal links.
3. Add a deterministic outlet-card generator that reads only the already-public page-ready JSON, validate its output count and disclosure boundary, and wire links into *Moj medij*.
4. Add the English report template and pipeline support. Run report checks and isolated HTML/PDF rendering.
5. Render touched site pages individually. A full site render remains behind the repository's explicit user-confirmation gate.
6. Inspect git status for source-adjacent render scatter, verify generated assets, and report any remaining owner-only decision.

## Risks and guards

- Never write to the master, official corpus, `data/processed/`, or the public annual-report artifacts without the established pipeline and publication gate.
- Generated outlet cards may contain only fields already present in public `moj_medij.json`.
- Preserve Croatian UTF-8 diacritics and English scalar parity.
- Preserve the user's unrelated edits under `explorations/linkedin-carousel/`.
- Do not run a full `quarto render` without asking for confirmation because it overwrites `docs/`.
