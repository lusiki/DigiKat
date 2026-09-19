# Findings presentation and publication resources

Author: [Luka Šikić](https://www.lukasikic.info/).

The presentation contains 15 slides and 12 findings, combining the broad media
overview and the separate textual report. HTML has a reading view, a keyboard
slide mode, mobile layout, source links and text alternatives for word clouds.
The matching PDF uses 16:9 pages, selectable text and linked authorship.

`slides.json` is the editable narrative. `style.css` controls the visual design,
`presentation.js` supplies optional navigation, and `build.py` reads the verified
public aggregate tables. HTML is self-contained and also directly editable.
Colours and Georgia/Calibri typography follow the reference report. Browser font
fallbacks are provided; the reviewed PDF embeds the Windows fonts.

From the repository root:

```powershell
python -X utf8 studies/demokrscanstvo-barometar/presentation/build.py
node studies/demokrscanstvo-barometar/presentation/render.mjs
python -X utf8 studies/demokrscanstvo-barometar/presentation/publish_assets.py
```

Render the three PDFs with Poppler and inspect every page before running
`verify.py` and recording visual approval. Render the barometer page from the
repository root to copy public assets into `docs/`. `publish_assets.py` prepares
resources but does not deploy. Publication uses the existing main/docs Pages site.

`package.py` collects the public PDFs/HTML, editable sources, aggregate inputs,
website introduction and three findings, with internal verification kept in a
separate directory. The portable slide builder rebuilds HTML from those aggregate
inputs; the text report builder also reproduces its PDF. The overview's editable
Python source is supplied with its existing project-based input requirements.

No source article bodies, row-level corpus exports or private research files are
included. The original analysis and technical editions remain local and unchanged.
