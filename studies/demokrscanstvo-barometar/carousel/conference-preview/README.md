# Conference design preview

Local alternative requested on 22 September 2026. It does not replace or publish
the current carousel. The 18-slide source is the approved HTML under
`assets/izvjestaji/`; all analytical content remains byte-for-byte identical.

The author dislikes pink. The revised palette uses neutral cool white and muted
yellow gold, with darker olive gold for legibility on white. Avoid pink, peach
and copper tones in further revisions of this design.

The supplied conference poster contributes its original flag photograph, navy
and gold palette, exact printed event title, date and venue. The base carousel
contributes its Georgia/Calibri typography, warm paper, native charts, structure,
source links, keyboard controls and responsive reading layout. The poster logos
and QR codes are not part of the lecture artwork. The existing research QR code
continues to link to the barometer.

From the repository root:

```powershell
python -X utf8 studies/demokrscanstvo-barometar/carousel/conference-preview/build.py
node studies/demokrscanstvo-barometar/carousel/render.mjs output/conference-carousel demokrscanske-vrijednosti-konferencijska-verzija tmp/pdfs/conference-carousel
python -X utf8 studies/demokrscanstvo-barometar/carousel/conference-preview/finalize.py
```

Use `build.py --poster <path>` to supply the original PDF on another machine.
Final HTML and PDF are under `output/conference-carousel/`. The HTML embeds the
photograph and styles; it works as a local file without a server. Keep the PDF
beside it for the download button. Fonts retain the base carousel's system-font
behavior in HTML and are embedded in the PDF.

The renderer checks all 18 slides for content/footer overlap, keyboard navigation,
WCAG A/AA violations and responsive fit at 320, 390, 768 and 1024 px. Finalization
checks exact analytical-body preservation, PDF text, embedded fonts, page bounds,
links and the integrity of the original assets. Inspect all 18 rendered PDF pages
in `tmp/pdfs/conference-carousel/` before sharing. The homepage remains a later
decision after the author reviews this design.
