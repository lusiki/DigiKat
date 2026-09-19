# Publish the public report on the barometer page

Authorization: the user requests the approved public PDF as a download on the
Medijski barometar demokršćanstva page and authorizes editorial selection of findings.

1. Copy the approved PDF unchanged into the site's existing reports resource path.
   Add a cover preview and generated publication metadata.
2. Add a prominent download block, a hero link and three concise findings. Read
   numeric findings from the existing release, use ordinary Croatian and scope
   them to the report's period. Preserve the interactive page.
3. Render the touched page from the repository root. Check asset hashes, generated
   HTML, working download, accessible links and desktop/mobile layout.
4. Publish only this change and its generated resources. Preserve unrelated work.
   Verify the live page and the exact downloadable PDF after deployment.

No new data analysis, selection changes, master writes or full-site local render
are required. The download is the previously approved PDF, without new editing.

## Implementation and verification

- Added three PDF download links, cover, publication details and three findings.
  Numbers and period are read from the release and report metadata; the render
  verifies the PDF hash and agreement with the release.
- The cover uses lossless WebP (38,180 bytes, identical decoded pixels). The
  rendered page is within the existing 1,500,000-byte resource budget.
- The touched page rendered successfully with Quarto 1.9.38 and R 4.6.0.
- Site quality passed for 127 active HTML pages; browser checks passed at eight
  widths from 320 to 2048 px, including accessibility, keyboard interaction and
  the static fallback. Desktop and mobile report screenshots were inspected.
- Thematic and all-platform rendered-data verifiers passed. The public PDF has
  the same SHA-256 as the approved original. No processed data were changed.
- Publication and live download verification follow the scoped commit.
