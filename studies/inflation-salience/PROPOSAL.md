# Proposal (first draft) — Inflation for whom? How Croatian Catholic media covered the cost-of-living shock

**Date:** 2026-06-29 · **Status:** ⚠️ SUPERSEDED by [PROPOSAL_v2_broadened.md](PROPOSAL_v2_broadened.md)
(2026-06-30, after a first-pass run showed Catholic *outlets* barely cover inflation; the unit broadened to
the religion×inflation intersection). Kept for the record. · **Owner:** L. Šikić
**Companion docs:** [LITERATURE.md](LITERATURE.md) · brainstorm + panel critique in
`research-ideas/inflation-salience-preferential-option-brainstorm.md`

> This is the *simple* version on purpose. It is built around **two plain questions and one figure**.
> The harder econometrics (conditional coefficients, lead-lag, preregistration) are parked in §7
> "If we want to go further" — they are optional upgrades, not part of the first paper.

---

## 1. The idea in one paragraph

Between 2021 and 2025 Croatia went through a sharp cost-of-living shock — food and energy prices rose much
faster than the headline inflation number. Catholic Social Teaching has a clear stance on this: the Church is
supposed to care most about how hardship lands on **the poor**. So this paper asks a simple, human question:
**when prices spiked, did Croatian Catholic media actually pay attention — and when they did, did they talk
about inflation as an *injustice* (a structural problem hurting the poor) or as a *charity* matter (donate,
help, Caritas)?** We answer it by counting how much Catholic outlets wrote about inflation, lining that up
against real price data, and reading how they framed it.

---

## 2. Two questions (that's it)

- **Q1 — Attention.** Did Catholic-media attention to inflation rise and fall with **real prices** —
  and especially with **food and energy** (the part that hits poor households hardest), more than with the
  headline number? *(Did they look at it?)*
- **Q2 — Framing.** When they covered inflation, did they frame it **structurally** ("this is unjust, the
  system fails the poor" — the CST critique) or **charitably** ("here's how to help" — almsgiving/Caritas)?
  *(How did they look at it?)*

A nice secondary question if the data cooperate: **do Catholic outlets do this differently from secular
media** (a small comparison), and **do the three big outlets differ** (Glas Koncila vs. Bitno.net vs. IKA)?

We deliberately do **not** start with a causal claim. We describe a pattern and let the reader judge whether
it looks like Catholic Social Teaching at work.

---

## 3. Why it's worth doing (the gap, in plain terms)

Three bodies of work exist, and none of them meets the other two (see [LITERATURE.md](LITERATURE.md)):

1. **Inflation & the media** — we know secular media only start covering inflation once it crosses ~4%, and
   that coverage is about *who is hurt* (the "heating or eating" framing), not the headline rate. The ECB even
   built a media inflation-attention index. *But all of this is secular, Western press.*
2. **Catholic Social Teaching on the economy** — from "the preferential option for the poor" to Pope Francis's
   "this economy kills" ("ova ekonomija ubija"), the doctrine is clearly about *structural* injustice, and
   theology itself distinguishes **charity** (relieving symptoms) from **justice** (changing structures).
   *But studies look at secular press about poverty, not at religious media as the storyteller.*
3. **Croatian Catholic media** — well studied on identity, nation, and culture-war themes. *But its
   coverage of the economy has never been measured, and never linked to real economic data.*

**Nobody has put the three together.** That's the opening, and it's a genuinely simple, intuitive one.

---

## 4. Data (we already have most of it)

- **The corpus:** the DigiKat master — ≈610k Croatian/Bosnian media posts, 2021–2025, already filtered to
  Catholic/religious content. We tag every post that mentions inflation. *(All of this exists; the inflation
  tagging is the main new step.)*
- **Real price data (free, public, monthly):** Croatian inflation (HICP) — the **headline** number *and* the
  **food + energy** sub-indices. Optionally unemployment and Google Trends for "inflacija" as a public-mood
  check.
- **Outlets:** Glas Koncila (Church weekly), Bitno.net (lay portal), IKA (news agency), and the rest of the
  Catholic field; the corpus already records which outlet each post came from.

---

## 5. What we actually do (three steps)

1. **Count attention.** For each month, compute the share of Catholic posts that are about inflation. Plot it
   against real inflation (headline vs. food/energy). *One clear time-series figure — this is the heart of the
   paper.*
2. **Read the framing.** Take the inflation posts and label each one **structural** (injustice/critique) vs.
   **charitable** (help/Caritas) vs. **other**. Use a keyword pass first, then have a person check a sample
   for accuracy. *(The structural/charity split borrows Iyengar's well-known episodic-vs-thematic framing —
   so it's a tested idea, not something we invented.)*
3. **Compare.** Show how the framing mix differs across the three outlets, and — if feasible — against a small
   secular comparison set.

That's the whole study. A figure, a frame-mix table, and an outlet comparison.

---

## 6. Two quick checks we do FIRST (so we don't fool ourselves)

Both are an afternoon of work and either could reshape the paper — so they come before anything else:

- **Is our inflation tagging clean?** Hand-check ~200 tagged posts. ("cijena" can mean a market price *or*
  "the price of salvation" in a homily — we need to catch that.)
- **Do Catholic media even talk about the economy this way?** Quickly check what share of economic coverage is
  CST-style at all vs. pure charity appeals vs. culture-war. **If there's almost no structural economic
  framing, that absence becomes the finding** — and it's still an interesting, publishable one.

---

## 7. If we want to go further (optional — NOT the first paper)

Park these. They're upgrades a reviewer might ask for, or a follow-up paper:

- A regression testing whether food/energy still predicts attention *after* controlling for headline CPI.
  (Honest caveat: only ~50 monthly points and food/energy moves with the 2022 war — so keep it modest and
  treat it as supporting, not headline.)
- A lead-lag check: does Catholic media *lead* public attention or just *echo* it (agenda-setter vs.
  resonance)?
- If the food/energy regression becomes the headline claim, preregister it (OSF). For the descriptive first
  paper, **no preregistration needed.**

---

## 8. Where it could go (venue)

Best fit: **Journal of Media and Religion** (international) or **Medijska istraživanja** (Croatian, English
accepted). Both reward exactly this kind of descriptive religion-and-media study. *(We avoid pitching the
descriptive first draft to a high-theory new-media journal — wrong audience.)*

---

## 9. Working title

*Inflation for whom? How Croatian Catholic media framed the 2021–2025 cost-of-living shock.*

---

## 10. Next step

1. Run the two §6 checks via `/data-analysis` (needs R + the master — run on the pipeline machine, or I write
   the script and hand it off).
2. If they pass, build the §5 figure + framing table.
3. Firm up the bibliography — confirm the handful of UNVERIFIED items in [LITERATURE.md](LITERATURE.md) before
   they go into `refs.bib`.
