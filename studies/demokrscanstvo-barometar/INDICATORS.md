# Indicator contract

No values are computed before the panel and definition freezes. Symbols below are specifications.

- N: eligible canonical articles in the frozen panel during the period.
- D: articles in the deduplicated union of accepted routes for the scope.
- P: frozen panel size.
- P_t: outlets with at least one eligible article (week/rolling28), or five (month).
- M: outlets with at least one included article in the period/scope.
- Medijska zastupljenost: 10,000 D/N, with unit “na 10.000 analiziranih članaka”.
- Širina prisutnosti: 100 M/P, with counts “M od P medija”; null if P_t/P <0.90.

Monthly P_t and M use different activity thresholds. The proposed corrected invariant at G1 is
P>=P_t and P>=M; P_t>=M also holds for weekly/rolling28 periods. Never silently discard an included
article to force the invalid blanket monthly inequality in the original brief.

Broad scope: accepted A1 union B union C. Narrow scope: accepted A1. Party labels A2 and unresolved
A? are outside both. Route D is diagnostic only. Counts, rates and scopes are not party support,
audience reach, author belief, outlet ideology or doctrinal correctness.

The six policy-domain rows plus Nerazvrstano can overlap. Principles are a separate facet, not
theme rows. Export composition and the four sensitivity variants specified by the brief.

The monthly headline uses the latest month with both indicators published. Weekly headlines use
the published 28-day window anchored to the headline week's end, with its own counts. Any weekly
change compares distinct raw weeks and names that interval. Never use the article-rate binomial
test on overlapping rolling windows. Missing, partial and true zero are separate states.

The exact status truth table, comparison rules, domain vocabulary, 80-token evidence window and
route definition are frozen at G2. The seam at 2024-04-01 always breaks drawn lines. Cross-seam
comparability requires the final June 2024 bridge and the PI's G3 decision.

Per-route human precision >=0.80 permits a route in the headline; 0.60–<0.80 is experimental;
<0.60 is dropped. The weighted broad union must also pass and human qualifies kappa must be >=0.70.
A failed broad scope falls back to passing A1; failed A1 means no empirical public release.
