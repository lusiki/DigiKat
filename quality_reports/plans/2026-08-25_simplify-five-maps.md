# Simplify the five analytical maps

## Goal

Simplify the reader-facing Croatian prose in the five analytical maps under `pages/mapa/`. Remove every reader-visible occurrence of `u 60 sekundi` and make the text read as short, natural, connected prose.

## Scope

- `pages/mapa/mapa.qmd`
- `pages/mapa/evolucija.qmd`
- `pages/mapa/mapa_stats.qmd`
- `pages/mapa/diskurs.qmd`
- `pages/mapa/događaji.qmd`

## Approach

1. Inventory reader-facing prose and identify long, technical, or mechanically structured passages.
2. Rewrite in plain Croatian while preserving all claims, calculated values, links, citations, Quarto syntax, and analytical limitations.
3. Remove colons, semicolons, and em dashes from running prose. Preserve required punctuation in YAML, code, captions, ranges, and structural syntax.
4. Remove the words `u 60 sekundi` from all five summary labels.
5. Run targeted text checks, structural checks, and a separate Quarto render of every touched page.

## Rationale

The maps already contain the right evidence and structure, but some sentences carry too many qualifications or use technical phrasing where a direct sentence would be clearer. The rewrite should improve flow without weakening methodological caution.

## Rejected alternatives

- Rebuilding the pages or changing their visual structure. The request concerns language, not layout.
- Removing caveats to make the text shorter. The caveats are part of the analytical meaning and will be restated more simply.
- Editing generated files under `docs/` by hand. Rendered output will be refreshed only through Quarto.
