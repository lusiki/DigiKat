# Plan: Executive bird's-eye overview — "izvršni pregled" HTML letter

## Goal

A single, presentable-in-15-minutes HTML document that gives a university executive /
funder a bird's-eye view of DigiKat: what the project is, how the data/analysis pipeline
works, and 2–3 headline findings (Mapa-weighted) — organized around at most **five major
linked concepts**, each hyperlinked to the live site page that expands it. Doubles as an
emailable single-file leave-behind (`embed-resources: true`).

This plan is the product of a multi-agent research + design + judge workflow: six readers
extracted findings/numbers/assets from every analytical page, three independent full-layout
concepts were designed against that evidence, and a judge panel scored them. Full transcript
retained in this session; only the decision-relevant substance is kept here.

## Decision: chosen layout

**Winner (score 8.8/10): "Koncept-kartice"** — hero KPI band → 3-term glossary strip →
five numbered concept cards with findings woven in next to the concept that produced them →
compact production timeline → closing links. Beat a pure prose "PI letter" (8.1 — better
writing, worse scannability for a cold reader) and a "guided-tour" minute-stamped scroll
(8.2 — best live-talk pacing, but minute-stamp chrome leaks into the leave-behind and it
carries the most maintenance debt: a 4th copy of actor-typology logic, a manually copied
PNG).

**Grafts pulled into the winner from the losing concepts** (see full list in workflow
output; the ones that change the build):
1. Letter framing: open with a short "Poštovani," salutation band (PI voice, 3–4 sentences)
   and close with a `.letter-signature` block — so it reads as a letter, not a dashboard.
2. Orientation line after the glossary strip: "pet koncepata, tri nalaza, jedna ograda."
3. Narrow reading measure (~44rem, line-height 1.7) on prose bands between card grids.
4. A `.pull-stat` device: one large mono petrol stat under Nalaz 1 — "12,6 % objava →
   42,9 % dosega" — the one number the audience should leave with.
5. Absolute `https://lusiki.github.io/DigiKat/...` URLs in all body links (not relative),
   so the emailed embed-resources copy never dangles; keep `doga%C4%91aji.html`
   percent-encoded.
6. Move the two-stream honesty caveat forward: one line in the glossary strip itself
   ("međugodišnji volumen nije usporediv — vidjeti ogradu niže"), in addition to the full
   callout-warning pinned beside the Evolucija card.
7. Recompute the Nalaz-1 share figure in-chunk from `proportions_summary.rds` (not a reused
   PNG) — eliminates figure/prose drift for the cheapest figure. Keep the actor-map and
   topic-network figures as reused PNGs (expensive to recompute) with dated `Izvor:` captions.
8. A `stopifnot()` guard chunk (mirroring `evolucija.qmd`'s pattern): assert corpus total =
   710.307 and platform shares sum to ≈100 % at render time, so a silent aggregate change
   fails the render instead of shipping wrong numbers.
9. Scripted presenter line for Nalaz 3: "kvalitativan obrazac, ne postotak" — pre-empts an
   executive asking for a percentage that neither source page publishes.
10. Minute pacing kept as HTML comments / speaker notes in the `.qmd`, not visible chrome.

## The 3 headline findings (all Mapa-weighted per the brief)

1. **Funkcionalna specijalizacija platformi** (Mapa ekosustava) — web proizvodi 73,8 %
   objava ali drži samo 65,3 % interakcija i 45,8 % dosega; Facebook s 12,6 % objava
   dosegne 42,9 % — gotovo kao web, sa šest puta manje objava. Figure: recomputed
   3-panel share chart from `platform_summary.rds`/`proportions_summary.rds`.
2. **Četiri puta do utjecaja** (Mapa ekosustava) — actor typology on log–log doseg ×
   angažman map, medians as cuts: Divovi / Graditelji zajednica / Megafoni / Specijalizirani
   akteri (Giants/Community Builders/Megaphones/Specialists on first use). Figure: reused
   `plot-actor-map` PNG. Actors named only as "istaknuti primjeri" — never ranked leaders
   (current top-by-interactions has drifted from the mapa.qmd prose: e.g. top web source by
   interactions is `novizivot.net`, not `vecernji.hr`; top YouTube is `pulherissimus`, not
   `LaudatoTV`).
3. **Dva tematska svijeta** (Tematske struje + Atmosfera diskursa, convergent) — pastoralni
   svijet (Duhovnost i liturgija, Karitas, Digitalna evangelizacija, pretežno pozitivan)
   vs. društveno-politički svijet (Politika, Povijest i identitet, Bioetika, najviši
   angažman i polarizacija); "konflikt, kontroverza i krizni narativi djeluju kao glavni
   pokretači interakcija." Talking point: two independent methods (topic co-occurrence +
   RIK conflict-language) converge on the same split. No invented percentage — neither
   source page publishes one; state it as a qualitative pattern.

**Mandatory, non-negotiable caveat**: the corpus merges two time-segregated collection
streams (monitoring 2021.–2024. + religijsko filtriranje 2024.–2026.; Instagram/TikTok only
from 2024; 2026 incomplete). The letter contains **no year-faceted volume chart** and states
this explicitly before or beside any temporal number (evolucija's 55,8 %→23,3 % concentration
figure is used only with its own "okvirne naznake putanje" hedge).

## The 5 linked concepts (cards)

1. **Mapa ekosustava** → `pages/mapa/mapa.qmd` — tko objavljuje i s kojim učinkom; carries
   findings 1 and 2.
2. **Tematske struje** → `pages/mapa/mapa_stats.qmd` — o čemu se govori; 16 kategorija,
   5 % uzorak.
3. **Atmosfera diskursa** → `pages/mapa/diskurs.qmd` — kako se govori; lilaHR 8 emocija +
   Relativni indeks konflikta (RIK), 2 % uzorak. (2 and 3 jointly carry finding 3.)
4. **Fokus na događaje** → `pages/mapa/događaji.qmd` — kada rasprava eruptira; digitalni
   seizmograf (Z-score unutar godine, prag 3 SD), otporan na promjenu metode 2024.
5. **Evolucija ekosustava** → `pages/mapa/evolucija.qmd` — vremenski presjek; utjecaj se
   raspršuje (55,8 %→23,3 %), angažman migrira s weba; framed only as "okvirne naznake
   putanje."

The korpus/baza foundation is *not* spent as a 6th concept card — it lives in the
production-timeline section, linking to `pages/baza.qmd`.

## Data-layer / production-pipeline section (compact, timeline device)

One `.timeline` block, five nodes, mirroring `about.qmd`'s device:
1. Prikupljanje — vendorski `.xlsx` izvozi.
2. Filtriranje — regex nad 95 hrvatskih religijskih pojmova; objava ulazi samo uz ≥2
   različita pogotka (korpus je tematski zahvat, ne kurirani popis medija).
3. Master — `merged_comprehensive.rds`, 710.307 × 47, dedup po URL-u, gitignored, backup
   prije prepisivanja.
4. Agregati — `R/03_aggregate.R` proizvodi tracked, no-PII agregate u `data/processed/`
   (CC BY 4.0) — jedini izvor brojki u ovom pregledu.
5. Analitičke razine — četiri razine + presjek na 2–5 % stratificiranim uzorcima (sjeme
   123), udpipe HR 2.5, CroSentilex/CroSentilex Gold/lilaHR.

Closing line: open-data distribution on Kaggle (CC BY 4.0), `FULL_TEXT` excluded.

## Concrete build

- **New file**: `pages/pregled/izvrsni-pregled.qmd` (ASCII slug — avoids a second
  đ-filename hazard). Auto-picked up by the existing `_quarto.yml` render glob
  (`pages/**/*.qmd`) — **no `_quarto.yml` nav change**; deliberately **unlisted** in the
  navbar (executive artifact + email leave-behind, not site IA).
- **Per-page YAML**: `lang: hr`, informative title/subtitle, `date: last-modified`,
  `toc: false`, `page-layout: article`, `format: html: { embed-resources: true }`,
  `execute: echo: false`.
- **Numbers**: zero hand-typed values. One setup chunk reads only tracked aggregates
  (`platform_summary.rds`, `proportions_summary.rds`, `source_summary.rds`,
  `{web,youtube,facebook}_actors.rds`) — never the master, never `data/nlp/`. Helper
  `fmt_hr()` with `big.mark = "."`, `decimal.mark = ","`. Include the `stopifnot()` guard
  chunk (graft #8).
- **Figures**: Nalaz-1 share chart recomputed in-chunk with `source("R/theme_digikat.R")`
  (graft #7). Nalaz-2 actor map and Nalaz-3 topic-network figure are reused PNGs from
  `docs/pages/mapa/*_files/figure-html/` with dated `Izvor:` captions — do not re-render the
  heavy udpipe/network chunks. The interactive `visNetwork` graph (`pages/izvori/mreza.qmd`)
  is **linked, not embedded** (would balloon the self-contained file).
- **CSS**: zero changes to `assets/css/custom.scss`. Reuse `.eyebrow`, `.metric-grid`/
  `.metric-card`, `.card-grid`/`.info-card`, `.featured-box`, `.timeline`/`.timeline-item`,
  `.tag`, `.dk-btn`/`.dk-btn-outline`, Quarto callouts. One small page-scoped `<style>` block
  for: `.koncept-broj` number chip, `.pull-stat`, `.letter-signature`, the narrow-measure
  wrapper, and an `@media print` rule.
- **Links**: absolute `https://lusiki.github.io/DigiKat/...` throughout body prose (graft
  #5); keep `pages/mapa/doga%C4%91aji.html` percent-encoded wherever hand-written in raw
  HTML/markdown.
- **Terminology guardrails to enforce at review**: RIK never RCI/CLI; lilaHR never NRC;
  "3 standardne devijacije" never "99. percentil"; sentence-case category names; „…"
  Croatian quotes; doseg always qualified as *potencijalni doseg*; actors named only as
  "istaknuti primjeri", never ranked leaders; do not copy the "Njaveći" typo from
  `mapa.qmd` line 250 (correct to "Najveći" or avoid the sentence).

## Render quirk (discovered at build time)

Rendering this page creates a stray `docs/docs/pages/mapa/.../plot-*.png` copy of the two
reused PNGs (Quarto copies referenced resources even though `embed-resources` also inlines
them as base64). The copies are redundant — the output HTML contains only data URIs.
**After every render of this page: delete `docs/docs/` before committing.**

## Render & verification (per `.claude/rules/quarto-verification.md`)

1. Pause Dropbox sync before rendering (per `CLAUDE.local.md` hazard).
2. From repo root: `"$QUARTO" render pages/pregled/izvrsni-pregled.qmd` (single page — this
   is a **content page reading only tracked aggregates**, not a HARD-GATE action; no full
   site render needed).
3. Confirm: renders clean, figures present (no empty `<img>`), Croatian diacritics literal
   (č ć ž š đ, including in the đ URL), `stopifnot()` guards pass, `docs/` changed only for
   this new page (+ its `_files/` if any) — no scatter outside `docs/`.
4. Confirm `data/processed/*.rds` is untouched by this render (verifier agent / `md5sum`
   check) — this page only reads aggregates, never writes them.
5. Open the rendered file locally, click every one of the 5 concept-card links and the 2
   study-page style checks (percent-encoded đ link, absolute URLs) to confirm no 404s.
6. Run `/review-page` (or the `numeric-claim-verifier` + `religion-media-domain-reviewer`
   agents directly) before calling it done — re-derive the 710.307 / 9-platform / 73,8 %/
   65,3 %/45,8 % / 12,6 %→42,9 % figures independently from `data/processed/*.rds` and check
   the actor-typology framing against the domain-review lens.
7. Do not add this page to `_quarto.yml` nav.
8. Hand off to `/commit` only after user review of the rendered output — not auto-committed.

## Not in scope / explicitly rejected

- No year-faceted volume/growth chart anywhere in the document (2025 surge is a collection
  artifact, not a finding).
- No embedding of the interactive source-network widget (file-size bloat).
- No new nav entry / no full-site render (HARD GATE avoided entirely).
- No hand-typed numbers, no invented percentage for the "two thematic worlds" finding.
