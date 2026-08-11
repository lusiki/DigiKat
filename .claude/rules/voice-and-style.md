---
paths:
  - "pages/**/*.qmd"
  - "R/*.qmd"
  - "_quarto.yml"
---

# DigiKat — Voice & Style Guide

The house voice for everything **reader-visible** on the DigiKat website (Croatian content; this guide is
English). Derived from a cross-page audit; it locks in what the strong analytical pages already do and resolves
the drift elsewhere. When editing or writing any page, conform to this. The five `pages/mapa/*` analytical pages
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

### 2b. Two registers — field first, method behind
The public pages address **the field first**: editors and journalists in Church and secular media, communications
staff, lay media owners, anyone who publishes and wants to know whether they are reaching anybody. They open with
a question that reader already has, answer it in plain Croatian, and **link** the machinery rather than reciting it.

The **academic register** — the inclusion rule in full, sampling fractions, the lexicon inventory, the
accumulator-versus-corpus distinction, the collection-instrument change, the reproducibility route — lives on
`pages/metodologija.qmd`, in the papers, and in `studies/**`. One click away, never deleted, never on the front page.

Both are house voice. Neither is a downgrade of the other, and the analytical pages do not become simpler: they
keep every finding, figure, number and interpretive read-out. What moves is the machine vocabulary that used to
surround them. **Do not restore a technical paragraph to a public page because it "reads as more rigorous"** — if
it belongs to the method, it belongs on metodologija, and a review pass that reverses this is reversing a decision
(PI, 2026-08-11), not fixing a lapse.

**Front-of-house vocabulary** (applies wherever a reader outside the project can land):

| Reject in public prose | Write instead |
|---|---|
| *web scraping*, API integracije | automatsko prikupljanje objava |
| strojno učenje, NLP, tokenizacija, lematizacija | računalna obrada teksta (technical names kept on metodologija) |
| Big Data, Text Mining | velike količine podataka (student-recruitment section only) |
| ansambl, prag 0,70, prozor od 3.000 znakova | pravilo uključivanja, stated plainly, detail on metodologija |
| stratificirani uzorak od 2–5 % | dio korpusa, with the exact fraction on metodologija |

The §5 terminology canon is untouched by this. *Korpus*, *objava*, *doseg*, *angažman*, *tonalitet*, *RIK* and the
layer names are already plain and stay exactly as they are; nothing in this pass renames a construct.

### 2c. Capability register and the commerce boundary
Where a finding supports action, an analytical page's **synthesis may close with one or two neutral sentences** on
what someone who publishes could do with it — when conflict vocabulary climbs and around what, which fixed feasts
reliably deliver attention and what that implies for timing. That is the **capability register**: a neutral
read-out addressed to a practitioner, in the same measured third person as the rest of the page.

It is not a pitch, and the boundary is a hard one. The words *usluga*, *ponuda*, *klijent*, *naručitelj*, any price,
any menu of work, and any case study **never appear on a public analytical or content page**. DigiKat may
*demonstrate* a capability; it never *sells* one. A dedicated knowledge-transfer page is the only artifact that
could ever state that commissioned work exists, and it is **deferred as of 2026-08-11** — so today the answer is
that no page does. If that page is ever built, everything commercial stays on it and in knowledge-transfer
language, never sales language.

**Out of bounds (reject):**
- Marketing hype / superlatives: *"Biblija za svakoga", "Najvažnija zajednica", "sveobuhvatan uvid", "pouzdanije i inovativnije znanstvene kulture"*. Enthusiasm yes; slogans no.
- Service, price or client vocabulary anywhere on the public site (§2c).
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
| The 710k master corpus | **korpus** (formal: *glavni skup podataka*) | *baza podataka* (as the corpus), *dataset / dataseta / dataset-a*, bare *baza* |
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
- **Large counts → period grouping: `710.307`** (and `≈710.000`, `710.000+`). Set `big.mark = "."` and
  `decimal.mark = ","` in **every** `scales`/`format`/`comma` call so figures match prose. **Reject**
  thin-space `710 000`, US-comma `710,000`, spelled `710 tisuća`.
- **Compute, don't hand-type.** Drive every corpus figure from `data/processed/*.rds` via inline `` `r ` `` — never restate the same number in two formats on one page, never hardcode literals (per the project's no-hand-typed-numbers principle).
- **Percentages → digit + `%`, decimal comma:** `12,3 %`. Reject narrating percentages in words off a chart (*"oko 80 posto"*) — compute and show the figure.
- **Year ranges → en dash + Croatian ordinal periods: `2021.–2026.`** (no surrounding spaces), in YAML titles, chart titles and prose alike. Reject `2021-2026`, hyphenated ranges, or `2021 do 2026`.
- **Approximation:** `≈` in display chrome, *oko* in prose. `≥` is fine for the inclusion rule (*"≥2 podudaranja"*).

## 8. Punctuation & typography
- **Don't stack connectors.** At most **one** em-dash aside per paragraph, and never pair an em dash with a
  semicolon in the same paragraph. Default to a full stop over `;` — reserve the semicolon for a single genuinely
  tight coordinate clause, not a habitual paragraph joiner. If a sentence needs two dashes (or a dash plus a
  semicolon) to hold together, it's doing too much — split it into two plain sentences instead. (Incident:
  the `mapa/index.qmd` lead packed two em dashes and a semicolon into two sentences — reworked to zero.)
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
1. **Lead / abstract** — **question-led** (§2b): opens with the question a reader who publishes already has,
   then situates this layer vs the others (with in-site links), states scope (*"korpus od 710.307 objava…
   2021.–2026."*, noting that 2026 is partial), and names which research questions (Q1–Q5) it answers. Q1–Q5 keep
   their formal wording; each gets a plain-language line beside it.
2. **Method note** — one reader-visible sentence: what was measured, on what, plus a link to
   [Metodologija](../metodologija.qmd), which carries the sample fraction, the lexicon inventory and the inclusion
   rule. The fraction no longer has to be restated on each page. **The no-drift requirement survives the move**:
   prose and code must still agree, and metodologija is now the single place that can drift, so it is the page to
   re-check after any pipeline change.
3. **KPI metric grid** — `.metric-grid` of 4 cards, canon-formatted values, right after the lead.
4. **Findings** — one section per movement: framing sentence → figure (title + subtitle + `Izvor:` caption) → interpretive read-out that *reads* the chart. **No chart without surrounding narrative.**
5. **Synthesis** — bolded headline findings, an optional 1–2 sentence capability-register close (§2c), and an
   explicit forward-link to the next layer.

Use one shared theme (`theme_digikat()`) on **all** figures. Standardize figure captions on Quarto `fig-cap`/`tbl-cap`
+ `Izvor:` (source) / `Napomena:` (note). The data page (`baza`) keeps its codebook role but still gets ≥1 interpreting
sentence per distribution.

## 10. Microcopy
- **Valuebox/metric-card labels:** Croatian, genitive-plural noun, sentence case, value above label (*"Medijskih objava"*, *"Tematskih kategorija"*) — Croatian only, value **derived** not hand-asserted.
- **Buttons/CTA:** Croatian imperative, no English half (*"Istraži podatke"*, *"Preuzmi bazu podataka"*); confine CTAs to landing/service pages, give recruitment CTAs a styled button.
- **Callouts:** `.featured-box`/`.callout-note` for definitions and headline findings; sentence-case titles (an imperative "define-before-you-proceed" title is fine: *"Prije nastavka, potrebno je definirati metrike…"*).

## Pre-publish checklist
1. Croatian-first, diacritics intact, no English-only prose, no Croglish.
2. Numbers: `710.307` · `12,3 %` · `2021.–2026.` — computed, not hand-typed; figures use
   `big.mark="."`, `decimal.mark=","`.
3. Terminology matches §5 canon (korpus / objava / tonalitet / RIK / canonical layer names); typology names unique.
4. Sentence-case headings; H1 carries the canonical layer name; no title↔subtitle duplication.
5. Right person for the page class; no leftover placeholder text; no marketing hype / jargon-fog.
6. Every figure/table/code block has a Croatian framing sentence; analytical pages follow the §9 spine.
6b. Field register on public pages (§2b): the lead opens with the reader's question, no front-of-house
   vocabulary from the §2b table, method detail linked to metodologija rather than recited. No service, price
   or client language anywhere (§2c).
7. Links relative & working; `„…"` quotes; no decorative emoji; proofread.
8. No stacked connectors: ≤1 em dash per paragraph, never an em dash + semicolon together, `;` used sparingly.
