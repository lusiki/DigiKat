"""Freeze frame, diagnostics and disjoint samples. No model inference here."""
from __future__ import annotations
import hashlib, html, json, re, shutil, sys
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode
import numpy as np
import pandas as pd

STUDY = Path(__file__).resolve().parent
OUT = STUDY / 'output' / 'private'
CFG = json.loads((STUDY / 'assignment.json').read_text(encoding='utf-8'))

def sha(s):
    return hashlib.sha256(str(s).encode('utf-8')).hexdigest()

def file_sha(p):
    h = hashlib.sha256()
    with open(p,'rb') as f:
        for b in iter(lambda:f.read(1024*1024), b''): h.update(b)
    return h.hexdigest()

def save_json(p, x):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(x, ensure_ascii=False, indent=2, default=str), encoding='utf-8')

def canonical_url(s):
    s=s.strip()
    if not s: return ''
    try:
        u=urlsplit(s)
        query=[(k,v) for k,v in parse_qsl(u.query,keep_blank_values=True)
               if not k.lower().startswith('utm_') and k.lower() not in {'fbclid','gclid'}]
        return urlunsplit((u.scheme.lower(),u.netloc.lower(),u.path,urlencode(query),''))
    except ValueError: return s

def clean(s):
    # Preserve the text, including suspected boilerplate. Only normalize encoding/whitespace.
    return html.unescape(s).replace('\r\n','\n').replace('\r','\n').replace('\x00','').strip()

def proportional(df, n, rng):
    counts=df.groupby('stratum').size().sort_index()
    n=min(n,len(df)); quota=counts*n/len(df)
    alloc=np.floor(quota).astype(int)
    for k in (quota-alloc).sort_values(ascending=False,kind='stable').index[:n-int(alloc.sum())]: alloc[k]+=1
    pieces=[]
    for k,N in counts.items():
        nh=int(alloc[k])
        if nh == 0: continue
        ix=rng.choice(df.index[df.stratum==k],size=nh,replace=False)
        p=df.loc[ix].copy(); p['N_h']=int(N); p['n_h']=nh
        p['inclusion_probability']=nh/int(N); p['sampling_weight']=int(N)/nh
        pieces.append(p)
    s=pd.concat(pieces,ignore_index=True)
    s['selection_order']=np.arange(1,len(s)+1)
    return s, pd.DataFrame({'stratum':counts.index,'N_h':counts.values,'n_h':alloc.values})

def main():
    if (OUT/'freeze.json').exists():
        raise SystemExit('Frame already frozen. Reuse it; a changed preparation requires a separate run.')
    OUT.mkdir(parents=True,exist_ok=True)
    d=pd.read_csv(OUT/'source_web.csv.gz',dtype=str,keep_default_na=False)
    d['outlet_id']=d.outlet_name.str.strip().str.casefold().map(lambda x:sha(x)[:16])
    d['canonical_url']=d.url.map(canonical_url)
    d['body_clean']=d.body_raw.map(clean)
    d['text_hash']=d.body_clean.map(sha)
    d['text_length']=d.body_clean.str.len()
    d['body_utf8_bytes']=d.body_clean.str.encode('utf-8').str.len()
    d['dedup_key']=[f'{o}|{u}|{date}' if u else f'{o}|{date}|{t}|{h}'
                    for o,u,date,t,h in zip(d.outlet_id,d.canonical_url,d.published_at,d.title,d.text_hash)]
    d['publication_id']=d.dedup_key.map(lambda x:'P'+sha(x)[:20])
    chosen=d.sort_values(['text_length','record_id'],ascending=[False,True],kind='stable').drop_duplicates('publication_id')
    retained=chosen.set_index('publication_id').record_id
    cross=d[['record_id','master_row','publication_id']].copy()
    cross['retained_record_id']=cross.publication_id.map(retained)
    cross['removed_export_duplicate']=cross.record_id != cross.retained_record_id
    cross.to_csv(OUT/'export_publication_crosswalk.csv',index=False,encoding='utf-8-sig')
    d=chosen.sort_values('record_id').reset_index(drop=True)
    d['content_status']=np.select([d.text_length==0,d.text_length<400,d.text_length>=31950],
                                  ['missing_text','short_source','possible_archive_truncation'],default='available_unverified')
    d['month']=d.published_at.str[:7]
    d['stratum']=pd.to_datetime(d.published_at).dt.to_period('Q').astype(str)
    d['input_hash']=[sha(json.dumps([t,b],ensure_ascii=False)) for t,b in zip(d.title,d.body_clean)]
    d['cleaning_removed_chars']=d.body_raw.str.len()-d.text_length
    d['exact_text_family']=np.where(d.text_length>=400,d.text_hash,'')
    d.to_parquet(OUT/'frame.parquet',index=False,compression='zstd')
    no_text=d.drop(columns=['body_raw','body_clean','dedup_key'])
    no_text.to_csv(OUT/'frame_manifest.csv.gz',index=False,compression='gzip')
    tables=OUT/'tables'; tables.mkdir(exist_ok=True)
    d.groupby('month').agg(publications=('publication_id','size'),outlets=('outlet_id','nunique'),
                          text_chars_median=('text_length','median')).reindex(
                          pd.period_range(CFG['period_start'],CFG['period_end'],freq='M').astype(str)).fillna(0).to_csv(tables/'frame_month.csv')
    d.groupby(['outlet_id','outlet_name']).agg(publications=('publication_id','size'),first=('published_at','min'),
                          last=('published_at','max'),text_chars_median=('text_length','median')).sort_values('publications',ascending=False).to_csv(tables/'frame_source.csv')
    for col in ['language','location','content_status','collection_era']:
        d.groupby(col,dropna=False).size().rename('publications').to_csv(tables/f'frame_{col}.csv')
    d.groupby(['month','outlet_id','outlet_name']).size().rename('publications').to_csv(tables/'frame_source_month.csv')
    families=d[d.exact_text_family!=''].groupby('exact_text_family').agg(publications=('publication_id','size'),
                   outlets=('outlet_id','nunique'),first=('published_at','min'),last=('published_at','max'))
    families[families.publications>1].to_csv(tables/'exact_reuse_families.csv')
    rng=np.random.default_rng(CFG['seed'])
    main_sample,alloc=proportional(d,CFG['sample_size'],rng)
    rest=d[~d.publication_id.isin(main_sample.publication_id)].copy()
    # Development deliberately covers both ordinary and long/problematic source cases.
    dev_parts=[]
    for label,sub,n in [('long',rest[rest.text_length>=10000],20),('short',rest[rest.text_length<700],10)]:
        if len(sub):
            z=sub.loc[rng.choice(sub.index,min(n,len(sub)),replace=False)].copy();z['development_reason']=label;dev_parts.append(z)
    reserved=set(pd.concat(dev_parts).publication_id) if dev_parts else set()
    candidates=rest[~rest.publication_id.isin(reserved)]
    dev_more,_=proportional(candidates,CFG['development_size']-len(reserved),rng)
    dev_more['development_reason']='quarter_proportional'
    dev=pd.concat(dev_parts+[dev_more],ignore_index=True)
    rest=rest[~rest.publication_id.isin(dev.publication_id)]
    challenge,_=proportional(rest,CFG['challenge_size'],rng)
    sets={'main':main_sample,'development':dev,'challenge':challenge}
    freeze_files={}
    for name,s in sets.items():
        s.to_parquet(OUT/f'{name}_inputs.parquet',index=False,compression='zstd')
        s.drop(columns=['body_raw','body_clean','dedup_key']).to_csv(OUT/f'{name}_manifest.csv',index=False,encoding='utf-8-sig')
        freeze_files[f'{name}_inputs.parquet']=file_sha(OUT/f'{name}_inputs.parquet')
        freeze_files[f'{name}_manifest.csv']=file_sha(OUT/f'{name}_manifest.csv')
    alloc.to_csv(tables/'sample_allocation.csv',index=False)
    assert len(main_sample)==CFG['sample_size'] and main_sample.publication_id.is_unique
    assert np.isclose(main_sample.sampling_weight.sum(),len(d))
    assert not set(main_sample.publication_id)&set(dev.publication_id)
    assert not set(main_sample.publication_id)&set(challenge.publication_id)
    assert not set(dev.publication_id)&set(challenge.publication_id)
    audit=json.loads((OUT/'source_audit.json').read_text(encoding='utf-8'))
    freeze_files['frame.parquet']=file_sha(OUT/'frame.parquet')
    freeze_files['export_publication_crosswalk.csv']=file_sha(OUT/'export_publication_crosswalk.csv')
    save_json(OUT/'freeze.json',{'assignment':CFG,'source_sha256':audit['sha256'],'files':freeze_files,
      'export_records':len(cross),'publications':len(d),'duplicates_removed':int(cross.removed_export_duplicate.sum()),
      'sources':int(d.outlet_id.nunique()),'main_size':len(main_sample),'development_size':len(dev),'challenge_size':len(challenge),
      'deduplication':'same outlet + tracking-cleaned URL + publication date; missing URL: outlet/date/title/exact text; retain longest body then lowest record ID',
      'cleaning':'HTML entities and line-ending normalization, NUL removal, outer whitespace only; no boilerplate removal',
      'topic_retrieval':'inherited official Catholic-topic filter; all in-window web records; no names or doctrine preselection',
      'denominator_limit':'No comparable all-journalism denominator; shares refer to the captured topic frame only',
      'exact_reuse':'identical cleaned body SHA256, at least 400 characters; separate publications retained; not a copying/origin inference',
      'python':sys.version,'numpy':np.__version__,'pandas':pd.__version__})
    print(json.dumps({'publications':len(d),'sample':len(main_sample),'development':len(dev),'challenge':len(challenge),
                      'duplicates':int(cross.removed_export_duplicate.sum()),'long_main':int((main_sample.text_length>10000).sum())}))

if __name__=='__main__':main()
