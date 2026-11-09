"""Read-only diagnosis and an identity-free, human-readable status report."""
import collections, difflib, html, json, re, statistics, unicodedata
import duckdb
from voices_common import STUDY,workdir,atomic_json,utc,CORPUS_HASH,CONFIG_HASH

def normal(s):return ' '.join(unicodedata.normalize('NFC',s).split())
def punctuation(s):
    return normal(s).translate(str.maketrans({'„':'"','“':'"','”':'"','’':"'",'‘':"'",'–':'-','—':'-'}))

def main():
    con=duckdb.connect(str(workdir()/'voices.duckdb'),read_only=True)
    rows=con.execute('''SELECT c.model,c.mode,c.item_id,c.attempt,c.seconds,c.raw_json,c.checks_json,c.error_type,w.text
        FROM pilot_llm_calls c JOIN pilot_window_candidates w USING(item_id)
        ORDER BY c.model,c.mode,c.item_id,c.attempt''').fetchall()
    groups=collections.defaultdict(list)
    for row in rows:groups[row[0],row[1]].append(row)
    diagnostics=[]
    for (model,mode),rr in sorted(groups.items()):
        first=collections.Counter();last=collections.Counter();lastrows={};evidence_types=collections.Counter()
        totals=collections.Counter();prompts=[];generations=[];samples=[]
        for _,_,item,attempt,seconds,raw,check,error,text in rr:
            payload=json.loads(raw);checks=json.loads(check)
            flags=list(checks['errors'])
            if not checks.get('finished'):flags.append('not_finished')
            if error:flags.append('transport_error')
            category='+'.join(sorted(flags)) if flags else 'accepted'
            if attempt==1:first[category]+=1
            lastrows[item]=(category,payload,checks)
            totals['calls']+=1
            if error:totals['transport_errors']+=1
            if payload.get('done_reason')=='length':totals['output_limit_stops']+=1
            if not checks['json_valid']:
                totals['invalid_json_calls']+=1
                if payload.get('done_reason')=='length':totals['invalid_json_with_output_limit']+=1
            prompts.append(payload.get('prompt_eval_count',0));generations.append(payload.get('eval_count',0))
            try:answer=json.loads(payload.get('response',''))
            except (ValueError,TypeError):continue
            for speaker in answer.get('speakers',[]):
                evidence=speaker.get('evidence','')
                if not isinstance(evidence,str) or not evidence or evidence in text:continue
                if normal(evidence) in normal(text):kind='whitespace_or_unicode_only'
                elif punctuation(evidence) in punctuation(text):kind='punctuation_normalization'
                elif punctuation(evidence).casefold() in punctuation(text).casefold():kind='case_normalization'
                else:kind='not_resolved_by_these_normalizations'
                evidence_types[kind]+=1
                # Private debug examples are not labels and never establish accuracy.
                if len(samples)<3 and attempt==1:
                    samples.append(dict(kind=kind,source=text,evidence=evidence))
        for cat,_,_ in lastrows.values():last[cat]+=1
        diagnostics.append(dict(model=model,mode=mode,first_attempt_categories=dict(first),
          final_attempt_categories=dict(last),totals=dict(totals),evidence_mismatch_spans=dict(evidence_types),
          prompt_tokens_min=min(prompts),prompt_tokens_max=max(prompts),generated_tokens_max=max(generations)))
        # These examples stay private and are omitted from the readable overview.
        atomic_json(STUDY/'output/private'/('debug_evidence_'+model.replace(':','_')+'_'+mode+'.json'),samples)
    counts=con.execute('SELECT type,count(*) FROM pilot_mentions GROUP BY type ORDER BY type').fetchall()
    name_docs=con.execute("SELECT count(DISTINCT doc_id) FROM pilot_mentions WHERE type='PER'").fetchone()[0]
    profile=json.loads((workdir()/'corpus_profile.json').read_text(encoding='utf-8'))
    ner=json.loads((workdir()/'pilot_report.json').read_text(encoding='utf-8'))
    llm=json.loads((workdir()/'pilot_llm_report.json').read_text(encoding='utf-8'))
    parse=json.loads((workdir()/'pilot_parse_report.json').read_text(encoding='utf-8'))
    mh=json.loads((workdir()/'minhash_report.json').read_text(encoding='utf-8'))
    out=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
        diagnostics=diagnostics,pilot_entity_spans=dict(counts),pilot_documents_with_person=name_docs,
        exact_repeat_rows=profile['documents']-mh['unique_texts'],
        note='Mechanical checks, not semantic accuracy. Repeated rows mean exact cleaned-text repeats, not proven independent contributions or plagiarism.')
    atomic_json(STUDY/'output/private/pilot_diagnosis.json',out)
    print(json.dumps(out,ensure_ascii=False,indent=2))
    # Recomputable report: every empirical figure comes from stored outputs.
    f=lambda n:f'{n:,}'
    sections=['<h1>Original pilot snapshot</h1><p>This is a historical pilot snapshot, not live status. Check PROGRESS.md and the saved stage logs for current execution. No human validation of recognition or statement attribution. No final research findings.</p>']
    sections.append('<table><tr><th>Work</th><th>Completed</th><th>Meaning</th></tr>')
    work=[('Corpus preparation',f(profile['documents'])+' documents','Cleaned full text, source metadata, exact hashes and interruption-safe storage.'),
      ('Name recognition pilot','10,000 documents',f(dict(counts).get('PER',0))+' detected person-name occurrences in '+f(name_docs)+' documents. Occurrences are not unique people.'),
      ('Parsing and inflection','1,000 quote-bearing + 1,000 person-bearing sentences','Samples overlap; saved token lemmas and sentence structure.'),
      ('Duplicate signatures',f(mh['unique_texts'])+' distinct cleaned texts','Signatures cover all documents. Near-duplicate families have not yet been constructed.'),
      ('LLM pilot','300 passages × 2 models × 2 processing modes','All benchmark runs finished. Some answers failed automatic acceptance rules. No model passed the scale-up gate.')]
    sections.extend('<tr>'+''.join('<td>'+html.escape(c)+'</td>' for c in row)+'</tr>' for row in work);sections.append('</table>')
    sections.append('<h2>First results you can inspect now</h2>')
    sections.append('<p>The corpus contains '+f(profile['characters'])+' cleaned characters. There are '+f(out['exact_repeat_rows'])+' rows beyond one representative of each exact cleaned text. This is a duplication count, not proof of copying between outlets.</p>')
    sections.append('<table><tr><th>Platform</th><th>Corpus documents</th><th>Documents with ≥300 characters</th></tr>')
    platforms=collections.defaultdict(lambda:[0,0])
    for r in profile['strata']:
        platforms[r['platform']][0]+=r['documents'];platforms[r['platform']][1]+=r['eligible_speech_documents']
    sections.extend(f'<tr><td>{html.escape(p)}</td><td>{f(n)}</td><td>{f(e)}</td></tr>' for p,(n,e) in sorted(platforms.items()));sections.append('</table>')
    morph=parse['benchmarks']['morphology'];aligned=sum(r['aligned_mentions'] or 0 for r in morph);changed=sum(r['changed_mentions'] or 0 for r in morph)
    sections.append(f'<p>In the morphology sample, {f(changed)} of {f(aligned)} aligned person-name occurrences differed from the model lemma ({changed/aligned:.1%}). This is model-derived inflection variation, not validated identity merging.</p>')
    sections.append('<h2>What “failure” means</h2><p>A passage result is a structured form: who speaks, what is said, its function, and a verbatim supporting excerpt. It is rejected if the form is incomplete, a required field is invalid, a quoted excerpt cannot be found literally, an identity is unsupported, or generation does not finish. One retry is allowed. A rejected whole form can contain useful or correct pieces. An accepted form can still be semantically wrong. These are not accuracy scores.</p>')
    sections.append('<table><tr><th>Model, four concurrent requests</th><th>Valid first JSON</th><th>Accepted after retry</th><th>Seconds/passage</th></tr>')
    for r in llm['results']:
        if r['mode']=='parallel4':sections.append(f"<tr><td>{r['model']}</td><td>{r['json_valid_rate']:.1%}</td><td>{r['processed']-r['failed']}/{r['processed']}</td><td>{r['effective_seconds_per_passage']:.1f}</td></tr>")
    sections.append('</table><p>Scale-up targets were ≥97% valid JSON and ≤4 seconds per passage. Neither configuration passed. The raw outputs and all rejection reasons are preserved.</p>')
    sections.append('<h2>Why the checks rejected outputs</h2>')
    for d in diagnostics:
        if d['mode']!='parallel4':continue
        t=d['totals'];sections.append(f"<p><b>{d['model']}:</b> {t.get('invalid_json_calls',0)} invalid JSON replies across first attempts and retries; {t.get('invalid_json_with_output_limit',0)} ended at the configured output limit. Evidence-mismatch classifications across all attempts: {html.escape(json.dumps(d['evidence_mismatch_spans']))}.</p>")
    sections.append('<p>The output limit was 768 generated tokens, with a 2,048-token context. Limit-related failures implicate this pipeline configuration; they do not prove that a model cannot understand the text. Evidence normalization categories describe string differences, not whether an interpretation was right.</p>')
    sections.append('<h2>What is not done yet</h2><p>No full-corpus name-recognition run, canonical person identities, dated office linking, corpus-wide speaker labels, person/outlet networks, claim clusters, or final Croatian research report. The 2024 collection change forbids cross-era volume interpretations. YouTube analysis covers available text, not verified video speech.</p><p>Next: repair and version the passage coder, test on a small fixed set, then repeat necessary checks. Name detection and duplicate-signature work remain reusable. No job is running.</p>')
    page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Voices study — progress and pilot results</title><style>body{font:17px/1.55 system-ui,sans-serif;color:#202b35;max-width:1050px;margin:45px auto;padding:0 25px}h1,h2{color:#174e66}table{width:100%;border-collapse:collapse;margin:24px 0}td,th{padding:12px;border-bottom:1px solid #ced7df;text-align:left;vertical-align:top}th{background:#eaf1f5}p{max-width:95ch}</style><body>'+''.join(sections)+'</body></html>'
    (STUDY/'output/private/pilot_overview.html').write_text(page,encoding='utf-8')
    con.close()

if __name__=='__main__':main()
