# Plan — Extend wiki + network to 6 platforms (Instagram, TikTok, Twitter)

**Date:** 2026-07-02 · **Author:** Claude (for PI Luka Šikić) · **Desc slug:** six-platform-expansion

## Context

PI asked for more platforms + density on the source network. Recon aggregated the master **once, safely,
into the scratchpad** (`actor_agg_all.rds`, 18,571 actor rows) — so no further master reads are needed.
Established: my aggregation reproduces the existing web/yt/fb numbers **exactly** (posts 19/19, interactions
19/19); existing selection ≈ **top-19 by total_interactions**. The new platforms are **individual/off-topic
heavy** — Instagram's top actor is `anonymous_user` (a placeholder), Twitter's top-19 is almost all
politicians/private persons, TikTok mixes news outlets with a few genuinely Catholic actors
(`shkm2026`, `mladifesthrvatska`, `poslanik.gospodina`). Per two AskUserQuestion answers, the PI chose:
**include ALL institutions AND individuals.**

## ⚠️ Disclosure note (PI-authorized, but flagged)

Named individuals (politicians *and* private persons) will be published as nodes/pages — account-level
**aggregate** stats (handle + post/interaction/reach counts) from already-public accounts. Caveats:
- Many new actors have **1–6 posts** → small cells / single-post attribution (re-identification consideration).
- Every actor is **per-row reversible** via `publish=no` in the sidecar.
- Pages render **locally only** — nothing is public until the PI commits + `/deploy`s; run `/disclosure-check` first.
- One carve-out I keep: **`anonymous_user`** (Instagram) is an anonymization placeholder, not a person → `noise`, `publish=no`.

## Selection rule

New aggregates = **top-19 per platform by `total_interactions`**, columns/format identical to the existing
`*_actors.rds`. **Existing web/yt/fb aggregates are NOT overwritten** (avoids changing published numbers /
the HARD-GATE overwrite).

## Steps

1. **Produce aggregates from the scratchpad** (`actor_agg_all.rds`, no master re-read): write
   `instagram_actors.rds`, `tiktok_actors.rds`, `twitter_actors.rds` to the scratchpad → verify readable +
   sane → **copy into `data/processed/`** (this copy is the HARD-GATE production step).
2. **Sidecar triage** — append ~56 rows (19×3 − `anonymous_user`) to
   `resources/dictionaries/source_labels.csv`: `kind` (institution/individual/noise), `label`
   (confessional/secular/other), `publish=yes` for all except `anonymous_user`; descriptions for the
   recognizable/Catholic ones, `TBD (PI)` for obscure individuals; `status=proposed`.
3. **Generator** — add `instagram`/`tiktok`/`twitter` to the `platforms` list in
   [R/wiki_sources.R](R/wiki_sources.R) (it generates their actor pages, hubs, index sections + log generically).
4. **Network** — extend the `platforms`/`plat_display`/`plat_cols` vectors in
   [pages/izvori/mreza.qmd](pages/izvori/mreza.qmd) to 6 (`dk_platform_colors` already defines
   instagram/tiktok/twitter). Brand-bridges auto-grow (Index/24sata/Slobodna/Večernji/Dnevnik/RTL mirror
   onto TikTok; laudato onto IG). Tighten `visPhysics` for density with ~100 nodes.
5. **Re-run + render** (retry loops for the flaky env): `Rscript R/wiki_sources.R`; render `mreza.qmd` +
   a couple of new sample pages. Full catalog render deferred to `/deploy`.
6. **Verify**: existing web/yt/fb `*_actors.rds` **md5 UNCHANGED**; the 3 new files present + sane; the
   network shows 6 constellations; diacritics/emoji literal; no scatter.

## Reused utilities / single source of truth

- `resources/dictionaries/source_labels.csv` (sidecar) + `R/wiki_sources.R` generator + `mreza.qmd` all
  read the **same** `data/processed/*_actors.rds`. `R/theme_digikat.R::dk_platform_colors` already has all 6.
- Aggregation method verified against existing aggregates (posts/int 19/19) — numbers are computed, not typed.

## ⚠️ Prerequisite — stabilize R first

Even small reads are segfaulting intermittently (~1 in 3) — the Dropbox filesystem driver stays active on
**Pause**. Before I execute, please **fully QUIT Dropbox** (Exit, not Pause); otherwise the generator re-run
and renders become a slog of retries. (Longer term: move the working clone out of Dropbox, per
`CLAUDE.local.md`.) I'll use retry loops regardless, but a quit makes it clean.

## Out of scope

Overwriting/refreshing the existing web/yt/fb aggregates; reddit/forum/comment (zero engagement); a full
site render (→ `/deploy`); committing (Dropbox has external staged changes — the PI's call).
