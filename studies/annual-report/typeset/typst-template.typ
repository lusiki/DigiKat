// DigiKat annual report — Typst design.
//
// Loaded after Quarto's definitions.typ, so anything redefined here wins. The page carries the same
// cream as the figures (#F5F4F0); on a white page every chart would sit in a visible grey rectangle.
//
// Two elements do the heavy lifting because they are the only ones that survive Pandoc's Typst
// writer with their identity intact: a level-4 heading is a figure or table title, and a block quote
// is its source note. A fenced div arrives here as an anonymous block and cannot be styled at all.

#let dk-paper      = rgb("#F5F4F0")
#let dk-panel      = rgb("#FFFFFF")
#let dk-accent     = rgb("#0F4C5C")
#let dk-accent-300 = rgb("#2C6F7E")
#let dk-accent-200 = rgb("#5A949F")
#let dk-accent-050 = rgb("#EAF0F2")
#let dk-ink        = rgb("#14181D")
#let dk-body       = rgb("#1B1D21")
#let dk-muted      = rgb("#6B6F76")
#let dk-faint      = rgb("#9A9EA6")
#let dk-hairline   = rgb("#E4E2DA")
#let dk-alert      = rgb("#B5462F")

// Palatino for everything that carries meaning, Segoe UI for labels and furniture. The figures are
// drawn in the same two families, so a chart and the paragraph beside it read as one document.
#let dk-serif = ("Palatino Linotype", "Book Antiqua", "Georgia", "Libertinus Serif")
#let dk-sans  = ("Segoe UI", "Corbel", "Arial")
#let dk-mono  = ("Consolas", "Courier New")

// One modular scale, ratio 1.333. Every size is a step on it, so nothing is set by eye.
#let sz-note  = 8.4pt
#let sz-small = 9.4pt
#let sz-body  = 10.5pt
#let sz-h4    = 12.5pt
#let sz-h2    = 14pt
#let sz-h1    = 19pt
#let sz-hero  = 25pt
#let sz-cover = 33pt

// Furniture: small, upper case, letter spaced. Used for the cover kicker and the running head, so
// all the document's small print speaks with one voice.
#let kicker(body, fill: dk-accent-300, size: 8pt) = text(
  font: dk-sans, size: size, fill: fill, tracking: 1.6pt, weight: "medium",
)[#upper[#body]]

// Two box species, and only two. A filled petrol box carries what the reader must not miss (method,
// caveat, myth against data). An unfilled hairline box carries the asides that may be skipped. Which
// one is used is read off the icon colour Quarto passes per callout type, because the type itself
// never reaches this function.
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none,
             icon_color: black, body_background_color: white) = {
  let c = icon_color.rgb().components()
  let red = c.at(0) > 55% and c.at(1) < 45%
  let green = c.at(1) > 45% and c.at(0) < 45%
  let rule = if red { dk-alert } else { dk-accent }
  // Breakable, with a sticky title. Forbidding the break avoided a stranded title but pushed any box
  // that did not fit onto a page of its own, leaving the previous page nine tenths empty. Sticky
  // keeps the title with the first lines of its body, which solves the orphan without the hole.
  block(
    breakable: true,
    width: 100%,
    fill: if green { none } else { dk-accent-050 },
    stroke: if green { (paint: dk-hairline, thickness: 0.6pt) } else { (left: 2.5pt + rule) },
    inset: (left: 16pt, right: 16pt, top: 14pt, bottom: 14pt),
    above: 2.1em, below: 2.1em,
  )[
    #set text(size: sz-small, fill: dk-body)
    #set par(leading: 0.82em, spacing: 1.2em)
    #block(below: 0.85em, sticky: true)[#text(font: dk-serif, size: sz-h4, weight: "bold", fill: rule)[#title]]
    #body
  ]
}

#let article(
  title: none, subtitle: none, cover-stat: none, cover-line: none, back-line: none,
  authors: none, keywords: (), date: none,
  abstract-title: none, abstract: none, thanks: none, cols: 1,
  lang: "hr", region: "HR", font: none, fontsize: 10.5pt,
  title-size: 1.5em, subtitle-size: 1.25em,
  heading-family: none, heading-weight: "bold", heading-style: "normal",
  heading-color: black, heading-line-height: 0.65em,
  mathfont: none, codefont: none, linestretch: 1, sectionnumbering: none,
  linkcolor: none, citecolor: none, filecolor: none,
  toc: false, toc_title: none, toc_depth: none, toc_indent: 1.5em,
  // Accepted and ignored: older Quarto releases pass page geometry through this call instead of
  // through page.typ. Without these the template errors out on "unexpected argument".
  paper: "a4", margin: none, ..rest,
  doc,
) = {
  set document(
    title: content-to-string(title),
    author: "DigiKat · Hrvatsko katoličko sveučilište",
    keywords: keywords,
  )

  // Asymmetric grid: the text block sits left of centre and the wider outer margin carries the page
  // number. White space stops being padding and becomes structure.
  set page(
    paper: "a4",
    margin: (left: 2.5cm, right: 3.3cm, top: 2.6cm, bottom: 2.4cm),
    fill: dk-paper,
    numbering: none,
  )
  set text(font: dk-serif, size: sz-body, fill: dk-body, lang: "hr", region: "HR",
           hyphenate: false, number-type: "old-style")
  set par(justify: false, leading: 0.9em, spacing: 1.6em)

  // ---- Cover ---------------------------------------------------------------------------------
  // One dominant element. The kicker, the rule and the colophon are furniture; the title and the
  // hero number are the only two things carrying weight, separated by as much air as the page gives.
  {
    set page(margin: (left: 2.5cm, right: 3.3cm, top: 3.6cm, bottom: 2.8cm))
    set text(number-type: "lining")
    block(width: 100%)[
      #kicker[DigiKat · opservatorij digitalnih medija]
      #v(6pt)
      #line(length: 100%, stroke: 1.2pt + dk-accent)
      #v(74pt)
      #text(font: dk-serif, size: sz-cover, weight: "bold", fill: dk-accent, tracking: -0.4pt)[#title]
      #v(12pt)
      #text(font: dk-sans, size: 14pt, fill: dk-muted)[#subtitle]
      #v(92pt)
      #if cover-stat != none {
        text(font: dk-serif, size: 46pt, weight: "bold", fill: dk-accent, tracking: -1pt)[#cover-stat]
      }
      #if cover-line != none {
        v(12pt)
        block(width: 86%)[#text(font: dk-sans, size: 10.5pt, fill: dk-muted)[#cover-line]]
      }
    ]
    // The year's own fingerprint, drawn from the same daily series as the chapter figure: one spike,
    // everything else ordinary. The shape of the argument, before a word is read.
    place(bottom + left, dy: -76pt, block(width: 100%)[
      #image("figures/cover_spark.png", width: 100%)
    ])
    place(bottom + left, block(width: 100%)[
      #line(length: 100%, stroke: 0.5pt + dk-hairline)
      #v(9pt)
      #text(font: dk-sans, size: 8.6pt, fill: dk-muted)[
        Urednik: doc. dr. sc. Luka Šikić \
        Hrvatsko katoličko sveučilište · Odjel za komunikologiju \
        Tekst i pregledani agregati: CC BY 4.0
      ]
    ])
    pagebreak()
  }

  // ---- Running head and outer footer -----------------------------------------------------------
  set page(
    header: context {
      if counter(page).get().first() > 1 {
        block(width: 100%)[
          #kicker(fill: dk-faint, size: 7.4pt)[Katoličke teme u digitalnom prostoru]
          #v(3pt)
          #line(length: 100%, stroke: 0.4pt + dk-hairline)
        ]
      }
    },
    // Bottom outer corner: where a thumb turns the page.
    footer: context {
      let n = counter(page).get().first()
      if n > 1 {
        align(right, text(font: dk-sans, size: 8.4pt, fill: dk-faint, number-type: "lining")[#n])
      }
    },
  )

  // ---- Headings ----------------------------------------------------------------------------
  set heading(numbering: sectionnumbering)
  let chapter = counter("dk-chapter")

  // Chapter opener: a rule, a big ghost numeral in the page's own tint, and the title. The numeral is
  // furniture the eye navigates by at flip-through speed without it competing for attention.
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    chapter.step()
    block(width: 100%, above: 0.2em, below: 2.2em)[
      #line(length: 100%, stroke: 1pt + dk-accent)
      #v(10pt)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 16pt,
        context {
          let n = chapter.get().first()
          text(font: dk-serif, size: 44pt, weight: "bold", fill: dk-accent-050,
               number-type: "lining")[#if n < 10 [0]#str(n)]
        },
        block(inset: (top: 14pt))[
          #text(font: dk-serif, size: sz-h1, weight: "bold", fill: dk-accent)[#it.body]
        ],
      )
    ]
  }
  show heading.where(level: 2): it => block(above: 2.8em, below: 1.15em)[
    #text(font: dk-serif, size: sz-h2, weight: "bold", fill: dk-accent-300)[#it.body]
  ]
  show heading.where(level: 3): it => block(above: 2.1em, below: 0.85em)[
    #text(font: dk-sans, size: 11pt, weight: "bold", fill: dk-ink)[#it.body]
  ]
  // Level 4 is a figure or table title, not a section: out of the contents, out of the PDF
  // bookmarks, and stuck to the object it names.
  show heading.where(level: 4): set heading(outlined: false, bookmarked: false)
  show heading.where(level: 4): it => block(above: 2.5em, below: 0.9em, sticky: true)[
    #text(font: dk-serif, size: sz-h4, weight: "bold", fill: dk-ink)[#it.body]
  ]

  // ---- Source notes ---------------------------------------------------------------------------
  // The note under every figure and table: small, sans, muted, and set to a narrower measure than
  // the body so it reads as an annotation and not as a paragraph.
  set quote(block: true, quotes: false)
  show quote: it => block(width: 92%, above: 1.0em, below: 2.6em, inset: (left: 0pt))[
    #set par(leading: 0.74em)
    #text(font: dk-sans, size: sz-note, fill: dk-muted, number-type: "lining")[#it.body]
  ]

  // ---- Links, lists, images ---------------------------------------------------------------------
  show link: set text(fill: dk-accent-300)
  // A URL must never split across a line break; box() makes it one indivisible object.
  show link: it => box(it)
  show strong: set text(fill: dk-ink, weight: "bold")
  set list(indent: 0pt, body-indent: 12pt, spacing: 1.25em,
           marker: text(fill: dk-accent-200)[•])
  show image: set image(width: 100%)
  show image: set block(above: 0.5em, below: 0.5em)
  set figure(gap: 0.9em)
  show figure.caption: set text(font: dk-sans, size: sz-note, fill: dk-muted)

  // ---- Tables -------------------------------------------------------------------------------
  // Tabular lining figures: digits of equal width, so a column of numbers forms a straight edge.
  set table(
    inset: (x: 10pt, y: 9pt),
    stroke: (_, y) => (bottom: 0.4pt + dk-hairline),
    fill: (_, y) => if y == 0 { dk-accent-050 } else { none },
  )
  show table: set text(size: sz-small, number-type: "lining", number-width: "tabular")
  show table.cell.where(y: 0): set text(font: dk-sans, weight: "bold", fill: dk-accent, size: 9pt)
  show table: set par(leading: 0.72em)
  // Tables stay breakable. Forbidding the break only moves the problem: the table's own title is a
  // separate heading, so an unbreakable table strands that title alone at the foot of a page.
  // Typst repeats the header row on the continuation, which reads correctly.
  show table: set block(above: 1.4em, below: 1.2em)

  show raw: set text(font: dk-mono, size: 0.88em, fill: dk-accent-300)

  // ---- Table of contents ---------------------------------------------------------------------
  if toc {
    block(above: 0em, below: 2.4em)[
      #text(font: dk-serif, size: sz-h2, weight: "bold", fill: dk-accent)[
        #if toc_title == none { "Sadržaj" } else { toc_title }
      ]
      #v(12pt)
      #line(length: 100%, stroke: 0.4pt + dk-hairline)
      #v(14pt)
      #set text(font: dk-sans, size: 10pt, fill: dk-body, number-type: "lining")
      #set par(leading: 1.3em)
      #outline(title: none, depth: toc_depth, indent: toc_indent)
    ]
    pagebreak()
  }

  doc

  // ---- Back cover -------------------------------------------------------------------------------
  // A report that stops mid-page reads as unfinished. This one closes.
  pagebreak()
  set page(header: none, footer: none)
  set text(number-type: "lining")
  place(horizon + left, block(width: 100%)[
    #line(length: 100%, stroke: 1.2pt + dk-accent)
    #v(18pt)
    #text(font: dk-serif, size: sz-hero, weight: "bold", fill: dk-accent)[DigiKat]
    #v(8pt)
    #kicker[Katoličke teme u digitalnom prostoru]
    #v(30pt)
    #text(font: dk-sans, size: 9pt, fill: dk-muted)[
      Hrvatsko katoličko sveučilište · Odjel za komunikologiju \
      Ilica 242, Zagreb · lusiki.github.io/DigiKat
    ]
    #if back-line != none {
      v(22pt)
      text(font: dk-mono, size: 7.6pt, fill: dk-faint)[#back-line]
    }
  ])
}
