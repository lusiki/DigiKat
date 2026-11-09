# Full-period media landscape, v1

This implements the user's request for a **first descriptive and exploratory
report using all years of determDB_merged.duckdb**, extending the supplied
`spirituality-associations-media-research-plan.pdf`. It does not replace the
earlier 2025 study. See `EXECUTION.md` for the approved scope and plan deviations.

## Deliverables

- Reader report: repository `output/pdf/spirituality-associations-media-landscape-2021-2026.pdf`.
- Editable text: `../output/report/MEDIA_LANDSCAPE_2021_2026.md`.
- Aggregate tables: `../output/tables/media-v1/`.
- Ten scientific figures, PNG and SVG: `../output/figures/media-v1/`.
- Local searchable directory: `../output/private/media/v1/organisation_directory.html`.
- All 1,325 organisation profiles: private `organisation_landscape.csv`.
- All 7,950 organisation-year combinations: private `organisation_year_complete.csv`;
  held names have blank counts, distinct from searched zeros, and 2026 is marked partial.
- Auditable restricted records: private `months/*.jsonl`, `items.csv`, `pairs.csv`,
  `pair_evidence.jsonl`, `ai_reading_queue.csv`, `topic_reading_examples.csv`.
- Blank preparation queue for independent review: private `future_review_queue.csv`.

No vendor text, titles, article URLs, personal contact fields or row identifiers
belong in the aggregate supplement. The directory is local and private; no site
or external account was published or updated.

## Reproduce

Python 3.14 is used. Install `../requirements.txt` and scikit-learn (which supplies
SciPy); the exact versions of this run are saved in the release environment.
The reconciled private register from `../01_register.py` is required. The default
source path is defined in `01_scan.py`; change `DB` for another machine before
starting a fresh output version. The source is always opened read-only.

From the repository root:

```powershell
python -X utf8 studies/spirituality-associations/media/00_run_scan.py
python -X utf8 studies/spirituality-associations/media/02_analyse.py
python -X utf8 studies/spirituality-associations/media/03_topics.py
python -X utf8 studies/spirituality-associations/media/03b_repeat_check.py
python -X utf8 studies/spirituality-associations/media/04_figures.py
python -X utf8 studies/spirituality-associations/media/05_report.py
python -X utf8 studies/spirituality-associations/media/06_verify.py
```

The first command uses six disjoint year workers, four SQL threads each, and
4 GB memory limits per connection. Use `01_scan.py` alone for sequential scanning.
Completed months are resumed only under the same database/rule signature. The
source schema, size/mtime fingerprint, total records and source/rule hashes are
frozen. For a different snapshot, use a new output version rather than modifying
the old cache signature. A cancelled month has a `.partial` file and is rerun.

After report creation, render all pages using Poppler and inspect the PNGs.
The repository's existing Poppler runtime is under `tmp/pdfs/poppler/`.
`verification.json` records numerical and disclosure checks; visual inspection
is recorded separately in `QUALITY_REVIEW.md`.

## Definitions and limitations

- **Frame:** 1,325 entries in the supplied active-status list dated 11 September
  2026; historical names, dissolution and year-specific eligibility are unresolved.
- **Search:** all dated records in the merged general feed, not the Catholic
  DigiKat subset. Existing complete-name rules and documented aliases are used;
  short/generic names held for identity work remain explicit.
- **Field separation:** title, body and snippet are searched independently.
  Offsets refer to the normalized field, not to original Unicode character offsets.
  Original fields are retained and can be joined through private row hashes.
- **Candidate publication-day:** platform + conservatively canonicalized URL +
  database date, falling back to vendor ID and then title/body hash. Different
  dates are retained because a URL can be reused; URL-only collapse is a sensitivity.
- **Exact record collapse:** identical values of the ten extracted source fields;
  this is not an assertion that every vendor/import field is identical.
- **Exact-text group:** identical normalized body with at least 200 characters;
  shorter bodies stay distinct. Near-copy story families are not yet resolved.
- **Restricted screen:** title/body matches preceding a small explicit set of
  tail markers, excluding four empirically ambiguous names and cases supported
  only by `skac st`. It is a sensitivity set, not an accepted-identity corpus.
- **Title/lead:** name in TITLE or the first 800 normalized body characters;
  navigation can still pass. C7 is a directly inspected counterexample.
- **Rates:** raw candidate records divided by raw monitored records only, within
  identical date/platform/source scope. No deduplicated numerator/raw denominator.
- **Common panel:** web domains with >=100 observed records in each of all 69
  months. It holds the observed domain set constant, not every collection condition.
- **Current own-domain map:** six documented organisation/domain mappings; unknown
  relationships are never relabelled as independent editorial sources.
- **NMF:** exploratory, name-masked surface-form TF-IDF; 6/8/10/12 topics, two
  starts, fixed eight-topic display, topic alignment across starts and full text,
  web-only projection and one-exact-text-group weighting. No Croatian lemmatisation
  or independent editorial-only model is claimed. Labels follow inspected examples.
- **Repeat suppression:** a subsequent diagnostic removes eight-token runs found
  in at least 20 distinct items, excludes contexts with fewer than 15 retained
  non-stopword tokens and compares six/eight-topic models with two starts. It was
  added after template-driven topics were observed; it is not preregistered and
  can remove substantive repeated announcements. National candidate counts do not change.
- **Review:** all human fields remain blank. AI case notes are purposive development
  observations. The blank future queue uses 40 exact-text clusters per first-seen
  year × web/other stratum after excluding designated development clusters; it still
  needs near-copy leakage checks and finer risk stratification before formal use.

The recent Q1 2024 replacement means the observed collection break is **January
2024**, not April 2024 as in the original plan. The full-period scan includes
every date through 10 September 2026. Calendar 2026 is explicitly partial.

Full unfiltered-export recovery, exhaustive alias discovery, historical eligibility,
source/production coding, two-reader validation and the full investigative phase
are later-stage plan packages, not completed results of this first report.
