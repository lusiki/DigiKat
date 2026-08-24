# Site metadata and freshness contract

Status: ratified for Site improvement Run 1  
Applies to: substantial Quarto pages, reports, datasets, and independently shareable research outputs

## Shared site identity

- Site title is `DigiKat`.
- Shared site description is the canonical purpose sentence in `_quarto.yml`.
- Canonical origin is `https://lusiki.github.io/DigiKat/`.
- The existing social card remains the site-wide fallback until a later branding decision replaces it.
- Social-image alternative text must name DigiKat and describe the image's informative content.

## Page fields

Use the following front-matter names for new or substantially revised pages. Existing pages adopt the contract in their assigned implementation run.

| Field | Requirement | Rule |
|---|---|---|
| `title` | Required | Unique, Croatian, sentence case, and suitable for a browser tab. |
| `subtitle` | Required for substantial pages | Adds scope or interpretation and does not repeat the title. |
| `description` | Required | One evidence-led sentence suitable for search and social previews. |
| `date` | Required for publications | Original publication date in ISO source form. Do not use it for the observation period. |
| `date-modified` | Required after a substantive revision | Last editorial or analytical revision date. Cosmetic rebuilds do not change it. |
| `data-cutoff` | Required when results depend on changing data | Latest included observation date, separate from publication and modification dates. |
| `status` | Required | One value from the ratified status vocabulary. |
| `categories` | Required where useful | Controlled project or output labels in sentence case. Do not use decorative tags. |
| `image` and `image-alt` | Required for independently shared outputs | Use a relevant image and meaningful alternative text. Do not reuse a generic card for record-specific pages. |
| `schema-type` | Required for major outputs | One of the types below. This project field drives later page-level JSON-LD work. |

`canonical-url: true` remains a shared Quarto setting. Page authors must not hand-write canonical URLs unless a publication deliberately lives outside the Quarto route.

## Freshness strip

Display only fields relevant to the page. Keep the labels exactly as follows.

- **Objavljeno** maps to the publication date.
- **Ažurirano** maps to the last substantive revision.
- **Podaci zaključno s** maps to the observation cutoff.
- **Status** maps to the ratified status value.

The project period, observation period, report year, publication date, and data cutoff are separate concepts and must never be collapsed into one date label.

## Schema.org types

| Output | Type |
|---|---|
| Site-wide project identity | `ResearchProject` and `WebSite` |
| Official corpus and public data artifacts | `Dataset` |
| Annual review, bespoke report, and thematic study | `ScholarlyArticle` or `Report` when supported by the emitter |
| Research or catalogue overview | `CollectionPage` |
| Methodology and project information | `WebPage` |
| Individual source profile | `ProfilePage` only when the page clearly identifies its subject and provenance. Otherwise use `WebPage`. |

Every major output must expose a title, description, URL, in-language value, publication or modification date where known, creator or publisher, licence, and image only when a valid image exists.

## Citation block

Major datasets, reports, and studies use the `.citation-block` component and include:

1. recommended citation;
2. permanent URL;
3. version or publication date;
4. licence;
5. machine-readable citation when available.

Do not invent a DOI or permanent identifier. If the stable identifier is the project URL, state that plainly.

## Review rules

- Metadata must describe the page that was rendered, not the project in the abstract.
- A detail page must not inherit an unrelated preview image.
- Publication and modification dates must not be inferred from the data cutoff.
- Status changes require editorial review. A successful build alone does not make a page `Stabilno izdanje`.
- Metadata and the visible freshness strip must agree.
