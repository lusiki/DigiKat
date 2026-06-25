---
paths:
  - "pages/**/*.qmd"
  - "R/*.qmd"
  - "_quarto.yml"
---

# DigiKat — Voice & Style Guide

The house voice for everything **reader-visible** on the DigiKat website (Croatian content; this guide is
English). Derived from a cross-page audit; it locks in what the strong analytical pages already do and resolves
the drift elsewhere. When editing or writing any page, conform to this. The four `pages/mapa/*` analytical pages
are the **gravitational center** — when in doubt, sound like them.

## 1. The voice in one sentence
DigiKat speaks as **a measured computational-social-science research team explaining its own empirical work to an
informed but non-specialist Croatian reader** — it states a finding and then *reads* it sociologically, never
dumping a chart or a number without interpreting it. Analytical, confident, open-science earnest. Not promotional,
not jargon-fog. Exemplar: *"Dominacija web-sadržaja nije samo brojčana. Ona odražava ulogu tradicionalnih medija
kao čuvara vijesti u hrvatskom društvu."*

## 2. Register & tone — by page class
- **Analytical pages** (`mapa`, `mapa_stats`, `diskurs`, `događaji`): academic-analytical, interpretive, measured. The center.
- **Landing/content** (`index`, `schedule`, `news`, `site-info`): neutral-explanatory science-communication; confident, understated.
- **Service pages** (`about` CTA, `resources`): warm, helpful, encouraging — but still grounded.

**Out of bounds (reject):**
- Marketing hype / superlatives: *"Biblija za svakoga", "Najvažnija zajednica", "sveobuhvatan uvid", "pouzdanije i inovativnije znanstvene kulture"*. Enthusiasm yes; slogans no.
- Latinate jargon-fog: *"transcendiraju", "bifurkacija", "rekonfiguriraju", "epicentar svih narativnih prijepora"*. Prefer plain Croatian verbs; **one evocative metaphor per section max**.
- Un-read data/code dumps: every table, figure and code block gets ≥1 framing sentence in Croatian (no raw `sessionInfo()` wall, no untitled distribution tables).
- Decorative emoji in body/analytical content (off-register for a research institution).

## 3. Narrative person & address — one rule per page class
- **Analytical pages → impersonal / descriptive third person.** *"Analiza obuhvaća korpus…", "Rezultati pokazuju…"*. No `vi`, no CTA. (Reflexive-passive is fine for process: *"Korpus se čita kroz četiri razine"* — but don't let it become agentless fog.)
- **Method/definition asides → sparing 1st-person plural** to state what the study does: *"Pod volumenom podrazumijevamo…"*. Framing/operationalization only, never interpretation of findings.
- **Service/CTA pages → 2nd-person plural (`vi`)** is expected: *"Pridružite se…", "…koja će vam pomoći"*. Use `mi/naš` for the team, `vi` for the reader. Confine exclamation marks to these pages.
- **Never** leave placeholder/scaffolding text in finished copy (e.g. *"(Ovdje možete pratiti najnovije vijesti…)"*).

## 4. Language policy
- **Croatian-first, everywhere reader-visible** — headings, prose, UI labels, captions, buttons. Diacritics č ć ž š đ are mandatory, literal UTF-8 in source (see `croatian-encoding.md`).
- **English technical terms:** keep untranslated only for proper nouns / established jargon with no clean Croatian equivalent (R, Python, Quarto, GitHub, NLP, FAIR, udpipe, brand/platform names). On **first use** gloss in Croatian with the English in parentheses — *"obrada prirodnog jezika (NLP)"* — then use Croatian or the acronym alone. Italicize a genuinely untranslatable inline term (*web scraping*, *baseline*) — and do it the **same way on every page**.
- **No Croglish:** reject *"tidyverse ekosystemom", "existirajuće", "velikih dataset-a", "dashboard"* (→ *nadzorna ploča*, glossed once).
- **No bilingual CRO/ENG inline labels and no English-only prose.** The whole project must be describable in Croatian. The home-page lead, CTAs, and valuebox labels are **Croatian only** (an English mirror, if ever wanted, is a separate `/en/` page — not inline slashes). English-as-code-identifier is tolerable only inside mono "tech-tag" pills (`ingest`, `dedupe`), never in prose.

## 5. Terminology canon
Left column is mandatory in reader-visible Croatian prose; normalize the variants away.

| Concept | **Canonical form** | Reject / normalize away |
|---|---|---|
| The ≈610k master corpus | **korpus** (formal: *glavni skup podataka*) | *baza podataka* (as the corpus), *dataset / dataseta / dataset-a*, bare *baza* |
| Distribution product (Kaggle/Zenodo) | **baza podataka** | (use only for the published product, not the empirical object) |
| A single media item | **objava** (pl. *objave*) | *post*, *zapis* (use *zapis* only for a DB row distinct from a post) |
| Channel / source | **platforma** | mixing *platforma*/*izvor* loosely (keep brand names as-is: web, YouTube, Facebook) |
| Reach | **doseg** | *reach* in prose |
| Engagement | **angažman** | *engagement* in prose |
| Volume | **volumen** | — |
| Polarity / tone | **tonalitet** (prose); *sentiment* only in metric labels & variable names | *ton*, *valencija*, **valenca** — pick one and stop interchanging |
| The 8 emotions | **emocije** — Ljutnja, Iščekivanje, Gađenje, Strah, Radost, Tuga, Iznenađenje, Povjerenje | — |
| Emotion lexicon | **lilaHR** (+ CroSentilex / CroSentilex Gold) | *NRC* / *NRC Leksikon Emocija* — the loaded file is **lilaHR**; fix the mislabel |
| Conflict index | **Relativni indeks konflikta (RIK)** | *RCI*, *CLI*, *rci* — one acronym site-wide: **RIK**, expanded once |
| 16-category scheme | **tematske kategorije** (category names in **sentence case**, e.g. *Duhovnost i liturgija*) | SCREAMING_SNAKE keys stay in code only |
| **Layer 1** | **Mapa ekosustava** | *karta / sistematizirana karta*, *medijski prostor* (as the layer name) |
| **Layer 2** | **Tematske struje** | *tematske cjeline*; the body must actually use *struje*, not only *kategorije* |
| **Layer 3** | **Atmosfera diskursa** | (surface the canonical name in the H1, not only YAML) |
| **Layer 4** | **Fokus na događaje** | *Dinamička analiza* (as the layer name) |
| Actor typology (L1) | **Divovi / Graditelji zajednica / Megafoni / Specijalizirani akteri** (pair English Giants/Community Builders/Megaphones/Specialists on first use) | English-only in prose |

**Typology names must be unique across layers.** L1's *Graditelji zajednica* (engagement quadrant) must not collide
with any L3 conflict-strategy group — give the L3 group a distinct name and state the two typologies are different constructs.

## 6. Headings
- **Sentence case everywhere** (first word + proper nouns only): *"Topografija digitalnog prostora"*. Reject Title Case in figure/axis text (*"Web Portali"* → *"Web portali"*; *"Duhovnost i Liturgija"* → *"Duhovnost i liturgija"*). **Croatian months are lowercase** (*siječanj*, *lipanj*).
- **The visible H1/title must contain the canonical layer name** (§5) — don't leave the controlled name only in YAML `categories` while the H1 is a different sentence.
- **No title↔subtitle duplication** and no subtitle that repeats the title — the subtitle must add information.
- The `index` numbered mono eyebrow (`01 — Analitički okvir`) is the one strong section-divider device — Croatian only. Analytical pages use plain sentence-case `##`/`###`; no numbered eyebrow needed.

## 7. Numbers & units (Croatian convention — identical in prose, valueboxes, figures)
- **Large counts → period grouping: `610.000`** (and `≈610.000`, `610.000+`). Set `big.mark = "."` in **every** `scales`/`format`/`comma` call so figures match prose. **Reject** thin-space `610 000`, US-comma `610,000`, spelled `610 tisuća`.
- **Compute, don't hand-type.** Drive every corpus figure from `data/processed/*.rds` via inline `` `r ` `` — never restate the same number in two formats on one page, never hardcode literals (per the project's no-hand-typed-numbers principle).
- **Percentages → digit + `%`, decimal comma:** `12,3 %`. Reject narrating percentages in words off a chart (*"oko 80 posto"*) — compute and show the figure.
- **Year ranges → en dash + Croatian ordinal periods: `2021.–2025.`** (no surrounding spaces), in YAML titles, chart titles and prose alike. Reject `2021-2025`, `2021.–2025.` with hyphen, `2021 do 2024`.
- **Approximation:** `≈` in display chrome, *oko* in prose. `≥` is fine for the inclusion rule (*"≥2 podudaranja"*).

## 8. Punctuation & typography
- **Em dash `—` (spaced)** — appositives, title/subtitle joins, parenthetical asides.
- **En dash `–`** — ranges only (`2021.–2025.`, `267–297`).
- **Hyphen `-`** — compounds only; **hyphenate paired adjectives consistently** (*društveno-politički*, *ekumensko-politički*).
- **Croatian quotation marks `„…"`** for any quoted term/title. Reject ASCII straight quotes. Pick one emphasis device: **bold** for constructs, *italic* for cited tokens.
- **Slash `/`** — genuine either/or or brand pairs (*Twitter / X*) only; not a bilingual or label-stacking separator.
- **Ampersand `&`** — write *i* in Croatian prose; keep `&` only in proper names/citations.
- **No decorative emoji.** **Links:** real Markdown hyperlinks with Croatian anchor text (*Poveznica*, not *Link*); relative in-site paths (`../mapa/diskurs.html`), never `raw.githack.com` previews or bracketed-literal URLs. Proofread for stray double spaces and typos before render.

## 9. Page architecture
**Every content page:** Croatian YAML `title` + an *informative* (non-duplicative) `subtitle`, `date: last-modified`,
category badges using the canonical layer name, and ≥1 framing sentence before any data/list block. Use the design-system
classes (`.metric-grid`/`.metric-card`, `.timeline`, `.featured-box`, `.card-grid`/`.info-card`).

**Every ANALYTICAL page follows this fixed spine:**
1. **Lead / abstract** — situates this layer vs the others (with in-site links), states scope (*"korpus od preko 610.000 objava… 2021.–2025."*) and goal, and names which research questions (Q1–Q5) it answers.
2. **Method note** — short, reader-visible: what was done, on what data, **state the real sample fraction in prose** (keep code and prose in sync), which lexicon/dictionary.
3. **KPI metric grid** — `.metric-grid` of 4 cards, canon-formatted values, right after the lead.
4. **Findings** — one section per movement: framing sentence → figure (title + subtitle + `Izvor:` caption) → interpretive read-out that *reads* the chart. **No chart without surrounding narrative.**
5. **Synthesis** — bolded headline findings + explicit forward-link to the next layer.

Use one shared theme (`theme_digikat()`) on **all** figures. Standardize figure captions on Quarto `fig-cap`/`tbl-cap`
+ `Izvor:` (source) / `Napomena:` (note). The data page (`baza`) keeps its codebook role but still gets ≥1 interpreting
sentence per distribution.

## 10. Microcopy
- **Valuebox/metric-card labels:** Croatian, genitive-plural noun, sentence case, value above label (*"Medijskih objava"*, *"Tematskih kategorija"*) — Croatian only, value **derived** not hand-asserted.
- **Buttons/CTA:** Croatian imperative, no English half (*"Istraži podatke"*, *"Preuzmi bazu podataka"*); confine CTAs to landing/service pages, give recruitment CTAs a styled button.
- **Callouts:** `.featured-box`/`.callout-note` for definitions and headline findings; sentence-case titles (an imperative "define-before-you-proceed" title is fine: *"Prije nastavka, potrebno je definirati metrike…"*).

## Pre-publish checklist
1. Croatian-first, diacritics intact, no English-only prose, no Croglish.
2. Numbers: `610.000` · `12,3 %` · `2021.–2025.` — computed, not hand-typed; figures use `big.mark="."`.
3. Terminology matches §5 canon (korpus / objava / tonalitet / RIK / canonical layer names); typology names unique.
4. Sentence-case headings; H1 carries the canonical layer name; no title↔subtitle duplication.
5. Right person for the page class; no leftover placeholder text; no marketing hype / jargon-fog.
6. Every figure/table/code block has a Croatian framing sentence; analytical pages follow the §9 spine.
7. Links relative & working; `„…"` quotes; no decorative emoji; proofread.
