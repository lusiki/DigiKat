// Visual system reverse-engineered from "Glasna tema, tiha većina" (Merkat Media, 2026):
// dark act dividers, cream spreads, one finding per page, green = how much, red = who speaks.
#let navy   = rgb("#121a24")
#let cream  = rgb("#f6f2ea")
#let cream2 = rgb("#efe8db")
#let ink    = rgb("#141b24")
#let muted  = rgb("#646a72")
#let rulec  = rgb("#b8b2a6")
#let teal   = rgb("#0b8a7f")
#let teal-l = rgb("#a8d4ce")
#let red    = rgb("#e4471f")
#let red-l  = rgb("#f2a48e")
#let stone  = rgb("#cbc6ba")
#let stone-l = rgb("#e2ddd2")
#let blue   = rgb("#2353a6")
#let blue-l = rgb("#9fb2d6")
#let paper-dark-text = rgb("#f3efe6")

#let serif = ("Palatino Linotype", "Book Antiqua")
#let sans  = ("Segoe UI", "Calibri")

#let RUN = "TKO TUMAČI VJERU?"

#let progress(n, label) = {
  if n == none { return }
  let cells = range(1, 11).map(i => box(width: 5.5pt, height: 5.5pt,
    fill: if i == n { red } else if i < n { rgb("#8a8f96") } else { stone }))
  stack(dir: ltr, spacing: 1.6pt, ..cells)
  h(8pt)
  text(font: sans, size: 7.6pt, fill: muted)[Zaključak #n od 10 · #label]
}

#let spread(section: "", finding: none, flabel: "", label: none, bg: cream, body) = page(
  fill: bg,
  margin: (top: 20mm, bottom: 20mm, left: 22mm, right: 22mm),
  header: context {
    set text(font: sans, size: 7.4pt, fill: muted, tracking: 0.9pt, weight: "semibold")
    grid(columns: (1fr, auto), RUN, upper(section))
  },
  footer: context {
    set text(font: sans, size: 7.6pt, fill: muted)
    grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      if finding != none { progress(finding, flabel) } else if label != none {
        stack(dir: ltr, spacing: 1.6pt, ..range(10).map(i => box(width: 5.5pt, height: 5.5pt, fill: rgb("#8a8f96"))))
        h(8pt); label } else [],
      counter(page).display())
  },
  body)

#let kicker(t) = text(font: sans, size: 8.6pt, weight: "bold", fill: red, tracking: 1pt, upper(t))
#let headline(t) = block(above: 7pt, below: 6pt, text(font: serif, size: 26pt, weight: "bold", fill: ink, hyphenate: false, par(leading: 0.38em, t)))
#let deck(t) = block(below: 14pt, text(font: sans, size: 11pt, fill: ink, par(leading: 0.55em, t)))
#let prose(t) = text(font: sans, size: 9.2pt, fill: ink, par(leading: 0.62em, t))
#let bigprose(t) = text(font: serif, size: 13pt, fill: ink, par(leading: 0.55em, t))
#let cols2(a, b) = block(above: 14pt, grid(columns: (1fr, 1fr), column-gutter: 22pt, prose(a), prose(b)))
#let note(t) = block(above: 10pt, text(font: sans, size: 7.4pt, fill: muted, par(leading: 0.55em, t)))
#let source(t) = place(bottom + left, dy: -2pt, block(width: 100%, text(font: sans, size: 7.2pt, fill: muted, par(leading: 0.55em, t))))
#let eyebrow(t) = text(font: sans, size: 7.6pt, weight: "bold", fill: muted, tracking: 0.9pt, upper(t))
#let hr() = line(length: 100%, stroke: 0.5pt + rulec)
#let tag(t) = text(font: sans, size: 7.4pt, fill: muted, t)

// ---- act divider --------------------------------------------------------------------------------
#let divider(act: "", title: "", number: "", unit: "", text-body: "", footer-label: "", visual: none, numcolor: red) = page(
  fill: navy, margin: (top: 22mm, bottom: 18mm, left: 22mm, right: 22mm), header: none, footer: none, {
  set text(fill: paper-dark-text)
  text(font: sans, size: 7.4pt, weight: "bold", tracking: 1pt, fill: rgb("#a7adb5"), act)
  v(2pt)
  text(font: serif, size: 46pt, title)
  v(1fr)
  grid(columns: (auto, 1fr), column-gutter: 10pt, align: bottom,
    text(font: serif, size: 190pt, fill: numcolor, top-edge: "bounds", bottom-edge: "bounds", number),
    block(inset: (bottom: 4pt), text(font: serif, style: "italic", size: 30pt, par(leading: 0.4em, unit))))
  v(26pt)
  block(width: 78%, text(font: serif, size: 13pt, par(leading: 0.55em, text-body)))
  v(1fr)
  if visual != none { visual }
  v(14pt)
  text(font: sans, size: 7.2pt, weight: "bold", tracking: 1pt, fill: rgb("#a7adb5"), footer-label)
})

// ---- charts --------------------------------------------------------------------------------------
// rows: array of (label, value, display, color, bold, aside)
#let hbars(rows, max: none, width: 9cm, label-w: 4.6cm, bar-h: 11pt, gap: 7pt) = {
  let m = if max == none { calc.max(..rows.map(r => r.at(1))) } else { max }
  grid(columns: (label-w, width + 3.2cm), row-gutter: gap, column-gutter: 8pt, align: (right + horizon, left + horizon),
    ..rows.map(r => (
      text(font: sans, size: 8.6pt, weight: if r.at(4) { "bold" } else { "regular" }, r.at(0)),
      stack(dir: ltr, spacing: 5pt,
        box(width: calc.max(r.at(1) / m * width, 1.2pt), height: bar-h, fill: r.at(3)),
        text(font: sans, size: 8.4pt, weight: if r.at(4) { "bold" } else { "regular" }, r.at(2)),
        if r.len() > 5 and r.at(5) != none { h(4pt); text(font: sans, size: 7.6pt, fill: muted, r.at(5)) })
    )).flatten())
}

// 100 % stacked bar. segs: array of (share, color, label)
#let stackbar(segs, width: 11cm, height: 16pt, min-label: 7) = box(width: width, height: height,
  stack(dir: ltr, ..segs.map(s => box(width: s.at(0) / 100 * width, height: height, fill: s.at(1),
    align(center + horizon, if s.at(0) >= min-label { text(font: sans, size: 7.4pt, fill: white, weight: "bold", s.at(2)) })))))

// Waffle of squares. groups: array of (count, color). cols per row.
#let waffle(groups, cols: 20, size: 9pt, gap: 2.2pt) = {
  let cells = groups.map(g => range(g.at(0)).map(_ => box(width: size, height: size, fill: g.at(1)))).flatten()
  grid(columns: (size,) * cols, gutter: gap, ..cells)
}
#let dots(groups, cols: 15, size: 9pt, gap: 3pt) = {
  // groups: (count, color, filled)
  let cells = groups.map(g => range(g.at(0)).map(_ => circle(radius: size / 2,
    fill: if g.at(2) { g.at(1) } else { none }, stroke: if g.at(2) { none } else { 0.9pt + g.at(1) }))).flatten()
  grid(columns: (size,) * cols, gutter: gap, ..cells)
}

// Dumbbell on a log axis. rows: (name, ring, dot, bold, aside)
#let dumbbell(rows, lo: 10, hi: 50000, width: 9cm, row-h: 13.5pt, ticks: (10, 100, 1000, 10000)) = {
  let x(v) = (calc.log(calc.max(v, lo)) - calc.log(lo)) / (calc.log(hi) - calc.log(lo)) * width
  let axis = box(width: width, height: 10pt, {
    for t in ticks { place(dx: x(t) - 10pt, box(width: 20pt, align(center, text(font: sans, size: 7pt, fill: muted, str(t))))) }
  })
  grid(columns: (4.4cm, width, 2.6cm), row-gutter: 0pt, column-gutter: 8pt, align: (right + horizon, left + horizon, left + horizon),
    ..rows.map(r => (
      text(font: sans, size: 8.2pt, weight: if r.at(3) { "bold" } else { "regular" }, r.at(0)),
      box(width: width, height: row-h, {
        for t in ticks { place(dx: x(t), line(start: (0pt, 0pt), end: (0pt, row-h), stroke: 0.3pt + stone-l)) }
        place(dx: x(r.at(2)), dy: row-h / 2, line(length: calc.max(x(r.at(1)) - x(r.at(2)), 0.1pt), stroke: 0.6pt + rgb("#8a8f96")))
        place(dx: x(r.at(1)) - 3.6pt, dy: row-h / 2 - 3.6pt, circle(radius: 3.6pt, fill: cream, stroke: 0.9pt + ink))
        place(dx: x(r.at(2)) - 3.6pt, dy: row-h / 2 - 3.6pt, circle(radius: 3.6pt, fill: red))
      }),
      text(font: sans, size: 7.4pt, fill: muted, r.at(4)),
    )).flatten(),
    [], axis, [])
}

// Bubble matrix (rows x columns), size ~ value. cells: array of rows; each row (label, sublabel, values, displays)
#let bubbles(cols, rows, maxv: 60, maxr: 9pt, colw: 1.55cm) = {
  grid(columns: (4.2cm,) + (colw,) * cols.len(), row-gutter: 9pt, align: (right + horizon,) + (center + horizon,) * cols.len(),
    [], ..cols.map(c => text(font: sans, size: 7.8pt, fill: muted, c)),
    ..rows.map(r => (
      stack(spacing: 2pt, text(font: sans, size: 8.6pt, r.at(0)), text(font: sans, size: 7pt, fill: muted, r.at(1))),
      ..r.at(2).zip(r.at(3)).map(((v, d)) => stack(dir: ltr, spacing: 3pt,
        box(width: 2 * maxr, height: 2 * maxr, align(center + horizon,
          circle(radius: calc.max(calc.sqrt(v / maxv) * maxr, 1.2pt), fill: red))),
        text(font: sans, size: 7.2pt, d)))
    )).flatten())
}

#let bignum(n, label, color: ink, size: 54pt) = stack(spacing: 7pt,
  text(font: serif, size: size, fill: color, top-edge: "bounds", bottom-edge: "bounds", n), text(font: sans, size: 9pt, fill: ink, label))

#let finding(n, title, tagtext, body) = grid(columns: (1.3cm, 1fr), column-gutter: 6pt, row-gutter: 0pt,
  text(font: serif, size: 24pt, fill: red, str(n)),
  block(below: 9pt, {
    text(font: sans, size: 9.4pt, weight: "bold", title)
    if tagtext != "" { h(6pt); text(font: sans, size: 7.4pt, fill: muted, tagtext) }
    linebreak()
    text(font: serif, size: 10.2pt, par(leading: 0.5em, body))
  }))

#let section-rule(t) = block(above: 8pt, below: 8pt, grid(columns: (auto, 1fr), column-gutter: 8pt, align: horizon,
  text(font: sans, size: 7.6pt, weight: "bold", tracking: 0.9pt, fill: muted, upper(t)), line(length: 100%, stroke: 0.5pt + rulec)))
