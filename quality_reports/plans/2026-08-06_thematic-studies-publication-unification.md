# Thematic studies publication unification

## Goal

Create one systematic publication experience for every item under **Tematska istraživanja** without
changing the scholarly content. Each study profile should use the DigiKat site design, identify and link
all authors consistently, expose every genuinely available format, and provide local HTML and PDF copies
of older papers. Existing Word files remain available when present.

## Rationale

The navigation currently points to seven study profiles, but the profiles and linked papers do not use a
single publication pattern. Some papers are local, others open externally, and their HTML/PDF appearance
and format availability differ. The site design system in `assets/css/custom.scss` is the visual source of
truth, so paper outputs should extend that system rather than introduce another identity.

## Scope and constraints

- Audit all seven `pages/studije/*.qmd` profiles, all local `assets/papers/*` files, and every linked paper.
- Preserve paper prose, figures, tables, citations, notes, and substantive metadata verbatim.
- Normalize only publication chrome: typography, spacing, colors, title/author presentation, navigation,
  format controls, profile metadata, link behavior, responsive layout, and print/PDF styling.
- Link author names on both the study profile and within the paper metadata. Prefer stable institutional,
  ORCID, or existing project-profile URLs; do not invent identities.
- Publish HTML and PDF for older papers where a usable source or existing paper file is available. Retain
  DOCX alongside them when it already exists.
- Do not fabricate a format for a study that has no full paper artifact.
- Render only touched pages during implementation. A full-site render requires separate confirmation under
  the repository safety rules.

## Implementation sequence

1. Build an inventory of study titles, status labels, authors, destinations, formats, and source artifacts.
2. Define one reusable study-profile component and one paper-output design derived from the DigiKat theme.
3. Localize or generate missing paper formats from canonical sources, keeping content byte/text equivalent
   as far as each conversion permits.
4. Apply standardized author links, format buttons, status/version details, and accessible labels to every
   study profile.
5. Render each touched `.qmd`, validate local and external links, compare extracted paper text before/after,
   inspect representative desktop/mobile HTML and PDF pages, and report any unavailable format explicitly.

## Rejected alternatives

- **Linking all papers to external previews:** rejected because it preserves the inconsistent visual and
  navigation experience and leaves availability dependent on third-party rendering.
- **Rewriting all papers into one new manuscript source:** rejected because it creates unnecessary risk of
  substantive edits; existing canonical sources and documents should be transformed minimally.
- **Showing disabled HTML/PDF buttons for absent manuscripts:** rejected because disabled controls imply an
  artifact exists. Profiles should state availability honestly and link only formats that can be opened.

## Verification

- `quarto render pages/studije/<page>.qmd` succeeds for each edited profile.
- No output is scattered outside `docs/`; `docs/` remains populated; `data/` is unchanged.
- Every format link returns/opens the declared type and every author link resolves.
- All rendered Croatian diacritics remain literal UTF-8.
- HTML papers share the DigiKat paper stylesheet; PDFs share the corresponding print design.
- Text extraction/diff checks show no substantive paper-content changes.

## Completion

Completed on 2026-08-06.

- All seven study profiles now carry linked author metadata and one shared format selector.
- All seven papers are published locally as HTML and PDF; the two genuinely available Word documents
  remain published. No newer manuscript was substituted for an older linked version.
- One stylesheet derived from the DigiKat design system governs every standalone HTML paper and every PDF
  printed from it. A pinned, repeatable publisher is available at `scripts/publish_thematic_papers.ps1`.
- Normalized visible-text comparison passed for all seven papers: the publication layer changed no
  manuscript text.
- All seven profiles rendered successfully. The site checker passed across 141 HTML files with no missing
  local targets, broken anchors, or mojibake signatures. All published asset copies match their `docs/`
  mirrors byte-for-byte, and `data/` remained unchanged.
- PDF inspection found 12–22 readable pages per paper, extracted text in every file, and live author/source
  hyperlinks. The anonymized peer-review manuscript remains intentionally unlinked by author identity.
