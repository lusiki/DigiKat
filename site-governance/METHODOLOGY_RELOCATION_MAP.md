# Methodology relocation map

Status: ratified for Site improvement Run 1  
Canonical page: `pages/metodologija.qmd`

Technical-method explanations have one canonical home. Result pages keep only the scope and caution needed to interpret the result in front of the reader. Any new repeated method passage must be assigned to one of the destinations below before publication.

## Canonical destinations

| Passage family | Stable destination | Pages where repetition currently occurs | Relocation rule |
|---|---|---|---|
| Inclusion terms, text window, two-step rule, model threshold | `pages/metodologija.qmd#method-corpus-inclusion` | `pages/baza.qmd`, `pages/about.qmd`, map introductions, project descriptions | Keep one plain sentence saying that the official corpus follows a documented inclusion rule. Move the terms, window, threshold, and implementation detail to the destination. |
| Measured precision, recall, and corpus noise | `pages/metodologija.qmd#method-corpus-quality` | corpus descriptions and analytical qualifications | A result page may say that the corpus is intentionally broad. Precision estimates and validation design belong at the destination. |
| Accumulator, official corpus, frozen study inputs, and data lineage | `pages/metodologija.qmd#method-data-lineage` | `pages/baza.qmd`, `pages/about.qmd`, research pages, reproducibility notes | Public pages name the official corpus. Mention a frozen historical input only when needed to interpret or reproduce that publication. Do not present the accumulator as a second public corpus. |
| Collection change in 2024, missing text, platform entry dates, and interrupted periods | `pages/metodologija.qmd#method-collection-break` | `pages/mapa/evolucija.qmd`, other map pages, reports, catalogue cautions | Keep a short warning beside any affected time comparison. The history, diagnostics, and full prohibition on cross-break volume claims belong at the destination. |
| Meanings of objava, interakcije, angažman, and doseg | `pages/metodologija.qmd#method-platform-metrics` | `pages/mapa/mapa.qmd`, `pages/mapa/evolucija.qmd`, `pages/moj-medij.qmd`, catalogue and source profiles | Keep the comparison group and the phrase `procijenjeni doseg` near a result. Full metric definitions and cross-platform limits belong at the destination. |
| Sampling fractions, fixed seed, strata, minimum text length, and excluded sources | `pages/metodologija.qmd#method-text-analysis` | `pages/mapa/mapa_stats.qmd`, `pages/mapa/diskurs.qmd`, `pages/mapa/događaji.qmd` | Keep the observed sample size and a sparse-cell warning when relevant. Move extraction details to the destination. |
| UDPipe preparation, thematic dictionaries, CroSentilex, lilaHR, and RIK construction | `pages/metodologija.qmd#method-text-analysis` | the three text-analysis map pages and long-form reports | Result pages name the measure in plain Croatian and link to the destination. Implementation inventories and preprocessing steps do not repeat. |
| Construct validity, causal limits, and what text measures cannot reveal | `pages/metodologija.qmd#method-interpretation-limits` | map conclusions, reports, source profiles, `Moj medij` | Keep the one caution specific to the claim being made. The general statement that words do not reveal motives, feelings, or causal effects belongs at the destination. |
| Processing chain, manifests, public aggregates, restricted full text, and rerun instructions | `pages/metodologija.qmd#method-reproducibility` | `pages/baza.qmd`, `pages/resources.qmd`, project and technical pages | Corpus and publication pages keep access, licence, citation, and artifact links. The end-to-end processing explanation belongs at the destination. |

## Short cautions allowed on result pages

A result page may retain one or more of the following when the caution directly changes how the adjacent result is read.

- The final year is incomplete, with the explicit data cutoff.
- A displayed time comparison crosses or approaches the 2024 collection change.
- A comparison is valid only within the named platform or comparison group.
- Doseg is an estimate from the service provider.
- A result rests on a small sample, sparse cell, or few observed dates.
- The result is descriptive and does not establish cause, intent, quality, or audience response.
- A tonalitet, emotion, or conflict label describes words in text and not a person's mental state.
- The corpus describes collected material and not the whole Croatian media universe.
- An editorial source label remains provisional.

These cautions should normally be one or two sentences followed by a link to the exact methodology anchor. They must not reproduce thresholds, dictionary inventories, pipeline steps, or long technical histories.

## Page-family disposition

| Page family | Scope statement retained locally | Canonical method link |
|---|---|---|
| Homepage and project pages | What the project studies and that findings come from the official corpus | Corpus inclusion and data lineage only when needed |
| Official corpus page | What is in the official corpus, what it can support, access, licence, and citation | Inclusion, quality, collection break, and reproducibility |
| Maps | Analytical question, observed population or sample, data cutoff, and one result-specific caution | Platform metrics or text analysis, plus collection break where relevant |
| `Moj medij` | Named comparison platform, minimum support, and profile-specific limitations | Platform metrics and interpretation limits |
| Source profiles | Source scope, platform, observed period, and provisional editorial label | Platform metrics and interpretation limits |
| Reports and studies | Versioned input, report period, and cautions specific to the reported claims | The relevant canonical method section or the publication's frozen method appendix |
