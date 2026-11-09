"""Additional aggregate controls and recorded Codex readings (not human labels)."""
from analyze import *

def csvread(name):
    with (OUT/(name+'.csv')).open(encoding='utf-8',newline='') as f:return list(csv.DictReader(f))

def main():
    docs,reps,members,anno,ext=load();units=read(PRIVATE/'local-units.json')
    repmap={d['group']:d for d in reps};allgroups=set(repmap);a1={d['group'] for d in reps if d['a1']};web={g for g,ds in members.items() if any(d['platform']=='web' for d in ds)}
    counts,surface,pos,term_sents=counters(units,reps)
    terms=defaultdict(set)
    for u in units:
        for t in u['terms']:terms[t].add(u['group'])
    table('concept_profiles',[{'term':t,'label':LEX[t]['label'],'scope':name,'groups':len(terms[t]&gs),'denominator':len(gs),'percent':100*len(terms[t]&gs)/len(gs)} for t in LEX for name,gs in [('all',allgroups),('a1_representative',a1),('web_presence',web)]])
    contrasts=csvread('contrasts');thresholds=[]
    for contrast in sorted({r['contrast'] for r in contrasts}):
        for variant in sorted({r['variant'] for r in contrasts}):
            rs=[r for r in contrasts if r['contrast']==contrast and r['variant']==variant and r['category']=='content' and r['weighted_log_odds']]
            for threshold in (5,10,20):
                cand=sorted([r for r in rs if int(r['combined_df'])>=threshold],key=lambda r:(-abs(float(r['weighted_log_odds'])),r['term']))
                for rank,r in enumerate(cand,1):thresholds.append({'contrast':contrast,'variant':variant,'threshold':threshold,'rank_abs':rank,'term':r['term'],'weighted_log_odds':r['weighted_log_odds'],'groups':r['combined_df']})
    table('contrast_ranks',thresholds)
    morphology=Counter((t['token'].casefold(),lemma(t),t['upos']) for u in units for t in u['tokens'] if re.match(r'^(?:demokršć|supsid|subsid|socijaln)',t['token'].casefold()))
    table('morphology_audit',[{'surface':k[0],'lemma':k[1],'upos':k[2],'n':n} for k,n in morphology.most_common()])
    # Author-assigned codes after actually reading all 55 selected sentence cases
    # and their 51 complete existing evidence contexts. These are AI decisions.
    funcs=[
      ['osporavanje','nabrajanje','osporavanje','nabrajanje','osporavanje','nabrajanje','nabrajanje','nabrajanje','obrazlozenje','nabrajanje'],
      ['nabrajanje','nabrajanje','osporavanje','nabrajanje','nabrajanje','nabrajanje','nabrajanje','nabrajanje','nabrajanje','nabrajanje'],
      ['osporavanje','razlikovanje','osporavanje','razlikovanje','opis','osporavanje','osporavanje','opis','obrazlozenje','osporavanje'],
      ['obrazlozenje','organizacijski_naziv','nabrajanje','obrazlozenje','nabrajanje','osporavanje','obrazlozenje','nabrajanje','neodredjeno','obrazlozenje'],
      ['obrazlozenje','obrazlozenje','obrazlozenje','obrazlozenje','obrazlozenje'],
      ['nabrajanje','drugi_referent','osporavanje','neodredjeno','obrazlozenje','nabrajanje','osporavanje','nabrajanje','nabrajanje','osporavanje']]
    packet=read(PRIVATE/'relation-review.json');review=[]
    for p,fs in zip(packet,funcs):
        assert len(p['examples'])==len(fs)
        for i,(u,f) in enumerate(zip(p['examples'],fs)):
            review.append({'pair':p['pair'],'case_index':i,'function':f,'record_key':u['record_key'],'group':u['group'],
                           'field':u['field'],'start':u['start'],'end':u['end'],'reviewer':'Codex AI','scope':'selected sentence plus full stored evidence context','human_validated':False})
    write(PRIVATE/'relation-review-decisions.json',review)
    table('relation_review_scope',[{'a':p['pair'][0],'b':p['pair'][1],'cases_read':len(p['examples']),'reviewer':'Codex AI','human_validated':False} for p in packet])
    # Each selection below had its complete available title/body read in this run.
    dev=read(OLD/'development_review.json');S={d['record_key']:d['source_name'] for d in docs}
    specs=[
      ('K01',119,'Europska solidarnost i razvoj','Davor Ivo Stier; citirani političar','solidarnost','europski fondovi i razvoj Hrvatske','Razvoj i infrastrukturne projekte opravdava demokršćanskom Europom solidarnosti.','izričit','nađena povezana primjena','Tumačenje govornika; nije dokaz ekonomskog učinka.','Utoliko se razlikujemo','rekao je Stier.'),
      ('K02',139,'Savjest i odluka o zabrani','Andrej Plenković; citirani političar','savjest i deklarirane demokršćanske vrijednosti','priziv savjesti liječnika','Pripadnost demokršćanskim vrijednostima navodi kao razlog protiv zabrane priziva savjesti.','izričit','nađena povezana primjena','Stav govornika; nije pravna ocjena ni dokaz provedbe.','GLAS-ova Anka','(Hina)'),
      ('K03',125,'Supsidijarnost i razine vlasti','Jakov Žižić; intervjuirani politolog','supsidijarnost; opće dobro','raspodjela vlasti i korekcija tržišta','Usporedbom političkih tradicija objašnjava raspodjelu vlasti te ulogu države u ispravljanju tržišnih učinaka.','izričit','nađeno objašnjenje i primjena','Jedna stručna interpretacija; tekstualna različitost nije broj neovisnih argumenata.','Demokršćani zastupaju načelo supsidijarnosti','Kod nacionalnih konzervativaca'),
      ('K04',122,'Popis vrijednosti i obiteljski kriterij','nacrt programa HDZ-a; preneseni stranački glas','solidarnost i društvena odgovornost','obiteljske zajednice','Širi tekst uz popis vrijednosti povezuje poštovanje obiteljskih zajednica s brigom, solidarnošću i odgovornošću.','izričit u programu','nađena programska primjena u širem tekstu','Lokalni kontekst donosi popis; puni pohranjeni tekst omogućuje užu prosudbu. Nije dokaz provedene mjere.','Među “temeljnim načelima','U dijelu programa'),
      ('K05',1,'Poštovanje načela bez pripadnosti','Samir Haj Barakat; citirani političar','načela bez imenovanja pojedinog načela','odluka o stranačkoj pripadnosti','Poštuje demokršćanska načela, ali odbija demokršćansku pripadnost i prelazak u HDZ.','izričit','konkretna primjena načela nije nađena','Opis dostojanstva i odgovornosti u drugom dijelu odnosi se na SDP; ne prenosimo ga na demokršćanstvo.','Ulazak u HDZ nije','poručio je Haj Barakat.'),
      ('K06',104,'Radnička solidarnost bez izričitog referenta','Andrej Plenković; prenesena čestitka','kršćanska solidarnost i dostojanstvo radnika','rad i produktivnost','Kršćansko načelo povezuje s radom, ali raspoloživi tekst ne imenuje demokršćanstvo.','nije utvrđen','nije potvrđeno kao demokršćanska primjena','Važan granični slučaj: stranačka pripadnost govornika ne popunjava nedostajuću vezu.','Hrvatske radnike i radnice pozvao','temeljne društvene vrijednosti.'),
      ('K07',100,'Povezani članak stvara pogrešnu vezu','više sugovornika; novinarski prijenos','socijalni nauk u naslovu povezane vijesti','rad trgovina nedjeljom','Pogodak socijalnog nauka nalazi se u preporučenoj poveznici; ne pripisuje se automatski argumentu glavnog članka.','nije utvrđen u glavnom argumentu','nije potvrđeno kao demokršćanska primjena','Pokazuje ograničenje selekcije i čišćenja.','>Promišljanja o neradnoj nedjelji','>U Saboru'),
      ('K08',124,'Afirmacija tradicije i kritika aktera','Jakov Žižić; citirani politolog','socijalno pitanje i demokršćanska tradicija','odnos političkih deklaracija i sadržaja','Pozitivno tumači socijalni doprinos tradicije te kritizira aktere koji zanemaruju njezina socijalno-ekonomska pitanja.','izričit','kontrast stavova prema različitim ciljevima','Ovo je analiza iznesenog stava; povijesne i anketne tvrdnje iz članka nisu potvrđene novim istraživanjem.','Politički akteri koji se predstavljaju','Odgovarajući na pitanja'),
      ('K09',111,'Opće dobro u socijalnom nauku','Vlado Kolak; autorski glas s citatom Ante Bekavca','dostojanstvo osobe i opće dobro','stranačko zapošljavanje i sloboda izražavanja','Povezuje socijalni nauk s javnim prosudbama, ali ne imenuje demokršćanski referent.','nije utvrđen','nije potvrđeno kao demokršćanska primjena','Srodan sadržaj ostaje izvan stroge oznake M3.','Prema tome opasne su','Svakako da je pravo')]
    private=[];public=[]
    for cid,idx,title,speaker,principle,problem,judgment,referent,status,limit,start,end in specs:
        d=dev[idx];begin=d['body'].index(start);finish=d['body'].index(end,begin)+len(end)
        public.append({'case':cid,'date':d['day'],'source':S[d['record_key']],'title':title,'speaker':speaker,'principle':principle,'problem':problem,'judgment':judgment,'referent':referent,'status':status,'limit':limit,'topic':d['topic'],'reviewer':'Codex AI','human_validated':False})
        private.append({**public[-1],'development_index':idx,'record_key':d['record_key'],'group':d['group'],'field':'body','start':begin+1,'end':finish,'evidence':d['body'][begin:finish],
          'body_sha256':hashlib.sha256(d['body'].encode()).hexdigest(),'scope':'complete available title and body read; stored text not guaranteed complete original',
          'topic':d['topic']})
    write(PRIVATE/'argument-cases.json',private);write(OUT/'argument_cards.json',public)
    write(OUT/'content_review_status.json',{'reader':'Codex AI','full_available_bodies_read':len(specs),'relation_sentence_cases':len(review),
       'distinct_relation_texts':len({r['record_key'] for r in review}),'human_codings':0,'selection':'Purposive contrastive cases from prior development pool; diverse relationship contexts selected deterministically; not random for prevalence.'})
    print('Supplementary controls and private case trails written.')

if __name__=='__main__':main()
