# Textual addendum execution

Approved input: `output/pdf/demokrscanstvo-plan-tekstualne-dopune.pdf` (18 pages).

Execute the computational/research core: M1 vocabulary, M2 original phrases and sentence relations, M3/M4 transparent AI-read case cards and a prospective blinded human sample, M5 lexical dispersion. Independent human coding is pending; the plan's explicit fallback applies. No content prevalence, reliability coefficients or sentiment-based political support estimates are fabricated.

Frozen original reports, source archive, inclusion rules and website remain unchanged. Row texts, keys, spans, document TF-IDF and coding packages are written exclusively to `$DIGIKAT_BAROMETAR_WORKDIR/text-addendum-v1`. Public aggregates go to `output/demokrscanstvo-text-addendum/v1`.

Sequence: prepare source linkage and expanded sentence annotations; compute local and sensitivity outputs; read selected relations and complete available bodies for argument cards; create the PDF; reconcile claims and inspect every rendered page. Analytical conventions and actual deviations are recorded with the release.

## Reproduce on the authorized Windows machine

From the repository root:

```powershell
& 'C:/Program Files/R/R-4.6.0/bin/Rscript.exe' studies/demokrscanstvo-barometar/text-addendum/prepare.R
python -X utf8 studies/demokrscanstvo-barometar/text-addendum/analyze.py
python -X utf8 studies/demokrscanstvo-barometar/text-addendum/supplement.py
python -X utf8 studies/demokrscanstvo-barometar/text-addendum/build_report.py
python -X utf8 studies/demokrscanstvo-barometar/text-addendum/verify.py
```

Use `DIGIKAT_BAROMETAR_WORKDIR` for the private cache on another machine. R uses project renv. The local startup reports an out-of-sync library; no bypass or lockfile modification was used. Exact R/UDPipe versions and model hash are recorded. Python calculations use the standard library; plotting/verification package versions are in the final manifest. Windows Calibri and Georgia are needed for the supplied PDF layout.

`supplement.py` records the case decisions made during this Codex run; it does not call a classifier or reproduce an independent reading. Preserve completed human-coder files before any future sample regeneration. The generated files are a prospective instrument, not finished coding.

For aggregate-only redrawing, the output package and `build_report.py` suffice; the original report/lexicon paths in `analyze.py` must remain available. The actual text preparation and verification require the restricted cache. Render all 18 final pages with Poppler and inspect them. Record the exact PDF hash in `visual_qa.json`, then run `verify.py --finalize`.

## Release and table contracts

- Report: `output/pdf/demokrscanstvo-tekstualna-dopuna-izvjestaj.pdf`. Editable source: `report.md`. Figures: PNG and SVG; numerical figure inputs are saved as CSV.
- `summary.json`: all analysis universes and missingness. Local sentence/offset counts reproduce the prior report. Expanded tokens are a new sensitivity only.
- `vocabulary_local.csv`, `vocabulary_expanded.csv`: one lemma per row, raw token and text counts, normalized frequency on the stated retained-token denominator, average TF-IDF including zeros, source and sentence support. Exact-text representatives are not independent stories. The raw single-lemma and broader concept counts must not be substituted for each other.
- `contrasts.csv`: two direct group-versus-group empirical-prior log-odds comparisons, based on presence among all members. Base, A1, surface, no overlapping groups, no largest source, no longest supporting text, and no largest supporting sentence. Prior recomputed from the two remaining corpora. Surface rows contain forms, not lemmas. Each term-specific control can have its own denominator. The largest source is chosen by archived record count within the comparison. Removing its groups removes all their contributions from both sides. Thresholds in `contrast_ranks.csv` are display filters after computing the shared vocabulary; rank is by absolute score. These scores are not p-values.
- `phrases.csv`: all bigrams/trigrams with at least five supporting groups plus every observed dictionary phrase. Common grammatical phrases remain in the full output; the report shows an explicitly selected content list. Phrase detection keeps original adjacency and breaks at punctuation. Dictionary uses the longest match at a given start; a later-start subphrase can overlap. Strict phrase counts can miss lemmatizer variants, such as `socijalno` versus `socijalan`; this is an acknowledged limitation, not a zero-content claim. Word-sequence control concerns identity of a supporting sentence after punctuation removal, not creation of extra bigrams.
- `relations.csv`: full 2×2 sentence contingency tables, NPMI and phi on all 7,467 units, including 2,963 zero-concept rows. The original 25-concept dictionary is preserved. Its regex representation removes punctuation; relationship findings require the retained source sentence and context. High association is not shared stance.
- `concept_profiles.csv`: all representatives versus representative-A1 versus any web presence. Denominators differ; zero does not signify absence from the wider discourse.
- `quarterly.csv`: one group at most once per platform/regime/quarter, followed through all its records. Support is not additive over time. The 2024-Q1 web denominator is six. Final quarter is partial; groups may recur across full-year comparisons. Small cells on other platforms are flagged.
- `dispersion.csv`: counts by platform/regime, quarters, known sources, unknown sources, and independent exclusions of dominant source, month, sentence and punctuation-free sentence. Source counts can overlap for a group carried by multiple sources. These are lexical persistence measures, not confirmed argument persistence.
- `near_copy_content_sensitivity.csv`: counts existing exploratory complete-link shingle clusters containing at least one hit at .85/.90/.95. These are not calibrated stories or independently validated paraphrases.
- `argument_cards.json`: nine purposive AI readings, with date/source, target, referent and limits. Individual exact group keys, source text and spans are private. Three strict positive examples, a wider-text programmatic case, target contrasts and boundary/negative cases are shown without prevalence. K06/K09 do not pass the stricter democratic referent criterion despite related Christian-social arguments.
- `sampling_design.csv`: seven nonempty strata, 400 exact groups, seed 20260920, weights totaling 2253. Two unchanged blinded packages, a 60-text pilot and full sampling membership are private. No coder time, reliability or prevalence is invented.
- `claim_register.json`: page-linked prose and numeric claims, source tables and interpretive status. `checks.csv`/`verification.json`: computational checks. `manifest.json`: inputs, annotations, outputs, code and actual runtime hashes.

## Execution choices and limits

Python was used for descriptive statistics rather than the plan's suggested tidytext/tidylo stack. The exact formulas are stated in the report. The explicit two-corpus posterior log-odds differ from tidylo's implementation relative to a pooled distribution and are not mislabeled as that function's output. R/UDPipe handles language preparation.

The approved computational-core fallback was used. M3/M4 human pilot and final coding, validated application matrix/prevalence, and a coded-content lexical contrast remain unperformed. Sentiment and LDA were conditional; no human pilot established the need for either. M5 reports lexical rather than coded-argument persistence. All limitations appear in the PDF itself.

Nine full available bodies and 55 relation sentence cases from 51 different texts (with their complete existing evidence contexts) were read by Codex AI. Relationship selection greedily increases lexical diversity, prioritizes negation at the initial tie, and excludes repeated group IDs and word sequences. Five relationship sets contain ten cases; HDZ/conscience has five. The readings are purposive, do not estimate classification errors, and have no independent human reliability.
