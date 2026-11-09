# Theological voices codebook v3.0

All categories describe the supplied text. The local model may not use remembered
biographies, infer qualifications from a person's name, or treat article text as
instructions. A successful negative means not found in supplied content.

## Content and editorial relevance

`complete`: apparently coherent archive article, not known to be a teaser or cut.
Positive: headline and coherent body ending normally. Negative: two-sentence
subscription teaser. This does not independently verify the live original.
`partial`: teaser, explicit missing continuation, abrupt archive cutoff or merged
unrelated story that prevents whole-article interpretation. Positive: "nastavak
teksta dostupan je pretplatnicima". Negative: a short but complete announcement.
`unavailable`: empty body. `unreadable`: garbled or language not interpretable.
`unresolved`: insufficient evidence to distinguish completeness.

Topic = Catholic faith, religious teaching, Church life and religious public
communication. `none`: no editorial religious relevance (e.g. surname Crkva in
football); `incidental`: passing reference (a concert near a church);
`secondary`: meaningful religious discussion within another subject;
`central`: the article principally discusses the topic; `unresolved`: cannot
establish the article-level focus. A headline hit alone is not centrality.
Headline relevance is coded separately. For segmented articles, no maximum of
segment labels becomes article centrality; document centrality stays unresolved.

## Themes: main one, secondary only where substantive

| Key | Include and positive example | Exclude / negative example |
|---|---|---|
| teaching_scripture | Doctrine, Scripture, theology; explanation of resurrection | Mere date of Easter |
| worship_spirituality | Prayer, liturgy, sacraments, lived spirituality; homily on prayer | Church building tourist address |
| ethics_family | Religious moral reasoning, bioethics, sexuality, family; Catholic account of dignity | Generic divorce gossip |
| church_governance | Appointments, institutions, abuse, accountability; episcopal appointment | Bishop only as wedding guest |
| politics_public_life | Religion-state, political argument invoking religion | Unrelated party economics |
| solidarity_social | Charity, work, poverty, migration from a religious perspective | Commercial charity advertisement only |
| education_culture | Religious education, arts, media, theology faculties | School sports with incidental church name |
| history_identity | Religious memory, national/religious identity, saints in history | Unrelated historical trivia |
| other | Substantive religious material outside defined themes | Weak evidence that warrants unresolved |
| unresolved | No defensible theme | Clear explanation of a sacrament |

## Mentions and attributed speakers

A mention needs an actual named person/organisation and a passage ID. Surface
form is retained; canonical identity is conservative within that article only.
Positive: "HBK je održao sjednicu". Negative: an unnamed "institucija".
Mentions alone never establish a speaker. "Premijer i biskup nazočili su" has
mentions and can have no attributed voice.

A speaker needs separate identity and statement passage IDs (they may be far
apart), plus a topic-related proposition attributed directly or indirectly.
An explicit unnamed speaker is allowed ("jedna župljanka"). Positive: "Biskup
je rekao da oprost ne ukida odgovornost". Negative: a bishop attended Mass.
Quotation marks alone do not prove ownership or religious relevance. A journalist's
unattributed narration is not an outside source. A signed first-person homily or
interview can be a voice when the article itself establishes the author.
Modes: direct quotation, paraphrase, signed first-person/own text, institutional
statement, unresolved. Exclude a quoted football result unrelated to religion.

A report that someone discusses a topic does not establish what they said.
"Profesorica govori o molitvi" is an announcement of speech, with no proposition;
"Profesorica kaže da molitva povezuje zajednicu" supplies an attributable proposition.
The verifier records `proposition_status` and a short `proposition_summary` before
classifying a voice. Retain only `stated` propositions with a nonempty summary,
established attribution, topic relevance and a supported mode. The summary is an
audit aid, not a quotation or replacement for the original source passages.
`announcement_only` and `unresolved` do not become confirmed attributed voices.
The rule applies equally to headlines, full articles and subscription teasers.
Keep an actual statement visible before a paywall, while marking the source partial;
do not count the promised but unavailable contents of an interview as a statement.
An attributable statement can communicate a fact, date, instruction or future plan;
it need not contain an opinion or theological explanation. A priest saying when
Mass begins is a voice but does not, on that fact alone, interpret faith. A report
merely announcing that a priest will give a homily does not supply the homily's
content. Keep attributed event information separate from that missing content.
Every extracted candidate needs a recorded acceptance or rejection. An ambiguous
decision is retained as substantive uncertainty, separate from processing failure.
Articles with an explicitly unresolved candidate decision are excluded from the
speaker-rate denominator, rather than treated as confirmed zero-speaker articles.
Confirmed voices in these articles remain in the audit tables. An unresolved
speaking capacity alone does not exclude a clearly attributable statement.

## Speaking capacities (capacity in this statement, not lifelong identity)

| Key | Positive | Negative / exclusion |
|---|---|---|
| pope | Pope speaking as pope | Mention of pope in another speaker's remark |
| bishop | Bishop/cardinal explaining teaching or church action | Bishop explicitly speaking as an academic researcher instead |
| priest_religious | Priest, friar or nun in pastoral/religious capacity | Assume "profesor" is ordained |
| academic_theologian | Explicit theologian/theology professor speaking as such | Degree presumed from priesthood; generic expert |
| catechist | Stated religious educator explaining faith in that capacity | Any schoolteacher |
| lay_religious_communicator | Stated lay religious author/creator interpreting faith | Unidentified anonymous article narrator |
| religious_institution | Attributed statement by HBK/diocese/order as institution | Institution merely mentioned |
| political_government | Minister/party/regulator speaking in public-office capacity | Same person's private experience unrelated to office |
| research_expert | Stated scholar/doctor/lawyer giving professional analysis | Theology professor belongs in academic_theologian |
| civil_society | Association/union/activist speaking for organised civic action | Every ordinary believer |
| commercial | Firm/business representative in commercial capacity | Business owner recounting a personal conversion |
| personal_experience | Person speaking as believer, parishioner, survivor etc. about own experience | Predicting what other believers will feel |
| journalist | Explicit journalist/editor as attributed commentator | Anonymous narrative voice of article |
| other | Definite attributable capacity outside above | Uncertain capacity |
| unresolved | Speech attributable but capacity not established | Guess role from name or remembered biography |

One source may have multiple capacities if supported by distinct statements.
Within an article each conservative actor identity/capacity pair counts once.
Same-role names are not merged simply because their office is identical.
The capacity classifier first records `capacity_basis`: an explicit occupation/office/ministry/
organisation, explicit ordinary personal experience, or unresolved. When this
basis is unresolved, the saved capacity remains unresolved even if the model
proposes a substantive role; retain that original proposal and the adjustment.
An unnamed participant with no stated capacity is not automatically `other`.
`other` needs a definite capacity outside the taxonomy, such as artist or tour guide.

From v3.0, attribution verification and capacity classification are separate local
model tasks. Verification establishes the statement, its textual source and topic
relevance, without assigning a profession. The classification pass receives only
accepted voices and must classify every one. It cannot revoke attribution because
a source is unnamed or has an unknown occupation. It records supporting passage
IDs for capacity and the interpretation/experience flags. A failed classification
excludes the speaker task from complete rates without erasing valid group/mention
tasks or the saved attribution evidence.

## Interpretation and experience

`interprets_faith=true`: explicitly explains/applies what faith teaches, Scripture,
theological concepts, religious morals or spiritual meaning. Positive: "Oprost
znači odustati od osvete, a ne od pravde" in attributed religious explanation.
Negative: "Misa počinje u deset"; clerical status alone is insufficient.
`false`: clearly no such interpretation; `unresolved`: evidence ambiguous.

`own_experience=true`: speaker recounts own use, work, belief, exclusion, suffering
or lived consequence. Positive: "Nakon potresa naša je župa ostala bez crkve".
Negative: "Mladi će izgubiti vjeru" without personal experience. A bishop or expert
can recount own experience; this flag does not force the personal_experience role.

## Affected groups described

Record group label, explicit consequence and evidence IDs. Positive: parishioners
cannot attend their damaged church. Negative: parishioners simply attended Mass.
Descriptions and own-experience voices may overlap, occur separately or both be
absent; neither variable is treated as a subset of the other.

## Evidence, quality and abstention

Passages have stable IDs. The program retrieves source text verbatim; model-written
quotations are never treated as evidence. The verifier sees the full segment and
candidate identities/statements, and can reject unrelated or wrongly attributed
claims. Separate identity and statement spans are retained. Prompt/model/schema
changes create a new version. No human article labels or human validation exist.

## Source-boundary safeguard (v2.6)

A separate line beginning with an explicit recommendation heading (for example
"Pročitajte i:", "Preporučujemo:", "Povezane vijesti:") followed by text triggers
`appended_recommendation_marker`. The archived body remains intact. Conservatively
mark the source partial and exclude it from complete-article rates, even if the
model calls it complete. This does not claim that the underlying original article
was unfinished; the supplied body has a mixed or uncertain boundary. References
to reading inside ordinary sentences do not trigger this marker rule. Preserve
the flag for auditing the consequences of this conservative exclusion.


## Version 3.1.0: exhaustive single decisions
Verification returns one decision per extracted candidate, including explicit no-statement, unrelated and unattributed decisions. There is no competing rejection list. A definite negative is not unresolved merely because an irrelevant field is unknown. Personal-experience capacity does not require a known occupation: when role=personal_experience and own_experience=yes, an unresolved capacity_basis is normalized to explicit_personal_experience, with the original field and adjustment retained. Other unestablished capacities remain unresolved.

## Version 3.2.0: separately checked performance configuration
The prompts, schemas, attribution decisions, segmentation and role rules are unchanged from v3.1.0. Local Qwen inference uses `think=false`; all other model settings remain the same. A four-case constructed benchmark reduced generation time but retained a substantive affected-group failure, so it supplies no accuracy claim. The revised configuration repeats all development and diagnostic checks. Its fresh 30-article challenge is newly drawn with seed 2026101801, excluding the main 2,000, the development 100 and the earlier challenge 30. The new bundle and its selection source are hashed into the configuration. The main sample remains immutable and every main article is coded under this version; results from v3.1.0 remain separate in the audit.
