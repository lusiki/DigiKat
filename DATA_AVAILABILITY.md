# Data availability — DigiKat

DigiKat follows open-science principles while respecting copyright, platform terms, privacy, and the
disclosure risks of row-level media data. “Present in the repository” does not mean that every asset
shares one license; third-party language resources retain their upstream terms.

## Availability matrix

| Asset | Repository | Redistribution | Governing terms |
|---|---|---|---|
| `data/merged_comprehensive.rds` | no | restricted | source copyright and platform/API terms |
| historical January 2026 Kaggle snapshot (612,065 rows) | external | public historical release | verify the version and license on Kaggle before reuse |
| `data/raw/**` and incoming spreadsheets | no | restricted | source-dependent |
| `data/processed/*.rds` | yes | open aggregate outputs | project-declared CC BY 4.0 |
| `data/sample/merged_sample.rds` | yes | open, fully synthetic | project-declared CC BY 4.0 |
| `data/nlp/**` | no | restricted/generated | contains sampled corpus text |
| `data/semantic/**` | no | restricted/local | contains text and embeddings |
| `studies/*/output/private/**` | no | restricted | row-level URLs, identities, excerpts, or coding |
| disclosure-reviewed study tables/figures | yes | open when explicitly tracked | project-declared CC BY 4.0 |
| `resources/**` | partly yes | resource-specific | see `resources/README.md` |
| project-authored scripts and documentation | yes | public repository | repository declares CC BY 4.0; no separate code license has been adopted |

Do not infer MIT licensing for the code. A future code-specific license requires an explicit project-owner
decision and cannot be retroactively assumed.

## Restricted master corpus

The current master contains **710,307 records and 47 columns**. The aggregate time span is January 2021
through June 2026; 2026 is partial. It covers:

`web`, `youtube`, `facebook`, `twitter`, `reddit`, `forum`, `comment`, `instagram`, and `tiktok`.

A record is retained only if its text matches at least **two distinct** canonical religious terms from
`R/religious_terms.R`. Incoming data is deduplicated by a platform-aware canonical URL: tracking
parameters are removed, but identity-bearing parameters such as the YouTube video ID are preserved.

The master contains source text, URLs, account/source fields, and engagement metadata. It is gitignored
and must not be copied into issues, pull requests, examples, or public study outputs.

Authorized non-commercial research access may be requested from:

**doc. dr. sc. Luka Šikić** — <luka.sikic@unicath.hr>

Access is not automatic and may require a purpose statement, storage safeguards, and acceptance of
source-platform restrictions.

A separate [Kaggle release](https://www.kaggle.com/datasets/lukasikic/croatian-catholic-digital-media-space)
contains an older January 2026 snapshot. It is not the current 710,307-row master. At the 2026-07-28
inventory, Kaggle’s API-level license label and its narrative description were not consistent; users
must resolve the governing terms on that release before redistribution.

## Public aggregate generation

`data/processed/` contains one complete 14-file generation:

- `platform_summary.rds`
- `platform_monthly.rds`
- `proportions_summary.rds`
- `source_summary.rds`
- `top_sources_by_year.rds`
- `top_web_sources.rds`
- `top_youtube_sources.rds`
- `top_facebook_sources.rds`
- `web_actors.rds`
- `youtube_actors.rds`
- `facebook_actors.rds`
- `instagram_actors.rds`
- `tiktok_actors.rds`
- `twitter_actors.rds`

The canonical builder is `R/03_aggregate.R`. Its default mode recreates and validates the generation in
a temporary directory. Production replacement requires `--apply`, a staged round-trip check, total
reconciliation, and a generation manifest.

Aggregates can still identify public media brands through `FROM`; they do not contain post text, URLs,
or row-level user data.

## Synthetic fixture

`data/sample/merged_sample.rds` is a deterministic, **fully synthetic** dataset with:

- 2,700 rows and the exact 47-column master schema;
- 50 rows for every source-type/year stratum;
- all nine source types and years 2021–2026;
- only `example.invalid` URLs and synthetic text; and
- SHA-256 `4c27aa2e422a4a371b80ceea64a745699830c2227a1f4af00214c77e0f98914c`.

Its manifest is `data/sample/merged_sample_manifest.json`. Regenerate it with:

```powershell
Rscript R/make_sample.R
```

Regression tests reject unexpected hosts and schema drift.

## Study-output disclosure boundary

Study folders use:

- `output/` for reviewed aggregates, figures, calendars, and de-identified summaries;
- `output/private/` for URLs, titles, text windows, row-level source identities, and coding sheets; and
- `output/intermediate/` for replaceable checkpoints.

Both restricted directories are ignored. Run `Rscript R/check_disclosure.R` before committing. The
automated check catches direct fields; a person must still review small cells and indirect identifiers.

## Pinned language model

`resources/models/croatian-set-ud-2.5-191206.udpipe`

- size: 19,236,607 bytes;
- SHA-256: `b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7`;
- model family: UDPipe Universal Dependencies 2.5, release 2019-12-06;
- upstream model terms: CC BY-NC-SA, with underlying treebank conditions also applicable; and
- Croatian SET treebank terms: CC BY-SA 4.0.

Only the copy under `resources/models/` is canonical.
