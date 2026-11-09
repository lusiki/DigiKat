"""Generate aggregate figures, exploratory report, and private searchable directory."""
from collections import Counter, defaultdict
from datetime import datetime, timezone
import html
import importlib.metadata
import json
import math
from pathlib import Path
import sys
import textwrap
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from common import ROOT, PRIVATE, TABLES, FIGURES, read_csv, write_csv, dump_json, sha

LABELS={'christian':'Christian lexical cues','other_named_traditions':'Other named traditions',
 'yoga_meditation_development':'Yoga meditation development','humanitarian_social_support':'Humanitarian social support',
 'culture_heritage_community':'Culture heritage community','no_lexical_cue':'No cue in these dictionaries'}

def load(name): return json.loads((TABLES/name).read_text(encoding='utf-8'))
def n(value): return f'{int(value):,}'
def save(fig,name):
    fig.savefig(FIGURES/(name+'.png'),dpi=180,bbox_inches='tight',facecolor='white')
    fig.savefig(FIGURES/(name+'.svg'),bbox_inches='tight',facecolor='white'); plt.close(fig)

def main():
    audit=load('register_audit.json'); media=load('media_snapshot.json'); cand=load('candidate_audit.json')
    design=load('matching_design.json'); filter_audit=load('filter_audit.json'); enrichment=load('enrichment_audit.json')
    county=pd.read_csv(TABLES/'county_population_adjusted.csv')
    orgs=read_csv(PRIVATE/'organisation_screen.csv'); register=read_csv(PRIVATE/'register.csv')
    by_id={r['association_id']:r for r in register}
    hits=read_csv(PRIVATE/'candidate_matches.csv')
    matches=defaultdict(list)
    for r in hits: matches[r['association_id']].append(r)
    profile=load('profile_audit.json')
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.spines.top':False,'axes.spines.right':False,
                          'axes.spines.left':False,'axes.edgecolor':'#ccd3d8','axes.titleweight':'bold'})
    c=county.sort_values('associations')
    fig,axes=plt.subplots(1,2,figsize=(11,7.6),sharey=True,gridspec_kw={'width_ratios':[1.3,1]})
    y=np.arange(len(c)); axes[0].barh(y,c.associations,color='#205978'); axes[0].set_yticks(y,c.county)
    axes[0].set_xlabel('Listed associations'); axes[0].set_title('Registered seats')
    axes[1].barh(y,c.associations_per_100000,color='#478b7c'); axes[1].set_xlabel('Associations per 100,000 residents')
    axes[1].set_title('Population adjusted'); axes[1].axvline(enrichment['national_associations_per_100000'],color='#222',ls=':',lw=1)
    for i,row in enumerate(c.itertuples()):
        axes[0].text(row.associations+3,i,str(row.associations),va='center',fontsize=8)
        axes[1].text(row.associations_per_100000+.4,i,f'{row.associations_per_100000:.1f}',va='center',fontsize=8)
    axes[0].set_xlim(0,max(c.associations)*1.17); axes[1].set_xlim(0,max(c.associations_per_100000)*1.17)
    fig.suptitle('Geography of the spirituality register frame',x=.05,ha='left',fontsize=15)
    fig.text(.05,.005,'Register: 11 September 2026. Population: DZS mid-2025. Dotted line: national density. Seats are not service areas.',fontsize=8)
    fig.tight_layout(rect=(0,.02,1,.95)); save(fig,'county_geography')
    cues=pd.read_csv(TABLES/'lexical_cues.csv'); cues=cues[cues.lexical_cue!='multiple_cues'].iloc[::-1]
    fig,ax=plt.subplots(figsize=(10,4.1)); ax.barh([LABELS[x] for x in cues.lexical_cue],cues.associations,color=['#aab5bd' if x=='no_lexical_cue' else '#205978' for x in cues.lexical_cue])
    for i,v in enumerate(cues.associations): ax.text(v+6,i,str(v),va='center')
    ax.set_xlim(0,920); ax.set_xlabel('Associations with a cue in the registered name'); ax.set_title('Name cues help discovery but do not classify organisations',loc='left',pad=16)
    fig.text(.02,.015,'Cue categories overlap. No cue means the selected expressions found nothing; it does not identify a secular group.',fontsize=8)
    fig.tight_layout(rect=(0,.04,1,1)); save(fig,'lexical_cues')
    observed=cand['organisations_with_candidates']; screened=design['organisations_with_rules']; held=len(orgs)-screened; zero=screened-observed
    fig,ax=plt.subplots(figsize=(9.5,3.5)); labels=['Unvalidated candidate','Screened with no candidate','Awaiting identity rules']; vals=[observed,zero,held]
    ax.barh(labels[::-1],vals[::-1],color=['#aab5bd','#a7c3d1','#205978'])
    for i,v in enumerate(vals[::-1]):ax.text(v+5,i,str(v),va='center')
    ax.set_xlim(0,max(vals)*1.15);ax.set_xlabel('Associations');ax.set_title('Three distinct outcomes of the 2025 discovery screen',loc='left',pad=15)
    fig.tight_layout();save(fig,'retrieval_status')
    fs=pd.read_csv(TABLES/'filter_sensitivity_12days.csv').groupby('platform',as_index=False).sum(numeric_only=True)
    fs['retention_pct']=fs.retained_rows/fs.raw_rows*100
    fs['candidate_retention_pct']=np.where(fs.candidate_rows>0,fs.retained_candidate_rows/fs.candidate_rows*100,np.nan)
    fs.to_csv(TABLES/'filter_sensitivity_by_platform.csv',index=False,encoding='utf-8')
    fig,ax=plt.subplots(figsize=(10,4.5)); x=np.arange(len(fs)); ax.bar(x-.18,fs.retention_pct,.36,label='All raw records',color='#aab5bd')
    ax.bar(x+.18,fs.candidate_retention_pct,.36,label='Name candidates',color='#205978')
    for i,row in enumerate(fs.itertuples()):
        if row.candidate_rows: ax.text(i+.18,min(row.candidate_retention_pct+3,105),f'n={row.candidate_rows}',ha='center',fontsize=7)
    ax.set_xticks(x,fs.platform,rotation=35,ha='right');ax.set_ylim(0,116);ax.set_ylabel('Retained by the i filter (%)');ax.set_title('Filter retention differs across platforms and retrieval rules',loc='left',pad=15)
    ax.legend(loc='upper left',bbox_to_anchor=(0,1.0),frameon=False,ncol=2,fontsize=9)
    fig.text(.02,.01,'Fixed diagnostic: 15th of each month in 2025. Labels give candidate denominators; no label means no candidates.',fontsize=8)
    fig.tight_layout(rect=(0,.03,1,1));save(fig,'filter_sensitivity')
    monthly=pd.read_csv(TABLES/'candidate_month_platform.csv').groupby('month',as_index=False).sum(numeric_only=True)
    fig,ax=plt.subplots(figsize=(10,3.4)); ax.plot(monthly.month,monthly.candidate_unique_items,marker='o',color='#205978')
    ax.set_xticks(range(12),[f'{i:02}' for i in range(1,13)]);ax.set_xlabel('Month in 2025');ax.set_ylabel('Candidate items within platform');ax.set_title('Retrieval volume is a diagnostic, not a validated attention trend',loc='left',pad=15)
    fig.text(.02,.01,'Monthly values sum platform-specific distinct items. Cross-platform duplicates can remain; no substantive trend inference.',fontsize=8)
    fig.tight_layout(rect=(0,.04,1,1));save(fig,'candidate_months')
    coverage=pd.read_csv(TABLES/'media_coverage_2025.csv').groupby('platform',as_index=False).agg(monitored_rows=('monitored_rows','sum'),months=('month','nunique'),rows_with_search_text=('rows_with_search_text','sum'))
    coverage.sort_values('monitored_rows',ascending=False).to_csv(TABLES/'media_platform_inventory.csv',index=False,encoding='utf-8')
    strata=[]
    for s in sorted({r['sampling_stratum'] for r in orgs}):
        group=[r for r in orgs if r['sampling_stratum']==s]
        strata.append({'sampling_stratum':s,'listed':len(group),'with_candidates':sum(int(r['candidate_items'])>0 for r in group),
          'screened':sum(r['search_status']=='screened' for r in group)})
    write_csv(TABLES/'candidate_by_sampling_stratum.csv',strata)
    ordered=sorted((int(r['candidate_items']) for r in orgs),reverse=True)
    pair_total=sum(ordered); concentration={f'top_{k}_share_pct':sum(ordered[:k])/pair_total*100 for k in [1,5,10,20]}
    concentration.update(denominator='unvalidated organisation-item pairs, all 1325 rows with unresolved/unscreened rows not treated as valid zeros',organisation_item_pairs=pair_total)
    dump_json(TABLES/'candidate_concentration_diagnostic.json',concentration)
    profiles_by_id={r['association_id']:r for r in read_csv(PRIVATE/'profile_evidence.csv')}
    directory=[]
    for row in orgs:
        r=by_id[row['association_id']]; p=profiles_by_id.get(row['association_id'],{})
        directory.append({'id':row['association_id'],'name':r['name'],'county':r['county'],'locality':r['locality_candidate'],
           'status':row['visibility_status'],'candidates':int(row['candidate_items']),'months':int(row['candidate_months']),
           'stratum':r['sampling_stratum'],'orientation':p.get('orientation_proposal','Not documented'),
           'activities':p.get('activity_proposals','Not yet coded'),'profile':p.get('coding_status','Not yet coded')})
    payload=json.dumps(directory,ensure_ascii=False).replace('<','\\u003c').replace('>','\\u003e').replace('&','\\u0026')
    template='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Croatia spirituality associations directory</title><style>body{font:16px/1.5 system-ui;margin:35px auto;padding:0 24px;max-width:1250px;color:#172d3d}h1{font-size:30px;line-height:1.2}p{max-width:950px}.filters{display:flex;flex-wrap:wrap;gap:12px;margin:26px 0}input,select{font:inherit;padding:10px;border:1px solid #a5b2bd;border-radius:4px}input{min-width:260px}table{width:100%;border-collapse:collapse;font-size:14px}th,td{padding:12px;text-align:left;vertical-align:top;border-bottom:1px solid #d8e0e4}th{background:#eaf0f3;position:sticky;top:0}.muted{color:#576a78;font-size:13px}button{font:inherit;padding:8px 20px;cursor:pointer}footer{margin-top:24px}details{margin-top:5px}summary{cursor:pointer}</style>
<h1>Croatia spirituality associations directory</h1><p>Research frame of 1,325 associations listed on 11 September 2026. Search the register and inspect the 2025 discovery screen. Candidate counts are <strong>not validated media visibility</strong>. Profile codes are documentary proposals awaiting human review.</p>
<p class="muted">Registered seats are not service areas. Organisations awaiting identity rules have not been searched. Screened organisations with no candidates may have been missed. Personal contacts, addresses and media text are omitted from this view.</p>
<div class="filters"><input id="q" aria-label="Search name or locality" placeholder="Search name, ID or locality"><select id="county" aria-label="County"><option value="">All counties</option></select><select id="status" aria-label="Retrieval status"><option value="">All retrieval states</option><option value="unvalidated_candidate">Candidate found</option><option value="not_observed_under_rules">Screened without candidates</option><option value="not_yet_searched">Awaiting identity rules</option></select></div>
<p id="count" aria-live="polite"></p><table><thead><tr><th>Association</th><th>County and seat</th><th>Retrieval status</th><th>Candidate items</th><th>Months</th></tr></thead><tbody id="rows"></tbody></table><footer><button id="prev">Previous</button> <button id="next">Next</button> <span id="page"></span></footer>
<script>const data=__DATA__;let page=0;const size=40;const el=id=>document.getElementById(id);const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));const norm=s=>String(s).toLocaleLowerCase().normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').replace(/đ/g,'d');const labels={unvalidated_candidate:'Unvalidated candidate',not_observed_under_rules:'Not observed under these rules',not_yet_searched:'Awaiting identity rules'};
[...new Set(data.map(x=>x.county))].sort().forEach(c=>{let o=document.createElement('option');o.value=c;o.textContent=c;el('county').append(o)});
function render(){const q=norm(el('q').value);const rows=data.filter(r=>(!q||norm(r.name+' '+r.locality+' '+r.id).includes(q))&&(!el('county').value||r.county===el('county').value)&&(!el('status').value||r.status===el('status').value));const pages=Math.max(1,Math.ceil(rows.length/size));page=Math.min(page,pages-1);el('count').textContent=rows.length+' of '+data.length+' associations';el('rows').innerHTML=rows.slice(page*size,(page+1)*size).map(r=>'<tr><td><strong>'+esc(r.name)+'</strong><br><span class="muted">UDR ID '+esc(r.id)+'</span><details><summary>Profile notes</summary><p>'+esc(r.orientation)+'<br>'+esc(r.activities)+'<br><span class="muted">'+esc(r.profile)+'</span></p></details></td><td>'+esc(r.county)+'<br>'+esc(r.locality)+'</td><td>'+esc(labels[r.status])+'</td><td>'+(r.status==='not_yet_searched'?'Not searched':r.candidates)+'</td><td>'+(r.status==='not_yet_searched'?'Not searched':r.months)+'</td></tr>').join('');el('page').textContent='Page '+(page+1)+' of '+pages;el('prev').disabled=page===0;el('next').disabled=page>=pages-1}
['q','county','status'].forEach(id=>el(id).addEventListener('input',()=>{page=0;render()}));el('prev').onclick=()=>{page--;render()};el('next').onclick=()=>{page++;render()};render();</script></html>'''
    (PRIVATE/'directory.html').write_text(template.replace('__DATA__',payload),encoding='utf-8')
    pilot_ids={r['association_id'] for r in read_csv(PRIVATE/'pilot_60.csv')}; pilot=[r for r in orgs if r['association_id'] in pilot_ids]
    pilot_states=Counter(r['visibility_status'] for r in pilot)
    # Preserve a reviewable queue for apparent misses and unscreened pilot cases.
    write_csv(PRIVATE/'pilot_apparent_misses.csv',[{**r,'alternate_name_checked':'','official_channel_checked':'','known_2025_activity_checked':'','coder':'','finding':''} for r in pilot if not int(r['candidate_items'])])
    geography='\n'.join(f"| {r.county} | {r.associations} | {r.share_pct:.1f}% | {r.associations_per_100000:.1f} |" for r in county.itertuples())
    strata_md='\n'.join(f"| {LABELS[r['sampling_stratum']]} | {r['listed']} | {r['screened']} | {r['with_candidates']} |" for r in strata)
    total_filter=filter_audit['totals']
    dev_audit=load('development_audit_summary.json') if (TABLES/'development_audit_summary.json').exists() else {'examples':0}
    full_ids={r['association_id'] for r in hits if r['route']=='full_registered_name'}
    alias_ids={r['association_id'] for r in hits if r['route']=='curated_alias'}
    full_items={r['record_key'] for r in hits if r['route']=='full_registered_name'}
    alias_items={r['record_key'] for r in hits if r['route']=='curated_alias'}
    dump_json(TABLES/'route_diagnostic.json',{'full_name_organisations':len(full_ids),'alias_organisations':len(alias_ids),
      'alias_only_organisations':len(alias_ids-full_ids),'full_name_items':len(full_items),'alias_items':len(alias_items),
      'additional_items_from_aliases':len(alias_items-full_items),'status':'unvalidated retrieval routes'})
    cue_counts={r['lexical_cue']:int(r['associations']) for r in read_csv(TABLES/'lexical_cues.csv')}
    web_filter=fs.loc[fs.platform=='web'].iloc[0]
    top_density=county.sort_values('associations_per_100000',ascending=False).iloc[0]
    report=f'''# Croatia spirituality associations and public visibility

Exploratory report dated 19 September 2026

## What this first exploration establishes

The supplied register is a reliable starting frame for an organisational atlas: all {n(audit['pdf_rows'])} entries reconcile independently to the PDF and its {audit['county_count']} county totals, with no discrepancies in IDs, normalized names, counties or page references. The frame is substantively broad. Its administrative spirituality label includes associations whose own descriptions emphasize religious formation, Buddhist practice, yoga, social care, volunteering, publishing and cultural heritage. Activities and declared orientation need separate coding.

The national geography is already measurable. Grad Zagreb contains {int(county.loc[county.county=='Grad Zagreb','associations'].iloc[0])} associations, or {county.loc[county.county=='Grad Zagreb','share_pct'].iloc[0]:.1f}% of the list, against {county.loc[county.county=='Grad Zagreb','population_share_pct'].iloc[0]:.1f}% of the mid-2025 population. Its {top_density.associations_per_100000:.1f} registered seats per 100,000 residents also gives it the highest population-adjusted density. Headquarters and actual service areas still need distinction.

The first full-year media screen found {n(cand['unique_candidate_items'])} unique candidate items associated with {observed} registered organisations. Those are discovery results, not validated visibility. Of the {n(screened)} organisations with initial rules, {zero} had no candidate; {held} other names require stronger identity rules and have not been searched. All {n(len(orgs))} rows remain in the directory.

## Data collected and provenance

| Resource | Observed scope | Role |
|---|---:|---|
| Supplied PDF and JSON | {n(audit['pdf_rows'])} IDs and {audit['pdf_pages']} PDF pages | Closed administrative frame |
| Official population estimates | 21 counties and {n(enrichment['population_national'])} residents | Geographical denominator |
| Saved official organisation pages | {enrichment['web_pages_attempted']} pages attempted; {profile['distinct_profile_source_groups']} in-frame profile groups | Documentary enrichment |
| General merged media snapshot | {n(media['snapshot_rows'])} records | Read-only source population |
| Calendar 2025 | {n(media['rows_2025'])} records on {media['days_2025']} dates | Candidate screen |
| Unfiltered diagnostic exports | {n(total_filter['raw_rows'])} records on 12 fixed dates | Filter sensitivity |

The PDF report date is 11 September 2026. The earlier brief called this a September snapshot correctly, but its media database totals have since changed. The measured local snapshot covers {media['snapshot_start']} through {media['snapshot_end']}; the report pins this run instead of repeating earlier database totals. It does not search only the Catholic DigiKat corpus.

Raw supplied files and website HTML are retained privately with SHA-256 hashes. The large source database is identified by file size, modification time, schema, measured counts and date bounds; it was opened read-only and its file fingerprint stayed unchanged. All figures and numeric claims are generated from the study tables.

## Registered geography

![Registered counts and population adjusted density](output/figures/county_geography.png)

| County | Associations | Share of frame | Per 100,000 residents |
|---|---:|---:|---:|
{geography}

Population estimates come from [DZS STAN-2026-3-1, table 1](https://podaci.dzs.hr/2026/hr/121477), published 4 September 2026. They refer to mid-2025, whereas organisations are listed in September 2026. The national density is {enrichment['national_associations_per_100000']:.1f} per 100,000. Rates describe registered seats, not membership, local participation, current activity or service reach. Population adjustment leaves Zagreb first but changes the ordering of several other counties.

## Register completeness and organisational diversity

Only {audit['website_populated']} entries ({100*audit['website_populated']/audit['pdf_rows']:.1f}%) have a website field, and {audit['email_populated']} ({100*audit['email_populated']/audit['pdf_rows']:.1f}%) have an email field. These are field-completeness measures. Website research recovered channels absent from the list, so an empty cell cannot establish online absence. No personal email addresses were copied into the derived register CSV. Registered locality candidates could be extracted by the final-comma rule for {n(audit['locality_candidate_populated'])} entries; these are not validated geocodes.

![Overlapping lexical discovery cues](output/figures/lexical_cues.png)

The selected name dictionaries leave {cue_counts['no_lexical_cue']} associations without any cue and give {cue_counts['multiple_cues']} more than one cue. They deliberately miss many implicit and local identities. The following priority strata are only a way to organize the feasibility sample; they are not estimates of religious or organisational family prevalence.

| Sampling stratum | Listed | Screened | With candidates |
|---|---:|---:|---:|
{strata_md}

The 60-case pilot contains ten organisations per stratum and covers all {design['pilot_counties']} counties. Selected public-facing cases are purposive; the remaining slots expand county diversity with a fixed hash tie-break. The sample is not representative, and results must not be extrapolated as national percentages.

The [official-source profile notes](WEB_EVIDENCE.md) cover nine contrasting groups and {profile['register_entries_with_profile_proposals']} register entries. [Breza](https://breza.hr/o-nama/) describes social support, youth and community work without establishing a religious identity. [SKAC Palma](https://www.skac.hr/upoznaj-skac/) and [SKAC Split](https://skac.st/o-nama/) connect Catholic or Christian formation to education and volunteering. [Korablja](https://korablja-arka.hr/tko-smo/) identifies its Arka community and international network. [Padmasana](https://padmasana.hr/en/o-nama/) describes Buddhist practice and a centre outside its registered-seat city. [Zdenac](https://zdenac.org/o-nama) and the [yoga network](https://www.yoga-in-daily-life.hr/centri) show why legal entities and shared public names must be separated. [Kršćanski akademski krug](https://www.krakr.hr/index.php/o-nama/sto-je-krscanski-akademski-krug.html) and the [Hvar branch of Matica hrvatska](https://www.matica.hr/ogranci/ogranak-matice-hrvatske-u-hvaru/) illustrate intellectual and cultural activities. These are documentary proposals awaiting human review; the baseline register's unknown values are preserved.

Two Zdenac IDs print the same domain. Their legal relationship is unresolved. The Samobor Matica branch was discovered online but is absent from the supplied frame; it was not added to the population. These are useful identity checks, not reasons to silently merge or expand the register.

## What the 2025 media screen found

![Retrieval states](output/figures/retrieval_status.png)

The {n(media['rows_2025'])}-record search yielded {n(cand['raw_candidate_rows'])} raw candidate rows, {n(cand['unique_candidate_items'])} deduplicated candidate items and {n(cand['organisation_item_pairs'])} organisation-item pairs. One item may mention several organisations, and one pair may match several routes. The discovery rules use complete multiword registered names and a small set of curated aliases. {held} short or generic names are explicitly held for additional identity work. Search text is title plus body; no Catholic keyword prefilter was imposed.

In the 60-case pilot, {pilot_states['unvalidated_candidate']} organisations had a candidate, {pilot_states['not_observed_under_rules']} were screened without a candidate, and {pilot_states['not_yet_searched']} await rules. Apparent misses have their own follow-up sheet, and the candidate queue contains {cand['human_review_queue_rows']} review records. Human coding fields remain blank. The small curated alias set adds {len(alias_items-full_items)} candidate items and {len(alias_ids-full_ids)} association names beyond full-name retrieval, demonstrating the importance of alias work without establishing recall.

![Monthly retrieval diagnostic](output/figures/candidate_months.png)

The {dev_audit['examples']} purposively selected AI development readings identified substantive organisational mentions, names embedded in related-article boilerplate, generic sayings, tag lists and a false name formed by a section label next to a headline. These readings are saved separately from human coding and support no precision estimate. A full-name hit therefore does not by itself establish article relevance. Material from institutional pages and own websites also means an external domain cannot automatically count as independent reporting. Source-level affiliation and social-account verification remain pending.

Candidate attention is uneven: the ten highest candidate counts account for {concentration['top_10_share_pct']:.1f}% of organisation-item pairs. This is a retrieval diagnostic, not a supported result about public attention concentration. Name length, aliases, boilerplate, current-frame selection and unknown historical existence can all change that distribution. No substantive ranking or inferential test is reported.

## What the standalone word filter changes

The deterministic audit reread unfiltered exports for the fifteenth of every month in 2025. Of {n(total_filter['raw_rows'])} raw records, {n(total_filter['retained_rows'])} ({filter_audit['all_row_retention_pct']:.1f}%) passed the documented filter. Of {total_filter['candidate_rows']} candidate records found with the same title/body rules, {total_filter['retained_candidate_rows']} ({filter_audit['candidate_retention_pct']:.1f}%) passed; {filter_audit['candidate_rows_lost']} were removed.

![Filter sensitivity by platform](output/figures/filter_sensitivity.png)

Of {int(web_filter.candidate_rows)} web candidates in the diagnostic, {int(web_filter.retained_candidate_rows)} passed. Candidate losses occurred on {', '.join(fs.loc[fs.candidate_rows>fs.retained_candidate_rows,'platform'])}. Several platform denominators are tiny, so the chart is a diagnostic rather than a stable platform comparison. Fixed dates are not a random sample; this result cannot estimate an annual correction factor, recover dissolved organisations, measure short-alias recall, or establish the visibility of unscreened organisations. Revised raw exports may also differ from the imported merged snapshot. A broader unfiltered extraction remains preferable when testing social-platform visibility.

## Readiness for the paper

The administrative frame, geography, source provenance, reproducible discovery pipeline and feasibility sample are ready for the next stage. The evidence supports a study of a heterogeneous administrative category and the measurement of its visibility. It does not yet support a national prevalence of organisational orientations or the share of associations receiving independent news coverage.

The next work should verify the pilot's legal identity and existence in 2025; expand inflected names and contextual aliases; investigate apparent zeros; verify owned domains and social accounts; and have two people independently code held-out candidate passages. Distinguish substantial coverage from incidental mentions and boilerplate. Resolve branch/umbrella relationships before grouping records. Once these checks pass, compute validated observation, monthly persistence, independent outlet breadth and concentration, using consistent platforms and denominators. Keep organisations with zero validated observations in the atlas, with uncertainty explicit.

## Reproduction and data availability

See [README](README.md), [protocol](PROTOCOL.md), [codebook](CODEBOOK.md) and [official-source notes](WEB_EVIDENCE.md). The scripts run from the repository root. The searchable local directory, source register, candidates, official-page evidence and blank review sheets are in gitignored `output/private/`. Aggregate tables and figures contain no media rows. Restricted vendor text and personal contact fields are not redistributed. These are exploratory research outputs, not an approved public data release.

Codex assisted with extraction, code, analysis and drafting. Documentary proposals and development readings are AI-assisted; they are not independent human validation. No organisations were contacted. Core sources are the supplied register PDF and JSON; the read-only DetermDB snapshot and its local data dictionaries; the twelve unfiltered exports; DZS table 1; and the linked official organisation pages. The machine-readable provenance files identify the exact local inputs and output hashes.
'''
    (ROOT/'EXPLORATORY_REPORT.md').write_text(report,encoding='utf-8')
    # Claim inventory is regenerated, not maintained by copying numbers into prose.
    dump_json(TABLES/'report_claims.json',{'register':audit['pdf_rows'],'counties':audit['county_count'],'website_fields':audit['website_populated'],
      'media_2025':media['rows_2025'],'screened':screened,'held':held,'candidate_organisations':observed,'screened_no_candidate':zero,
      'candidate_items':cand['unique_candidate_items'],'pilot_states':dict(pilot_states),'filter_totals':total_filter,
      'candidate_top10_share_pct':concentration['top_10_share_pct']})
    print('Report, five figure pairs and private directory generated.')

if __name__=='__main__': main()
