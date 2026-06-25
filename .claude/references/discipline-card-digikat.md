# DigiKat Discipline Card

> Read by the research/paper skills (`/lit-review`, `/research-ideation`, `/review-paper`) and the
> `scholar-skill:*` family so they do NOT default to economics / AER / causal-identification conventions.

- **field:** sociology of religion · communication / media studies · digital humanities · computational text analysis
- **dominant_paper_types:** descriptive, computational-text-analysis, mixed-methods
- **NOT:** reduced-form causal (no DiD/IV/RDD/synthetic control), structural, formal-theory

- **citation_style:** APA 7th (default) | Chicago author-date (history/sociology venues)
- **language:** bilingual — Croatian content + abstracts; English for international venues

- **venues_hr:** Medijska istraživanja · Društvena istraživanja · Nova prisutnost · Diacovensia · Crkva u svijetu
- **venues_en:** New Media & Society · Journal of Media and Religion · Social Media + Society · Religion · Information, Communication & Society

- **methods_referee_tilt:** `descriptive`
  - emphasize: sampling frame, measurement/construct validity, lexicon validity, representativeness of the
    2–5% stratified sample, false-positive rate of the ≥2-term inclusion filter, platform-coverage gaps,
    encoding integrity, temporal coverage.
  - do NOT raise: parallel trends, first-stage F, overlap/ignorability, identification.

- **preregistration_norm:** NOT expected for descriptive/exploratory work.
  - Trigger OSF preregistration ONLY for a confirmatory directional hypothesis on a NOT-YET-examined corpus
    slice (candidate: Study 3, christian-democracy). `scholar-design` refuses retrospective prereg — respect that.

- **corpus_constraints:**
  - size: ~610k posts (2021–2025), Croatian/Bosnian
  - inclusion: ≥2 distinct Catholic root-term matches (`R/religious_terms.R`)
  - platforms: web portals (dominant) · YouTube · Facebook · Twitter · Reddit · forums
  - themes: 16 dictionary categories; sentiment via CroSentilex / CroSentilex Gold / lilaHR
  - access: master gitignored / on request; processed aggregates CC BY 4.0 in repo

- **declarations required on every output:** data-availability statement + AI-use disclosure
  (via `scholar-skill:scholar-open` / `scholar-skill:scholar-ethics`).
