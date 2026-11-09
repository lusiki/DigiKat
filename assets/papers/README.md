# Thematic paper assets

Every paper linked from **Tematska istraživanja** uses `digikat-paper.css`, which extends the DigiKat
website design system to standalone manuscripts and their print/PDF editions. Run the publisher from the
repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish_thematic_papers.ps1
```

The publisher does not rerun an analysis or alter manuscript prose. It takes the exact HTML version
linked by the study profile, adds common navigation and author links, repairs declared format links, and
prints the styled document to PDF. Remote inputs are pinned to immutable Git commits. A local, newly
rendered church-framing manuscript can be supplied with `-ChurchFramingSourceHtml` and
`-ChurchFramingSourceDocx` while its source revision is being prepared for publication.

| Local stem | Canonical HTML input | Additional source format |
|---|---|---|
| `trzista-paznje` | `Mapping-Catholic-Digital-Media-Space` commit `2deb813`, v7 | — |
| `memorijalni-okvir` | `Memorijalni-okvir` commit `78ccc07`, `manuscript_one` | Word |
| `katolicki-influenceri` | official-corpus rerun in `studies/catholic-influencers`, recovered from `Katolicki_Influenceri` commit `fa34ff5` | Word |
| `redovnicke-zajednice` | `Redovnicke-zajednice` commit `74f1a1a`, `analysis_v3` | — |
| `crkva-i-dezinformacije` | author-selected published `03_framing_paper_2.html`, `Church-and-dezinfo` commit `1475dd9` | Word |
| `sadrzaj-ili-identitet` | author-selected published `rsp_paper_revised.html`, same commit | Word |
| `inflation-information-delayed-repricing` | local checked output `PAPER_EMIP_v2_full.html` | Word |
| `socijalni-nauk-i-gospodarstvo` | local checked output `PAPER_RSP_v2.html` | — |
| `katolicko-obrazovanje-i-stepinac` | local checked output `catholic-education-paper-v2.html` | Word |

On 9 November 2026 the author selected the two linked upstream HTML manuscripts
for publication. These editions are dated 14 April 2026 and are pinned in
`church-and-dezinfo-release.json`. They are not the later local corpus rerun.
`crkva-i-dezinformacije-data/` is retained as the previous rerun's provenance;
it is not an input to the currently selected framing manuscript or study profile.

The Word editions are converted from the frozen rendered HTML, including its
computed tables and figures. PDFs are rendered from those Word editions. No
analysis is rerun and no unpublished local results are substituted. Browser
controls and folded R code are omitted from Word/PDF. Doubled TeX escaping is
corrected in the format conversion without changing the formulas.

To rebuild, download the source files listed in the release manifest into
`tmp/church-papers-publication/`, saving the manifest's `source` object as
`source-manifest.json`. Run `scripts/format_linked_church_papers.ps1` (Python
with lxml and python-docx, plus Quarto's Pandoc). Render both DOCX files to PDF
with LibreOffice and inspect every page. Run
`node scripts/render_linked_paper_math.cjs <KaTeX-package-directory>` (KaTeX 0.19.1)
to embed rendered formulas and font assets in the `.browser.html` files. Publish the HTML and
DOCX files with `scripts/publish_thematic_papers.ps1 -SkipPdf`, selecting only
these two stems and supplying the ChurchFramingSourceHtml/Docx and
ChristianDemocracySourceHtml/Docx arguments. Install the verified PDFs beside
them. Render the index and both study profiles from the repository root and
verify all six downloads in `docs/assets/papers/`.
