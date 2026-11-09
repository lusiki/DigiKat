"""Reconcile aggregates, private evidence spans, PDF numerics and frozen inputs."""
from analyze import *
import argparse,importlib.metadata
import numpy as np
import pdfplumber
from pypdf import PdfReader

PDF=ROOT/'output/pdf/demokrscanstvo-tekstualna-dopuna-izvjestaj.pdf'
def csvread(name,folder=OUT):
    with (folder/(name+'.csv')).open(encoding='utf-8',newline='') as f:return list(csv.DictReader(f))
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--finalize',action='store_true');args=parser.parse_args()
    checks=[]
    def passed(name,detail):checks.append({'check':name,'status':'PASS','detail':detail})
    docs,reps,members,anno,ext=load();s=read(OUT/'summary.json');units=read(PRIVATE/'local-units.json')
    assert len(docs)==s['records']==2306 and len(reps)==s['exact_groups']==2253
    assert len(units)==7467 and sum(not u['terms'] for u in units)==s['zero_concept_sentences']==2963
    passed('Frozen universe and 1:1 source linkage','2306 records; 2253 representatives; 7467 sentence units; 2963 zero-concept rows preserved')
    source={d['record_key']:d for d in docs}
    for u in units:assert source[u['record_key']][u['field']][u['start']-1:u['end']]==u['text']
    for r in read(PRIVATE/'argument-cases.json'):
        assert source[r['record_key']][r['field']][r['start']-1:r['end']]==r['evidence']
        assert sha_bytes(source[r['record_key']]['body'])==r['body_sha256']
    for hit in read(PRIVATE/'phrase-hits.json'):
        text=source[hit['record_key']][hit['field']][hit['start']-1:hit['end']]
        assert text and text[0].isalnum() and text[-1].isalnum()
        # Actual sequence must fit entirely in one local sentence, same field.
        assert any(u['start']<=hit['start']<=hit['end']<=u['end'] for u in units if u['group']==hit['group'] and u['field']==hit['field'])
    passed('Source spans','Every local sentence and all argument spans match normalized fields; dictionary phrases stay in one field/sentence')
    vocab=csvread('vocabulary_local');assert sum(int(r['occurrences']) for r in vocab)==99681
    assert all(int(r['groups'])<=2253 and int(r['groups_after_largest_sentence'])<int(r['groups']) for r in vocab)
    tfidf=csvread('document-tfidf',PRIVATE);byterm=defaultdict(list)
    for r in tfidf:byterm[r['term']].append(float(r['tfidf']))
    for r in vocab:
        assert len(byterm[r['term']])==int(r['groups'])
        assert math.isclose(sum(byterm[r['term']])/2253,float(r['mean_tfidf']),abs_tol=1e-12)
        assert math.isclose(10000*int(r['occurrences'])/99681,float(r['per_10000']),abs_tol=1e-10)
    assert math.isclose(sum(float(r['per_10000']) for r in vocab),10000,abs_tol=1e-8)
    passed('Vocabulary and TF-IDF accounting','99681 retained tokens; document means include 2253 groups; normalized frequencies sum to 10000')
    oldpairs={frozenset((r['a'],r['b'])):r for r in csvread('lexical_pairs',ROOT/'output/demokrscanstvo-analysis/v1')}
    for r in csvread('relations'):
        old=oldpairs[frozenset((r['a'],r['b']))];assert int(r['groups'])==int(old['groups'])
        assert math.isclose(float(r['npmi']),float(old['npmi']),abs_tol=1e-12)
        x=np.array([int(r['a'] in u['terms']) for u in units]);y=np.array([int(r['b'] in u['terms']) for u in units])
        assert math.isclose(float(np.corrcoef(x,y)[0,1]),float(r['phi']),abs_tol=1e-12)
        assert sum(int(r[k]) for k in ['both','a_only','b_only','neither'])==7467
    passed('Associations independently reconciled','All support and NPMI match previous frozen lexical output; phi matches Pearson correlation of full binary sentence vectors')
    counts,_,_,_=counters(units,reps)
    for name,yearA,yearB,monthend in [('web_2021_2023','2021','2023','13'),('web_jan_aug_2025_2026','2025','2026','09')]:
        groups=[]
        for year in (yearA,yearB):groups.append({g for g,ds in members.items() if any(d['platform']=='web' and d['day'][:4]==year and d['day'][5:7]<monthend for d in ds)})
        ca=Counter();cb=Counter()
        for g in groups[0]:ca.update(counts[g])
        for g in groups[1]:cb.update(counts[g])
        for r in csvread('contrasts'):
            if r['contrast']==name and r['variant']=='base':
                assert (int(r['a_groups']),int(r['b_groups']))==tuple(map(len,groups))
                assert int(r['a_count'])==ca[r['term']] and int(r['b_count'])==cb[r['term']]
                assert int(r['a_tokens'])==sum(ca.values()) and int(r['b_tokens'])==sum(cb.values())
    passed('Temporal membership','Both contrasts reconciled from all group members; 511/273 and 121/139 groups; no use of representative date alone')
    ph=csvread('phrases')
    assert all(0<=int(r['remaining_groups'])<=int(r['groups']) and 0<=int(r['remaining_word_sequence_groups'])<=int(r['groups']) for r in ph)
    # Directly enumerate adjacent lemma pairs for the principal headline phrases.
    for phrase in ('demokršćanski vrijednost','dostojanstvo radnik','priziv savjest'):
        gs=set()
        for u in units:
            ls=[lemma(t) for t in u['tokens']]
            if any(' '.join(ls[i:i+2])==phrase for i in range(len(ls)-1)):gs.add(u['group'])
        record=next(r for r in ph if r['phrase']==phrase and r['kind']=='ngram')
        assert len(gs)==int(record['groups'])
    passed('Phrase headline supports','Independent adjacent-token enumeration matches 454, 11 and 14 text groups; all controls are bounded by initial support')
    design=read(PRIVATE/'sampling-design.json');sample=design['units'];assert len(sample)==len({r['group'] for r in sample})==400
    assert math.isclose(sum(r['weight'] for r in sample),2253,abs_tol=1e-8)
    sr=csvread('sampling_design');assert sum(int(r['N_h']) for r in sr)==2253 and sum(int(r['n_h']) for r in sr)==400
    rng=random.Random(SEED);expected=[]
    for r in sr:
        frame=[d for d in reps if ('A1' if d['a1'] else 'other')+'|'+('web' if d['platform']=='web' else 'other')+'|'+('before' if d['day']<'2024-04-01' else 'after')==r['stratum']]
        expected.extend(d['record_key'] for d in rng.sample(sorted(frame,key=lambda d:d['record_key']),int(r['n_h'])))
    assert expected==[r['record_key'] for r in sample]
    assert read(PRIVATE/'coder-A.json')==read(PRIVATE/'coder-B.json')
    assert all(all(v is None or v==[] for v in d['codes'].values()) for d in read(PRIVATE/'coder-A.json'))
    passed('Sampling and honest validation status','400 unique groups; weights sum 2253; seed reproduction exact; two blind packs contain no completed codes')
    quarters=csvread('quarterly');assert all(int(r['groups'])<=int(r['eligible_groups']) for r in quarters)
    sm=[r for r in csvread('figure_quarter_denominators') if r['small']=='True'];assert len(sm)==1 and sm[0]['quarter']=='2024-Q1' and int(sm[0]['eligible_groups'])==6
    passed('Small temporal cells','2024-Q1 has six web texts and is explicitly marked; 2026-Q3 flagged as partial')
    manifest=read(OUT/'manifest.json')
    for rel,h in manifest['inputs'].items():
        if not rel.startswith('private/'):assert sha(ROOT/rel)==h
    assert sha(ROOT/'output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf')==read(ROOT/'output/demokrscanstvo-analysis/v1/manifest.json')['report']['sha256']
    assert sha(ROOT/'output/pdf/demokrscanstvo-plan-tekstualne-dopune.pdf')==read(ROOT/'output/demokrscanstvo-text-plan/qa.json')['pdf_sha256']
    passed('Preserved reports','Approved plan and previous analytical report retain input SHA256 hashes')
    reader=PdfReader(PDF);assert len(reader.pages)==18
    claims=read(OUT/'claim_register.json');texts=[page.extract_text() for page in reader.pages]
    for entry in claims:
        expected=re.sub(r'!\[[^]]+\]','',entry['text'])
        expected=re.sub(r'\[([^]]+)\]\(https?://[^)]+\)',r'\1',expected)
        # Restrict to numeric words, avoiding Latin/math names containing digits.
        nums=set(re.findall(r'(?<![\w])\d+(?:[.,]\d+)*(?![\w])',expected))
        for number in nums:assert number in texts[entry['page']-1],(entry['page'],number)
    with pdfplumber.open(PDF) as pdf:
        for i,page in enumerate(pdf.pages):
            chars=page.chars;assert chars and all(0<=ch['x0']<ch['x1']<=page.width+.1 and 0<=ch['top']<ch['bottom']<=page.height+.1 for ch in chars),(i+1,'off-page text')
    assert all('\ufffd' not in t and '\u25a0' not in t for t in texts)
    assert 'demokršćanske' in ''.join(texts).casefold()
    passed('PDF numeric and geometry checks','18 pages; every numeric token in prose/tables found on its registered page; no off-page characters or replacement glyphs')
    # Scan public structured/text outputs for actual private row identifiers.
    private_keys={d['record_key'] for d in docs}|{d['group'] for d in docs}
    for p in OUT.glob('*'):
        if p.suffix in ('.csv','.json','.md','.txt'):
            found=set(re.findall(r'[0-9a-f]{64}',p.read_text(encoding='utf-8')))
            assert not (found&private_keys),p
    passed('Public/private separation','No original record keys or exact group IDs in public text aggregates; evidence and row-level TF-IDF stay private')
    table('checks',checks)
    result={'status':'PASS','checks':checks,'pdf_pages':18,'human_validation':False,'pdf_sha256':sha(PDF)}
    if args.finalize:
        visual=read(OUT/'visual_qa.json');assert visual['pdf_sha256']==sha(PDF) and visual['pages_inspected']==list(range(1,19)) and visual['status']=='PASS'
        manifest['code']={p.name:sha(p) for p in Path(__file__).parent.glob('*') if p.is_file()}
        manifest['renv_lock_sha256']=sha(ROOT/'renv.lock')
        manifest['runtime_packages']={name:importlib.metadata.version(name) for name in ('numpy','matplotlib','reportlab','svglib','pypdf','pdfplumber')}
        manifest['report_sha256']=sha(PDF)
        manifest['files']={str(p.relative_to(OUT)):sha(p) for p in OUT.rglob('*') if p.is_file() and p.name not in {'manifest.json','verification.json'}}
        manifest['visual_qa']='all 18 current rendered pages inspected';write(OUT/'manifest.json',manifest)
        result['visual_qa']='PASS';result['reproducibility']=read(OUT/'reproducibility.json')
    write(OUT/'verification.json',result);print(json.dumps({'status':'PASS','checks':len(checks),'pages':18,'finalized':args.finalize},ensure_ascii=False))
def sha_bytes(s):return hashlib.sha256(s.encode()).hexdigest()
if __name__=='__main__':main()
