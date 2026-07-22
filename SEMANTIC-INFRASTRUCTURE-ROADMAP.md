# Semantic Infrastructure Roadmap — DigiKat

*A one-page map of five "knowledge librarians" you can hire for the ≈710k-post corpus, in build
order, with the exclusive conclusions each one unlocks. Distilled from the Herk "levels" discussion.*

## The one principle
Do not climb for the sake of climbing. Hire the **cheapest librarian that ends your current pain**,
and let different rooms of the archive employ different ones. Meaning-search everywhere; the
corkboard only where a paper is genuinely about relations; automation last, with a human still checking.

## The five levels

| # | Librarian | What it is, technically | Effort / cost | **Exclusive conclusions it licenses** |
|---|-----------|-------------------------|---------------|----------------------------------------|
| 1 | **Signpost** | One page telling the assistant where everything lives (this repo already has `CLAUDE.md`) | An afternoon | None new — protects consistency |
| 2 | **Dossier wiki** | Cross-linked notes, one per topic (codebook, coding decisions, findings); machine-drafts, you correct | Days, ongoing discipline | None new — keeps 6 years of coding consistent; survives team turnover |
| 3 | **Meaning search** | Every post → a vector (coordinate on a map of meaning) in a local `duckdb`; hybrid vector+BM25 retrieval via `ragnar`/`ellmer`. Unit = **document** | A weekend; <$50 hosted or a night on local `bge-m3`; a few GB disk. **No cloud needed — data stays local** | Themes beyond the 16 categories; how far **comment discourse drifts from portal framing** and whether the gap widens around events; **reworded/syndicated copies** (which portal feeds which, with what delay); a topic's vocabulary **migrating** (abortion: theological → political). *Claims about documents in bulk.* |
| 4 | **Corkboard (knowledge graph)** | An LLM reads each article carrying a fixed form (who did what to whom); forms → labeled edges; name variants collapsed with L3 embeddings + a human pass; analysed in `tidygraph`/`igraph`. Unit = **relation** | 1–3 months part-time; a few hundred $ extraction; **name resolution is the human time-sink** | The handful of accounts **brokering** between the institutional church and lay influencers; **tracing one claim** from a fringe source into the mainstream in countable steps/days; whether the Catholic media space is **redundant or hangs on two hubs** (a fragility claim). *Claims about connections, not content.* |
| 5 | **Night shift** | Scheduler + all of the above: wakes daily, fetches, fingerprints, fills forms, updates map + board, leaves a report a human approves | Plumbing + a review habit | **Reaction speed to events** as they unfold; **prospective / preregistered** designs instead of always retrospective; **preserves comments deleted** before any retrospective study could see them. *Claims about timing and survival.* |

## Build order for DigiKat
1. **Signpost + dossiers now** — you already have `CLAUDE.md`/`MEMORY.md`; grow the dossiers from published studies.
2. **Meaning search next** — highest value-per-effort. Because the corpus is already a table, every RAG
   crawl/scrape step drops away: short posts = one vector each (no chunking); only long portal articles
   get split. Carry `platform`, `date`, the 16 categories, `data_source` as metadata so you can slice.
3. **Corkboard only where a study demands it** — the disinformation / influencer-network work. Graph
   those platforms; leave the rest at Level 3.
4. **Automation last** — and keep a human in the filing loop for an academic project.

## Validation habits (so it survives peer review)
- **L3:** hand-check a sample of retrievals; report retrieval precision in the methods section.
- **L4:** sample a few hundred edges by hand, report edge precision. Set optional schema fields
  `required = FALSE` (a required field with no answer invites hallucinated edges); test on labelled
  positive **and** negative examples before the batch run.
- **All levels:** respect the corpus caveats already in `MEMORY.md` — the ~2024 collection-method change
  confounds cross-year volume; condition on `data_source` + platform before reading any trend as real.

## Generalization to the whole media space
None of the machinery knows the topic is religion — converter, form-filling reader, and network math are
**content-blind**. So generalization is just swapping the archive and the schema:
- **Scale out** — ingest the broader Croatian media space; the Catholic corpus becomes one region on a
  larger meaning map. Tests whether religious discourse **leads, lags, or echoes** the general agenda
  (agenda-setting measured directly, not inferred).
- **Scale across** — reuse identical signposts, dossier schemas, and relation menus for political / health /
  climate discourse, or another country. Ask whether the Orthodox space in Serbia shows the same two-hub fragility.
- **Publish the ladder itself** — the mapping *infrastructure level → class of conclusion it licenses* is a
  methods contribution in its own right, with DigiKat as the worked demonstration.

---
*Positron/R stack throughout: `ragnar` + `duckdb` + `ellmer`; local embeddings via Ollama `bge-m3` for
sensitive data. No Python required for the core text path. Wrap the embed/extract steps as `targets` so you
never pay the embedding cost twice.*
