# Thematic paper assets

Every paper linked from **Tematska istraživanja** uses `digikat-paper.css`, which extends the DigiKat
website design system to standalone manuscripts and their print/PDF editions. Run the publisher from the
repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish_thematic_papers.ps1
```

The publisher does not rerun an analysis or alter manuscript prose. It takes the exact HTML version
linked by the study profile, adds common navigation and author links, repairs declared format links, and
prints the styled document to PDF. Remote inputs are pinned to immutable Git commits. A local, newly
rendered church-framing manuscript can be supplied with `-ChurchFramingSourceHtml` and
`-ChurchFramingSourceDocx` while its source revision is being prepared for publication.

| Local stem | Canonical HTML input | Additional source format |
|---|---|---|
| `trzista-paznje` | `Mapping-Catholic-Digital-Media-Space` commit `2deb813`, v7 | — |
| `memorijalni-okvir` | `Memorijalni-okvir` commit `78ccc07`, `manuscript_one` | Word |
| `katolicki-influenceri` | official-corpus rerun in `studies/catholic-influencers`, recovered from `Katolicki_Influenceri` commit `fa34ff5` | Word |
| `redovnicke-zajednice` | `Redovnicke-zajednice` commit `74f1a1a`, `analysis_v3` | — |
| `crkva-i-dezinformacije` | official-corpus rerun of `03_framing_paper_2`; exact input and result manifests are in `crkva-i-dezinformacije-data/` | Word |
| `inflation-information-delayed-repricing` | local checked output `PAPER_EMIP_v2_full.html` | Word |
| `socijalni-nauk-i-gospodarstvo` | local checked output `PAPER_RSP_v2.html` | — |
| `katolicko-obrazovanje-i-stepinac` | local checked output `catholic-education-paper-v2.html` | Word |

The church-media asset currently uses the official corpus rebuilt on 10 August 2026. Its source checkout
is based on `Church-and-dezinfo` commit `1475dd9`; the new-corpus revisions are local until they receive an
immutable upstream commit. Reproduce the current asset by passing the rendered HTML and Word paths to the
two church-framing publisher parameters. Broken Word links embedded in older HTML are rendered as
unavailable text unless an actual Word artifact exists.
