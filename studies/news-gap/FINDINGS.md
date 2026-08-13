# The News Gap, Catholic edition: provisional findings

## Status

The numerical analysis is complete and reproducible. The findings remain exploratory because the blinded topic-validation protocol has not yet passed. The canonical dictionary classifies 99.9% of posts, but manual spot checks found face-validity errors from broad terms. By PI decision on 13 August 2026, the six product profiles may nevertheless appear in `Moj medij` as a provisional editorial diagnostic. They must not be presented as human-validated rankings or direct audience-preference measures.

## Main descriptive result

The field result gives each of six editorial products equal weight after pooling seven complete 2025 months within product. A positive gap means the topic received a larger share of recorded interactions than of published posts.

| Topic | Published | Recorded interaction share | Gap | Robustness range |
|---|---:|---:|---:|---:|
| Duhovnost i liturgija | 49.00% | 54.15% | +5.15 pp | +3.07 to +5.82 pp |
| Crkveno upravljanje i struktura | 22.84% | 17.96% | -4.88 pp | -5.18 to -1.57 pp |
| Mediji, umjetnost i kultura | 2.27% | 0.85% | -1.43 pp | -1.37 to -1.18 pp |

The ranges cover the reported sensitivity checks: 99th-percentile winsorization, removal of the most-interacted post in each product-month, and full-text classification. These are the only field-level directions stable enough to foreground provisionally. A superficially large multiplier for “Odnos s drugim religijama i pogledima” is not robust to influential-post checks and should not be promoted.

This is a difference in the composition of recorded interactions, not direct evidence of audience demand, preferences, satisfaction, or editorial quality.

## Does supply chase the previous month's premium?

No detectable relationship appears in the current panel. The fixed-effects estimate is -0.025 percentage points of next-month production share for a one-point current engagement gap (95% time-HAC interval -0.112 to +0.063; p = 0.527; 304 product-topic-month transitions across eight current months). The 999-replication whole-month bootstrap interval is -0.093 to +0.102.

Robustness estimates change sign and every interval includes zero. The defensible conclusion is “no evidence of next-month chasing in these data,” not “Catholic outlets do not respond to engagement.” The short time series makes this an exploratory associational test.

## Papal-transition question

The proposed before/during-event contrast is not estimable. Primary-source collection is nearly absent from 29 March to 10 April and from 28 April to 10 May 2025, including the conclave and election of Leo XIV. The weekly series is shown only to make the missingness visible; it cannot support a claim that the gap narrowed or widened around the transition.

## Product interpretation

The output includes descriptive six-product profiles, but they are validation leads rather than rankings. Recorded engagement is highly uneven: the top ten posts account for 14% to 45% of interactions depending on product, while zero-interaction rates range from 4% to 85%. Several named product-topic gaps shrink sharply when influential posts are removed or winsorized. No outlet-specific sales claim should be made before validation and a measurement review with that outlet.

## Decision

- Suitable now: research audit, validation planning, and the provisional `Moj medij` outlet profiles authorised by the PI.
- Not suitable yet: annual-report headline, public paper result, validated outlet ranking, or paid diagnostic.
- Next gate: complete the blinded coder sheet and high-interaction audit under `VALIDATION_PROTOCOL.md`, revise only study-specific matching rules when required, and rerun the complete pipeline.

The numerical authority is `output/analysis_results.json`; machine-readable tables, figures, and a hash manifest are in `output/`.
