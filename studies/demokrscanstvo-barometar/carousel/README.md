# Christian-democracy carousel

An 18-slide Croatian carousel, authorized by the author on 2026-09-22, replaces
the earlier 15-slide findings presentation. It introduces DigiKat and its data,
presents ten selected findings, and links to both reports and public resources.
The exact author-requested title and byline are retained on the cover.

The author approved the conference design for replacement and publication on
2026-09-22. The `conference/` overlay preserves the reviewed 18-slide content and
adds the exact conference title, date and original flag photograph from the
supplied poster. Its approved palette is navy, neutral white and muted yellow
gold. The author dislikes pink; avoid pink, peach and copper accents. The tracked
photograph and provenance hashes make the build independent of the desktop PDF.
All public URLs and filenames remain stable when this edition is published.

The author subsequently replaced slides 10–15 with exploratory data views: selected
public figures, leading web sources, monthly counts, peak months, peak-month topics
and the busiest day. `prepare_exploration.py` reads the frozen private records and
writes only aggregates to `assets/izvjestaji/demokrscanske-vrijednosti-karusel-podaci.json`.
The normal build requires only that public file. To recalculate it, run
`python -X utf8 studies/demokrscanstvo-barometar/carousel/prepare_exploration.py`
on the pipeline machine. Matching audits remain in ignored `output/`.

These six slides cover the 1,811 web articles in the existing 2,306-record
collection. The six named figures are an explicit editorial selection, not an
exhaustive NER ranking or a classification of Christian-democratic supporters.
Counts match full given name and surname (including Croatian case endings) in
the stored title/body, once per article. They can miss surname-only mentions.
The aggregate records exact patterns, denominators, input hashes and limitations.
Monthly and topic counts reconcile to the existing public releases.

The title refers to Catholic media. Slide 3 explicitly states that the findings
from the reports cover the broader media discussion, including general media.
They are not a new Catholic-publisher subset analysis. The official corpus count
comes from the versioned corpus manifest, not the accumulator in the older README.

## Build and review

From the repository root, using Python with ReportLab, PyMuPDF, Pillow and pypdf,
Node 24, the installed axe-core package and headless Chrome:

```powershell
python -X utf8 studies/demokrscanstvo-barometar/carousel/build.py
node studies/demokrscanstvo-barometar/carousel/render.mjs
python -X utf8 studies/demokrscanstvo-barometar/carousel/publish.py
python -X utf8 studies/demokrscanstvo-barometar/carousel/verify.py
```

The semantic, self-contained HTML is the shared source for reading, keyboard
presentation and PDF. Charts and text are native HTML/CSS, not screenshots.
The PDF embeds the Georgia/Calibri reference fonts and retains selectable text,
links, document structure and bookmarks. No PDF/UA conformance is claimed.
The QR code opens the public Christian-democracy research page.

`build.py` reads only tracked public evidence. It records input hashes and numeric
claims under `output/demokrscanstvo-carousel/`. `render.mjs` checks desktop fit,
WCAG A/AA rules, keyboard navigation and widths 320, 390, 768 and 1024. Set
`CHROME_PATH` if Chrome is installed outside its Windows default location.

`publish.py` prepares the PDF, HTML, cover and checksummed metadata under
`assets/izvjestaji/`, renders every PDF page under `tmp/pdfs/demokrscanstvo-carousel/`,
and removes only the four named assets of the retired public presentation from
the source and generated resource directories. Historical authoring source remains.

Inspect all 18 final PDF PNGs. The verifier independently checks key report
numbers, title/byline, scope note, embedded fonts, links and publication hashes.
Then render the research page through Quarto and run the site link and browser
checks. Normally also render the full site before publishing. For this revision,
automatic approval review required the focused render to protect unrelated dirty
generated files. These scripts never rebuild corpus data or publish Git.
