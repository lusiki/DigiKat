# Public edition

This separate fourteen-page Croatian PDF implements the author's September 19,
2026 request for a substantive report for a general audience. It preserves the
teal/copper, Georgia/Calibri visual approach of the original analytical edition.

The PDF uses publication counts consistently and describes the selected material.
It includes a plain-language source explanation, expanded monthly portraits,
thematic charts, attributed examples and discussion of political identity, social
principles, voices and European affairs. It does not contain operational status,
audit logs, validation notices, archive-change explanations, deduplication units,
route comparisons or sensitivity/model appendices. No trend in public opinion,
audience reach or causal political effect is asserted. Topic shares remain shares
of the existing computer-grouped material; no new human-coded prevalence is claimed.

The full technical edition and its verified reproducibility package remain intact.
Technical provenance and internal claim sources for this edition live alongside
the builder output, never as appendices to the public PDF. The original data and
website are not changed by these scripts.

## Rebuild and check

From the repository root with Python and the installed PDF/plot dependencies:

```powershell
python -X utf8 studies/demokrscanstvo-barometar/public-report/build.py
& 'tmp/pdfs/poppler/poppler-26.09.0/Library/bin/pdftoppm.exe' -r 115 -png 'output/pdf/demokrscanstvo-u-medijskom-prostoru.pdf' 'tmp/pdfs/demokrscanstvo-public/page'
python -X utf8 studies/demokrscanstvo-barometar/public-report/verify.py
```

The HTML edition is generated from the same page content after `build.py` has
written the chart SVGs. It re-runs `make_pages()` with HTML emitters in place of
the ReportLab helpers, so its words and numbers cannot drift from the PDF:

```powershell
python -X utf8 studies/demokrscanstvo-barometar/public-report/build_html.py
Copy-Item output/demokrscanstvo-public/v2/demokrscanstvo-u-medijskom-prostoru.html assets/izvjestaji/
```

Inspect every rendered page, especially charts, Croatian characters, spacing and
full labels. Use `verify.py --visual-reviewed` only after that inspection. The
verifier reconciles all retained numeric series independently to the original
public monthly thematic release, checks source hashes and original-artifact
preservation, and checks the delivered PDF's geometry and removed terminology.

Final PDF: `output/pdf/demokrscanstvo-u-medijskom-prostoru.pdf`.
Supporting output: `output/demokrscanstvo-public/v2/`.
