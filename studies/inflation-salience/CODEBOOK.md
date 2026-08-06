# Coding protocol — religion and the cost of living

This is the fixed codebook applied to all 1 450 candidate items in June 2026 and re-applied
unchanged in the blind re-annotation of August 2026. It is reproduced in the manuscript
appendix so that a referee can replicate the coding without access to the corpus.

An annotator sees a date, an outlet type, a headline and an excerpt of roughly 800
characters centred on the cost-of-living phrase that caused the item to be selected. No
existing label, no model output and no other annotator's decision is shown.

Four decisions are made on every item, in order. Later decisions are conditional on
earlier ones.

## 1. `infl` — is the item genuinely about the cost of living?

`1` if the item discusses actual prices, inflation, the cost of living, purchasing power,
or something becoming more expensive, in a literal economic sense.

`0` if the cost-of-living phrase is figurative or belongs to an unrelated sense. The
recurring cases are metaphorical inflation ("inflation of words", "of values", "of
superlatives", "hyperinflation of martyrs"), and cost words used for something that is not
a consumer price, such as a court cost or the cost of gambling.

A passing mention counts. The item does not have to be *about* inflation as its main
subject; it has to make a genuine reference to it.

## 2. `link` — is religion genuinely connected to the cost-of-living content?

Answered only when `infl = 1`; otherwise `0`.

`1` if the religious element and the cost-of-living element belong to the same statement.
A church raising its fees, a bishop commenting on prices, a Caritas food bank responding
to hardship, clergy salaries, the cost of a pilgrimage, parish heating bills.

`0` when the two merely appear near one another. This is the single most common error the
selection filter makes, and the reasons it makes it are known:

- **Landmark.** A religious building used as a geographic reference. "From the parish
  church towards the market where prices have risen."
- **Juxtaposition.** A news roundup or sidebar where an item about the Pope sits beside an
  item about textbook prices.
- **Secular organisation carrying a religious word.** *Crveni križ* (Red Cross),
  *Papa-test* (Pap smear), *trapist* as a cheese or a beer rather than the order.
- **Metaphor or idiom.** Religious vocabulary used figuratively about the economy.
- **Contrast.** The text explicitly says the debate has moved *away from* prices *to* a
  religious subject.

If religion and prices are in the same sentence but the connection is purely rhetorical
decoration, code `0`.

## 3. `foreign` — whose inflation is it?

Answered only when `link = 1`; otherwise `0`.

`1` if the inflation being discussed is another country's: a German bishop on child
poverty in Germany, the Pope on wage deflation in Italy, prices in Iran.

`0` if it is Croatian, or if the item is about Croatia and merely mentions a foreign
figure in passing.

The test is where the *prices* are, not where the *speaker* is. A Croatian bishop
commenting on Croatian prices is domestic. The same bishop commenting on Argentine
inflation is foreign.

## 4. `register` — in what way does religion meet the cost of living?

Answered only when `link = 1`. One label, the dominant one. This is the hardest judgement
and the one with the lowest agreement in every validation run.

| Label | The item is about |
|---|---|
| `cost_relig_life` | The price of religious goods and services rising. Mass stipends, church fees, weddings, funerals, blessings, pilgrimages, candles. The Church as a seller. |
| `institution` | Clergy, a diocese, the Pope or a parish appearing in economic news as an actor or a commentator. Church finances, clergy pay, a bishop's remarks on the economy. The Church as an economic agent or voice. |
| `charity` | Relief. Caritas, food banks, soup kitchens, aid to households in difficulty, collections for the needy. |
| `justice` | A structural or moral claim about who bears the burden. Inequality, the poor as a class, an economic system criticised, the preferential option for the poor. Naming an injustice, not describing a hardship. |
| `devotional` | Prayer, homily or devotional content that touches economic hardship without an institutional or structural claim. |
| `other` | Genuinely linked but none of the above. |
| `disputed` | Use only when two labels fit equally well and the excerpt cannot settle it. Say which two in the note. |

The distinction that matters most, and the one that most often goes wrong: **`charity`
describes a response to hardship; `justice` makes a claim about its cause.** A Caritas
report that it fed more families is `charity`. A Caritas statement that poverty is
produced by how the economy is organised is `justice`.

The second distinction that goes wrong: `cost_relig_life` and `institution` share
vocabulary, since both are full of *crkva* and *biskup*. Ask what the item is *reporting*.
If it reports a price the Church charges, it is `cost_relig_life`, even if a bishop is
quoted. If it reports the Church acting or speaking about the wider economy, it is
`institution`.

## Output

One row per item: `item, infl, link, foreign, register, note`. `register` is `none` when
`link = 0`. The note is one short clause, and is required whenever the answer was close.

---

# Protocol addendum — attention object and institutional unit (August 2026)

Applied to material already coded in June 2026; no new posts enter the pool. The addendum
adds three decisions. The first two are made only on posts the June coding placed in the
`institution` register; the third is made on every post of the measured core. The same
three-annotator majority design is used, and the annotator sees the same evidence as
before: a date, an outlet type, a headline and an excerpt centred on the cost-of-living
phrase, with no existing label shown. The June register is disclosed to the annotator only
to the extent implied by which sheet the item is on.

## 5. `object` — what economic subject does the institution's appearance concern?

The question this decides: when the institution appears in cost-of-living coverage, is it
attending to *its own* economic position or to *other people's* hardship? Coded only on
`institution`-register posts.

| Label | The economic content concerns |
|---|---|
| `own` | The institution's own economic position. Its costs — heating, energy, salaries, maintenance, insurance, building repair. Its revenues — collections, donations, fees failing to cover costs. Its finances, budgets, property, investments, or the pay of clergy and staff. |
| `household` | The cost of living as the burden of others. Households, families, pensioners, the poor. Pastoral or public concern about hardship that is not the institution's own. |
| `both` | Both subjects present with comparable weight, for example a bishop who describes parish heating bills and household hardship in one statement. |
| `other` | Neither. The institution appears in economic coverage without either subject — a ceremonial appearance at an economic event, a general remark on the economy with no cost content of either kind. |

The test is the *object of the economic content*, not who speaks. A journalist's report on
diocesan finances is `own`; a bishop's homily on family poverty is `household`.

## 6. `voice` — does the sector itself speak?

Coded on the same posts as `object`. `sector` if the post carries a direct statement by a
sector actor — a quotation, an interview, a homily, an official statement or press
release. `outside` if the sector is written about and no sector actor speaks in the post.

Together with `object`, this separates the readings the analysis must distinguish: an
institution *saying* that its own costs have risen (`own` + `sector`) is direct evidence
that the institution attended to its own position; an outsider writing about church
finances (`own` + `outside`) is not.

## 7. `unit` — which institutional unit acts or speaks?

Coded on every post of the measured core. The unit is the one that performs the economic
action the post reports: for a price change, the unit that set the price; for a statement,
the unit whose actor speaks; for relief, the body that provides it. One label, the
dominant one.

| Label | Unit |
|---|---|
| `parish` | A parish, its priest, or a parish church acting as such. |
| `diocese` | A diocese or archdiocese, its bishop or archbishop, its chancery or curia. |
| `order` | A religious order, monastery or its members acting as such. |
| `caritas` | Caritas at any level, or another church relief body. |
| `conference` | The bishops' conference as a body. |
| `vatican` | The Pope, the Holy See, or a Vatican office. |
| `church` | The Church in general, with no specific unit identifiable. |
| `none` | No church unit is the actor — for example, lay commentary about religion and prices. |

`unit_name` is a free-text field: the specific named unit when the post names one, spelled
as the post spells it ("Zagrebačka nadbiskupija", "župa sv. Ante"). It is used only for
the matched-pair analysis and never leaves `output/private/`.

## Output

One row per item. Object sheet: `item, object, voice, unit, unit_name, note`. Unit sheet:
`item, unit, unit_name, note`. `unit_name` is empty when no unit is named. The note is one
short clause, required whenever the answer was close.
