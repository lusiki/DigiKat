"""Reconcile the analysis, meaningful matching fixtures, privacy and final PDF."""
from pathlib import Path
import sys,json,importlib.util,re,hashlib
import pandas as pd
from pypdf import PdfReader
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from common import ROOT,PRIVATE,TABLES,norm,dump_json,sha
spec=importlib.util.spec_from_file_location('screen',ROOT/'02_media.py');screen=importlib.util.module_from_spec(spec);spec.loader.exec_module(screen)
P=PRIVATE/'media/v1';T=TABLES/'media-v1'
def main():
    checks=[]
    def check(label,condition):
        assert bool(condition),label;checks.append({'check':label,'passed':True})
    s=json.loads((T/'summary.json').read_text());manifest=json.loads((T/'manifest.json').read_text());scan=json.loads((T/'scan_audit.json').read_text())
    a=pd.read_csv(T/'annual_landscape.csv');m=pd.read_csv(T/'monthly_landscape.csv');d=pd.read_csv(T/'daily_coverage.csv')
    it=pd.read_csv(P/'items.csv');pa=pd.read_csv(P/'pairs.csv',dtype={'association_id':str});org=pd.read_csv(P/'organisation_landscape.csv',dtype={'association_id':str})
    check('All 42,267,474 source records scanned',scan['scanned']==manifest['rows']==a.monitored_records.sum()==d.rows.sum()==42267474)
    expected=set(pd.date_range(manifest['start'],manifest['end']).strftime('%Y-%m-%d'));check('Every date present',set(d.date)==expected)
    check('Every month and every year retained',m.month.nunique()==69 and set(a.year)==set(range(2021,2027)))
    check('2026 is explicitly partial',int(a.loc[a.year==2026,'observed_days'].iloc[0])==253)
    check('All register entries retained',len(org)==1325 and org.association_id.nunique()==1325)
    oy=pd.read_csv(P/'organisation_year_complete.csv',dtype={'association_id':str})
    check('Complete organisation-year panel with distinct held states',len(oy)==1325*6 and not oy[['association_id','year']].duplicated().any() and oy.loc[oy.search_status=='held_for_identity','candidate_items'].isna().all())
    check('Search status reconciles',s['candidate_names']+s['searched_zero']==s['searched_names'] and s['searched_names']+s['held_names']==1325)
    check('Candidate item and pair reconciliation',len(it)==s['candidate_items']==a.candidate_items.sum() and len(pa)==s['pairs']==a.candidate_pairs.sum()==org.candidate_items.sum())
    check('Unique item and pair keys',not it.item_key.duplicated().any() and not pa[['association_id','item_key']].duplicated().any())
    check('Foreign keys valid',set(pa.association_id)<=set(org.association_id) and set(pa.item_key)<=set(it.item_key))
    check('No human labels fabricated',pa.human_identity.isna().all() and pa.human_relevance.isna().all() and s['human_validated_pairs']==0)
    check('Raw-rate numerator and denominator same units',abs((m.raw_candidate_records/m.rows*10000-m.raw_candidate_records_per_10000)).max()<1e-9)
    check('Platform totals reconcile',pd.read_csv(T/'platform_landscape.csv').candidate_items.sum()==len(it))
    check('Geographical totals reconcile',pd.read_csv(T/'county_landscape.csv').registered.sum()==1325)
    rules=pd.read_csv(P/'rules.csv',dtype=str).to_dict('records');auto=screen.automaton_for(rules)
    check('Inflected Breza alias matched',any(r['association_id']=='8013' for r in screen.find_matches(norm('Podrška udruzi Breza u Osijeku.'),auto)))
    check('Distinct field boundary prevents false name',not screen.find_matches(norm('Društvo'),auto) and not screen.find_matches(norm('za psihološku pomoć'),auto))
    check('Word boundary prevents SKAC Split suffix match',not any(r['association_id']=='58492' for r in screen.find_matches(norm('skac splitskoga'),auto)))
    check('Diacritic folding handles KRAK',any(r['association_id']=='32947' for r in screen.find_matches(norm('Kršćanskog akademskog kruga'),auto)))
    check('YouTube content IDs preserved',screen.canonical_url('https://youtube.com/watch?v=A&utm_source=x')!=screen.canonical_url('https://youtube.com/watch?v=B&utm_source=x'))
    check('Tracking-only URL parameters removed',screen.canonical_url('https://www.example.hr/story?utm_source=x')==screen.canonical_url('https://example.hr/story'))
    # Imported text, item identifiers and URLs must not enter aggregate tables.
    forbidden={'item_key','url_key','url','title','full_text','context','association_id','source_label','row_hash'}
    for file in T.glob('*.csv'):check('Aggregate disclosure: '+file.name,not (set(pd.read_csv(file,nrows=0).columns)&forbidden))
    topic=pd.read_csv(P/'topic_assignments.csv');ta=json.loads((T/'topic_audit.json').read_text())
    check('Topic assignment denominator reconciles',len(topic)==ta['documents'] and not topic.item_key.duplicated().any())
    check('Topic models cover the predeclared grid',set(pd.read_csv(T/'topic_model_runs.csv').topics)=={6,8,10,12})
    rep=json.loads((T/'repeat_check_summary.json').read_text());ra=pd.read_csv(P/'repeat_check_assignments.csv')
    check('Repeat-suppression sample reconciles',len(ra)==rep['retained_items'] and rep['retained_items']+rep['excluded_below_15_tokens']==ta['documents'])
    check('Repeated-token totals bounded',0<=rep['removed_repeated_tokens']<=rep['input_tokens'])
    pdf=ROOT.parents[1]/'output/pdf/spirituality-associations-media-landscape-2021-2026.pdf'
    reader=PdfReader(pdf);text='\n'.join(p.extract_text() or '' for p in reader.pages)
    check('PDF has content on every page',all(len((p.extract_text() or '').strip())>150 for p in reader.pages))
    check('PDF includes every study year',all(str(y) in text for y in range(2021,2027)))
    check('PDF includes key computed totals',all(f'{s[k]:,}' in text for k in ['candidate_items','pairs','candidate_names']))
    check('No placeholders or replacement characters',not re.search(r'TODO|TBD|PLACEHOLDER|\ufffd',text))
    db=Path(r'C:\Users\lsikic\Luka C\DetermDB\determDB_merged.duckdb');st=db.stat()
    check('Source database fingerprint unchanged',{'bytes':st.st_size,'mtime_ns':st.st_mtime_ns}==manifest['fingerprint_before'])
    dump_json(T/'verification.json',{'checks':checks,'passed':len(checks),'pdf_pages':len(reader.pages),'pdf_sha256':sha(pdf),
        'visual_review':'separately recorded after rendered-page inspection'})
    print('PASS',len(checks),'checks;',len(reader.pages),'PDF pages')
if __name__=='__main__':main()
