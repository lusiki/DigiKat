"""Synthetic rule diagnostics, plus saved machine-only development/challenge audit.

Constructed cases test operational rules; they are not labelled real articles and
provide no estimate of classifier accuracy on journalism.
"""
from __future__ import annotations
import argparse, json, time
from datetime import datetime, timezone
import pandas as pd
from coder import connect, code_article, get_config_hash, config, runtime_snapshot, OUT, STUDY
from prepare import save_json, sha, file_sha

CASES=[
 ('mention_only','Biskup i gradonačelnik bili su na otvorenju. Na pročelju je pisalo HBK. Nitko nije dao izjavu.',
  {'voices':0}),
 ('unrelated_quote','Na utakmici je bio župnik Marko. Trener Luka je rekao: "Igrali smo loše u obrani." Crkva je vidljiva iza stadiona.',
  {'voices':0}),
 ('experience','Župljanka Ana opisala je posljedice potresa: "Naša je crkva zatvorena. Već mjesecima molim u privremenoj dvorani i nedostaje mi zajednica."',
  {'has_experience':True,'role':'personal_experience'}),
 ('prediction','Sociolog Ivan Horvat rekao je da će, prema njegovoj procjeni, zatvaranje župne crkve smanjiti druženje vjernika. Nije govorio o vlastitom iskustvu.',
  {'has_experience':False,'role':'research_expert','has_groups':True}),
 ('theologian','Profesorica teologije Ana Markić objašnjava uskrsnuće: "Kršćanska nada nije bijeg od odgovornosti. Vjera nas poziva na brigu za bližnjega."',
  {'role':'academic_theologian','has_interpretation':True}),
 ('priest_not_academic','Župnik Marko Kovač rekao je: "Vjera nas uči opraštanju i odgovornosti prema bližnjemu." U tekstu nema podataka o njegovu akademskom radu.',
  {'role':'priest_religious','forbidden_role':'academic_theologian','has_interpretation':True}),
 ('separated_attribution','Profesorica teologije Ana Markić razgovarala je s novinarkom.\nRazgovor se vodio u knjižnici.\nNa stolu su bile knjige.\nNakon kratke stanke nastavila je objašnjenje: "Milosrđe ne ukida pravdu; poziva nas da vidimo dostojanstvo druge osobe."',
  {'role':'academic_theologian','has_interpretation':True}),
 ('paywall','Teologinja objašnjava što znači oprost. Pročitajte cijeli razgovor uz pretplatu. Nastavak teksta dostupan je samo pretplatnicima.',
  {'content':'partial','voices':0}),
 ('institution','Hrvatska biskupska konferencija objavila je priopćenje: "Pozivamo na pomoć obiteljima koje su izgubile dom. Župni uredi organizirat će smještaj."',
  {'role':'religious_institution','has_groups':True}),
 ('mass_schedule','Župnik Marko Kovač poručio je: "Nedjeljna misa počinje u deset sati. Nakon nje održat će se sastanak župnog vijeća."',
  {'role':'priest_religious','has_interpretation':False,'has_experience':False}),
 ('ambiguous_source','Jedan neimenovani sudionik rasprave rekao je: "Vjera zahtijeva da ne ponižavamo slabije." Njegovo zanimanje i funkcija nisu navedeni.',
  {'role':'unresolved','has_interpretation':True}),
 ('narrator','Vjera traži odgovornost. Evanđelje govori o milosrđu. Autor ovog nepotpisanog uredničkog teksta nije identificiran i ne navodi tuđe izjave.',
  {'voices':0})
]

def fixtures():
    records=[]
    for i,(name,body,expected) in enumerate(CASES):
        for variant in range(2):
            title='Primjer za provjeru pravila' if not variant else 'Rasprava o vjeri i zajednici'
            text=body if not variant else ('Mjesto događaja bilo je javno dostupno.\n'+body+'\nDogađaj je potom završen.')
            pid=f'D{i+1:02d}{variant}'
            records.append({'publication_id':pid,'title':title,'body_clean':text,'outlet_name':'SINTETSKI PRIMJER',
              'published_at':'2026-01-01','input_hash':sha(json.dumps([title,text],ensure_ascii=False)),
              'content_status':'available_unverified','case':name,'expected':expected,'synthetic':True})
    filler='\n'.join(f'Dio programa broj {i} bio je posvećen organizaciji susreta. Posjetitelji su razgledali prostor, a zapisničar je zabilježio raspored i tehničke pojedinosti događaja.' for i in range(1,76))
    extra=[
      ('expert_own_experience','Teologinja Ana Markić opisala je svoj rad: "U župi sam godinama razgovarala s obiteljima koje su izgubile bližnje. Ti su razgovori promijenili moje razumijevanje vjere i milosrđa."',
       {'role':'academic_theologian','has_experience':True}),
      ('headline_body_mismatch','Ovo je cjelovita vremenska prognoza. U Zagrebu će biti sunčano, a u gorju oblačno. Temperatura će dosegnuti dvadeset stupnjeva. Prognoza završava bez drugih tema.',
       {'voices':0,'relevance':'none'}),
      ('late_long_statement',filler+'\nProfesorica teologije Ana Markić na kraju je izjavila: "Uskrsnuće pokazuje da kršćanska nada nadilazi smrt. To je razlog da u životu ne odustanemo od ljubavi prema bližnjemu."',
       {'role':'academic_theologian','has_interpretation':True}),
      ('long_separated_identity','Profesorica teologije Ana Markić preuzela je riječ.\n'+filler+'\nOna je potom nastavila svoje izlaganje: "Milosrđe nas poziva na pomoć slabijima. To je zahtjev evanđelja i izraz kršćanske vjere."',
       {'role':'academic_theologian','has_interpretation':True}),
      ('appended_recommendation','Grad je popravio cestu i otvorio promet za sva vozila. Radovi su završili u petak.\nKRAJ ČLANKA\nPREPORUČUJEMO DRUGU VIJEST: Papa o oprostu. Pročitajte cijeli tekst te druge vijesti na zasebnoj poveznici.',
       {'content':'partial','voices':0}),
      ('religious_sister','Redovnica sestra Marija iz dominikanskog reda objašnjava: "Molitva nije bijeg od svijeta. Evanđelje nas poziva da u svakoj osobi prepoznamo bližnjega."',
       {'role':'priest_religious','has_interpretation':True})]
    for i,(name,text,expected) in enumerate(extra,1):
        title='Papa o važnosti molitve' if name=='headline_body_mismatch' else 'Provjera čitanja cijelog članka'
        records.append({'publication_id':f'X{i:02d}','title':title,'body_clean':text,'outlet_name':'SINTETSKI PRIMJER',
          'published_at':'2026-01-01','input_hash':sha(json.dumps([title,text],ensure_ascii=False)),
          'content_status':'available_unverified','case':name,'expected':expected,'synthetic':True})
    return records

def run_probes():
    """Additional development contrasts, separate from the unchanged 30 diagnostics."""
    cases=[
      ('announcement_with_paywall','Teologinja Ana Babić u novom razgovoru govori o pomirenju i značenju kršćanskog oprosta. Cijeli razgovor i njezini odgovori dostupni su samo pretplatnicima.',0),
      ('announced_future_speech','Biskup Ivan Marić održat će predavanje o postu. Tema najavljenog predavanja jest značenje posta u kršćanstvu. Ovo je nepotpisana urednička najava bez citata i bez pripisanih izjava.',0),
      ('visible_quote_before_paywall','Teologinja Ana Babić rekla je: "Kršćanski oprost ne ukida odgovornost za učinjeno zlo." Ostatak intervjua dostupan je samo pretplatnicima.',1),
      ('visible_paraphrase_before_paywall','Biskup Ivan Marić poručio je da će župe otvoriti dvorane za smještaj obitelji čiji su domovi stradali u potresu. Nastavak razgovora dostupan je samo pretplatnicima.',1)]
    db=connect();chash=get_config_hash();checks=[]
    save_json(OUT/'configs'/f'{chash}.json',{'config_hash':chash,'configuration':config(),'environment':runtime_snapshot()})
    rows=[]
    for i,(name,body,count) in enumerate(cases):
        title='Razgovori i događaji u vjerskoj zajednici'
        row={'publication_id':f'B{i+1:02d}','title':title,'body_clean':body,'outlet_name':'SINTETSKI KONTRAST',
             'published_at':'2026-01-01','input_hash':sha(json.dumps([title,body],ensure_ascii=False)),
             'content_status':'available_unverified','case':name,'expected_voices':count,'synthetic':True}
        rows.append(row)
    save_json(OUT/'statement_probe_inputs.json',rows)
    save_json(OUT/'configs'/chash/'statement_probe_inputs.json',rows)
    for row in rows:
        old=db.execute('SELECT result_json FROM articles WHERE set_name=? AND publication_id=? AND config_hash=?',
                       ('statement_probe',row['publication_id'],chash)).fetchone()
        if old:result=json.loads(old[0])
        else:
            result=code_article(db,row,'statement_probe',chash,challenge=True)
            db.execute('INSERT INTO articles VALUES(?,?,?,?,?,?)',('statement_probe',row['publication_id'],chash,row['input_hash'],
                       json.dumps(result,ensure_ascii=False),datetime.now(timezone.utc).isoformat()));db.commit()
        passed=(result['status']=='complete' and len(result['voices'])==row['expected_voices'] and
                (row['case']=='announced_future_speech' or result['source_content']=='partial'))
        checks.append({'id':row['publication_id'],'case':row['case'],'passed':passed,
                       'expected_voices':row['expected_voices'],'actual_voices':len(result['voices']),
                       'processing':result['status'],'content':result['source_content']})
        save_json(OUT/'statement_probe_review.json',{'config_hash':chash,'checks':checks,
                  'note':'Additional constructed development contrasts; no empirical accuracy estimate.'})
        print(json.dumps(checks[-1]),flush=True)
    db.close()
    if not all(x['passed'] for x in checks):raise SystemExit('Statement boundary probe failed; inspect the saved evidence.')

def run_diagnostics():
    db=connect();chash=get_config_hash();runtime=runtime_snapshot()
    save_json(OUT/'configs'/f'{chash}.json',{'config_hash':chash,'configuration':config(),'environment':runtime})
    priority={'D031':0,'X03':1,'D101':2,'D110':3,'D081':4,'X05':5}
    records=sorted(fixtures(),key=lambda row:priority.get(row['publication_id'],4))
    save_json(OUT/'diagnostic_inputs.json',records)
    save_json(OUT/'configs'/chash/'diagnostic_inputs.json',records)
    checks=[]
    for row in records:
        old=db.execute('SELECT result_json FROM articles WHERE set_name=? AND publication_id=? AND config_hash=?',
                       ('diagnostic',row['publication_id'],chash)).fetchone()
        if old:result=json.loads(old[0])
        else:
            result=code_article(db,row,'diagnostic',chash,challenge=True)
            db.execute('INSERT INTO articles VALUES(?,?,?,?,?,?)',('diagnostic',row['publication_id'],chash,row['input_hash'],
                       json.dumps(result,ensure_ascii=False),datetime.now(timezone.utc).isoformat()));db.commit()
        actual={'voices':len(result['voices']),'has_experience':any(v['own_experience']=='yes' for v in result['voices']),
          'has_interpretation':any(v['interprets_faith']=='yes' for v in result['voices']),
          'has_groups':bool(result['affected_groups']),'content':result['source_content'],'relevance':result.get('relevance')}
        roles={v['role'] for v in result['voices']};fail=[]
        for k,v in row['expected'].items():
            ok=(v in roles) if k=='role' else (v not in roles) if k=='forbidden_role' else actual[k]==v
            if not ok:fail.append({'field':k,'expected':v,'actual':sorted(roles) if k in {'role','forbidden_role'} else actual[k]})
        checks.append({'id':row['publication_id'],'case':row['case'],'structural_status':result['status'],'failures':fail})
        print(json.dumps(checks[-1],ensure_ascii=True),flush=True)
        save_json(OUT/'diagnostic_review.json',{'config_hash':chash,'synthetic':True,'checks':checks,
         'note':'Rule checks on constructed examples, not empirical accuracy or human-coded articles.'})
    db.close()

def audit():
    db=connect();chash=get_config_hash();results={}
    for name in ['development','challenge','challenge_challenge','diagnostic','main']:
        rows=[json.loads(r[0]) for r in db.execute('SELECT result_json FROM articles WHERE set_name=? AND config_hash=?',(name,chash))]
        if not rows:continue
        tasks={k:sum(r['task_validity'].get(k,False) for r in rows)/len(rows) for k in ['topics','mentions','speakers','groups']}
        long=[r for r in rows if r['segments_expected']>1]
        results[name]={'articles':len(rows),'task_validity_rates':tasks,'segmented_articles':len(long),
          'segmented_task_validity_rates':{k:sum(r['task_validity'].get(k,False) for r in long)/len(long) for k in tasks} if long else {},
          'topic_disagreements':sum(r.get('topic_disagreement',False) for r in rows),
          'zero_speaker_articles':sum(not r['voices'] for r in rows),
          'partial_sources':sum(r['source_content']=='partial' for r in rows),
          'seconds':sum(r.get('elapsed_seconds',0) for r in rows)}
    # Compare the same fresh articles under primary and alternative local settings.
    # Neither side is truth. Disagreement remains explicit and is not averaged away.
    primary={pid:json.loads(raw) for pid,raw in db.execute('SELECT publication_id,result_json FROM articles WHERE set_name=? AND config_hash=?',('challenge',chash))}
    alternative={pid:json.loads(raw) for pid,raw in db.execute('SELECT publication_id,result_json FROM articles WHERE set_name=? AND config_hash=?',('challenge_challenge',chash))}
    comparisons=[]
    for pid in sorted(set(primary)&set(alternative)):
        x,y=primary[pid],alternative[pid]
        comparison={'publication_id':pid,'primary_relevance':x.get('relevance'),'alternative_relevance':y.get('relevance'),
          'relevance_disagreement':x.get('relevance')!=y.get('relevance'),
          'primary_roles':sorted({v['role'] for v in x['voices']}),'alternative_roles':sorted({v['role'] for v in y['voices']}),
          'primary_no_speaker':not bool(x['voices']),'alternative_no_speaker':not bool(y['voices']),
          'source_completeness_disagreement':x['source_content']!=y['source_content'],
          'resolution':'Keep the frozen primary configuration; retain alternative result and disagreement as sensitivity evidence. Neither output is ground truth.'}
        comparison['role_disagreement']=comparison['primary_roles']!=comparison['alternative_roles']
        comparisons.append(comparison)
    save_json(OUT/'challenge_disagreements.json',{'config_hash':chash,'comparisons':comparisons,
      'note':'Fresh machine challenge, no human reference labels and no measured accuracy.'})
    diag=json.loads((OUT/'diagnostic_review.json').read_text(encoding='utf-8')) if (OUT/'diagnostic_review.json').exists() else {}
    diag_ok=diag.get('config_hash')==chash and len(diag.get('checks',[]))==30 and not any(c['failures'] or c['structural_status']!='complete' for c in diag['checks'])
    save_json(OUT/'development_review.json',{'config_hash':chash,'sets':results,'all_diagnostic_rules_passed':diag_ok,
      'note':'Machine-only structural, evidence-link and synthetic rule checks. No empirical ground truth.'})
    print(json.dumps({'config_hash':chash,'sets':results,'diagnostics_ok':diag_ok},indent=2))
    db.close();return chash,results,diag_ok

def freeze():
    chash,results,diag_ok=audit()
    d=results.get('development',{});c=results.get('challenge_challenge',{});primary=results.get('challenge',{})
    ok=(d.get('articles')==100 and c.get('articles')==30 and primary.get('articles')==30 and diag_ok and
        all(v>=.95 for v in d.get('task_validity_rates',{}).values()) and
        all(v>=.95 for v in c.get('task_validity_rates',{}).values()) and
        all(v>=.95 for v in primary.get('task_validity_rates',{}).values()))
    if not ok:raise SystemExit('Gate not passed. Inspect diagnostics and processing, revise or withdraw unreliable tasks; do not start main.')
    # Persist config even before main; freeze is auditable and requires exact code/config hash.
    save_json(OUT/'coder_freeze.json',{'config_hash':chash,'main_authorized_by_checks':True,
      'created_at':datetime.now(timezone.utc).isoformat(),'development_articles':100,'fresh_challenge_articles':30,
      'diagnostics':30,'machine_only':True,'classification_accuracy':'not measured',
      'configuration_file':f'configs/{chash}.json'})

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['run','probes','audit','freeze']);a=p.parse_args()
    {'run':run_diagnostics,'probes':run_probes,'audit':audit,'freeze':freeze}[a.command]()
