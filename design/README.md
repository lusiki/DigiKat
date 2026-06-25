# DigiKat — Quarto site theme

Design system and theme for the **DigiKat** research site (Croatian Catholic
University). Built on Quarto's `website` project type with the Bootstrap 5
**cosmo** theme, extended by a single SCSS layer.

## Files

```
_quarto.yml          Site config: navbar, footer, format, fonts, grid width
_digikat.scss        The theme — SCSS variable overrides + component CSS
index.qmd            Landing: hero + statistics band + intro
metodologija.qmd     Four-layer framework + actor archetypes + 16 themes
studije.qmd          Five thematic studies
podaci.qmd           Chart frame example + open-data / codebook cards
tim.qmd              Research team
assets/
  digikat-logo.svg   Navbar mark (2×2 grid)
  favicon.svg        Favicon
"DigiKat Design System.dc.html"   Visual styleguide / reference (not part of the site)
```

## Render

```bash
quarto preview      # live
quarto render       # build to _site/
```

## Type & color

- **Source Serif 4** (headings) · **Source Sans 3** (body) · **IBM Plex Mono**
  (data/labels). All carry full Latin Extended-A for Croatian diacritics
  (č ć đ š ž). Loaded via `@import` in the SCSS `scss:uses` block — no local
  font files needed. To self-host, drop woff2 files in `assets/fonts/` and
  swap the `@import` for `@font-face` rules.
- Brand accent **petrol `#0f4c5c`** is reserved — never use it as a data color.
- 16-color **categorical palette** lives in the `$dk-cat` SCSS map and as
  `--dk-cat-t01 … --dk-cat-t16` CSS custom properties, so Plotly / OJS /
  ggiraph can read the exact same colors. Helper classes `.dk-fill-tNN`
  (background) and `.dk-stroke-tNN` (color) are generated for static figures.

## Layout pattern

Designed sections are full-bleed bands. In a `.qmd`:

```markdown
::: {.column-screen}
<section class="dk-section">
<div class="dk-container">
  …content using .dk-* classes…
</div>
</section>
:::
```

`.column-screen` (Quarto) breaks out to the viewport; `.dk-container` re-centers
to the 1180px content width; `.dk-section` adds vertical rhythm + hairline rule.

Component classes: `.dk-hero`, `.dk-stats`, `.dk-layers`/`.dk-layer`,
`.dk-card`(`--actor`), `.dk-theme-chip`, `.dk-chart`, `.dk-person`, `.dk-eyebrow`,
`.dk-grid--2/3/4/themes`, `.dk-status--ok/progress/planned`.

## To finish before launch

- Replace placeholder team names and photos in `tim.qmd`.
- Replace `site-url` and the GitHub link in `_quarto.yml`.
- Wire the **EN** navbar link to a `en/` mirror (or Quarto profiles) once the
  English pages exist; pages set `lang:` in front matter.
- Swap the illustrative chart in `podaci.qmd` for real figures.
