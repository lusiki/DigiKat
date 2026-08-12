// moral-economy — TYPST STYLE FOR THE RSP MANUSCRIPT PDF.
//
// Injected into the Typst preamble by 28_render_paper.R (format: typst, include-in-header).
// It styles only the typeset artefact. The manuscript itself stays plain markdown, so nothing
// here can change a number, a table or a word of the text.
//
// The build copy rewrites three things before Quarto sees it, and the rules below are written for
// that shape:
//   * a table or figure caption arrives as a LEVEL-3 HEADING (markdown "####", shifted by one),
//   * a source note arrives as a BLOCK QUOTE,
//   * a thousands separator arrives as U+00A0, which Typst sets as a fixed-width tie.
// Pandoc's Typst writer drops a fenced div's class, so those two element types are the only
// handles a show rule can actually reach.

#set par(justify: true, leading: 0.68em)
#set block(spacing: 1.05em)
// Hyphenation is off at document level and switched back on by the first line of the body, which
// 28_render_paper.R injects. Everything before that line is the title block, and hyphenating it is
// how the subtitle came to read "1 Jan-/uary 2021" across the first two lines of page one.
#set text(hyphenate: false)

// Section headings: the running text is serif and the structure is sans, so a reader can find a
// section by its shape rather than by reading it.
#show heading.where(level: 1): it => block(
  above: 1.9em, below: 0.85em,
  text(font: "Segoe UI", weight: 600, size: 13pt, fill: rgb("#7a2e1e"), it.body),
)
#show heading.where(level: 2): it => block(
  above: 1.5em, below: 0.7em,
  text(font: "Segoe UI", weight: 600, size: 11pt, fill: rgb("#2b2b2b"), it.body),
)

// Level 3 is a table or figure caption and nothing else. `sticky: true` glues it to the block that
// follows, which is what stops a caption stranding at the foot of a page while its table starts the
// next one. The number is set in the heading colour so a reader scanning for "Table 3" finds it.
#show heading.where(level: 3): it => block(
  above: 1.5em, below: 0.45em, sticky: true, width: 100%,
  {
    set par(justify: false, leading: 0.5em)
    text(font: "Segoe UI", weight: 400, size: 9pt, fill: rgb("#1f1f1f"), it.body)
  },
)

// Source notes. Small, grey, unjustified and set to the same measure as the table above them, so a
// note reads as apparatus rather than as a second paragraph of argument.
#show quote.where(block: true): it => block(
  above: 0.55em, below: 1.9em, width: 100%,
  {
    set par(justify: false, leading: 0.52em, hanging-indent: 0pt)
    set text(font: "Segoe UI", size: 8pt, fill: rgb("#5a5a5a"), style: "normal")
    it.body
  },
)

// Tables carry booktabs rules only, no vertical lines and no full grid. Body text is set down
// because Table 4 and Table A1 carry seven and six columns on A4; the horizontal inset is what
// keeps two right-aligned numeric columns from touching, which is how "No era-assigned" and
// "Mixed" used to print as one word.
#show table: set text(size: 7.6pt, font: "Segoe UI", hyphenate: false)
#show table: set par(justify: false, leading: 0.5em)
#set table(
  stroke: (_, y) => (
    top: if y == 0 { 0.9pt + rgb("#333333") } else if y == 1 { 0.5pt + rgb("#666666") } else { 0pt },
    bottom: 0pt,
  ),
  inset: (x: 6.5pt, y: 3.8pt),
  fill: (_, y) => if calc.odd(y) and y > 1 { rgb("#f7f5f1") } else { none },
)
#show table.cell.where(y: 0): set text(weight: 600)

// A table that comfortably fits a page should never be split by one. Tables 3, 4 and A1 are long
// enough that forbidding a break would push most of a page out; the four short ones are not, and a
// three-row table broken across a page break is the clearest sign of an unfinished document. The
// cell count is the only size signal available before layout, so it is the one used.
#show table: it => if it.children.len() <= 40 { block(breakable: false, it) } else { it }

// Figures are placed exactly where they appear and carry no Typst caption of their own: their
// words are the heading above and the block quote below, so a figure title and a table title are
// the same object on the page.
#set figure(gap: 0.7em)
#show figure: set block(above: 1.1em, below: 0.6em)
#show figure.caption: set text(size: 8.5pt, font: "Segoe UI", fill: rgb("#555555"))

// The reference list is a bullet list in markdown, and it is the only list in the manuscript that
// is not numbered. Bullets and justification are both wrong for it: a marker turns apparatus into
// argument, and justifying a line that holds a long DOI opens word gaps a reader trips over. Each
// entry becomes a hanging-indented block instead.
// `set par(hanging-indent: …)` inside a block is silently ignored here — the paragraph is created
// by the block and does not pick the setting up. The function form does apply, and is verifiable:
// the second line of every entry starts 1,5em in from the first.
#show list: it => block(above: 0.9em, below: 0.9em, {
  set text(size: 9.3pt)
  for child in it.children {
    block(spacing: 0.62em, par(hanging-indent: 1.5em, justify: false, leading: 0.55em, child.body))
  }
})
