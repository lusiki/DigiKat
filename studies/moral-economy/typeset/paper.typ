// moral-economy — TYPST STYLE FOR THE RSP MANUSCRIPT PDF.
//
// Injected into the Typst preamble by 28_render_paper.R (format: typst, include-in-header).
// It styles only the typeset artefact. The manuscript itself stays plain markdown, so nothing
// here can change a number, a table or a word of the text.

#set par(justify: true, leading: 0.68em)
#set block(spacing: 1.05em)
#set text(hyphenate: true)

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

// Tables carry booktabs rules only, no vertical lines and no full grid. Body text is set down to
// 8.5pt because Table 3 and Table A1 carry eight columns on A4.
#show table: set text(size: 8pt, font: "Segoe UI", hyphenate: false)
#show table: set par(justify: false, leading: 0.5em)
#set table(
  stroke: (_, y) => (
    top: if y == 0 { 0.9pt + rgb("#333333") } else if y == 1 { 0.5pt + rgb("#666666") } else { 0pt },
    bottom: 0pt,
  ),
  inset: (x: 5pt, y: 3.6pt),
  fill: (_, y) => if calc.odd(y) and y > 1 { rgb("#f7f5f1") } else { none },
)
#show table.cell.where(y: 0): set text(weight: 600)

// Figure captions are supporting apparatus, so they are smaller, sans and grey.
#show figure.caption: set text(size: 8.5pt, font: "Segoe UI", fill: rgb("#555555"))
#set figure(gap: 0.7em)
