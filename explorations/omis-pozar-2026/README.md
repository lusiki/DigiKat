# Omiš wildfire 2026 — how a story spreads, hour by hour

**Question.** Using a media-monitoring export of everything published about the Omiš wildfire
(13–17 August 2026), reconstruct the *media* fire next to the physical one: who entered the story
when, how fast it peaked and decayed, what it was about at each hour, who got the attention, how far
it travelled, how much of it was echo — and turn that into a public piece (blog / LinkedIn) plus a
reusable "rapid topical coverage" pipeline.

**Not part of the DigiKat corpus.** This exploration is self-contained (own dictionaries, own theme,
own outputs). It only borrows the URL canonicaliser from `R/lib/digikat_utils.R`. Nothing here reads
or writes `data/`, `pages/`, `docs/` or `studies/`.

**Status.** 2026-08-18: pipeline built and verified end to end on a **synthetic** vendor-shaped export
(every output is stamped *SINTETIČKI PODACI*). Waiting for the real export to be dropped into
`input/`. **Nothing produced so far is a finding.**
**Kill-by.** 2026-09-01 — if the real export has not been run by then, flag for ARCHIVE.

---

## Run it

```powershell
# from this folder
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' run_all.R              # real export(s) in input/
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' run_all.R --synthetic  # pipeline test on fake data
```

Drop the vendor export(s) — `.xlsx` or `.csv`, the standard 49-column Determ shape (`DATE`, `TIME`,
`TITLE`, `FROM`, `URL`, `SOURCE_TYPE`, engagement fields, `FULL_TEXT`…) — into `input/` (gitignored).
Several files are fine; they are bound and deduplicated on canonical URL. ~12 s end to end.

| Step | Does | Writes |
|---|---|---|
| `00_make_synthetic.R` | fake export with a plausible diffusion story, for testing only | `output/synthetic/` |
| `01_ingest.R` | read → clean time (Europe/Zagreb) → dedupe → **which fire** → outlet type → ring → frames → attention → echo | `output/items.rds` (private), `output/agg/qa.json` |
| `02_analyze.R` | every aggregate and every scalar the story quotes | `output/agg/*.csv`, `output/agg/derived.json` |
| `03_figures.R` | nine figures, one theme | `output/figures/*.png` |
| `04_story.R` | blog draft (HR) + LinkedIn posts (HR/EN), numbers filled from `derived.json` | `output/story_hr.md`, `output/linkedin_*.md`, `output/story_numbers.md` |
| `05_replay.R` | self-contained interactive replay (play/scrub through the hours) | `output/replay.html` (`#h=30` deep-links an hour) |

`output/private/` holds anything with a headline or URL (first movers, top-10 attention items, echo
clusters, the full item list). Read them, quote a headline if you want — they are public news
headlines — but they are not part of the automated outputs.

## After the real export lands — read this before believing anything

1. **`output/agg/qa.json` first.** Rows read / dropped / kept; the "which fire" split (a `požar`
   query catches Pelješac, Dugi otok and Brač too — only `omis` items feed the story); the share
   without a clock time (set to noon → would smear the hourly chart); the largest sources left in
   `ostali_web`. If a Dalmatian portal, a national outlet or a foreign site sits there, add it to the
   matching regex in `lib.R` and rerun. This is a 5-minute loop and it changes the "who was first" answer.
2. **`FIRE_EVENTS` in `lib.R`** — the on-the-ground timeline that annotates every figure. Times come
   from live blogs and DORH; `precision` says how each is known. Correct any that better sources contradict.
3. **Frames are dictionary hits.** Open `output/private/items_titles.csv`, sort by a frame, read 30
   items per frame. If a stem misfires (the way `županija` was firing `politika`), fix the regex in
   `lib.R`, rerun. State in the post that frames are dictionary-based.
4. **Interactions are vendor values and differ by platform.** Web has many zeros by construction;
   Facebook counts reactions+comments+shares; X counts RT+favourites. Every figure that mixes platforms
   says so; keep it that way.
5. **The first hours may be under-captured.** Monitoring crawlers index with a lag; the first item's
   timestamp is the publication time, not the capture time, so ordering is fine, but very early
   *social* posts may be missing entirely. Say so.

## What the figures are and why these nine

| # | Name | Reads as | The one number in the title |
|---|---|---|---|
| 1 | **Dva požara** | mirror chart: items/hour up (by outlet type), interactions/hour down; fire events numbered with a key | items · hours |
| 2 | **Štafeta** | one row per source ordered by entry time; dot = first item (size = volume), line = how long it stayed, tick = median | sources · entered in 6 h |
| 3 | **Spektrogram** | frames × 3-h bins heat map, frames ordered by onset | onset hours of politics / cause / solidarity |
| 4 | **Objavljeno i nagrađeno** | dumbbell: share of items vs share of interactions per outlet type | top-10 share · zero share |
| 5 | **Krugovi** | radial: time clockwise, five rings from official sources to the rest of the world, colour = items per 3 h, white dot = first arrival | domestic vs foreign share |
| 6 | **Prozor** | cumulative share of items per outlet type; t50 dots | t50 · t80 |
| 7 | **Temperatura** | sensational-headline share by type and over time; the words | share of sensational headlines |
| 8 | **Jeka** | identical headlines on ≥3 outlets, coloured by who was first | echo share |
| 9 | **Rano i kasno** | interactions per item by entry window, web and Facebook | — |

The story spine is 1 → 2 → 3 → 4 (what happened, who carried it, what it was about, who was
rewarded), with 5–8 as the "and also" and 9 as the promotion lesson. For LinkedIn use 1, 5, 2, 3
in that order; 5 is the thumbnail.

## Honesty rules baked into the outputs

- Every title number comes from `derived.json`; the prose in `story_hr.md` is generated from the
  same file. Edit the *words*, never retype a number.
- Descriptive only. "Who was first" is a timestamp comparison, not influence. "Rewarded" is recorded
  attention, not quality. Frames are dictionary hits. Half-life and t50/t80 are properties of this
  export, not of "the media".
- Closed groups (WhatsApp, Viber, Facebook groups) — where the first hours' most useful information
  actually moved — are invisible to the instrument. Say it every time the piece talks about the first hours.
- One death, dozens injured: never present "who was fastest" as a league table.
- Synthetic runs stamp every figure, the story banner, the replay page and the console. `01_ingest.R`
  refuses to run a real export that carries the SYNTHETIC stamp and vice versa.

## Reusing this for the next event

Everything event-specific sits at the top of `lib.R`: `FIRE_EVENTS`, `FIRE_TAGS`, `FRAMES`,
`SENSATIONAL_RX`, the outlet regexes and `RINGS`. For a different event you replace those five
blocks (an election, a flood, a scandal each want their own frames and their own "which event"
disambiguation), point `T0` at the moment the clock should start, and the rest of the chain runs
unchanged. That is the "quick topical coverage" pattern this exploration exists to prove.

## Files

```
lib.R                  definitions: paths, event registry, dictionaries, outlet typology, rings, helpers
00_make_synthetic.R    test data (never a finding)
01_ingest.R … 05_replay.R
run_all.R              the chain
input/                 vendor export(s), gitignored
output/                gitignored: items.rds, agg/, figures/, private/, synthetic/, story_*.md, linkedin_*.md, replay.html
```
