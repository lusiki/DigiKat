# Review of the PDF-first analytical protocol

Date: 2026-09-19. Scope: planning and read-only feasibility audit; no new empirical
model fitting, inclusion changes or website changes.

## Delivered artifacts

- Source: `plans/2026-09-19_demokrscanstvo-pdf-protocol.md`.
- Reproducible PDF renderer: `plans/render_demokrscanstvo_protocol.py`.
- Output: `../output/pdf/demokrscanstvo-plan-analize.pdf`, 16 pages in Croatian.
- Earlier analytical-story proposal now points to this revised protocol.

## Data and implementation checks

- All 12 files listed in the two public release manifests match their SHA256
  checksums. Monthly included counts sum to 2,306, with 2,290 stored-body matches
  and 16 snippet matches. No included title-only records.
- Platform counts in the 2025 feasibility table were recalculated from the
  monthly aggregate and match: web 212, print 41, TV 17, Facebook 14, X 11,
  Reddit 7, TikTok 2, forums 2, YouTube 2, radio 1; other platforms zero.
- Existing thematic release has 1,731 distinct concatenated contexts, not
  independent stories. The private cache contains 2,306 rows; whitespace word
  length has median 48 and range 2 to 1,099, with 131 rows of at most 20 words.
- Private candidate schema has source_name, title and stored text but no
  standalone author or URL fields. Cached thematic annotations retain only
  context_id and selected lemmas, not the sentence/offset/negation structure
  required for the proposed contextual associations.
- Engine review confirms the A1/default substantive-register issue, default
  domestic geography, and heuristic speaker attribution. New interpretations
  require a separate positive-evidence coding layer.
- Data collection break and selection effects are part of the comparison
  protocol. Thresholds, pilot sizes and effort ranges are proposed design
  decisions, not empirical findings or universally validated standards.

## Method and interpretation review

The plan separates publications, original passages, concatenated contexts,
near-duplicate text groups and shared quotations. It defines the units and
denominators for topic shares, lexical associations and principle applications.
It separates development from held-out evaluation; independent human coding is
prospective, not claimed as completed. Each module has a feasible fallback.
Potential findings are conditional and paired with alternative explanations.

The revision explicitly delivers a standalone analytical report before the
user selects any modules for barometer integration. The present PDF is the
protocol, not that future empirical report.

## PDF quality checks

- Rendered all 16 pages with Poppler 26.09.0 and inspected every page visually.
  Re-rendered and inspected page 11 after its final substantive revision.
- Checked text extraction, Croatian characters, 16 outline entries, 5 source
  links and TrueType font embedding. No replacement characters or text outside
  the page were detected. No clipped or overlapping elements found visually.
- Body font is 11.2 pt, with 11.1 pt on the dense platform-inventory page.
- Final SHA256:
  `a179e03737a4a9eb2107246727f948bc6890e7cb84b991ed066e32fb1d2cef60`.

This records an assistant-led source/code and editorial review. It is not
independent academic peer review or validation of the future analytical labels.
