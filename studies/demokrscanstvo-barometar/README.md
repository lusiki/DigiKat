# Medijski barometar demokršćanstva

Status: **G1 and G2 completed; human validation pending**. The fixed panel has 115 outlets.
Definition `1.0.0+33429974d0b8` is frozen after independent development review. No validated
empirical release exists. The approved execution plan is
[`quality_reports/plans/2026-09-18_demokrscanstvo-barometar.md`](../../quality_reports/plans/2026-09-18_demokrscanstvo-barometar.md).
It records the PI's amendments to the original [brief](BRIEF.md).

All 69 monthly classification chunks are complete. The verified private coding
package has 320 PI items and 80 second-coder items under the full frozen design
(rare strata are censused). It is ready in `WORKDIR/validation/1.0.0+33429974d0b8/`;
see [PIPELINE.md](PIPELINE.md) for the independent human-coding handoff.

The resource will measure how frequently Christian-democratic ideas and Christian social thought
applied to public-policy questions appear in a fixed panel of Croatian online news media.
It measures coverage, not support, party strength, reach or a publisher's beliefs.
The source population is the restricted DetermDB general web feed, separate from the official
DigiKat corpus and the accumulator used by earlier studies.

The conference target is **Izazovi i budućnost demokršćanstva u Hrvatskoj i Europi / The Challenges
and Future of Christian Democracy in Croatia and Europe**, Hrvatsko katoličko sveučilište / Catholic
University of Croatia, **24 September 2026**. Conference timing never waives human validation.

## Local setup

Use R 4.6.0 and the project's restored renv library. Copy variable names from
[`config/paths.example.Renviron`](config/paths.example.Renviron) into the user `.Renviron`, with actual
paths. The work directory must be outside the repository and Dropbox. Do not put private paths in
public output. Both DetermDB connections are read-only. Upstream imports are separate PI-run work.
The PI chose the existing database snapshot without importing the April 2024 re-download.

Never leave an R session connected during an upstream import. The pipeline closes its connections
and fails on a lock, rather than retrying against a writer. When an upstream snapshot changes,
previous readiness/eligibility caches must not be mixed with the new snapshot.

## Current commands

Run from the repository root. Stages enforce their own prerequisites.

```powershell
Rscript studies/demokrscanstvo-barometar/run.R --stage=readiness
Rscript studies/demokrscanstvo-barometar/run.R --stage=inventory
Rscript studies/demokrscanstvo-barometar/run.R --stage=panel
Rscript studies/demokrscanstvo-barometar/run.R --sample
Rscript studies/demokrscanstvo-barometar/run.R --stage=classify --workers=8
Rscript studies/demokrscanstvo-barometar/run.R --stage=validation
Rscript studies/demokrscanstvo-barometar/run.R --stage=bridge
Rscript studies/demokrscanstvo-barometar/run.R --stage=method-pdf
Rscript studies/demokrscanstvo-barometar/run.R --stage=accept-validation
Rscript studies/demokrscanstvo-barometar/run.R
Rscript studies/demokrscanstvo-barometar/run.R --edition
```

With no arguments, the command performs a checked refresh after G3, using eight
workers. `--workers=1` through `--workers=12` controls update/classification
parallelism. `--edition` explicitly creates a new monthly edition during update
or aggregation; a routine refresh preserves the existing edition.

The `panel` stage produces a review proposal. It does not freeze a panel. Review files are
aggregate-only; candidates, canonical article URLs, duplicate capture metadata and caches remain
in the private work directory. Proposed outlet labels require PI review.

The full source-schema synthetic run in [PIPELINE.md](PIPELINE.md) passes on 3,206 invented
records and writes only to `tempdir()`. `preview.R` additionally renders synthetic HTML and
copies checked synthetic downloads into `docs/` for browser checks. Never stage or publish
those preview files. The page is excluded from normal site builds until a genuine release
is installed. `--apply` refuses synthetic data, unfinished human validation and missing
vendor aggregate-licence evidence.

## Gates and ownership

The PI owns the panel (G1), definition (G2), human validation and bridge decision (G3), first public
installation (G4), full website render (G5) and merge/publication (G6). Later routine updates remain
PI-run, weekly when new upstream days exist. A refresh changes series and figures; findings and the
conference PDF belong to a separately approved monthly edition.

D8's special AI passage-access procedure was withdrawn by the PI. The classifier's 80-token evidence
window is unchanged. Human validation labels and development/evaluation separation remain required.
No source article text, headlines, quotations, article URLs or per-outlet topic counts are public.
The excluded collaborator is not assigned or contacted. The coauthored manuscript and its
dictionaries are not reused, and its related-study card is omitted. Definition seeds are
the brief and existing CST document titles, documented in the resource provenance.

The method-only Croatian conference PDF has been rendered and visually checked. It explicitly
states that human validation is unfinished and contains no empirical indicator findings.

## Reproducibility and licence

Every run records the source fingerprint and relevant code/configuration hashes. The existing
shared URL canonicalizer defines article identity. The title is stripped before testing body
eligibility; snippets never substitute for body text. Date assignment uses the source DATE string.
No page render opens DetermDB or produces aggregates.

Restricted source material is not redistributed. Public derived aggregates are intended for
CC BY 4.0 only after the required vendor-terms confirmation and publication gate. Until then this
directory contains implementation and review material, not a licensed empirical data release.
