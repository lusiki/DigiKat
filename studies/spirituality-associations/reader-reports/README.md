# Two Croatian reader reports

Revised 22 September 2026 to foreground direct interpretations of indicators and results, with named organisation rankings, outlet distributions and organisation-specific vocabulary and topics. The methodological-limitations and collection-issues passages have been removed from the reader-facing manuscripts at the user's request. Operational provenance remains here and in the aggregate metadata.

- `../../../output/pdf/udruge-duhovnosti-u-medijskom-prostoru.pdf`: overview, ranking of ten leading names, media channels, temporal and geographic patterns, and organisational profiles.
- `../../../output/pdf/udruge-duhovnosti-od-rijeci-do-javne-uloge.pdf`: seven overall/thematic word clouds, the same ten organisations' topic profiles, selected word counts and substantive readings.
- Editable manuscripts: `overview.md`, `language.md`. Expanded manuscripts: `*-resolved.md`.
- Reproducible aggregate inputs: `tables/`; visual assets: `figures/`.

## Reproduction

From the repository root, with the existing Python dependencies and Windows Calibri/Georgia fonts:

```powershell
python -X utf8 studies/spirituality-associations/reader-reports/prepare.py
python -X utf8 studies/spirituality-associations/reader-reports/organisations.py
python -X utf8 studies/spirituality-associations/reader-reports/build.py
```

Render both PDFs with Poppler at 100 dpi into `tmp/pdfs/associations-pair/overview-01.png` and `language-01.png`, etc. Then run `python -X utf8 studies/spirituality-associations/reader-reports/verify.py` and inspect every page. The build checks page overflow. Verification checks text bounds, page counts, unresolved templates, numerical reconciliation, source hashes, aggregate-only exports and fresh PNG renders. `QUALITY_REVIEW.md` records actual visual inspection.

## Organisation comparison

`organisations.py` reads existing frozen `output/private/media/v1/pair_evidence.jsonl` without rescanning the database. The ranking selects web records carrying the existing `restricted_candidate` flag and a title/lead match (name in the title or first 800 normalised body characters). Explicit tag/category/author/page archive URL paths and tag-page boilerplate are removed. One canonical URL is counted per organisational name; its earliest retained publication-day supplies the join key for text analysis.

Two contextual rules address observed identity collisions. The Breza entry requires an Osijek, breza.hr, Zemlja bez granica or socio-therapeutic cue in the name context. Moje mjesto pod suncem requires a Rijeka, Čekade, poverty, social or inclusion cue. The latter is reported as an organisation/programme name. Rules, removal counts and source hashes are in `organisation_method.json`; exact membership is saved privately as `reader_rank_membership.csv`.

The comparison contains 7,219 distinct web URLs, 7,283 name-URL pairs and 333 names. Counts describe named web appearances. They are not restricted to articles authored by the organisation. Domain tables include media, organisational and institutional sites; the prose explicitly identifies own-site publishing where the evidence supports it. Domains are counted separately, including IKA and HKM subdomains. The existing frozen entity links have not acquired human-validation labels through this revision.

New aggregate files:

- `organisation_ranking.csv`: counts and domain breadth for all names in the comparison.
- `organisation_outlets.csv`: domain counts and within-name shares for the top ten.
- `prominent_web_outlets.csv`: domain counts with each web URL counted once.
- `organisation_topics.csv`: frozen six-topic assignments for the top ten, with per-organisation text denominators.
- `organisation_words.csv`: document frequencies of individual words, with matching denominators.
- `organisation_facts.json`: formatted table and numeric expansions consumed by the PDF builder.

## Word and topic counts

`prepare.py` reconstructs the existing repeat-suppression input and checks the retained keys against the frozen 18,938-item assignment file. Names are masked, repeated eight-token sequences are suppressed and the existing stop-word filter applies. Each displayed surface form counts once per retained context. The full-period clouds use the same six topic assignments without refitting. Diacritics are restored for selected display labels only.

For organisation profiles, the ranking's web records are joined to those same retained contexts. The organisation-specific denominator is displayed alongside its topic distribution and word tables. Topic percentages describe this text subset, not every ranked URL. The word table uses explicitly selected frequent, substantive terms; these are listed in `PROFILE_TERMS` and metadata, and are not presented as an exhaustive top-four ranking. Generic page labels and isolated proper-name fragments are omitted from displayed selections; all frequencies remain available in the aggregate file. Colour and position in clouds are decorative.

## Evidence and scope

The supplied frame remains the full administrative spirituality category, covering 1,325 entries. The original 23,436 name-linked publication-days, 18,938 text contexts and new URL-based comparison are separately labelled. No causal effect, audience response, sentiment or independent validation is inferred from volume. Annual prose describes observed counts and keeps the 2026 endpoint explicit.

The original C2-C5 cases are retained as paraphrases. Additional readings inspected prominent-name passages for SKAC Palma, the Međimurje association, Moje mjesto pod suncem, Catholic professional associations, Ime dobrote, the Jastrebarsko Matica branch, Sunce and Alfa Albona. They support the activity descriptions in the portraits. These are AI-assisted readings, not new human annotations. No article text, title, URL, personal contact or row key is exported into the aggregate tables. The source snapshot, upstream study, production corpus and website remain unchanged.
