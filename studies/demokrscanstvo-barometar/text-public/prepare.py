"""Public word-cloud tables from frozen textual analysis; never export raw texts."""
from pathlib import Path
from collections import Counter, defaultdict
import csv, hashlib, importlib.util, json, os, re

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'output/demokrscanstvo-text-public/v1'
WORK = Path(os.environ.get('DIGIKAT_BAROMETAR_WORKDIR', 'C:/Users/lsikic/Luka C/DigiKat_barometar_work'))
BASE = ROOT / 'output/demokrscanstvo-text-addendum/v1'
read = lambda p: json.loads(Path(p).read_text(encoding='utf-8-sig'))
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
def write(p, x):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(x, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
def table(p, rows):
    with p.open('w', encoding='utf-8-sig', newline='') as f:
        w=csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

def main():
    (OUT/'tables').mkdir(parents=True, exist_ok=True)
    (OUT/'internal').mkdir(exist_ok=True)
    spec=importlib.util.spec_from_file_location('analysis',ROOT/'studies/demokrscanstvo-barometar/text-addendum/analyze.py')
    a=importlib.util.module_from_spec(spec); spec.loader.exec_module(a)
    docs=read(WORK/'analytical-report-v1/grouped-documents.json')
    D={d['record_key']:d for d in docs}
    reps=[D[k] for k in read(WORK/'analytical-report-v1/representatives.json')]
    T={d['group']:d['topic'] for d in reps}
    counts=defaultdict(Counter); pos=defaultdict(Counter)
    for u in read(WORK/'text-addendum-v1/local-units.json'):
        for t in u['tokens']:
            if a.keep(t):
                counts[u['group']][a.lemma(t)]+=1
                pos[a.lemma(t)][t['upos']]+=1
    df=Counter(); topicdf=defaultdict(Counter)
    for g,c in counts.items(): df.update(c.keys()); topicdf[T[g]].update(c.keys())
    vocab=list(csv.DictReader((BASE/'vocabulary_local.csv').open(encoding='utf-8-sig')))
    assert len(counts)==2253 and all(df[r['term']]==int(r['groups']) for r in vocab)
    assert sum(sum(c.values()) for c in counts.values())==99681
    # One common editorial filter for all clouds; counts are never changed.
    stop=set('godina vrijeme dio mjesto pitanje drugi sav velik nov prvi dobar važan današnji sadašnji bivši ostali takav isti različit cijeli svoj hrvatski politički europski temeljan nacionalan suvremen daljnji siguran razvijen spreman blizak prav velik malen mnogi posljednji jedini određeni konkretan opći glavan ukupan svaki tadašnji zapravo sam dr. sc. tzv. korijena penav nauak'.split())
    # Contextual adjectives politički/hrvatski/europski/nacionalan are retained:
    stop -= {'hrvatski','politički','europski','nacionalan'}
    def eligible(t):
        return (t not in stop and not a.SELECT.match(t) and re.fullmatch(r'[a-zčćđšž]+(?:-[a-zčćđšž]+)*',t)
                and pos[t].most_common(1)[0][0] in {'NOUN','PROPN','ADJ'})
    display={s:s.title() for s in ['hrvatska','europa','plenković','tuđman','škoro','trump','vuletić','žižić','njemačka','stier','zagreb','zapad']}
    display.update({s:s.upper() for s in ['hdz','sdp','hss','hds','epp','eu','cdu','csu','hsls']})
    # First names lack an unambiguous referent in a stand-alone cloud.
    stop.update('andrej franjo ivan miroslav donald davor ivo usidriti održati takozvani'.split())
    topics=[r for r in csv.DictReader((ROOT/'output/demokrscanstvo-analysis/v1/topic_sensitivity.csv').open(encoding='utf-8-sig')) if r['scope']=='exact_text_groups' and r['topic']!='unassigned']
    ns=Counter(T.values())
    assert all(ns[r['topic']]==int(r['n']) for r in topics)
    rows=[]; clouds={}
    for key,c,n,limit in [('all',df,2253,48)]+[(r['topic'],topicdf[r['topic']],ns[r['topic']],18) for r in topics]:
        chosen=sorted(((t,k) for t,k in c.items() if eligible(t) and k>=3),key=lambda z:(-z[1],z[0]))[:limit]
        clouds[key]=[]
        for rank,(t,k) in enumerate(chosen,1):
            row={'scope':key,'rank':rank,'lemma':t,'word':display.get(t,t),'texts':k,'denominator':n,'percent':100*k/n}
            rows.append(row); clouds[key].append(row)
    table(OUT/'tables/word-clouds.csv',rows)
    table(OUT/'tables/topics.csv',[{'topic':r['topic'],'label':r['label'],'texts':int(r['n']),'denominator':2253,'percent':100*int(r['n'])/2253} for r in topics])
    phrase_specs=[('demokršćanski vrijednost','demokršćanske vrijednosti'),('desni centar','desni centar'),('demokršćanski stranka','demokršćanska stranka'),('demokršćanski načelo','demokršćanska načela'),('kršćanski demokracija','kršćanska demokracija'),('narodnjački vrijednost','narodnjačke vrijednosti'),('obiteljski vrijednost','obiteljske vrijednosti'),('demokršćanski svjetonazor','demokršćanski svjetonazor')]
    phrases=list(csv.DictReader((BASE/'phrases.csv').open(encoding='utf-8-sig')))
    pr=[]
    for lemma,label in phrase_specs:
        hits=[r for r in phrases if r['phrase']==lemma]
        assert hits and len({r['groups'] for r in hits})==1
        n=int(hits[0]['groups']); pr.append({'phrase':label,'texts':n,'denominator':2253,'percent':100*n/2253})
    table(OUT/'tables/phrases.csv',pr)
    selected=['vrijednost','stranka','hdz','načelo','domoljublje','narodnjaštvo','obitelj','solidarnost','sloboda','odgovornost','rad','gospodarstvo','savjest','dostojanstvo','supsidijarnost']
    table(OUT/'tables/selected-words.csv',[{'word':display.get(t,t),'lemma':t,'texts':df[t],'denominator':2253,'percent':100*df[t]/2253} for t in selected])
    inputs=[WORK/'analytical-report-v1/grouped-documents.json',WORK/'analytical-report-v1/representatives.json',WORK/'text-addendum-v1/local-units.json',BASE/'vocabulary_local.csv',BASE/'phrases.csv',ROOT/'output/demokrscanstvo-analysis/v1/topic_sensitivity.csv']
    write(OUT/'internal/preparation.json',{'records':len(docs),'texts':len(reps),'retained_tokens':99681,'topic_sum':sum(ns.values()),'unassigned':ns['unassigned'],'vocabulary_rows_reconciled':len(vocab),'cloud_words':len(rows),'filter_stopwords':sorted(stop),'method':'DF of original retained lemmas; majority NOUN/PROPN/ADJ; same exclusions in each cloud; original NMF topic assignments; top 48 overall and 18 per topic; minimum 3 texts; no clustering of cloud coordinates','inputs':{str(p):sha(p) for p in inputs}})
    print(json.dumps({'clouds':len(clouds),'words':len(rows),'topics':dict(ns),'top_overall':clouds['all'][:10]},ensure_ascii=False))

if __name__=='__main__':main()
