# Plan — Navigacija + preseljenje sadržaja: index → O projektu, Mapa pregled, redoslijed tabova

**Date:** 2026-07-01 · **Scope:** site IA / nav refactor (`_quarto.yml`, `index.qmd`, `pages/about.qmd`, new `pages/mapa/index.qmd`)

## Context

The landing page (`pages/index.qmd`, nav label "Osnovne informacije") currently carries three heavy
sections below the hero+stats: the 5-step data→analysis pipeline, the Q1–Q5 research questions, and the
full team roster. The PI wants the landing leaner and these moved into **O projektu** (`pages/about.qmd`),
which today holds only goals/value/recruitment. Separately: the "DigiKat" brand and the bare site URL
currently open **O projektu** (because Quarto auto-generates `docs/index.html` as a redirect to
`pages/about.html` — it skips `pages/index.qmd` as the home since that page is `page-layout: custom`), the
navbar tab order needs fixing, and the "Mapa" entry point should land on an **overview of all five maps**
rather than jumping straight into Mapa ekosustava.

Outcome: a lean landing that teases the framework and links into O projektu; a consolidated "O projektu"
page (goals → questions → analytical framework → value → leader/team → recruitment); a new Mapa overview
hub; the brand/home resolving to the landing; and the requested tab order.

## Design decisions (please confirm any you'd change)

1. **Migration scope** — "everything below the `Od medijske objave do analize` description" = the 5-step
   pipeline `<details>`, the whole **Istraživačka pitanja** section, and the whole **Tim** section. The
   framework **heading + one-line description STAY on the landing** as a teaser (the boundary line).
2. **The "tab" on the landing** = a styled button under the framework teaser — *"Cijeli analitički okvir i istraživanje →"* — linking to O projektu. (The landing keeps hero + stats + framework-teaser only.)
3. **Brand/home fix** = move the landing to a **root `index.qmd`** so `docs/index.html` *is* the landing
   (no redirect). This fixes both the "DigiKat" brand click and the bare URL. Trade-off: the landing's URL
   changes from `/DigiKat/pages/index.html` to `/DigiKat/` (the desired home URL; nothing links to the old
   path — verified). Lighter alternatives (`logo-href`, redirect stub) fix only the brand, not the bare URL.
4. **Mapa overview** = new `pages/mapa/index.qmd` (section landing) with a card per map + jump link; also
   added as the first item ("Pregled mapa") in the navbar "Mapa medijskog prostora" menu.

## Files & changes

### 1. `_quarto.yml` (nav order, render list, Mapa menu, home href)
- **`render:`** add `- index.qmd` alongside `- pages/**/*.qmd`.
- **Navbar `left:` order** → Osnovne informacije · O projektu · Baza podataka · Mapa medijskog prostora · Tematska istraživanja · Projektni raspored · Obavijesti · Resursi.
- **"Osnovne informacije"** href → `index.qmd` (root).
- **"Mapa medijskog prostora"** menu: prepend `- text: "Pregled mapa"` → `pages/mapa/index.qmd`, above the five existing layer entries.
- Footer "Metodologija" link (→ `pages/about.qmd`) left as-is.

### 2. `index.qmd` (git-move from `pages/index.qmd`; trim + retarget links)
- `git mv pages/index.qmd index.qmd` (preserves history).
- **Remove** the migrated blocks: the framework `<details>` 5-step timeline ([pages/index.qmd:79-109](pages/index.qmd#L79-L109)), the **Istraživačka pitanja** section ([pages/index.qmd:113-132](pages/index.qmd#L113-L132)), the **Tim** section ([pages/index.qmd:134-157](pages/index.qmd#L134-L157)).
- **Keep** the framework eyebrow + `Od medijske objave do analize` heading + description; **append a button** *"Cijeli analitički okvir i istraživanje →"* → `pages/about.html`.
- **Retarget the two hero links** now that the file sits at repo root: `baza.html` → `pages/baza.html`; `mapa/mapa.html` → `pages/mapa/index.html` (the new overview).

### 3. `pages/about.qmd` (integrate migrated content in the production design system)
- Broaden `title` → `"O projektu"`, `subtitle` → `"Ciljevi, istraživačka pitanja, analitički okvir i istraživački tim"`.
- Insert three sections, re-expressed with the site's own classes/markdown (drop the landing's full-width `<section>`/1180px/eyebrow chrome; port the inner card grids ~verbatim — they're self-contained and on-brand). Proposed order:
  1. **Ciljevi projekta** (existing)
  2. **## Istraživačka pitanja** — Q1 in a `.featured-box`, Q2–Q5 in a `.card-grid` (from the ported Q-cards)
  3. **## Od medijske objave do analize** — the 5-step pipeline (ported numbered-card timeline, framing sentence first)
  4. **Doprinos i vrijednost projekta** (existing)
  5. **## Voditelj projekta** — Luka Šikić card shown; the other 9 members kept in a `<details>` "Prikaži cijeli tim" (collapsible) — this is the "Istraživački tim" → "Voditelj projekta" rename + keep-collapsible request
  6. **Pridružite se našem istraživanju!** (existing recruitment CTA — stays last)

### 4. `pages/mapa/index.qmd` (NEW — Mapa overview hub)
- Standard content page (`title: "Mapa medijskog prostora"`, informative subtitle, `date: last-modified`, category badge). No R/data chunks → renders anywhere, fast.
- Framing lead: four analitičke razine + a temporal cross-cut (Evolucija), on the ~710.000-objava korpus, 2021.–2026.
- `.card-grid` of five `.info-card`s, each = canonical layer name + 1-sentence "what it answers" + a jump link:
  - **Mapa ekosustava** → `mapa.html` — tko objavljuje i koliko odjekuje (volumen, doseg, angažman; tipologija aktera).
  - **Tematske struje** → `mapa_stats.html` — o čemu se govori (16 tematskih kategorija, stratificirani uzorak).
  - **Atmosfera diskursa** → `diskurs.html` — kako se govori (emocije i tonalitet; RIK).
  - **Fokus na događaje** → `događaji.html` — kada se govori (događaji oblikuju volumen/konflikt/tonalitet).
  - **Evolucija ekosustava** → `evolucija.html` — kako se mijenja kroz vrijeme (rast, migracija utjecaja, širenje kruga aktera).

## Voice / correctness guardrails
- Croatian-first, diacritics literal UTF-8; house voice per `.claude/rules/voice-and-style.md` (canonical layer names, `710.000` period-grouped, `2021.–2026.`, `—`/`–`, no marketing hype, no decorative emoji, real Markdown links with Croatian anchors). No hand-typed corpus numbers introduced (overview prose uses only already-published rounded figures / labels, no new derived stats).

## Verification (touched pages only — NOT a full render)
Pause Dropbox first (repo lives inside Dropbox — render file-locking hazard). Using off-PATH RStudio Quarto + R 4.4.1 from the **repo root**:
- `md5sum data/processed/*.rds` before/after (must be identical — these pages read no data).
- Render individually: `index.qmd`, `pages/about.qmd`, `pages/mapa/index.qmd` (rc=0, no chunk errors).
- Inspect generated HTML: (a) navbar-brand href resolves to root `index.html`; (b) `docs/index.html` is the landing, not a redirect; (c) nav tab order matches; (d) Mapa menu shows "Pregled mapa"; (e) diacritics literal (č ć ž š đ, not `&#…;`); (f) the three landing→about / hero → baza,mapa-overview links resolve; (g) no stray output outside `docs/` (no root `site_libs/`, `pages/**/*.html` scatter, `*_files/` beside sources).
- Optional: multi-lens review workflow (voice-and-style + Croatian + link/numeric verify) on the three edited pages.

## HARD GATE (separate, user-confirmed step)
The **full-site `quarto render`** (so the new nav order + Mapa "Pregled" propagate to *all* pages, and the
orphaned `docs/pages/index.html` reconciles) overwrites `docs/` — I will **stop and confirm** before running
it, or hand off to `/deploy`. This plan's own verification renders only the three touched pages.
