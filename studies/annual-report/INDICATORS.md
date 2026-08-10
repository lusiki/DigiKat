# Indicator codebook — annual-report spine

Status: version `edition-1.0`, first applied to reporting year 2025. AR01–AR08 are published; AR09–AR10
remain outside the spine until their data and validation gates exist.

Definitions below are unchanged from `pilot-0.1`. What changed is coverage: the source is now the official
corpus (`data/digikat_corpus.rds`) rather than accumulator-vintage aggregates, all sixteen theme categories
are reported under one denominator, tone is annual, and the event calendar is complete. Those were the
edition-1 acceptance conditions already recorded in `GAPS.md`, so they are gap closures, not redefinitions.

## Shared rules

- **Reporting period:** preceding calendar year.
- **Comparable series:** starts in 2024 and must be conditioned on `data_source × platform`. A pooled aggregate
  that omits `data_source` may supply a single-year snapshot but cannot support a movement claim.
- **Collection interruptions:** a run of days with no post on any platform is an instrument fact. It is excluded
  from every average and from both sides of any period comparison, and it is disclosed wherever the period is
  shown. Reporting year 2025 carries one, 1–14 September.
- **Named universe:** institutional media outlets only, after PI ratification and disclosure review.
- **Suppression:** named cells below five posts are suppressed by default; rare combinations receive human review
  even above that threshold.
- **Labels:** confessional/secular results report the classified share and unclassified remainder. They are
  described as indicative until the PI-owned sidecar is ratified.
- **Missing values:** never converted to zero unless zero is the documented measurement meaning. Platforms
  without interaction or reach capture are excluded from those denominators and named in the note.
- **Revisions:** every definition change increments the version and triggers a back-series decision.

## AR01 — Volume of Catholic-themed coverage

- **Plain definition:** How many included posts about Catholic themes were recorded during the reporting year,
  overall and on each platform?
- **Numerator/unit:** included post rows; count of posts.
- **Denominator:** none for counts; all reporting-year posts for platform shares.
- **Current source:** the corpus, cut by the report itself into platform, month and day cells carrying `dk_era`;
  reconciled cell for cell against `data/processed/platform_summary.rds`.
- **Caveats:** collected coverage is not the whole internet; platforms differ in collection and metrics;
  Instagram and TikTok enter only in the later period.
- **Comparability:** compare editions only inside common platform/stream cells and for equally complete periods.
- **Edition-1 status:** published. Annual snapshot plus one within-stream half-year comparison, with the
  distinct-source count beside the volume so a widened watch list is not read as a livelier debate.
- **Output:** platform-share table and figure, monthly and daily series, half-year slope chart.
- **Version:** `edition-1.0`.

## AR02 — Indicative confessional/secular composition

- **Plain definition:** Among posts from sources that the editorial sidecar can classify, what share comes from
  confessional and what share from secular outlets?
- **Numerator/unit:** reporting-year posts in each label; count and percentage.
- **Denominator:** posts from classified sources only. Classified coverage is separately divided by all posts.
- **Current source:** `source_summary.rds` joined exactly on `FROM` to
  `resources/dictionaries/source_labels.csv`.
- **Required edition-1 aggregate:** source × year × platform × stream, plus a ratified label version.
- **Caveats:** labels are editorial judgements; unclassified posts are not redistributed; identical brands may
  appear under several platform-specific source names.
- **Comparability:** use the same label-version hash or restate all editions under a new ratified version.
- **Edition-1 status:** published as indicative only; the sidecar covers 34,5 % of annual volume and is still
  `proposed`.
- **Output:** labelled-composition figures in the tone chapter, always with classified coverage stated.
- **Version:** `edition-1.0`.

## AR03 — Leading institutional actors

- **Plain definition:** Which institutional outlets produced the most included posts on each platform during the
  reporting year?
- **Numerator/unit:** posts per actor; count.
- **Denominator:** eligible institutional actors on the platform.
- **Current source:** `top_*_sources.rds` supplies all-period layout examples; `source_summary.rds` supplies
  reporting-year totals without platform.
- **Required edition-1 aggregate:** actor × platform × year × stream.
- **Caveats:** volume is not quality or influence; aliases require entity reconciliation; individuals are never
  named.
- **Comparability:** stable entity IDs and platform-specific eligibility are required.
- **Edition-1 status:** published. The named league covers institutional outlets the sidecar clears, above the
  five-post floor; concentration statistics cover all sources without naming any.
- **Output:** league table, concentration curve, private mirror profiles.
- **Version:** `edition-1.0`.

## AR04 — Actor quadrants and movement

- **Plain definition:** How are institutional outlets distributed between the four neutral interaction/reach
  quadrants, and which outlets changed quadrant? Legacy interpretive names are not used as substantive roles
  until qualitative validation supports them.
- **Axes:** total interactions and total reach within platform.
- **Rule:** pilot typology repeats the current per-platform median split. Edition 1 must decide whether annual
  medians float or the reference medians are frozen; frozen reference medians are recommended for movement.
- **Current source:** all-period `*_actors.rds` objects.
- **Required edition-1 aggregate:** actor-year-platform panel with stable entity IDs and metric availability.
- **Caveats:** current actor files contain only selected top actors; thin accounts can cross medians by chance.
- **Comparability:** no movement is reported until the reference rule and eligible universe are frozen.
- **Edition-1 status:** the 2025 distribution is published; movement stays blocked until the reference rule is
  frozen.
- **Output:** quadrant distribution table for the reporting year.
- **Version:** `edition-1.0`.

## AR05 — Engagement benchmarks

- **Plain definition:** How many interactions does a typical post receive for an actor of the same platform and
  type?
- **Primary unit:** median interactions per post within `platform × actor type`.
- **Secondary unit:** exposure-normalized engagement only where reach is consistently defined and non-missing.
- **Current source:** all-period `*_actors.rds`; interaction-per-post can be derived.
- **Required edition-1 aggregate:** actor-year-platform panel plus metric-coverage diagnostics.
- **Caveats:** interactions are platform-specific and not equivalent behaviours; zero capture is not necessarily
  zero engagement.
- **Comparability:** benchmark only within platform and metric definition; never pool unavailable platforms.
- **Edition-1 status:** published for platforms that capture the metric; platforms below the coverage floor are
  excluded and printed as not recorded.
- **Output:** per-platform and per-quadrant medians behind the private profiles.
- **Version:** `edition-1.0`.

## AR06 — Thematic profile and movers

- **Plain definition:** Which of the frozen Catholic-theme categories occupied the largest share of recorded
  thematic mentions during the reporting year?
- **Numerator/unit:** mentions assigned to a dictionary category; count and share.
- **Denominator:** all category mentions in the eligible annual input; a post may contribute to more than one
  category.
- **Current source:** the stratified theme sample restricted to corpus members, scored against the frozen
  dictionary; TikTok and texts of 100 characters or fewer remain excluded.
- **Mover rule:** change in share within comparable platform/stream cells, with a minimum support threshold fixed
  before inspection.
- **Caveats:** sample estimates are not weighted to the full corpus; dictionary detection is not manual topic
  coding; overlapping categories mean mention shares are not shares of unique posts; precision and recall are
  not yet validated.
- **Comparability:** dictionary hash and token pipeline must match; otherwise publish a break.
- **Edition-1 status:** published. All sixteen categories under one denominator, from 6 174 corpus documents
  (5,0 % of the corpus year). Movers stay blocked until there is a previous edition to move from.
- **Output:** sixteen-category figure and table, with mention share and dominant-theme share side by side.
- **Version:** `edition-1.0`.

## AR07 — Tone and conflict

- **Plain definition:** How positive/negative and how conflict-oriented was the recorded discourse overall and
  on the year's leading themes?
- **Units:** frozen sentiment score and conflict index, reported separately with their empirical ranges.
- **Current source:** the stratified tone sample restricted to corpus members, scored on lemmas against
  CroSentilex Gold and the lilaHR emotion set; TikTok and short texts remain excluded.
- **Caveats:** lexicon scores approximate linguistic tone and do not establish author intention; aggregation can
  hide outlet differences; the pilot object does not expose the annual conflict measure, score direction,
  empirical range, or uncertainty needed for interpretation.
- **Comparability:** frozen lexicons, preprocessing, scale direction, and minimum cell size.
- **Edition-1 status:** published for the reporting year from 2 532 corpus documents (2,0 % of the corpus year),
  with document counts and 95 % intervals, overall, by leading theme and by source label.
- **Output:** tone-by-theme dot plot with intervals, tone-and-conflict comparison by source label.
- **Version:** `edition-1.0`.

## AR08 — Events of the year

- **Plain definition:** On which dates did recorded attention depart most strongly from that year's ordinary
  daily rhythm?
- **Rule:** daily volume z-score calculated across observed sample days within year; candidate peaks use the
  existing detector threshold.
- **Current source:** daily counts from the corpus itself, over the complete calendar.
- **Still required:** private evidence packets and a documented two-person event-naming decision.
- **Caveats:** a peak identifies sample volume, not population attention or its cause; several days may belong
  to one event. The 2025 object represents 351 of 365 calendar days because days with no sampled posts are
  absent; collection interruptions must also be ruled out.
- **Comparability:** same within-year standardisation, minimum daily coverage, threshold, and tie rule.
- **Edition-1 status:** published on population volume rather than a sample: daily counts come from the corpus
  itself, over the complete calendar, with the collection interruption excluded from the baseline. Four days
  clear the pre-set three-deviation threshold. Naming is editorial, taken from the public calendar and
  cross-checked against each day's theme composition.
- **Output:** year line with marked arcs and interruption, arc table with deviation and arc length.
- **Version:** `edition-1.0`.

## AR09 — Church-voice penetration

- **Plain definition:** When secular outlets cover a topic on which an institutional Church source has spoken,
  how often and how quickly does the Church framing appear in that coverage?
- **Source:** new voice-carry study and matched source/uptake design.
- **Caveats:** exposure is not uptake; topic overlap is not transmission; matched timing and negative controls are
  required.
- **Comparability:** unavailable until the construct and matching window pass validation.
- **Pilot status:** blocked; not in the recurring spine.
- **Version:** `future`.

## AR10 — Audience-side survey

- **Plain definition:** How do audiences encounter, trust, and use digital coverage of Catholic themes?
- **Source:** new survey module.
- **Caveats:** sampling frame, non-response, instrument stability, ethics, and stewardship are unresolved.
- **Comparability:** requires a repeated instrument and sampling design.
- **Pilot status:** blocked; not in the recurring spine.
- **Version:** `future`.
