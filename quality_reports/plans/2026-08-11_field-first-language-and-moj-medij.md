# Field-first language pass + „Moj medij" + the knowledge-transfer seam

**Date:** 2026-08-11 (rev. 2, same day) · **Owner:** PI (Luka Šikić) · **Status:** proposed, awaiting approval

## Why

DigiKat's public surface currently addresses one audience in one register. The landing page leads with
what the project *does* (mapira, empirijsko istraživanje, otvorena znanost), `pages/about.qmd` leads with
*web scraping*, *API integracije*, *strojno učenje*, *Big Data* and *Text Mining*, and `pages/mapa/index.qmd`
states the inclusion rule (window, term count, ensemble threshold) in its opening paragraph. That register
is correct for reviewers and funders. It is the wrong front door for the people the project is about:
editors and journalists inside Church media, lay media owners answering to donors, communications staff
answering to bishops, and priests who make videos.

Those groups share one deficit their own field has already written down, which is that they cannot afford
audience research. They share one question, which is whether they are reaching anybody. DigiKat already
holds the answer and states it in a vocabulary that keeps them out.

The correction is a **clarity repositioning, not a confessional one**. The project keeps its name, keeps
its neutral analytical voice, and adds no doctrinal benchmarking. What changes is that public pages lead
with the reader's question in plain Croatian and put the machinery one click away, plus one new capability
that lets an outlet look itself up.

Revision 2 adds a third element. The PI supplied a strategy resource (2026-08-11) locating a future
services layer *outside* DigiKat (personal site or separate entity), with the site itself carrying exactly
one modest artifact: a knowledge-transfer page. This plan adopts that seam and the register boundary it
implies, and nothing else from the commercial layer touches the repo.

## Decisions locked (PI, 2026-08-11)

| # | Decision | Consequence |
|---|---|---|
| 1 | **Field-first, method behind.** Rewrite the public pages in the field register; technical detail moves to a new `pages/metodologija.qmd`. | One voice, not two sites. Requires amending the analytical-page spine in the style rule. |
| 2 | **Keep „Katolički medijski opservatorij".** | No rename anywhere. The trigger-word concern is handled by surrounding language only. |
| 3 | **Their questions, neutral voice.** Lead with the field's own questions; no anchoring in HBK's *Crkva i mediji* or the World Communications Day messages; pastoral vocabulary only where natural. | Sidesteps the credibility conflict with any future study of how secular media frame Catholic topics. Nothing on the site claims to measure the Church against its own goals. The strategy resource assumed a pastoral register; this decision overrides it — the capability register below works in neutral Croatian. |
| 4 | **Build the „Moj medij" lookup.** An editor searches their outlet and gets one screen. | The only new analytical capability in this pass. Static, client-side (GitHub Pages has no server). |
| 5 | **Keep Q1–Q5, add plain-language translations.** | The style rule's requirement that each analytical page names the questions it answers stays satisfied. |
| 6 | **Leave the frozen-study doorway alone.** | No change to nav labels, study cards, slugs, or any published study. The `crkva-i-dezinformacije` URL keeps the word. |
| 7 | **No public research agenda in this pass.** | Nothing about planned studies appears on the site. The resource's "one public study per service line" criterion is recorded below as **internal** selection guidance only. |
| 8 | **REVERSAL (rev. 2, needs PI confirmation): the cooperation page returns.** Round one deferred the collaboration/independence page; the strategy resource re-derives it as the single on-site artifact of the knowledge-transfer seam, and the independence rule it carries is asset protection for that seam, not decoration. | New `pages/suradnja.qmd`, see Part D. If the PI re-defers, Part D drops out cleanly and nothing else in the plan depends on it except the two lead-magnet links, which then point nowhere and are omitted. |

**Explicitly out of the repo (handoffs to the personal site / business layer):** the priced service
catalog, case-study phrasing (situation → analysis → result), pilot analyses for friendly outlets,
anchor-client pursuit, grant-application support as a service, and any subscription offer (early-warning
monitoring on the conflict index, campaign evaluation). DigiKat may *demonstrate* these capabilities; it
never *sells* them. The one page that may even name commissioned work is `suradnja.qmd`.

**Standing rules adopted from the resource (record in MEMORY.md):**
- Clients and subjects may check facts before publication; they never veto findings. Unflattering results
  are published. Independence is the feature, not a constraint.
- No political portals as clients of any future services layer — it burns the field's trust and the
  secular market's at once.
- Any publication touching a paid relationship discloses it.

**PI checks to run early, outside this repo (the resource is right to insist):** the university's rules on
outside work and contracting, and the DigiKat funding terms on private exploitation of project outputs.
Nothing in this pass depends on the answers, but `suradnja.qmd`'s wording ("preko sveučilišta" vs. a bare
contact) does, so that page is written last.

## Scope

**In:** `index.qmd`, `pages/about.qmd`, `pages/baza.qmd`, `pages/mapa/*.qmd` (five layers + overview),
`pages/izvori/index.qmd` and the hub pages, `pages/resources.qmd`, `pages/news.qmd`,
`pages/schedule.qmd`, `pages/site-info.qmd`, `pages/pregled/izvrsni-pregled.qmd`, nav labels in
`_quarto.yml`, `.claude/rules/voice-and-style.md`, plus new `pages/metodologija.qmd`,
`pages/moj-medij.qmd` and `pages/suradnja.qmd`.

**Out:** `pages/studije/**` (frozen), `studies/**` (study working folders), every number anywhere. This
pass changes **no** computation, **no** aggregate, and **no** published figure. Prose and structure only,
plus additive pages and one additive data artifact.

---

## Part A — the language pass

**Doctrine, one line:** every public page opens with a question the reader already has, answers it in
plain Croatian, and links the machinery rather than reciting it.

Rev. 2 adds a second half to the doctrine: where a finding supports action, the page may say so — one or
two neutral sentences on what an editor or communications office could do with it (the **capability
register**). Neutral recommendation, never pitch; the words *usluga*, *ponuda*, *klijent* and any price
never appear outside `suradnja.qmd`.

### A1. New page: `pages/metodologija.qmd`

The technical home. Receives, by moving rather than duplicating:

- the inclusion rule in full (word list size, decisive/total term requirement, the 3.000-character window,
  the ensemble threshold), currently spread across `about.qmd` step 02 and `mapa/index.qmd` para 1;
- sampling fractions and the lexicon inventory (lilaHR, CroSentilex, CroSentilex Gold), currently inline
  in the mapa method notes;
- the accumulator-versus-corpus distinction and why finished studies stay pinned;
- the 2024 collection-instrument change and what it forbids (volume across the seam is not attention);
- the reproducibility route (GitHub, manifest, aggregates).

All figures read from `data/digikat_corpus_manifest.json` as they do today. No number is retyped.

### A2. Page-by-page

| Page | Change |
|---|---|
| `index.qmd` | H1 unchanged. The lead paragraph switches from what the project is to what a reader can find out. The stats band and source network stay. |
| `pages/about.qmd` | Q1–Q5 keep formal wording, each gains one plain-language line. The four goal cards lose *web scraping*, *API integracije* and the jargon-first framing of *Računalna analiza*. Pipeline step 02 keeps a one-sentence plain version and links to metodologija for the rule. The student-recruitment section (Big Data / Text Mining tags) stays; it serves a real third audience, but it moves below the substance. |
| `pages/mapa/index.qmd` | Opening paragraph loses the inclusion-rule sentence, gains the four questions the layers answer. Corpus size and span stay. |
| `pages/mapa/*.qmd` (5) | Lead becomes question-led. The method note collapses into a short reader-visible sentence plus a link to metodologija. **The synthesis section gains a capability-register close: 1–2 neutral sentences on what the finding means for someone who publishes** (e.g. diskurs → when conflict vocabulary climbs and around what; događaji → what fixed feasts reliably deliver and what that implies for timing). Findings, figures, interpretive read-outs and all numbers are untouched. |
| `pages/baza.qmd` | Keeps its codebook role. Gains a plain opening that says what the database is for and who may use it. |
| `pages/izvori/index.qmd` | The dense `callout-note` splits: the plain caveats stay visible, the technical provenance moves behind a link. Generated by `R/wiki_sources.R`, so the change is to the generator's template, not the page. |
| `pages/resources.qmd`, `news.qmd`, `schedule.qmd`, `site-info.qmd`, `pregled/izvrsni-pregled.qmd` | Light pass against the vocabulary table. |
| `_quarto.yml` | Add „Metodologija" to the navbar and footer; add „Suradnja" to the footer only (the resource's word is *modest* — not a navbar item). „Osnovne informacije" is a vague label for a landing page and is a candidate for something plainer. Studije menu untouched. |

### A3. Vocabulary table (applied site-wide)

| Currently | Plain-Croatian front-of-house |
|---|---|
| *web scraping*, API integracije | automatsko prikupljanje objava |
| strojno učenje, NLP, tokenizacija, lematizacija | računalna obrada teksta (technical names retained on metodologija) |
| Big Data, Text Mining | velike količine podataka (recruitment section only) |
| ansambl, prag 0,70, prozor od 3.000 znakova | pravilo uključivanja, stated plainly, detail on metodologija |
| stratificirani uzorak od 2–5 % | dio korpusa, s exact fraction on metodologija |
| korpus / objava / doseg / angažman / tonalitet / RIK | **unchanged** — these are already the canon and already plain |

The existing terminology canon in the style rule (§5) survives intact. Nothing in this pass renames a
construct; it removes the machine vocabulary that surrounds them.

## Part B — amend `.claude/rules/voice-and-style.md`

Without this, a later review pass restores the deleted paragraphs. This already happened once, and
`MEMORY.md` records the annual report's honesty-guard conflict as still unresolved.

Three edits:

1. **New §2b, "Two registers."** Public pages address the field first; the academic register lives on
   `pages/metodologija.qmd`, in the papers, and in the studies. Both are house voice; neither is a
   downgrade of the other.
2. **Amend §9 spine item 2 (method note).** Today it requires a reader-visible method note stating the
   real sample fraction in prose on every analytical page. It becomes: a one-sentence plain statement of
   what was measured on what, plus a link to metodologija, which carries the fraction. The rule against
   prose and code drifting apart stays; it just applies to metodologija instead of five pages.
3. **New §2c, "Capability register and the commerce boundary."** An analytical page's synthesis may close
   with 1–2 neutral, actionable sentences for practitioners. It may never name services, prices, clients
   or offers; `pages/suradnja.qmd` is the only page that may state that commissioned work exists, and even
   there in knowledge-transfer language, not sales language. This is the enforcement hook that keeps the
   lead-magnet wiring from drifting into a brochure.

Also record in `MEMORY.md`: the register split is a decision; the three standing rules from the resource
(fact-check-not-veto, no political-portal clients, paid-relationship disclosure).

## Part C — „Moj medij"

### C1. What the data actually supports (measured, not assumed)

`data/processed/source_summary.rds` is **17.976 rows of year × source** with `productivity`,
`total_interactions`, `avg_engagement_rate`, `total_reach`, covering **10.777 distinct sources**.
Coverage above a volume floor:

| Floor (total posts, all years) | Sources |
|---|---:|
| ≥ 10 | 1.764 |
| ≥ 50 | 736 |
| ≥ 100 | 501 |

That is the answer to the objection that an editor whose outlet is not among the 87 published catalogue
profiles finds nothing. At a ≥10 floor the lookup covers **1.764 outlets**, twenty times the catalogue.

**What exists:** yearly volume, interactions, reach, engagement rate, per source; per-platform actor
aggregates for six platforms; PI-owned editorial labels and publish flags for 109 sources
(`resources/dictionaries/source_labels.csv`); the Layer-1 typology rule.

**What does not exist and cannot be faked:** monthly series per source, a platform column inside
`source_summary`, theme mix per source, and tone per source. The NLP layer runs on a stratified 2–5 %
sample, so for most outlets a per-source theme or tone figure would rest on a handful of documents even
if the aggregate existed.

### C2. Version one (this pass, no pipeline change)

A single page, `pages/moj-medij.qmd`, static and client-side:

- a search box over the eligible sources;
- headline card: total objava, interakcija, doseg, and prosječan angažman po objavi, all years;
- a yearly trend (volume and interactions), with the collection-seam caveat attached in plain words;
- position: rank and share within the outlet's platform, and against a peer group (platform + editorial
  label where the sidecar has one);
- typology placement, reusing the Layer-1 rule so the lookup and the catalogue can never disagree;
- a link to the full catalogue profile where one exists;
- **a closing band (lead-magnet wiring): one sentence that a deeper, private analysis of a single outlet
  is the kind of work described on [Suradnja](suradnja.qmd), with the link and nothing more.** Falls away
  if decision 8 is re-deferred.

Build shape: a new `R/06_moj_medij.R` precomputes one PII-free `data/page-ready/moj_medij.json` from the
existing tracked aggregates; the page ships a small vanilla-JS widget over it. No server, no new
dependency, no read of the corpus at render time.

**Disclosure policy (needs PI confirmation, see open decisions):** a volume floor, plus the sidecar's
`publish` flag governing any source that is a named individual rather than an institution. The catalogue
already withholds 27 actors pending editorial review and the lookup must honour the same decision.
`R/check_disclosure.R` runs against the generated JSON before it is committed.

### C3. Version two (separate approval, not this pass)

Monthly series, a platform split, and theme mix and tone for outlets above a higher volume floor. This
requires extending `R/03_aggregate.R` and running it with `--apply`, which is a HARD GATE that overwrites
tracked `data/processed/*.rds`. Listed so the phase boundary is explicit, not smuggled in.

Version two is also what an early-warning or evaluation service would run on. It stays a research
deliverable here; any service built on it lives outside the repo.

## Part D — `pages/suradnja.qmd` (the knowledge-transfer seam)

One short page, service register per the style rule (warm, grounded, `vi` allowed), footer-linked. Content,
in full — this is deliberately all of it:

1. **What the team does on commission:** analize po narudžbi, evaluacije kampanja i događanja, radionice
   i edukacija (data literacy for newsrooms — the field's own stated priority). Knowledge-transfer
   framing; universities do this and nobody blinks.
2. **The independence rule, stated plainly:** naručitelji i subjekti analiza mogu provjeriti činjenice
   prije objave; nalaz ne mogu mijenjati ni zaustaviti. Objavljujemo i nalaze koji nisu laskavi. Podaci su
   otvoreni (CC BY 4.0), pa svatko može provjeriti sve.
3. **Disclosure commitment:** svaka publikacija koja se dotiče plaćenog odnosa taj odnos navodi.
4. **Contact.**

No prices, no menu, no case studies, no client names. The page is simultaneously the independence
statement round one deferred — the two documents turned out to be the same document.

Written **last** in the sequence, because its contracting sentence depends on the PI's off-repo checks
(university rules, funding terms).

## Internal guidance recorded, not published

Future public studies should each demonstrate one capability the knowledge-transfer page names (a past
media-storm reconstruction → monitoring; an Easter/campaign analysis → evaluation; a youth-reach study →
strategy; the pilgrimage study already demonstrates destination work). This is a selection criterion for
the PI's planning, kept out of the site per decision 7. The realistic counterparties are dioceses, orders
and shrines, regulator/ministry/EU programs, and international Catholic foundations — not small newsrooms;
that shapes which demos matter, and none of it belongs on DigiKat.

---

## Verification and cost

1. `data/processed` is **current** as of 2026-08-11: its `input.sha256` matches
   `data/digikat_corpus_manifest.json`, so `digikat_assert_aggregates_current()` will not halt a render.
2. `freeze: auto` re-executes every R chunk on any source change, so a prose-only edit to the mapa pages
   still forces a full udpipe re-run. Budget a long full render, not a text edit.
3. Pause Dropbox sync before the full render (see `CLAUDE.local.md`); no concurrent Quarto process.
4. Run Quarto from the repo root only.
5. After a full render: `git checkout -- docs/pages/studije docs/site_libs`, because the studije exclusion
   drops those pages and prunes the content-hashed CSS bundles they reference.
6. Confirm no render scatter outside `docs/`, diacritics literal in the rendered HTML, and
   `data/processed/*.rds` byte-identical afterwards.
7. `Rscript tests/run_tests.R`, `R/check_sources.R`, `R/check_site_links.R`, `R/check_disclosure.R` all green.
8. Per-page review with the `/review-page` lens on `index`, `about`, `metodologija`, `suradnja` and one
   mapa page before the full render.

## Sequence

1. Amend the style rule (Part B) — everything else is measured against it.
2. Write `pages/metodologija.qmd` by moving content out of `about` and `mapa/index`.
3. Language pass over the pages in A2, one page at a time, rendering each; capability-register closes on
   the five mapa pages in the same pass.
4. `R/wiki_sources.R` template edit, regenerate the catalogue.
5. `R/06_moj_medij.R` + `pages/moj-medij.qmd`, disclosure check, render.
6. `pages/suradnja.qmd` (after the PI's off-repo checks resolve its contracting sentence).
7. `_quarto.yml` nav + footer, full render, restore step, verification battery.
8. `MEMORY.md` entries (register decision + standing rules), commit.

## Open decisions before implementation

1. **Confirm decision 8** — the suradnja page reverses the round-one deferral. If re-deferred, Part D and
   the two lead-magnet links drop out; everything else stands.
2. **Volume floor and the personal-account rule for „Moj medij".** ≥10 posts gives 1.764 outlets, ≥50
   gives 736. Recommendation: ≥10 for web domains, and for named individuals on social platforms show
   only those with `publish = yes` in the sidecar.
3. **Does „Moj medij" become the front door to `pages/izvori/`?** Recommendation: yes, the catalogue index
   gains the search box at the top and the 87 deep profiles stay as they are.
4. **Rename „Osnovne informacije" in the navbar?** It is the landing page and the label says nothing.
5. **Off-repo, PI:** university outside-work/contracting rules and project funding terms — determines one
   sentence on `suradnja.qmd`, blocks nothing else.
