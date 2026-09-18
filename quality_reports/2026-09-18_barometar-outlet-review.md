# Barometer outlet and pipeline review — 2026-09-18

Review scope: R3 §§1,4,5,6,7,9, existing pre-G1 implementation, metadata readiness and denominator/panel logic. The registry and source data were not edited. No DetermDB article text, candidate classifications or per-outlet numerators were inspected. Public outlet imprints, about/contact pages and the regulator's publication register supplied the identity evidence.

## Outlet recommendations

[Machine-readable recommendations](2026-09-18_barometar-outlet-review.csv) contains all 86 reviewed domains from the unresolved candidates that passed the preliminary raw ≥20/month continuity screen. These are recommendations for registry metadata, not frozen panel membership: each inclusion still needs ≥20 **eligible**, deduplicated articles in every membership month. The final pass resolves the earlier ten outstanding cases, with the evidence limitations below retained explicitly.

The initial registry contained455 rows,100 proposed-eligible rows and353 rows with an unknown editorial or Croatia-link field. There were104 raw-continuity≥20 candidates with at least one unknown field;18 already had an explicit editorial exclusion, leaving86 substantive unresolved candidates reviewed here. No target panel size was used.

The CSV records one primary evidence URL per recommendation. Where a current imprint could not be fetched, the [Croatian AEM publication registry](https://pmu.e-mediji.hr/Forms/Common/DownloadStatic.aspx?id=1) provides publisher/location evidence, with PDF page anchors. This is identity evidence; registration alone is not an automatic inclusion rule. The CSV notes explicitly identify inference or archived evidence.

Applied distinctions:

- Specialist editorial journalism (technology, culture, music, lifestyle, gaming) is eligible when it is a news publication with an identifiable editorial operation. The brief's games-site exclusion applies to playable games/services; HCL and GoodGame have editorial news/review operations.
- Corporate ownership is not an exclusion. ADIVA and HRPortfolio are recommended excluded because their own about pages identify a pharmacy customer programme and investment transaction platform respectively, without a distinct named news newsroom established in the reviewed metadata. ADIVA has named medical expert authors; that does not by itself establish an independent editorial publication. See [ADIVA programme description](https://www.adiva.hr/adiva/o-nama/adiva-podrska-vasem-zdravlju/), [ADIVA contacts](https://www.adiva.hr/kontakti/) and [HRPortfolio about](https://hrportfolio.hr/info/o-nama).
- Municipal, county, diocesan, federation and other official institutional sites remain excluded under the explicit brief rule even if they publish notices.
- Logično identifies a BiH publisher in its [own terms](https://www.logicno.com/uvjeti-koristenja-i-privatnost). No positive Croatian editorial/audience link beyond shared language was established, so croatia_link=FALSE is an evidence-limited recommendation.
- GoodGame's Croatian link is an explicit inference from its [editorial lineage](https://www.goodgame.hr/impressum/), not a verified street address. HCL explicitly calls itself a Croatian gaming portal in its [advertising metadata](https://www.hcl.hr/oglasavanje/).
- [Novi život](https://www.novizivot.net/impressum/) is an independent Christian news publisher in Tordinci. It is a potential third confessional outlet if eligible continuity passes; the brief's expectation of only HKM/Laudato must not be hard-coded against measured eligibility.
- Segment labels are operational buckets, not judgements about individual political beliefs. Maxportal's political_portal and TRIS/SBPeriskop regional labels are review judgements.

## Final ten resolutions and evidence limits

Earlier web-tool failures were retried against the same public sites with direct HTTP metadata retrieval. No lack of an AEM entry, failed request or missing current street address was treated as proof of non-news status.

| Domain | Recommendation and supporting metadata |
|---|---|
| casopiskvaka.com.hr | Include, national. [Own imprint](https://www.casopiskvaka.com.hr/p/impresum-kvaka-casopis-za-knjizevnost.html) names Velika Gorica publisher, editors and board; [about](https://www.casopiskvaka.com.hr/p/o-casopisu-kvaka-casopis-za-knjizevnost.html) describes editorial selection, news, interviews and criticism alongside creative literature. This is specialist cultural publication inclusion, not an open self-publishing community. |
| creativabox.com | Exclude, non_news. [Own about](https://creativabox.com/about/) identifies a recipe/food community and creative ideas. Croatian link remains unknown; it is immaterial to the independently evidenced non-news exclusion. No foreign location was inferred from shared language. |
| estetica.hr | Include, national. [Current about/footer](https://estetica.hr/o-nama/) names ESTETICA PREMIUM PORTAL d.o.o., Zagreb, separate newsroom contact and interviews/columns. The earlier START DESIGN contact was stale. |
| extravagant.com.hr | Include, regional. [Own privacy](https://extravagant.com.hr/pravila-privatnosti/) identifies Škrljevo/Bakar operator; [masthead](https://extravagant.com.hr/) describes a Rijeka fashion/lifestyle/interview/video magazine. Regional label is an operational remit judgement. |
| grabancijas.com | Include, national. [Own privacy](https://grabancijas.com/privacy-policy/) identifies Epiphany Publishing Zagreb. [Editorial values](https://grabancijas.com/editorial-values-and-guidelines/) describe a journalistic operation with balanced reporting, source protection and correction obligations. Business, politics and technology are parallel sections; national avoids assigning political ideology. |
| hop.com.hr | Include, political_portal, with explicit uncertainty. [Own homepage](https://www.hop.com.hr/) identifies a news/column product, named editor Igor Drenjančević and separate Croatia/world/county-news navigation. This supports a Croatian audience inference beyond language alone; a legal publisher street address remains unverified. The segment denotes its public-affairs/column product, not ideological agreement or classification of a person. |
| jolie.hr | Include, national. [Own terms](https://jolie.hr/opci-uvjeti-koristenja/) identify ASTI Zagreb. Its [publisher anniversary metadata](https://jolie.hr/jolie-atelier/jolie-hr-slavi-velikih-10-desetljece-ljepote-autenticnosti-i-povezanosti-u-svijetu-koji-se-stalno-mijenja/) names Anita Radovčić as editor; the [launch announcement](https://jolie.hr/jolie-atelier/lansirali-smo-prvi-jolie-box-i-tiskano-jolie-izdanje-kojim-slavimo-zene-poduzetnice-i-poslovne-zene/) names her chief editor. Advertising ownership does not exclude this distinct editorial publication. |
| mojtv.hr | Include, national, **news paths only**, as detailed below. [Own imprint](https://mojtv.hr/m2/impressum.aspx) identifies Samobor publisher and editor. |
| seebiz.eu | Include, national, with historical-evidence caveat. [Current imprint](https://www.seebiz.eu/impressum/) gives its editorial team. [Archived own imprint](https://hura.hr/wp-content/uploads/2017/04/presscut_web_clanak_2659120.pdf) identifies Infoweb; [HND publishing-rights record](https://hnd.hr/iz-medija/dogovorili-se-dznap-i-izdavaci/) corroborates Infoweb/SEEbiz among contracted media publishers. Historical Croatian publishing participation plus newsroom continuity supports the link; a current street address was not established. |
| svejetu.hr | Exclude, non_news. [Own about](https://www.svejetu.hr/o-nama) names Invisit, Velika, Croatia, and explicitly describes a shopping-discount/group-buying aggregator. |

No unresolved admission recommendation remains among these 86 cases. The remaining unknown Croatian-link field for Creativabox is retained rather than invented; editorial=FALSE independently resolves its exclusion. HOP and SEEbiz are evidence-backed recommendations with the limitations above, not claims that a current legal publisher address was verified.

### MojTV news scope and aliases

The metadata-only cache sample covers 36 completed months, 2021-01 through 2023-12, in denominator signature `fb06399359c9391f126ebec679ced78c413d07100328528c973e500e8af22086`. Cache columns contain URLs, host, dates, document keys, character counts and eligibility flags, never titles or text. This was a read of completed files, not an additional source-DB scan. Counts are eligibility diagnostics, not Christian-democracy numerators.

For normalized hostname `mojtv.hr`, allow only:

- Desktop news: `^/magazin/[0-9]+/[^/]+\\.aspx$`.
- Mobile news: `/m2/magazin/clanak.aspx` with a valid integer `id` parameter after generic query normalization. Reject unrelated service or forum paths even if they have an `id`.

The sample contains 3,777 distinct desktop URL keys representing 3,772 article IDs, and 111 distinct mobile URLs/IDs. Two IDs occur in both representations, 109 only in mobile, and five IDs have multiple desktop slugs. The union is 3,881 article IDs versus 3,888 URL keys. Therefore retain both news forms and add a documented **study-local MojTV article-ID alias** after `digikat_canonicalize_url()`, preserving the generic canonical URL for audit. Do not alter the shared canonicalizer. A stable identity such as hostname plus integer article ID merges the seven observed aliases without losing the 109 mobile-only items.

Do not allow all `/m2/`: it includes 718 film records, 17 forum URLs and one each of registration, schedule and terms in the sample. Other non-news path families include `/film/`, `/serije/`, `/emisije/`, `/kanal/`, `/kino/`, `/dvd/`, `/filmografija/`, `/videoteka/`, `/arhiva/`, `/profil/` and `/forum/`. Test same-ID desktop/mobile and changed-slug deduplication, distinct IDs, invalid IDs and mobile film/schedule rejection. Recompute full eligible continuity with this scope before admitting MojTV to the panel.

The preliminary raw continuity screen is only a prioritisation aid. Registry aliases may cause another outlet to pass after aggregation. Reconcile any remaining unknown metadata against the actual eligible-continuity proposal before freezing G1. Do not silently convert unreviewed unknowns into substantive exclusions.

## Pipeline findings

1. **Verified denominator bug, reported and fixed by root during this review.** A tracking-only homepage such as `https://example.invalid/?igshid=x` passed the old non-editorial filter even though canonicalisation returned the bare homepage. The raw URL filter used a shorter tracking list and did not decode parameter names. Root reports the helper fixed and metadata scan restarted. Old helper-hash cache output should remain invalid for the new run.
2. **Registry incompleteness can silently change panel composition.** `02_panel.R:246` combines continuity with `yes(editorial)` and `yes(croatia_link)`; unknowns evaluate false. This is fine for a proposal only if unresolved candidates are visibly tracked and resolved before freeze.
3. **Monthly invariant correction.** `INDICATORS.md:8-15` correctly preserves monthly active-outlet threshold≥5 while M counts outlets with≥1 included article. Consequently monthly P_t≥M is not generally true. Ratify P≥P_t and P≥M for months, and P_t≥M only for weekly/rolling28 periods. Never discard included articles to force the inconsistent blanket inequality.
4. **Implementation coverage.** At inspection, `run.R:18-41` exposed readiness/inventory/panel only and explicitly rejected classification/sample release. Steps03–11, real route definitions, sentence/window engine, actor attribution, validation workflow, bridge and public export were still outstanding. Existing generic compiler helpers are not a completed classifier.
5. **Use the orchestrator.** `run.R:73` selects combined registry-alias candidates. Calling the metadata helper directly with defaults (`02_panel.R:62`) uses inventory candidates and can miss aliases.
6. **Future cache changes.** `02_panel.R:43` hashes helpers/canonicalisation inputs, but not all SQL in02_panel.R. A material SQL eligibility change must also invalidate/version the cache contract.

## Readiness and validation observed

Initial WORKDIR: `C:/Users/lsikic/Luka C/DigiKat_barometar_work`. Completed readiness reported data through2026-09-10,19,404,881 web rows and1961 observed days from2079 calendar days (118 masked). Input digest: `74f473e129d7a1613574b12a565374384bb28aafd8d4641c2d59ae4066e9d604`. Environment: R4.6.0, DuckDB1.5.4, stringi1.8.7/ICU74.1.

At initial inspection, no R/Rscript/DuckDB-loader process was active. Readiness, fingerprints, proposed masks and inventory artifacts existed. The old denominator signature had28 completed month pairs through2023-04, without a final manifest or panel proposal. Root subsequently restarted the corrected scan: check its process/log before starting any additional DB scan.

The synthetic `tests/barometar_denominator_tests.R` passed under project renv with explicit UTF-8 source loading and a Windows-compatible UTF-8 locale. It checks cross-month/batch/outlet canonical deduplication, title eligibility, masked-day and90% boundaries, missing-day handling, schema/calendar errors and snapshot pure logic. Startup emitted an inherited C.UTF-8 locale warning and renv out-of-sync notice; these did not fail the test. Only temporary test data were written.

After the active scan completes, apply reviewed registry metadata, rebuild the panel proposal through `run.R --stage=panel`, resolve any eligible unknowns and freeze the authorized G1 artifacts. Re-run denominator checks after any further eligibility edits. Human validation labels remain required downstream; the user's authorization does not manufacture them.
