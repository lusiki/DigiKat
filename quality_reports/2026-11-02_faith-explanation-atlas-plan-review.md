# Review of the plan "Exploratory atlas of public explanation of faith" and of the essay redesign

Date: 2026-11-02
Reviewed: `quality_reports/plans/2026-11-02_faith-explanation-existing-evidence-atlas.md` (saved plan) and the
chat-only redesign ("essay about people, voices and the public presence of faith", ~35 pages, actor portraits).
Method: read-only inventory of the saved outputs of five studies and one exploration. No analysis was run,
no file in any study was changed. Two inventory tabulations over already exported CSVs were made to see what
the material can carry; their figures are orientation for this review, not numbers for the report.
Status: proposals. Nothing below is approved or implemented.

---

## 1. The one finding that changes the plan

The essay wants portraits of named people and their words. The saved material splits as follows.

| Source | What it holds per person | Who it names |
|---|---|---|
| A. `studies/catholic-voices-network` (corpus to 2026-10-16, 611 583 docs) | documents, outlets, platforms, dated offices (Wikidata), confessional / secular / unlabelled split, quarterly series, co-presence edges, text families. **No speech, no passages.** | 110 people public by role and above thresholds |
| D. `studies/theological-voices` (corpus to 2026-06, 413 985 rows) | mentions **and statements** (name + speech verb in one paragraph), Catholic vs other sources, per year; the "teolog" label analysis; women; 300-post coded sample; 50 coded channels. **No quotations in the report.** | 117 persons on a PI-defined closed list |
| B. `studies/theological-voices-v2` (web frame 282 701 publications, 2 000 coded) | attributed voices with **passages**, role, "interprets faith", "own experience", organisation. Numbers withdrawn by policy; records exist. | anyone the model extracted, incl. private individuals |
| C. `studies/theological-voices-editorial` | source concentration, exact-text reuse, 50-source directory | outlets only |
| Exploration `2026-10-26_office-register-mentions` | full-name mention counts for the 1 394-person register, per platform | register names (lookup, not speakers) |

Cross-checking A against D on names (inventory only):

- Of the 117 closed-list persons, **46 are among A's 110** and **70 are not**. The 70 absent are 27 priests,
  22 academic theologians, 6 lay voices, 6 religious sisters, 5 Međugorje seers and 4 bishops.
- Of A's 110, only **7 are Catholic voices who are not bishops or popes** (Damir Stojić, Ante Vučković, Jozo
  Grbeš, Ivan Bodrožić, Tonči Matulić, Marin Karačić, Josip Šimunović). **64 of the 110 are not on the closed
  list at all**, and most of those are politicians, Vatican officials and foreign statesmen (Milanović,
  Plenković, Jandroković, Trump, Biden, Vance, Putin, Zelenskij, Macron, von der Leyen, Vučić, Dodik, Parolin,
  Tagle, Marx, Sarah, Fernández …).

Consequence: study A can carry the field overview and the portraits of popes and bishops, and it can carry an
honest observation that the religious corpus is full of politicians who are mentioned without speaking. It
cannot carry a single portrait of a priest, theologian, lay author, sister or seer beyond those seven names.
Those portraits exist only through D (counts) and B (passages).

**The saved plan (§3 C) classes study D as "historical methodological context only".** For this essay that is
the wrong call. D is the only per-person speech evidence for the people the PI's second question is about
("less prominent theologians and lay voices"). It should be promoted to a primary source, with its statement
rule said once in plain words and its caveats kept.

## 2. What the opening can already say

The chat plan lists four "tensions" as open questions. Study D has measured versions of all of them, on the
closed list or the 300-post sample, model-coded and not human-validated. They are observations with a stated
basis, not estimates of the whole public sphere, and they are the natural spine of the opening.

1. The public voice of faith is episcopal and papal. Of 71 259 closed-list statements, bishops give 50 % and
   popes 37 %; the 25 academic theologians give 4 %.
2. Being named is not speaking, and one office outweighs a faculty: Archbishop Kutleša alone has 4 046
   statements, all 25 academics together 3 033.
3. The Church's voice travels through secular outlets: 55 % of bishops' statements are published outside
   Catholic media. One New-Year papal message appeared on 22 portals in a single day, none of them Catholic.
4. The most engaged Catholic channels on YouTube and Facebook have no face: 24 of the top 50 are anonymous
   devotional channels, theological education is visible in 2, and the "priest profiles" group is 97 % one
   channel (pulherissimus). Doctrine vocabulary is frequent there, appeals to the Magisterium rare.
5. Ordinary believers are written about, not heard: in 150 Catholic-source posts they are described in 53
   and speak in 3.
6. Women: 13 of 117 persons, 1,0 % of statements.
7. The word "teolog" mostly names foreigners and non-faculty voices: of 1 571 posts calling someone a
   theologian, 58 name one of the 25 faculty theologians; the names most often attached are Halík, Rahner,
   Küng, Guardini, Moltmann, von Balthasar and, at home, Dalibor Milas and Marko Vučetić.

Study A adds, for the same opening, the shape of presence: 202 965 documents (33,2 %) contain at least one
of the 110 public people; Pope Francis alone is in 51 682 documents across 1 462 outlets; bishops' documents
are about one third in confessional outlets and one eighth in secular ones, with half unlabelled.

## 3. Proposed amendments to the plan

### 3.1 Re-rank the sources (replaces §3 C's demotion)

- **D** primary for who speaks and how much, for the non-episcopal names, for women, for the "teolog" label,
  for the 50 coded channels and for the echo sequences.
- **A** primary for presence, offices, outlets per person, platform and time, networks and text families, and
  for popes and bishops in full.
- **B** primary for passages and for the only attributed-speech records with role labels.
- **C** for outlet concentration and exact reuse; the exploration for register orientation only.
- `studies/theological-authority` not used; its usable part (the top 50 channels) is already inside D.

State D's rule once, in Croatian, where it first matters: an "izjava" is the person's name next to a verb of
speaking within the same paragraph. It catches reported speech and quotations of written work alike.

### 3.2 Drop study A's rule-tier speech from edition 1

The 31 458 sentence-level candidate statements exist only in `voices.duckdb`, were never released by the
study, and would introduce a third definition of speech beside D's proximity rule and B's coded voices.
Using them needs database queries (pending Q10) and buys confusion. Leave them out, say so in the note on
the material, and point to them as further work. This also removes the main reason Q10 mattered.

### 3.3 One naming rule for the narrative, stated once

The plan's disclosure text covers inventories but not the portraits. Propose:

- A person is named in the essay only if they are (a) among A's 110, or (b) on the PI's closed list of 117,
  or (c) a named office-holder or public author in a B passage whose public role is visible in the text.
- Nobody from B's `personal_experience`, `civil_society` or `catechist` rows is named, even though the table
  carries 156 named ordinary believers. They appear as "vjernica iz Splita", "hodočasnik", "župljanin".
- Private accounts stay as platform group labels, as in A.
- B labels saints as speakers (Sv. Augustin, Sv. Jeronim, Toma Akvinski are coded `academic_theologian`).
  They are quoted authorities, not voices; use them only to illustrate that distinction.

### 3.4 Portraits in three sizes, chosen by the evidence

- **Full portraits** (A + D + B available): Franjo, Lav XIV., Dražen Kutleša, Josip Bozanić, Mate Uzinić, Vlado
  Košić, Đuro Hranić, Zdenko Križić. B has 16 to 26 interpreting rows for Kutleša across 14 outlets, 13 for
  Križić, 10 for Uzinić, 9 for Bozanić, 8 for Hranić.
- **Medium portraits** (D counts plus one to three B passages): Antun Sente (653 statements), Tomislav Pervan
  (526), Damir Stojić (447), Željko Tanjić (348), Marinko Vukman (337), Ante Vučković (296), Jozo Grbeš (289),
  Tonči Matulić (142), Stjepan Baloban (143), Željka Markić (150, 138 in secular sources), Marko Vučetić (57,
  all secular; B has a full case), Jelena Lončar (132, the most-quoted sister). Expect thin passage evidence:
  in B the academics are spread over 138 distinct names with at most two rows each.
- **Group portraits** where the evidence is about a kind of voice, not a person: the anonymous devotional
  channels; ordinary believers (anonymised); women on the list; the Međugorje seers; the institutions that
  speak (B's largest speaker role, 25 % of speaker appearances, is "religious institution"); the politicians
  inside the religious corpus (mentioned, almost never explaining); and who gets called "teolog".
- **Posthumous voices** as their own small portrait: Tomislav Ivančić (d. 2017) has 1 041 mentions and 271
  "statements" in D and is the top voice of a devotional YouTube channel; Benedikt XVI. (d. 2022-12-31),
  Franjo Kuharić, Alojzije Stepinac likewise. D does not separate living from dead; A does (contemporary /
  historical / sacred). The essay must never present posthumous circulation as contemporary speech. Add this
  to §9 beside "do not attach a later office to an earlier passage".

### 3.5 A passage protocol that is selection for display, not coding

B's `tables/voices.csv` has 3 009 valid voice rows, 1 184 labelled as interpreting faith, in 751 articles
from 324 outlets, with the passages embedded; `tables/evidence_passages.csv` holds 60 388 passages. No
query is needed. Propose a written selection rule, recorded in the evidence index:

- Candidate rows: `interprets_faith = yes`, `task_valid`, `complete_article_base`, named public person or
  institution under §3.3, passage of at least about 300 characters.
- Spread deliberately across years 2021 to 2026, across Catholic and secular outlets, and across modes
  (`own_text` 2 009 rows, `direct` 999).
- Before quoting, re-read the full saved text (`main_inputs.parquet` holds the complete cleaned inputs) so
  that a truncated passage is shown with its surrounding sentences, and mark every omission.
- Show at least two known machine mistakes beside the passages or in the note: the saint-as-theologian
  label, the constructed case in which an unrelated quotation was attributed (D021), and the two paywall
  probes in which a visible quotation before the paywall was missed (B03, B04).
- Say in the chapter, once, that model labels guided the search and that the reader sees the text.

### 3.6 Restructure the middle of the essay

The chat plan gives 9 pages to portraits and 6 to "what people say". Passages will live inside portraits, so
the two chapters would overlap. Propose that portraits answer **who**, and the passages chapter answers
**how** faith gets explained in public, using D's existing coded lenses as the organising idea: what the
explanation leans on (Scripture, Magisterium, tradition and saints, private revelation, personal experience,
reason and science, law and rights, nation and history) and in what form it reaches the public (a homily
reported by IKA, an author's own column, an interview in a secular medium, a statement relayed to twenty
portals, a devotional caption, an institutional communiqué).

Suggested allocation, still proportions: opening 3 · the visible field 5 · portraits 10 · how faith is
explained 6 · outlets 4 · connections and circulation 3 · time 1 · conclusions 2 · note on the material 1
(35).

### 3.7 Keep a one-page "time" passage

The chat plan drops time entirely. A has quarterly presence and rank stability; the 2025-Q1 → Q2 step
(Kendall 0,10, the lowest in the series) is the papal transition, and Lav XIV. reaches 20 557 documents in
eight quarters. One page on the arrival of a new voice, in descriptive language and with no event causation,
belongs in an essay about people.

### 3.8 Outlets chapter: use what exists, name the unlabelled half

A's `source_distribution` shows hkm.hr carrying all 110 people in 42 193 documents and laudato.hr 105 of
them; C gives hkm.hr 19,3 % of the web frame; D's 50 coded channels give type, visible mandate and how often
the channel itself interprets. Per-person confessional / secular shares in A rest on an outlet labelling
that covers roughly half of the documents (about 50 % "unlabelled" for every bishop). Write "u označenim
izvorima" and show the unlabelled share rather than a two-way split.

### 3.9 Circulation: three existing cases, one caution

Pair A's family sizes (147 families with 50 or more copies, the largest 2 857) with D's echo sequences (the
papal New-Year message on 22 portals in one day, a bishop's ordination on 14) and C/B's exact-reuse family
(five Bosnian local portals, identical text, same day). That last family is an Orthodox feast text ("Sveti
Jovan"); say plainly that the corpus is topical and carries such material, rather than trimming the example.

### 3.10 Numbers and prose discipline

- In portraits at most one number per paragraph; the rest of the figures live in captions and the companion.
- Every count carries its study and cut-off in the evidence index; in prose use period tags ("u građi do
  listopada 2026." for A, "do lipnja 2026." for D and B) and never add across studies.
- House rules apply: no colons or em-dashes in Croatian prose, thousands with a no-break space, generated
  numerals through the agreement helpers, every term explained at first use.
- Display fixes only: A's public name "Mijo NIkić" needs its capitalisation corrected in the text, not in the
  data; record it in the evidence index.

### 3.11 Companion: smaller and labelled

Keep three population files with explicit labels (110 public set; 117 closed list; 1 394 register), B's
voices table filtered to the rows the essay displays, D's `voices_summary.csv`, and the figures reused. The
705 095 detected strings and 8 037 060 mention records stay in the database with a pointer; they are not
exported for this edition.

### 3.12 Title

Working title aligned to the question: „Tko vjeri daje javni glas?" with the subtitle „Ljudi, ustanove i
riječi u hrvatskom digitalnom prostoru 2021.–2026." The saved plan's title asks who explains faith, which the
evidence answers less directly than who is given a voice.

## 4. The ten questions, re-read against the PI's message

Answered by the message of 2026-11-02 and to be recorded in the plan: Q1 PI and professional theologians;
Q2 Croatian essayistic prose, procedures in the background; Q3 about 35 pages; Q4 essay with portraits,
cautious; Q5 broad thematic coverage; Q6 all actor types including institutions and politicians, with
status labels; Q7 private edition; Q8 passages with commentary over maps.

Recommended defaults for the two still open:

- **Q9 visual style.** Reuse the editorial report's visual system (Palatino body, dark chapter dividers,
  source notes as block quotes) with a long-prose variant: fewer, larger figures, pull quotes for passages,
  and the existing 50-source directory format for the companion. PDF plus HTML, no editable manuscript.
- **Q10 meaning of "no coding".** Read-only exports and layout scripts are allowed; no new model run, no new
  coding, no identity merge. With §3.2 adopted, no database query is required for edition 1.

The two questions at the end of the chat plan:

- **Several portraits or one central person.** Several. About eight full portraits, twelve medium, and the
  group portraits of §3.4. A single central figure would be Kutleša by every count, and that would turn the
  essay into something the evidence does not ask for.
- **Less prominent voices or prominence as found.** Order by prominence, because that is what the field
  looks like and the opening must say so, but give the less prominent roughly equal page space on purpose.
  That is where the evidence is thin, where the honest "we can see this much and no more" belongs, and where
  theologians can add what the material cannot.

## 5. Items that would need a run, left pending

- A per-person list of outlets from A (`network_inputs/appearances.csv`, 78 MB, exists as CSV). A group-by
  over it is a faithful aggregate of an existing table, but it is still a computation; hold it under Q10.
- Statement counts for anyone outside D's closed list. Not available without a new run; say "not measured".
- Any accuracy or validation figure. None exists; none is to be produced here.
- Opening D's `.rds` files (`coded_sample.rds`, `person_posts.rds`, `sample.rds`): on this machine today
  `Rscript --vanilla` crashed on `readRDS` (exit 139). The CSVs cover this review; Phase 2 should check the R
  installation before relying on the `.rds` inputs.

## 6. Verification criteria to add to the plan's §9

- No private individual from the coding tables is named; the naming rule of §3.3 is cited in the note.
- Every quoted passage was re-read in its full saved text; omissions are marked.
- Posthumous and historical presence is labelled as such wherever a count or passage concerns a deceased person.
- No figure mixes the three corpus cuts (A to 2026-10-16, D to 2026-06, B's web frame) in one total.
- Study A's rule-tier speech records are not cited as findings.
