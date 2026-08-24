# DigiKat release checklist

Status: ratified for Site improvement Run 6

Owner: project editor

Applies to: the active Quarto site, the source catalogue, **Moj medij**, analytical maps and long-form reports

## Automated release gate

Run from the repository root in the locked R and Node environments.

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' tests/run_tests.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' tests/check_run6_site_quality.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' R/check_sources.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' R/check_disclosure.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' R/00_setup.R
quarto render
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' R/check_site_links.R
npm ci
npm run check:site
npm run check:browser
git diff --check
```

The browser check uses Chrome and the pinned `axe-core` package. It covers 320, 375, 390, 768 and 1024 pixels. It fails on page-level horizontal overflow, serious or critical WCAG 2.2 A/AA findings, browser-console or network errors, missing focus indication, reduced-motion regressions, or a broken keyboard path through **Moj medij**.

## Page-weight budgets

Budgets count each HTML document plus the local stylesheets, scripts and primary images it requests. Shared browser caching makes later navigations lighter, but the uncached figure is the release guard.

| Page class | Budget | Representative surface |
|---|---:|---|
| Standard page or source profile | 1.500 kB | project, methodology, catalogue profile |
| Source network | 2.000 kB | interactive network of sources and relationships |
| Analytical map | 8.000 kB | map HTML plus vector figures |
| **Moj medij** | 2.000 kB | embedded aggregate search data and interface |
| Overview | 2.000 kB | Croatian and English governed-workflow pages |
| Long-form report | 5.000 kB | annual review and bespoke report |

The static check prints the measured maximum for every class. A budget increase needs a documented reason and must not be used to conceal an accidentally embedded library, base64 image or duplicate dataset.

## Manual review matrix

Review the representative pages in `SITE_IMPROVEMENT_PLAN.md` after the automated gate passes. Confirm:

- the site still reads as an academic research publication rather than a commercial product;
- Croatian diacritics, sentence case, dates and controlled terms are intact;
- the project period, observation period, report year, publication date and data cutoff remain distinct;
- chart summaries and tables communicate the same result as the visual figure;
- keyboard focus follows the visible reading order and no focus is trapped;
- narrow layouts preserve navigation, publication links, the official-corpus panel, map evidence, report navigation and the footer;
- social previews describe the page being shared, while source profiles without a specific image expose no generic record image;
- print and PDF editions retain citations, figures and page structure.

Automated accessibility checks cannot establish full WCAG conformance. Colour meaning, chart interpretation, reading order, link purpose in context and the scholarly adequacy of alternative summaries remain manual editorial decisions.
