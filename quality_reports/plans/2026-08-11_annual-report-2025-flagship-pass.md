# Plan — annual report 2025, flagship editorial pass

**Date:** 2026-08-11 · **Requested by:** PI · **Scope:** `studies/annual-report/` only. No data, no
corpus, no `docs/`.

## Goal

Edition 1 currently spends its first four pages defending its method before showing a finding. The
report's job is to be a flagship bait product: informative at a surface level, simple, catchy,
serious, appealing, and free of methodological detail. Every self-defensive passage moves to the
back matter (Metodologija) or disappears; the reader meets the ten numbers, the papal-death arc and
the myth box inside three minutes.

## Decisions

1. **Inclusion rule out of the front.** The 119-term / 0,70-threshold / 84,5 % sentence is replaced
   by a breadth claim ("the whole Catholic media space is here"). Full rule stays in Metodologija.
2. **Collection-gap arithmetic out of the front.** The 351-days / 3 948-missing-posts paragraph is
   deleted. The gap stays drawn on the charts and stated once in Metodologija.
3. **The "why we do not compare years" callout is deleted.** The within-stream comparison is now
   claimed, not justified. One sentence in Metodologija carries the rule.
4. **The sampling paragraph is deleted**, including the unclear "uz svaku takvu brojku stoji koliko
   je objava iza nje". Sample sizes survive in the figure source notes and Metodologija.
5. **Colons and em-dashes are swept** from all reader-visible Croatian prose, in the template and in
   the generated figure/table titles and notes. `Izvor:` source-note prefixes are the exception.
6. **"Koje institucije najviše objavljuju?" → "Koji izvori najviše objavljuju?"** (league table title
   in `03_report_assets.R`; they are sources, not institutions).
7. **Nothing half-done is announced.** "Ostali izvori … dok popis ne bude ratificiran" and "Strelice
   promjene doći će s drugom edicijom" are deleted.
8. **The typology-movement caveat is replaced** by an intuitive sentence about what the groups mean.
9. **Structural changes:** the "Kako čitamo ove brojke" chapter is dissolved into two sentences in
   the Sažetak; the English executive summary moves to the back matter; "Što još ne mjerimo" is
   reframed as "Što slijedi" (roadmap, not confession); the product-demo box moves from the special
   chapter to the end of the events chapter, where it belongs.
10. **Two more "Pitanja koja podaci otvaraju" boxes** (themes, events) and **two more teaser lines**
    (themes, tone) — the conversion devices the PI likes, applied evenly.
11. Tone chapter now leads with the finding rather than with the definition of the tone score.

## Rejected

- A second "mit i podaci" box on "only church media write about the Church". Checked against the
  data first: `confessional_share_classified` is **62,8 %**, so the myth is true among labelled
  sources and the box would have been false.
- Relaxing `05_report_checks.R`. Not needed — every honesty guard is satisfied by keeping its exact
  trigger phrase in Metodologija (`prekid`, `dana s prikupljanjem`, `unutar istoga toka
  prikupljanja`, `status prijedloga`, `Vrh u podacima pokazuje`, `Kompozitni indeks`, `Publika`).
  Both title/note counts stay at 18, so all nine figures and all nine tables remain installed.

## Conflict to resolve with the PI (not resolved here)

`.claude/rules/annual-report-writing.md` "honesty guards" require the seam caveat, indicative-label
hedging and visible gap panels **in the findings prose**. This pass moves them to the back matter.
The rule text needs amending to "caveats live in Metodologija and on the website, not in findings
prose", or a future reviewer pass will restore the deleted paragraphs.

## Execution

`03_report_assets.R` → `04_sync_fragments.R` → `05_report_checks.R` → `06_render_report.R`
(stages 00–02 are not re-run; they read the corpus and nothing upstream changed).
