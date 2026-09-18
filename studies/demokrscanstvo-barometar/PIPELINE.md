# Pipeline contract

The approved plan and BRIEF.md specify the complete release. G1 (115 outlets) and G2
(`1.0.0+33429974d0b8`) are complete. Human validation and the public installation remain
outstanding. Synthetic checks are not validation estimates.

| Stage | Input | Output | Gate constraint |
|---|---|---|---|
| 00_readiness | restricted DB metadata, logs and web day fingerprints | private snapshot, schema, observed-day mask | read-only; no active loader |
| 01_outlets | read-only web FROM/host/month counts | private inventory and continuity candidates | no topic counts |
| 02_panel | registry proposal, eligible canonical articles | proposed membership, denominator audit | PI must ratify G1 |
| 03_candidates | frozen panel and proposed definitions | private literal-superset candidates | after G1 |
| 04_classify | private candidates, versioned rules | private evidence and classifications | development split only before G2 |
| 05_validation_draw | frozen full-history decisions | blinded private human coding sheets | after G2 |
| 06_validation_score | human coding/adjudication | precision, agreement, route gates | PI accepts at G3 |
| 07_bridge | old/new June 2024, same frozen rules/panel | private paired results, aggregate bridge summary | D9 at G3 |
| 08_aggregate | private eligible articles and classifications | monthly, weekly, rolling28 and facets | accepted route set |
| 09_figures | screened public aggregate preview | matched PNG/SVG/social card | real fonts, no source text |
| 10_summary_pdf | fixed panel and definition metadata | isolated two-page method-only conference PDF | no empirical findings before validation |
| 11_checks | all release files | reconciliation, disclosure, reproducibility | must pass before installation |
| 12_update | changed read-only snapshot, same frozen instrument | rebuilt checked preview with retained editions | G3 required; upstream import stays separate |

Stages are implemented and exercised on invented inputs. The empirical route through G3
cannot execute until two humans return their coding and the PI adjudicates disagreements.
`accept_validation.R` records the delegated recommendation from that actual evidence.

## Data boundaries

`data/processed/` is untouched. All restricted working files live under
`DIGIKAT_BAROMETAR_WORKDIR`, or the ignored study `output/private/` and `output/intermediate/`.
Preview releases go to ignored `output/release/`. A reviewed release will be installed to
`data/barometar/demokrscanstvo/` by explicit `--apply`. Never write generated HTML by hand.

The preliminary FROM continuity screen is a conservative computational shortcut, not the panel
rule. The rule uses >=20 **eligible canonical articles** in every complete membership month,
excluding 2024-01 through 2024-03. Exact URL/outlet deduplication is global within each source
batch before monthly grouping. An article belongs to its earliest eligible capture's DATE.
Day observation is based on >=90% non-null body fields among all web rows, not only panel outlets.

## Refresh and determinism

Cheap readiness checks inspect schema, max date and import logs. Full fingerprinting also detects
changed old days. Day fingerprints preserve hash-sum integers as strings. A changed day can affect
outlet-month boilerplate and canonical representatives on another date; invalidate those dependencies
before rebuilding months, ISO weeks and 28-day windows. Never aggregate months from weeks.

Sort outputs deterministically and write UTF-8/LF; CSVs receive a BOM. The public determinism check
permits only computed_at/code_commit metadata differences. Changes to a frozen panel or definition
need a new version and fresh human evaluation, not silent amendments.

## Human coding and release commands

After full-history classification, `run.R --stage=validation` creates a private,
integrity-bound package under `WORKDIR/validation/<definition_version>/`. Open
`human_PI.html` locally for the PI and give `human_second.html` to the independent
second human. Each must enter their own name, complete every assigned item and
export answers. Browser answers stay local. Do not share either coder's answers
with the other before independent coding finishes. The assistant must not fill
in either file or view evaluation passages.

Run `06_validation_score.R --pi=<export.json> --second=<export.json>` to prepare
private adjudication templates. The PI must review disagreements, document the
reason for every changed/disagreed field, and mark their completed review in the
returned adjudication JSON. Rerun with `--adjudicated=<json> --log=<csv>` to score.
Then rerun the bridge and `run.R --stage=accept-validation`. An A1 failure prevents the
empirical release. All export paths are private local paths, never repository files.

```powershell
Rscript studies/demokrscanstvo-barometar/run.R --sample
Rscript studies/demokrscanstvo-barometar/run.R
Rscript studies/demokrscanstvo-barometar/run.R --edition
Rscript studies/demokrscanstvo-barometar/run.R --apply
quarto render pages/demokrscanstvo/index.qmd
```

The default command and `--stage=update` call the same checked refresh helper
with eight workers. Override that count with `--workers=1` through `--workers=12`.
`--edition` is accepted only for update or aggregate. G3 is checked before a
refresh opens either source database; installation remains a separate `--apply`.

`--definition=v2` intentionally refuses an unprepared migration. A new version needs a new
inventory, development review, full recomputation and fresh human evaluation; the flag cannot
manufacture those inputs. The synthetic run uses invented rows only and writes into tempdir().
The page reads release files only and labels a synthetic override visibly.

The refresh helper keeps the frozen panel file unchanged, retains every old edition byte for
byte, reuses fixed matrix bins and appends changed previously published values to revisions.csv.
It conservatively rebuilds dependencies after an upstream snapshot change. If the installed
snapshot, source logs and max date are unchanged, it exits with `nema novih podataka`.
Installation retains the previous generation privately and rolls it back if the swap fails.
Weekly data updates preserve edition findings. Creating a new monthly edition is explicit.

The empirical edition PDF and production navigation are downstream of G3/G4. The method-only
conference PDF is already available without making an empirical release claim.
