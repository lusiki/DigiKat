# Conference carousel design preview

Requested scope: create a separate version for the author's review before deciding
whether to adopt it. Do not publish, replace the live carousel or change the home
page in this pass.

1. Use the existing 18-slide HTML carousel as the content source. Preserve lecture
   title, author, slide order, all findings, figures, caveats and source links.
2. Extract the original flag photograph from the supplied conference poster PDF.
   Borrow deep navy and soft gold, keeping the existing Georgia/Calibri typography,
   warm paper, spacious analytical layouts and dark-slide rhythm.
3. Establish the conference/lecture hierarchy on the cover. Use the title actually
   printed on the poster, “Izazovi i budućnost demokršćanstva u Hrvatskoj i Europi”,
   and its date and venue. Keep the photograph strongest on the cover, subdued on
   the closing slide and absent from the analytical reading area.
4. Deliver standalone preview HTML and PDF in output/conference-carousel. Reuse
   the existing browser renderer with optional output arguments; preserve defaults.
5. Check all slides visually, document geometry, mobile widths, keyboard controls,
   accessibility, PDF links/fonts and unchanged analytical text. Retain local
   provenance hashes for the poster and original carousel.

No analytical inputs, published assets or Quarto pages require modification.

## Result

Completed as a local HTML/PDF alternative under `output/conference-carousel/`.
Reviewed the full 18-page rendered sequence and the opening, analytical and closing
layouts at full size. Browser checks pass for desktop fit, four mobile widths,
keyboard navigation and WCAG A/AA rules. Final verification confirms that all 18
analytical bodies and all finding headings match the original, the PDF retains
34 links and embedded Georgia/Calibri fonts, and original HTML/PDF hashes remain
unchanged. No publication or homepage change was made.

Author revision: remove pinkish warmth. Replaced peach/bronze-leaning accents
with muted yellow gold and dark olive gold, and warmed ivory with cool neutral
white. The layout, image, content and preview-only scope remain the same.

## Approved publication

The author approved the latest neutral-white/yellow-gold version and explicitly
requested replacement of the existing carousel, commit and push. Integrate the
approved theme into the primary builder using a tracked copy of the original
poster photograph. Compare generated HTML with the approved preview, preserving
all content and existing public URLs. Rebuild PDF, cover and metadata, render the
site, check the carousel and affected page, stage only task files, commit and push
to main, then verify the deployed artifact. No unrelated working changes belong
in this commit.

Publication checks completed: all 18 production PDF pages are pixel-identical to
the approved preview; production HTML differs only in the stable PDF filename.
The 116-page full Quarto render and focused page render pass. The 1200px thumbnail
uses WebP quality 74 to keep the page within its existing weight limit. Site
quality checks pass for 127 active pages; link checks pass for 140 HTML files;
the affected page passes eight viewport/accessibility checks. Carousel navigation,
four mobile widths, numerical evidence, embedded fonts and PDF links pass.

The full render also changed unrelated generated pages. Automatic approval review
rejected broad cleanup, so these changes remain unstaged. A separately approved,
absence-guarded restoration recovered only four missing tracked CSS dependencies
for frozen studies. No data changed. The commit includes only carousel source,
its four public assets in both source and docs, and this plan.
