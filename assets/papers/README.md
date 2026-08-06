# Thematic paper assets

Every paper linked from **Tematska istraživanja** uses `digikat-paper.css`, which extends the DigiKat
website design system to standalone manuscripts and their print/PDF editions. Run the publisher from the
repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish_thematic_papers.ps1
```

The publisher does not rerun an old analysis or alter manuscript prose. It takes the exact HTML version
linked by the study profile, adds common navigation and author links, repairs declared format links, and
prints the styled document to PDF. Remote inputs are pinned to immutable Git commits.

| Local stem | Canonical HTML input | Additional source format |
|---|---|---|
| `trzista-paznje` | `Mapping-Catholic-Digital-Media-Space` commit `2deb813`, v7 | — |
| `memorijalni-okvir` | `Memorijalni-okvir` commit `78ccc07`, `manuscript_one` | Word |
| `katolicki-influenceri` | `Katolicki_Influenceri` commit `fa34ff5`, `analysis_hr` | — |
| `redovnicke-zajednice` | `Redovnicke-zajednice` commit `74f1a1a`, `analysis_v3` | — |
| `crkva-i-dezinformacije` | `Church-and-dezinfo` commit `6dffe79`, `03_framing_paper_2` | — |
| `inflation-information-delayed-repricing` | local checked output `PAPER_EMIP_v2_full.html` | Word |
| `socijalni-nauk-i-gospodarstvo` | local checked output `PAPER_RSP_v2.html` | — |
| `katolicko-obrazovanje-i-stepinac` | local checked output `catholic-education-paper-v2.html` | Word |

The church-media manuscript remains anonymous in all formats because it is under peer review. The author
entry is therefore intentionally not linked. Broken Word links embedded in older HTML are rendered as
unavailable text unless an actual Word artifact exists; no newer manuscript version is substituted.
