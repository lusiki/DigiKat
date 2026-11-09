// Adapted from theological-voices/typeset/template.typ (source hash in manifest).
// All dimensions are layout constants. Reader-facing values come from the register.
#let navy = rgb("#121a24")
#let cream = rgb("#f6f2ea")
#let cream2 = rgb("#efe8db")
#let ink = rgb("#141b24")
#let muted = rgb("#646a72")
#let rulec = rgb("#b8b2a6")
#let teal = rgb("#0b8a7f")
#let red = rgb("#e4471f")
#let stone = rgb("#cbc6ba")
#let serif = "Palatino Linotype"
#let sans = "Segoe UI"
#let data = json("../output/private/report_data.json")
#let value(id) = text(data.claims.at(id).display)
#let raw(id) = data.claims.at(id).value
#let RUN = "KATOLIČKE TEME U ARHIVU DIGIKAT"

#set page(paper: "a4")
#set text(font: sans, size: 10pt, lang: "hr", fill: ink, fallback: false)
#set par(leading: 0.65em)

#let spread(section: "", tint: false, body) = page(
  fill: if tint { cream2 } else { cream },
  margin: (top: 21mm, bottom: 23mm, left: 22mm, right: 22mm),
  header: context {
    set text(font: sans, size: 7pt, fill: muted, tracking: 0.65pt)
    grid(columns: (1fr, auto), RUN, upper(section))
  },
  footer: context {
    set text(font: sans, size: 7pt, fill: muted)
    grid(columns: (1fr, auto),
      grid(columns: (auto, 1fr), column-gutter: 7pt,
        stack(dir: ltr, spacing: 2pt, ..range(8).map(i => box(width: 5pt, height: 5pt, fill: if i < 3 { teal } else { stone }))),
        [Radno istraživačko izdanje]),
      counter(page).display())
  },
  {
    set text(font: sans, size: 10pt, lang: "hr", fill: ink, fallback: false)
    set par(leading: 0.65em)
    body
  })

#let kicker(t) = text(font: sans, size: 8.3pt, weight: "bold", fill: red, tracking: 0.8pt, upper(t))
#let headline(t) = block(above: 8pt, below: 9pt,
  text(font: serif, size: 27pt, weight: "bold", hyphenate: false, par(leading: 0.3em, t)))
#let deck(t) = block(below: 19pt, text(size: 11pt, par(leading: 0.55em, t)))
#let prose(t) = block(above: 7pt, below: 7pt, text(size: 10pt, par(leading: 0.65em, t)))
#let small(t) = text(size: 8.5pt, par(leading: 0.55em, t))
#let note(t) = block(above: 10pt, text(size: 8.3pt, fill: muted, par(leading: 0.55em, t)))
#let source(t) = place(bottom + left, block(width: 100%,
  text(size: 7.3pt, fill: muted, par(leading: 0.5em, t))))
#let hr() = block(above: 12pt, below: 12pt, line(length: 100%, stroke: 0.6pt + rulec))
#let gap() = v(15pt)
#let big(t) = text(font: serif, size: 62pt, fill: teal, top-edge: "bounds", bottom-edge: "bounds", t)
#let subhead(t) = block(above: 13pt, below: 6pt, text(font: serif, size: 15pt, weight: "bold", t))
#let columns(a, b) = grid(columns: (1fr, 1fr), gutter: 22pt, a, b)
#let panel(body) = block(width: 100%, fill: cream2, inset: 14pt, radius: 2pt, body)
#let infoline(label, val) = block(above: 5pt, below: 5pt,
  grid(columns: (1fr, auto), column-gutter: 10pt, text(size: 9.2pt, label), text(size: 10pt, weight: "bold", val)))
#let source-row(name, amount, count, share) = block(above: 10pt, below: 10pt, {
  grid(columns: (1fr, auto, auto), column-gutter: 15pt,
    text(size: 10pt, weight: "bold", name), text(size: 10pt, count), text(size: 10pt, fill: teal, weight: "bold", share))
  v(5pt)
  box(width: amount / raw("source_1_n") * 100%, height: 10pt, fill: teal)
})
#let monthbar(id) = {
  let amount = raw(id)
  box(width: 6.4pt, height: 76pt,
    align(bottom, if amount == none {
      box(width: 5.1pt, height: 76pt, fill: red.transparentize(76%))
    } else {
      box(width: 5.1pt, height: amount / raw("month_axis_max") * 76pt, fill: teal)
    }))
}
#let monthchart(body) = block(above: 10pt, below: 8pt, body)
#let monthbars(..bars) = stack(dir: ltr, spacing: 0.45pt, ..bars.pos())
#let yearlabels(..years) = grid(columns: (12fr, 12fr, 12fr, 12fr, 12fr, 6fr),
  ..years.pos().map(y => text(size: 8pt, fill: muted, y)))
#let case-row(source-name, date-label, title-label, url) = block(above: 9pt, below: 9pt, {
  grid(columns: (1fr, auto), column-gutter: 9pt,
    text(size: 9.5pt, weight: "bold", link(url, source-name)),
    text(size: 8.5pt, fill: muted, date-label))
  v(3pt)
  text(size: 8.7pt, title-label)
})
#let method-row(label, treatment) = block(above: 6pt, below: 6pt,
  grid(columns: (1.1fr, 1fr), gutter: 15pt, small(label), small(treatment)))

#let cover(body) = page(fill: navy, margin: (top: 22mm, bottom: 20mm, left: 22mm, right: 22mm),
  header: none, footer: none, {
    set text(font: sans, size: 10pt, lang: "hr", fill: cream, fallback: false)
    set par(leading: 0.65em)
    body
  })
#let cover-title(t) = block(above: 28pt, below: 18pt,
  text(font: serif, size: 42pt, hyphenate: false, par(leading: 0.22em, t)))
#let cover-deck(t) = block(text(size: 13pt, fill: cream, par(leading: 0.6em, t)))
#let cover-big(t) = block(below: 14pt, text(font: serif, size: 82pt, fill: rgb("#32b6a7"), t))
#let cover-label(t) = text(size: 8pt, tracking: 1pt, fill: rgb("#afb7bf"), t)
#let cover-note(t) = text(size: 8.2pt, fill: rgb("#c9cdd1"), par(leading: 0.5em, t))
#let cover-space() = v(1fr)

// Full-report editorial components, adapted from the initial report's acts,
// summary rows, horizontal bars, restrained diagrams and source directory.
#let section-rule(t) = block(above: 17pt, below: 10pt,
  grid(columns: (auto, 1fr), column-gutter: 10pt, align: horizon,
    text(size: 8pt, weight: "bold", fill: muted, tracking: 0.8pt, upper(t)),
    line(length: 100%, stroke: 0.6pt + rulec)))
#let bigprose(t) = block(above: 12pt, below: 12pt,
  text(font: serif, size: 15pt, par(leading: 0.5em, t)))
#let mini-stat(number, label) = stack(spacing: 8pt,
  text(font: serif, size: 40pt, fill: teal, number), small(label))
#let take(title, result, body) = block(above: 12pt, below: 18pt,
  grid(columns: (1fr, 1.45fr), column-gutter: 22pt,
    stack(spacing: 7pt, text(size: 9pt, weight: "bold", title),
      text(font: serif, size: 37pt, fill: teal, result)),
    text(size: 10pt, par(leading: 0.6em, body))))
#let proportional-bar(amount, base, primary: teal, height: 17pt) = box(width: 100%, height: height,
  stack(dir: ltr,
    box(width: amount / base * 100%, height: height, fill: primary),
    box(width: (base - amount) / base * 100%, height: height, fill: stone)))
#let cumulative-row(k, share, amount, base) = block(above: 14pt, below: 14pt, {
  grid(columns: (1fr, auto), text(size: 10pt, k), text(size: 11pt, weight: "bold", share))
  v(6pt)
  proportional-bar(amount, base)
})
#let size-row(size-label, count, amount, maximum) = block(above: 12pt, below: 12pt,
  grid(columns: (75pt, 1fr, 40pt), column-gutter: 12pt, align: horizon,
    text(size: 10pt, size-label),
    box(width: amount / maximum * 100%, height: 14pt, fill: teal),
    align(right, text(size: 11pt, count))))
#let period-row(label, count, body) = block(above: 15pt, below: 22pt, {
  grid(columns: (1fr, auto), text(font: serif, size: 18pt, label),
    text(font: serif, size: 30pt, fill: teal, count))
  v(8pt); hr(); small(body)
})
#let note-box(title, body) = block(width: 100%, fill: cream2, inset: 17pt, {
  text(font: serif, size: 19pt, title)
  v(10pt); prose(body)
})
#let source-entry(name, date-label, title-label, url) = block(above: 14pt, below: 14pt, {
  grid(columns: (10pt, 1fr, auto), column-gutter: 9pt, align: horizon,
    box(width: 7pt, height: 7pt, fill: teal),
    text(size: 11pt, weight: "bold", link(url, name)),
    text(size: 9pt, fill: muted, date-label))
  v(6pt)
  block(inset: (left: 19pt), text(size: 9.2pt, title-label))
})
#let directory-header() = {
  grid(columns: (22pt, 1fr, 65pt, 48pt), column-gutter: 8pt,
    small[Red.], small[Izvor], align(right, small[Objave]), align(right, small[Udio]))
  v(6pt)
  line(length: 100%, stroke: 0.7pt + rulec)
}
#let directory-row(rank, name, count, share) = block(above: 5pt, below: 5pt,
  grid(columns: (22pt, 1fr, 65pt, 48pt), column-gutter: 8pt, align: horizon,
    text(size: 8.5pt, fill: muted, rank), text(size: 9pt, name),
    align(right, text(size: 9pt, count)), align(right, text(size: 9pt, fill: teal, share))))
#let wavebar(amount) = box(width: 6.4pt, height: 95pt, align(center + horizon,
  if amount != none { rect(width: 3.2pt, height: calc.max(amount / raw("month_axis_max") * 92pt, 1pt),
    radius: 2pt, fill: teal, stroke: none) }))
#let full-monthbar(amount) = box(width: 6.4pt, height: 170pt, align(bottom,
  if amount == none {
    box(width: 5.1pt, height: 170pt, fill: red.transparentize(78%))
  } else { box(width: 5.1pt, height: amount / raw("month_axis_max") * 170pt, fill: teal) }))
#let darkspread(body) = page(fill: navy,
  margin: (top: 22mm, bottom: 22mm, left: 22mm, right: 22mm), header: none,
  footer: context {
    set text(font: sans, size: 7pt, fill: rgb("#a7adb5"), fallback: false)
    grid(columns: (1fr, auto), [DIGIKAT · RADNO ISTRAŽIVAČKO IZDANJE], counter(page).display())
  }, {
    set text(font: sans, size: 10pt, fill: cream, lang: "hr", fallback: false)
    set par(leading: 0.6em)
    body
  })
#let act-label(t) = text(size: 8pt, fill: rgb("#a7adb5"), tracking: 1pt, t)
#let act-title(t) = block(above: 26pt, text(font: serif, size: 48pt, t))
#let summary-title(t) = block(above: 26pt, below: 24pt,
  text(font: serif, size: 36pt, t))
#let act-number(t) = block(above: 20pt, below: 15pt,
  text(font: serif, size: 112pt, fill: teal, top-edge: "bounds", bottom-edge: "bounds", t))
#let act-word(t) = block(above: 20pt, below: 20pt, text(font: serif, size: 64pt, fill: red, t))
#let act-caption(t) = block(width: 85%, text(font: serif, size: 20pt, par(leading: 0.4em, t)))
#let act-note(t) = text(size: 8pt, fill: rgb("#a7adb5"), par(leading: 0.6em, t))
#let dark-stat(value-body, label, body) = block(above: 18pt, below: 18pt,
  stack(spacing: 9pt,
    text(font: serif, size: 55pt, top-edge: "bounds", bottom-edge: "bounds", value-body),
    text(size: 10pt, weight: "bold", label),
    text(size: 9pt, fill: rgb("#bfc7cf"), par(leading: 0.6em, body))))
