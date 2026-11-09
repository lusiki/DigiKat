"""Check final PDF text, numerical reconciliation and produce visual-review sheets."""
from pathlib import Path
import hashlib,json
import fitz
import pandas as pd
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[2]
QA=ROOT/'tmp/pdfs/associations-pair'
def main():
    reports=json.loads((HERE/'tables/reports.json').read_text())
    checks=[]
    for stem,r in zip(['overview','language'],reports):
        path=ROOT/r['file'];doc=fitz.open(path);assert len(doc)==r['pages']
        full='\n'.join(p.get_text() for p in doc)
        assert '{{' not in full and '\ufffd' not in full and '23.436' in full and '18.938' in full
        assert '1.325' in full
        for phrase in ['neovisno potvrđeni','neovisna ljudska provjera','promjena prikupljanja','metodološka ograničenja','još nisu','mogućih objava','ne možemo']:
            assert phrase not in full.lower(),(stem,phrase)
        bad=[]
        for i,page in enumerate(doc):
            assert len(page.get_text())>250
            for block in page.get_text('dict')['blocks']:
                for line in block.get('lines',[]):
                    for span in line['spans']:
                        x0,y0,x1,y1=span['bbox']
                        if x0<40 or x1>page.rect.width-40 or y0<15 or y1>page.rect.height-20:bad.append((i+1,span['text']))
        assert not bad,bad
        pngs=sorted(QA.glob(stem+'-[0-9][0-9].png'));assert len(pngs)==len(doc)
        assert all(p.stat().st_mtime>=path.stat().st_mtime for p in pngs),'Stale page render'
        for start in range(0,len(doc),4):
            imgs=[Image.open(p).convert('RGB') for p in pngs[start:start+4]]
            w,h=imgs[0].size; sheet=Image.new('RGB',(w*2,h*2+40),'#dddddd')
            for j,im in enumerate(imgs):sheet.paste(im,((j%2)*w,(j//2)*h+40))
            ImageDraw.Draw(sheet).text((15,12),f'{stem} / pages {start+1}-{min(start+4,len(doc))}',fill='black')
            sheet.save(QA/f'{stem}-sheet-{start//4+1}.png')
        checks.append({'file':r['file'],'pages':len(doc),'words':len(full.split()),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'size_bytes':path.stat().st_size,'text_bounds':'pass','placeholders':'none'})
    words=pd.read_csv(HERE/'tables/word_document_frequency.csv');topics=pd.read_csv(HERE/'tables/topics.csv')
    assert int(topics['items'].sum())==18938
    assert (words.publication_days<=18938).all()
    for t,row in topics.set_index('topic').iterrows():assert (words[words.topic==t].publication_days<=row['items']).all()
    overview=fitz.open(ROOT/reports[0]['file']);language=fitz.open(ROOT/reports[1]['file'])
    text=''.join(p.get_text() for p in language)
    for n in topics['items']:assert f'{n:,}'.replace(',','.') in text
    for term in ['projekt','program','pomoc']:
        n=int(words[(words.topic==0)&(words.term==term)].iloc[0].publication_days)
        assert f'{n:,}'.replace(',','.') in text
    rank=pd.read_csv(HERE/'tables/organisation_ranking.csv');top=rank.head(10)
    outlets=pd.read_csv(HERE/'tables/organisation_outlets.csv')
    themes=pd.read_csv(HERE/'tables/organisation_topics.csv')
    ow=pd.read_csv(HERE/'tables/organisation_words.csv')
    method=json.loads((HERE/'tables/organisation_method.json').read_text(encoding='utf-8'))
    membership=pd.read_csv(HERE.parent/'output/private/media/v1/reader_rank_membership.csv')
    assert not membership.duplicated(['association_id','url_key']).any()
    actual=membership.groupby('association_id').size().sort_index()
    assert actual.equals(rank.set_index('association_id').web_publications.sort_index())
    assert rank.web_publications.sum()==method['rank_pairs']==len(membership)
    assert membership.url_key.nunique()==method['unique_web_urls']
    for row in top.itertuples():
        assert outlets.loc[outlets.association_id==row.association_id,'web_publications'].sum()==row.web_publications
        ot=themes[themes.association_id==row.association_id]
        assert ot.analysed_publications.nunique()==1
        denom=int(ot.analysed_publications.iloc[0]);assert ot.web_publications.sum()==denom<=row.web_publications
        assert abs(ot.share_pct.sum()-100)<1e-8
        w=ow[ow.association_id==row.association_id]
        assert (w.web_publications<=denom).all() and (w.analysed_publications==denom).all()
        for stem in ['overview','language']:
            manuscript=(HERE/f'{stem}-resolved.md').read_text(encoding='utf-8')
            assert row.name in manuscript,(stem,row.name)
    for filename,digest in method['inputs'].items():
        path=HERE.parent/'output/private/media/v1'/filename
        assert hashlib.sha256(path.read_bytes()).hexdigest()==digest
    for file in HERE.joinpath('tables').glob('organisation_*.csv'):
        cols=set(pd.read_csv(file,nrows=0).columns)
        assert not cols.intersection({'item_key','url_key','url','context','title','full_text','email'})
    result={'checks':'passed','reports':checks,'topic_denominator':18938,'candidate_denominator':23436,
        'rank_pairs':method['rank_pairs'],'rank_unique_urls':method['unique_web_urls'],'ranked_names':method['names'],
        'organisation_totals_reconciled':True,'input_hashes_unchanged':True,'human_validation_claimed':False,
        'visual_review':'See QUALITY_REVIEW.md; contact sheets do not themselves establish review.'}
    (HERE/'tables/verification.json').write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding='utf-8')
    print(json.dumps(result,indent=2,ensure_ascii=False))
if __name__=='__main__':main()
