# Christian democracy in public discourse: analytical and visual plan

Status: proposal only. Requested on 2026-09-19 after the public barometer upgrade.
No new coding, model fitting, data extraction or visual implementation is authorized
by this planning request. Existing completed barometer changes are separately
authorized for commit and push.

## The story to investigate

**Working public title:** *Kako demokršćanstvo živi u javnom govoru: identitet,
vrijednosti i društvena pitanja.*

The central question is how a political and intellectual tradition becomes
visible in media: as a name claimed or contested, a set of social principles,
or an argument about a concrete problem. The analysis should establish which
forms appear, where, and in what circumstances. Their relative importance is
an empirical question, not a conclusion to decide before coding.

Use “media relevance” in five observable senses: visibility, thematic breadth,
connection to public issues, presence across communication settings, and
persistence or repetition over time. Present these as separate findings rather
than a composite score with arbitrary weights. Audience support, electoral
importance and policy influence require different evidence.

The story should move from **visibility → content → connected ideas → public
arguments → communication settings → moments and repetition**. Each section
should answer one public question with one main visual and a short interpretation.

## Starting material and what can be reused

The current release covers 2021-01-01 to 2026-09-10 and includes 2,306 publications:
2,211 name Christian democracy explicitly; 95 additional publications qualify
through Christian-social arguments without that explicit route. The routes can
overlap within the 2,211; they are not opposing or mutually exclusive ideologies.
The platform archive denominator is 41,397,670 searchable records. That is a
reference population for visibility rates, not the size of the thematic sample.

- **Public and ready:** monthly counts and denominators, text availability,
  platform totals, six overlapping public-policy domains, route counts, ten NMF
  topics and topic-by-platform-by-month tables.
- **Private and available for later reuse:** included-record identities,
  archived title/body or fallback text, qualifying windows, dictionary hits,
  stored facets, source metadata and Croatian annotations. The thematic model
  used 1,731 distinct contexts and 1,372 features. Record keys allow new analytical
  attributes to be joined without rerunning the 41-million-record search.
- **Needs further derivation:** sentence/context word associations, near-duplicate
  story families, more explicit principle-to-issue links, argument mode, checked
  speaking roles, and event interpretation.
- **Not established by these materials:** representative public opinion, a
  complete media census, comparable audience reach, causal influence, or the
  direction in which ideas travelled between platforms.

The existing ten topics are a useful descriptive starting point. Their random-start
agreement is moderate, and some components reflect repeated statements/events.
They should be checked against distinct stories before supporting larger claims.

## Analytical modules

| Module and public question | Analysis and feasible input | Main visual | Result it should support |
|---|---|---|---|
| **1. Visibility: how much attention is there?** | Reuse monthly included counts and rates per 10,000 searchable records. Keep count, relative visibility and platform composition distinct. | Annotated small-multiple timelines; a compact platform composition chart. | Where recorded attention is concentrated and when it intensifies within comparable collection periods. |
| **2. Topics: what is the conversation about?** | Use the current fixed NMF solution, inspect mixed/low-separation cases, and compare publication-weighted with story-family-weighted distributions. Keep a whole-document context sensitivity analysis separate from the qualifying-passage view. | Ranked topic bars and a topic-by-period heatmap; accessible detail cards. | Whether the topic landscape is broad or concentrated, and which patterns survive reducing repetition. |
| **3. Vocabulary: which ideas occur together?** | Build sentence/context-level lemma and phrase co-occurrences. Compare association strength with raw frequency and inspect the underlying passages privately. | A restrained word-association network, backed by a sortable pair table and selected-word neighbourhood. | Which terms connect political identity, social principles and public issues; which words bridge otherwise separate discussions. |
| **4. Principles: which parts of the tradition become visible?** | Construct a separate, multi-label concept layer using existing families first. Distinguish explicit names from paraphrased ideas; code justified links between a principle and a concrete issue. | Principle prevalence dot plot and principle-by-public-issue matrix. | Which concepts are explicitly articulated, what they are applied to, and which receive little attention in this selected material. |
| **5. Argument: what work does the reference do?** | Code identity/self-positioning, historical or intellectual explanation, concrete social/policy argument, and criticism or contestation. Keep argument mode separate from stance toward a named target. | Mode-by-topic matrix and a small set of reviewed, paraphrased analytical vignettes. | How an invocation of Christian democracy functions in a discussion, beyond merely counting the name. |
| **6. Platforms: how does the conversation differ?** | Compare within-platform topic and principle shares over matched available periods. Show sample sizes and text basis. Use a common model/codebook, not a different topic fit for each platform. | Topic-by-platform heatmap and paired bars for selected contrasts. | Differences in the content of recorded discussion across media and social platforms. |
| **7. Voices and settings: who introduces these ideas?** | Verify speaker roles in context: political, church, academic, civic, journalistic, mixed or unattributed. Separate quoted speakers, publishers and commenters. Add domestic/European/other geographical reference only where supported. | Role-by-theme matrix; a compact geographical-reference chart if enough cases are clear. | Which kinds of speakers connect the tradition to which issues, and how domestic and European frames meet. |
| **8. Moments and circulation: sustained discussion or repeated events?** | Identify attention peaks within collection periods, group near-duplicate stories, examine recurrence and cross-platform appearances, and verify event labels against the actual texts. | Event timeline, theme-composition panels around selected peaks, and publication-vs-story-family bars. | Whether apparent prominence comes from continuing discussion, a small number of events, or extensive republication. |

Modules 1, 2 and 6 can build directly on current tables. Modules 3, 4 and 8 are
the main new analytical contribution. Modules 5 and 7 depend more heavily on
contextual coding and should follow a successful pilot.

## What the concept layer should contain

Keep three analytically distinct layers, allowing overlap:

1. **Named tradition and political identity:** Christian democracy, party
   identification, conservatism, patriotism, national identity and European
   heritage. These describe observed political language; they are not all
   treated as defining principles of the tradition.
2. **Social principles:** human dignity, common good, solidarity, subsidiarity
   and participation. These are already represented in the local concept
   resources. The doctrinal grounding for the first four is the
   [Compendium of the Social Doctrine of the Church, §§160–163](https://www.vatican.va/roman_curia/pontifical_councils/justpeace/documents/rc_pc_justpeace_doc_20060526_compendio-dott-soc_en.html).
3. **Applications and extensions to assess:** work and fair wages, social
   justice, social-market economy, family and care, freedom of conscience,
   civil society, democratic institutions, European cooperation, peace and
   environmental responsibility. Several are already in the dictionaries;
   others need an explicit operational definition before counting. The
   [EPP's 2012 platform](https://www.epp.eu/files/uploads/2015/09/Platform2012_EN1.pdf)
   and [2024 manifesto](https://www.epp.eu/papers/epp-manifesto-2024) provide
   dated examples of political self-definition, not a neutral definition of
   every Christian-democratic current.

Christian social thought and Christian democracy remain related but distinct
objects. “Solidarity” or “family” alone does not establish Christian-democratic
content. The frozen inclusion rule remains unchanged; these concepts describe
already-included material. A broader search for implicit ideas outside that
selection would be a separately defined future study.

Show both explicit naming and substantive application, where the latter has
been coded from the argument. Low observed frequency must not be recast as
absence from the tradition, absence from all media, or doctrinal failure.

## Word associations: a specific design

The existing topic-model vocabulary omits shared retrieval terms and retains
only nouns, proper nouns and adjectives. It cannot answer every proposed word
question unchanged. Build a separate contextual token view that retains key
anchors, relevant verbs and negation, and preserves phrases such as *opće dobro*,
*socijalna pravda* and *socijalno tržišno gospodarstvo*.

- Count associations in the same sentence or a consistently defined short
  context. Do not link words merely because they occur in separate distant
  passages of one long article. Overlapping evidence windows must not multiply
  observations; all marginals and joint frequencies use the same analytical unit.
- Present observed joint counts alongside a frequency-adjusted association
  measure such as normalized pointwise mutual information. Call these lexical
  associations in public copy; they do not establish causal or ideological links.
- Set a minimum evidence requirement before drawing a network edge. A starting
  design is support in at least ten distinct story families, with sensitivity
  checks at five and twenty. Retain rare principles in count tables even when
  there is insufficient support for network placement.
- Check associations within major platforms and collection periods to identify
  relationships produced only by mixing very different sources or periods.
- Treat actor names separately from conceptual vocabulary. Clean URLs,
  navigation fragments and obvious boilerplate. Do not confuse a cluster named
  after a politician with a school of Christian-democratic thought.
- Use a small, stable network with labelled edges/weights and an accessible
  table. Avoid an unreadable graph of every word or a word cloud as the main
  analytical result.

## Design decisions driven by this collection

**Platform sizes.** Current counts are web 1,811; X 137; Facebook 108; print 72;
comments 56; TV 28; radio 27; Reddit 26; forums 20; YouTube 11; Instagram 8;
TikTok 2; Bluesky and Threads 0. Fine comparisons should start with web, X and
Facebook. Smaller platforms can supply descriptive counts and examples, not
elaborate independently estimated topic structures. If grouped into wider
communication settings, retain their original platform identity in drill-downs.
Proposed presentation rules: counts only below 20 cases; broad profiles with
clear denominators at 20–49; richer comparisons from 50 upward. These are display
rules, not automatic assurances of statistical precision.

**Time.** Separate periods before and after 2024-04-01. Compare platforms only
within an explicitly shared availability interval. Preserve missingness and
the partial 2026 endpoint. Event charts describe recorded attention, not changes
in public interest caused by an event. Archive capture dates cannot identify
the original speaker or the direction of diffusion.

**Repetition.** Retain the published count of 2,306 for visibility. Add a
separate analytical story-family layer for sensitivity and interpretation.
Record counts describe repetition in the media; family counts approximate the
breadth of distinct discussion. Check similarity clusters privately so that
different articles quoting one sentence are not automatically collapsed into
the same whole story. Where relevant distinguish shared-quotation families
from whole-story families. Never silently redefine the main denominator.

**Selection and circularity.** The collection was selected partly through
Christian-democratic and Christian-social vocabulary. Theme/principle shares
are conditional on that selection. Compare all included records with the A1
subset and report the additional B/C-only subset separately where useful.
Do not interpret the current predominance of A1 as evidence that implicit
Christian-social thinking is rare throughout the wider public sphere.

**Legacy facets need checking.** The present engine defaults to `supstancijski`
when identity cues are absent and defaults geographical reference to `domaće`
when no foreign/EU cue is found. Neither default is positive evidence for
substantive policy reasoning or a domestic reference. The new analytic layer
must distinguish positive evidence from unknown/unclassified cases before
using these facets as findings. Keep the frozen inclusion engine unchanged.
Existing speaker attribution is a proximity rule and requires contextual checks.

**Text and uncertainty.** Title/snippet-only records and short posts need
different expectations from long articles. Compare available-text and fuller-text
subsets; inspect uncertain topic assignments instead of treating the strongest
component as a perfect label. Any resampling should respect story families and
platform/period structure. Sampling intervals do not cover classifier error or
make this a probability sample of all media.

**Publication.** Reuse the aggregate-only contract. Original text, article URLs,
account names and row identifiers stay private. Public vignettes should be
reviewed paraphrases. Speaker-role aggregates are feasible; per-outlet topic
rankings or identifiable accounts would require changing the current public
disclosure scope. Findings and interpretations belong in the main story;
technical decisions belong in a single expandable method section.

## Execution sequence after approval

1. **Define and pilot the analytical units.** Join the existing included records,
   confirm context/text fields, propose story-family rules, and draft the concept,
   argument-mode and speaking-role codebook. Privately review a proposed 120–160
   distinct-story sample spanning topics, major platforms, periods, inclusion
   routes and uncertain cases; cover rare categories more intensively. Use it
   for development, with a separate evaluation sample if accuracy is estimated.
   Decisions to accept here: taxonomy, analytical units, and feasible modules.
2. **Produce the core story.** Topic/repetition sensitivity, lexical associations,
   principle-to-issue links and platform profiles. Deliver aggregate tables,
   four to six draft figures, and short interpretations linked to actual results.
3. **Add interpretive depth.** Proceed with modes, voices and event case studies
   where the pilot supports reliable coding. Select three or four contrasting
   event episodes from verified text, rather than labelling every spike.
4. **Integrate the narrative.** Add the results as a deeper analytical section
   within the existing barometer, with the current overview retained. Aim for
   six principal visuals, optional detail panels, a coherent written conclusion,
   downloadable aggregates, and the same keyboard/mobile/static fallbacks.

Suggested first visual package: an attention timeline; topic bars comparing
publications and story families; a focused association network; a principle–issue
matrix; a platform–theme heatmap; and three event portraits. Voices and argument
mode can replace a weaker visual if their coding proves more informative.

Each empirical statement should be reproducible from a versioned aggregate.
Reconcile counts, preserve units and denominators, inspect interpretation-changing
sensitivity results, review Croatian wording and render the page before release.
New analytical outputs should be a separate versioned release linked to the
existing manifests. Rendering continues to read aggregates without fitting
models or opening the source database.

## What is deliberately deferred

No national “Christian-democratic relevance index,” audience- or engagement-based
league table, automatic sentiment ranking of political actors, or causal claim
about elections/policy. No automatic inference that a source endorses what it
quotes. No reclassification of the entire archive or extension of inclusion
criteria as a side effect of adding richer analysis. Those questions can be
revisited if the necessary data and a separate research design become available.

## Local references

- [Current public presentation and verification](../2026-09-19_barometar-public-resource.md)
- [Count, text and collection method](../../studies/demokrscanstvo-barometar/MULTIPLATFORM.md)
- [Current contextual NLP method](../../studies/demokrscanstvo-barometar/THEMATIC.md)
- [Frozen concept families](../../resources/dictionaries/demokrscanstvo/v1/concept_families.yaml)
- [Frozen public-policy domains](../../resources/dictionaries/demokrscanstvo/v1/domain_themes.yaml)
- [Current source page](../../pages/demokrscanstvo/index.qmd)
