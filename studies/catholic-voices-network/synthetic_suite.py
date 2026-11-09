"""54 constructed cases. Never a reference sample of real journalism.

Preserves all 30 v2 texts and four statement probes. Legacy role/group/content
fields outside the passage schema are retained in metadata, not called passed.
Long legacy texts are windowed; lost distant attribution counts as a failure.
"""
import json,re
from voices_common import ROOT

NAMES=['Ana Markić','Marko Kovač','Ivan Horvat','Hrvatska biskupska konferencija',
       'Ana Babić','Ivan Marić','sestra Marija','neimenovani sudionik','Teologinja',
       'župnik Marko','Trener Luka','Župljanka Ana','Biskup','gradonačelnik','Papa']

def fixture(case,text,names,expected,author=''):
    return dict(id=case,case=case,text=text,names=names,author=author,expected=expected,
                synthetic=True,legacy_expected=None)

def extra_cases():
    return [
      fixture('F01','Ja, Ana Babić, molim svakoga jutra. Molitva mi je pomogla u žalovanju.',
              ['Ana Babić'],{'stated':1,'mode':['first_person'],'function':['testimony']},'Ana Babić'),
      fixture('F02','U svojoj sam župi godinama pomagao obiteljima. Vjera mi je davala snagu.',
              [],{'stated':1,'mode':['first_person'],'function':['testimony']},'Marko Kovač'),
      fixture('F03','Danas sam čitala Evanđelje i molila za svoju obitelj.',[],
              {'stated':1,'mode':['first_person']},'Ana Babić'),
      fixture('F04','Biskup Ivan Marić posjetio je školu. Razgledao je obnovljene učionice.',
              ['Ivan Marić'],{'stated':0},'Ana Babić'),
      fixture('F05','Ana Babić prenosi riječi župnika Marka: "Molitva nas uči strpljenju."',
              ['Ana Babić','župnika Marka'],{'stated':1,'speaker':['župnika Marka'],'mode':['direct']},'Ana Babić'),
      fixture('F06','Na plakatu piše: "Ja sam put, istina i život." Posjetitelji su fotografirali plakat.',
              [],{'stated':0},'Ana Babić'),
      fixture('F07','Mi u udruzi Svjetlo organiziramo pomoć potrebitima jer nas vjera poziva na solidarnost.',
              ['udruzi Svjetlo'],{'stated':1,'mode':['institutional']},'udruzi Svjetlo'),
      fixture('F08','Sutra ću govoriti o kršćanskom postu. Sadržaj predavanja objavit ću poslije susreta.',
              [],{'stated':0,'announced':1},'Marko Kovač'),
      fixture('T01','Zagrebački nadbiskup rekao je: "Milosrđe je zahtjev evanđelja."',
              ['Zagrebački nadbiskup'],{'stated':1,'mode':['direct'],'function':['explains_doctrine','pastoral']}),
      fixture('T02','Sveti Otac poručio je da kršćani moraju pomagati siromašnima.',
              ['Sveti Otac'],{'stated':1,'mode':['indirect']}),
      fixture('T03','Ministar obrazovanja i biskup nazočili su otvorenju škole. Nisu održali govore.',
              ['Ministar obrazovanja','biskup'],{'stated':0}),
      fixture('T04','Župnik je objavio: "Misa je u nedjelju u deset sati."',
              ['Župnik'],{'stated':1,'function':['institutional_info']}),
      fixture('T05','Biskup će održati propovijed o oprostu. Objavljeni tekst sadrži samo najavu.',
              ['Biskup'],{'stated':0,'announced':1}),
      fixture('T06','Teologinja objašnjava oprost u razgovoru dostupnom samo pretplatnicima. Nema njezinih odgovora u ovom tekstu.',
              ['Teologinja'],{'stated':0}),
      fixture('H01','U knjizi je citiran Augustin: "Vjera traži razumijevanje." Riječ je o povijesnom citatu.',
              ['Augustin'],{'stated':1,'mode':['direct'],'historical':['Augustin']}),
      fixture('H02','Na izložbi je prikazan portret Augustina. Nije naveden nijedan njegov citat.',
              ['Augustina'],{'stated':0,'historical':['Augustina']}),
      fixture('H03','Arhiv donosi propovijed pape Franje iz 2022.: "Vjera nas poziva na milosrđe." Tekst je ponovno objavljen 2026.',
              ['pape Franje'],{'stated':1,'mode':['direct'],'historical':['pape Franje']}),
      fixture('H04','U Evanđelju Isus kaže: "Ljubite jedni druge." To je biblijski citat.',
              ['Isus'],{'stated':1,'mode':['direct'],'sacred':['Isus']}),
      fixture('H05','Župnik Marko Kovač tumači Augustinov tekst: "Ovaj nas tekst poziva da razmislimo o vjeri."',
              ['Marko Kovač','Augustinov'],{'stated':1,'speaker':['Marko Kovač'],'historical':['Augustinov']}),
      fixture('H06','Papa Franjo umro je 2025. U današnjoj vijesti spominje se njegova ostavština. Nema citata ni pripisanog sadržaja.',
              ['Papa Franjo'],{'stated':0,'historical':['Papa Franjo']})]

def fixtures():
    old=ROOT/'studies/theological-voices-v2/output/private'
    source=json.loads((old/'diagnostic_inputs.json').read_text(encoding='utf-8'))
    probes=json.loads((old/'statement_probe_inputs.json').read_text(encoding='utf-8'))
    assert len(source)==30 and len(probes)==4
    out=[]
    for row in sorted(source+probes,key=lambda r:r['publication_id']):
        case=row['case'];legacy=row.get('expected',{})
        exp={'stated':0 if legacy.get('voices')==0 else 1}
        if 'expected_voices' in row:exp['stated']=row['expected_voices']
        if legacy.get('has_interpretation') is True:exp['function']=['explains_doctrine','explains_practice','pastoral']
        if legacy.get('has_interpretation') is False:exp['forbidden_function']=['explains_doctrine','explains_practice']
        if legacy.get('has_experience') is True:exp['function']=['testimony']
        if legacy.get('has_experience') is False:exp['forbidden_function']=exp.get('forbidden_function',[])+['testimony']
        if case=='mass_schedule':exp['function']=['institutional_info']
        if case=='institution':exp['mode']=['institutional']
        if case in ['theologian','separated_attribution']:exp['authority']=['academic']
        if case=='priest_not_academic':exp['forbidden_authority']=['academic']
        text=row['body_clean'];names=[n for n in NAMES if n in text]
        f=fixture(row['publication_id'],text,names,exp);f['case']=case;f['legacy_expected']=legacy
        out.append(f)
    out+=extra_cases();assert len(out)==54 and len({x['id'] for x in out})==54
    return out

def windows(case,cap=1200):
    text=case['text']
    if len(text)<=cap:return [text]
    # Same bounded reading constraint; no hidden hand-written synopsis of long cases.
    paras=re.split(r'\n\s*\n|\n',text);out=[]
    for i,p in enumerate(paras):
        if any(name in p for name in case['names']):
            chunk='\n'.join(paras[max(0,i-2):i+3])
            if len(chunk)>cap:
                at=chunk.find(p);chunk=chunk[max(0,at-(cap-len(p))//2):][:cap]
            if chunk not in out:out.append(chunk)
    return out

def assess(case,rows):
    # Deduplicate overlapping windows only for this constructed-case check.
    stated={r['surface']:r for r in rows if r['proposition_status']=='stated'}
    exp=case['expected'];fail=[]
    if len(stated)!=exp['stated']:fail.append('stated_count')
    if 'announced' in exp and len({r['surface'] for r in rows if r['proposition_status']=='announced_only'})!=exp['announced']:fail.append('announced_count')
    for key,field in [('mode','mode'),('function','function'),('authority','authority_cue'),('speaker','surface')]:
        values={r[field] for r in stated.values()}
        if key in exp and not values.intersection(exp[key]):fail.append(key)
        if values.intersection(exp.get('forbidden_'+key,[])):fail.append('forbidden_'+key)
    # Historical/sacred exclusions are identity-layer tests, not claims that the
    # coder inferred life dates. Preserve these assertions for the identity suite.
    return fail

if __name__=='__main__':
    cases=fixtures()
    print(json.dumps(dict(cases=len(cases),windows=sum(len(windows(c)) for c in cases),
        max_chars=max(len(w) for c in cases for w in windows(c)),synthetic=True)))
