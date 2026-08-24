# Shared academic design system

Status: ratified for Site improvement Run 1  
Implementation: `assets/css/custom.scss` and `R/theme_digikat.R`

The shared system is quiet, evidence-led, and suitable for research publication. Components use hairline borders, warm paper, white reading surfaces, petrol accents, restrained semantic colour, and shadows only where they clarify layering.

## Tokens

The SCSS exposes stable CSS custom properties for colour, typography, spacing, radii, shadows, focus, and chart identity. Platform and semantic chart colours mirror `R/theme_digikat.R`. Later reports may consume the `--dk-*` variables without copying literal values.

Typography roles are fixed.

- Source Serif 4 for titles and editorial headings.
- Source Sans 3 for prose and interface labels.
- IBM Plex Mono for metadata, status, small labels, and tabular values.

## Components

| Purpose | Class contract |
|---|---|
| 60-second summary | `.summary-60`, `.summary-60__label` |
| Publication records | `.publication-list`, `.publication-entry`, `.publication-entry__title`, `.publication-entry__meta`, `.publication-entry__finding`, `.publication-entry__links` |
| Freshness and status | `.freshness-strip`, `.freshness-strip__item`, `.freshness-strip__label`, `.freshness-strip__value`, `.status` plus one status modifier |
| Citation | `.citation-block`, `.citation-block__label`, `.citation-block__text` |
| Figure presentation | `.figure-card`, `.figure-card__takeaway`, `.figure-card__meta` |
| Downloads | `.download-group` |
| Expandable references | `details.reference-section`, `.reference-section__content`, `.reference-table` |

Status modifiers are `.status--working`, `.status--preliminary`, `.status--updating`, `.status--stable`, and `.status--archived`.

## Authoring rules

- Use a 60-second summary only on a substantial page. It is an editorial abstract, not a promotional hero.
- A publication entry represents one citable output and includes one finding, date, status, and only the formats that exist.
- Keep essential findings and cautions outside expandable reference sections.
- Put long definitions, variable dictionaries, reproduction details, and wide reference tables inside expandable sections when this improves scanning.
- A figure card begins with a takeaway and ends with a real caption, accessible summary, and download group when files exist.
- Components must not rely on colour alone to convey status or meaning.
- Do not place repeated calls to action, decorative badges, gradients, or dashboard-style chrome inside these components.

## Accessibility and motion

All interactive elements receive a visible petrol focus ring through `:focus-visible`. The shared reduced-motion rule removes nonessential animation and smooth scrolling when the user requests reduced motion. Expandable references use native `details` and `summary` elements so keyboard and screen-reader behaviour remains available without custom JavaScript.

## Print

Print output removes interactive navigation and shadows, keeps borders in neutral ink, expands reference sections through the document source when a complete print reference is required, and avoids splitting publication, citation, summary, and figure components across pages where the browser supports it.
