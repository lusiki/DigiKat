# Thematic map of Christian democracy in media

The thematic map describes the language of the publications included in the
media barometer. It is a separate aggregate release linked by SHA256 to the
underlying monthly barometer release. It does not alter the inclusion rule.

## Method

1. Reconstruct the original qualifying A1/B/C evidence windows from the private
   classification checkpoints and candidate texts. Apply the same title removal,
   web boilerplate masking and normalization as the classifier. Each window has
   at most 80 tokens. Overlapping windows are merged within each field; identical
   passages in a record are counted once in its contextual text.
2. Lemmatize the distinct contexts using the Croatian SET UD 2.5 UDPipe model,
   retaining nouns, proper nouns and adjectives. Discard short/nonalphabetic
   terms, a documented generic stop list, and the shared retrieval vocabulary.
3. Compute L2-normalized TF–IDF with sublinear term frequency, minimum document
   frequency 5, maximum document frequency 85%, and at most 6,000 features.
   Fit non-negative matrix factorization (NMF) on distinct contexts. Repeated
   contexts receive the same assignment, and all archived publications enter
   the final counts. Near-duplicate passages can remain distinct fitting units.
4. Compare 6, 8, 10 and 12 components using the leading terms and six strongest
   example contexts per component. Ten components preserve interpretable
   distinctions between political identity, electoral reporting, cultural
   debate, European affairs and intellectual discussion. Names and descriptions
   are editorial interpretations of these components, not predefined classes.
5. Normalize component vectors to unit L2 length, rescale document contributions
   accordingly and assign each record to its largest contribution. Contexts
   without retained vocabulary remain unassigned. Each record is counted once;
   the resulting themes describe its primary contextual vocabulary, not all
   subjects addressed in the full publication.
6. Compare the selected solution with three random starts (seeds 23, 71, 113)
   using adjusted Rand agreement. Diagnostics, package versions, model hash and
   fixed seed are recorded in `summary.json`. Random-start agreement describes
   model stability, not classification accuracy or independent human validation.

Monthly topic counts reconcile exactly with the original included counts for
each platform and month. Platform/year filters use this same fixed model; they
do not refit topics. Percentages describe the selected included publications.
An empty selection displays no findings, rather than a fabricated distribution.
The annual slices reflect the dates available in the source, including the
partial final year and the April 2024 collection change.

The original dictionary policy themes remain a separate, overlapping measure
of public-policy concepts in the qualifying passage. They must not be added
to the mutually exclusive NMF topic counts. Neither analysis measures support,
reach, or the political position of an author or source.

## Reproduction

From the repository root, using the configured external barometer work directory:

```text
Rscript studies/demokrscanstvo-barometar/thematic_prepare.R
python -m pip install -r studies/demokrscanstvo-barometar/requirements-thematic.txt
python studies/demokrscanstvo-barometar/thematic_build.py --inspect
python studies/demokrscanstvo-barometar/thematic_build.py
python studies/demokrscanstvo-barometar/thematic_verify.py
quarto render pages/demokrscanstvo/index.qmd
```

The inspection report, lemmas, contexts and record assignments stay outside the
repository. Only the two aggregate CSVs, topic descriptions, model diagnostics,
this method note and checksums are public. Labels are bound to the model input
signature: changes to input data or vectorization require another label review.
The page reads aggregates and never opens the source database.

## Design references

The presentation combines attention over time with contextual language analysis,
an approach used in [Media Cloud](https://ojs.aaai.org/index.php/ICWSM/article/view/18127).
The statistical implementation follows the documented
[TF–IDF/NMF topic extraction workflow](https://scikit-learn.org/stable/auto_examples/applications/plot_topics_extraction_with_nmf_lda.html).
These references inform the design and method; all barometer findings are
computed from the local data.
