"""Private exact-output qualification of the compact dependency decoder stack.

Requires exclusive runner lock and idle GPU. No corpus text is printed.
Original qualification files and study result tables are never changed.
"""
import gc
import json
import time

import classla
import duckdb
import numpy as np
import torch

import dependency_memory as memory
from dependency_memory_parallel import MemorySafeDependencyPipeline
import rules_memory_safe as adapter
import rules_parallel_standard as original
from verify_rules_parallel_standard import digest
import voices_common as common


def read_rows(con, ids):
    return con.execute('''SELECT s.item_id,s.text,s.start_char,d.text_clean,
        s.mentions_json,s.author_qid,r.status,r.parsed_json,r.statements_json,r.first_person_signal
        FROM candidate_sentences s JOIN docs d USING(doc_id)
        LEFT JOIN rule_sentence_results r USING(item_id)
        WHERE s.item_id IN (SELECT unnest(?)) ORDER BY s.item_id''',[ids]).fetchall()


def run_rows(rows, pipeline, label):
    results, documents = [], []
    def recorded(text):
        doc = pipeline(text)
        documents.append(digest(doc.to_dict()))
        return doc
    for index, row in enumerate(rows, 1):
        _, text, base, full, raw, author, *_ = row
        results.append(original.reference.execute_sentence(recorded,text,base,full,json.loads(raw),author))
        if index % 250 == 0:
            print(common.utc(),label,index,'/',len(rows),flush=True)
    return results, documents


def main():
    proof_path = common.workdir()/'rules_memory_safe_parity.json'
    if proof_path.exists():
        raise RuntimeError('Qualification already exists; preserve it')
    memory.verify_reference()
    con = duckdb.connect(str(common.workdir()/'voices.duckdb'),read_only=True)
    try:
        fixed = [r[0] for r in con.execute("""SELECT item_id FROM candidate_sentences
            WHERE needs_parse AND platform='web' ORDER BY item_id LIMIT 2000""").fetchall()]
        largest = [r[0] for r in con.execute("""SELECT s.item_id FROM candidate_sentences s
            JOIN rule_sentence_results r USING(item_id) WHERE s.platform='web' AND r.status='complete'
            ORDER BY length(s.text) DESC,s.item_id LIMIT 10""").fetchall()]
        nonstandard = [r[0] for r in con.execute("""SELECT item_id FROM candidate_sentences
            WHERE needs_parse AND platform<>'web' ORDER BY item_id LIMIT 50""").fetchall()]
        rows = read_rows(con,sorted(set(fixed+largest)))
        other = read_rows(con,nonstandard)
        trigger = read_rows(con,['DK0211188:s27'])
        assert len(fixed)==2000 and len(largest)==10 and len(other)==50 and len(trigger)==1
        assert all(r[6]=='complete' for r in rows)
        assert trigger[0][6] is None
    finally:
        con.close()
    proof = dict(created_utc=common.utc(),corpus_sha256=common.CORPUS_HASH,
        config_hash=common.CONFIG_HASH,passed=False,status='starting',
        source_hashes=adapter.source_hashes(),reference_decoder_sha256=memory.verify_reference(),
        original_parallel_proof_sha256=common.file_sha(common.workdir()/'rules_parallel_standard_parity.json'),
        fixed_standard_sentences=len(fixed),largest_completed_standard_sentences=len(largest),
        fixed_nonstandard_sentences=len(other),standard_unique_sentences=len(rows),
        sample_sha256=digest([r[0] for r in rows]),nonstandard_sample_sha256=digest(nonstandard),
        selection='First 2000 needed standard IDs plus 10 longest completed standard inputs; first 50 needed nonstandard IDs',
        scope='Exact-output and memory recovery qualification; no speed threshold or semantic accuracy claim')
    common.atomic_json(proof_path,proof)
    torch.set_num_threads(4)
    outputs, documents = {}, {}
    try:
        with common.gpu_lock():
            common.ensure_ollama_idle()
            for kind, sample in (('standard',rows),('nonstandard',other)):
                for mode in ('reference','compact'):
                    memory.restore()
                    started=time.perf_counter()
                    if mode=='compact' and kind=='standard':
                        pipeline=MemorySafeDependencyPipeline((r[1] for r in sample),kind)
                    else:
                        if mode=='compact':memory.install()
                        pipeline=classla.Pipeline('hr',type=kind,
                            processors='tokenize,pos,lemma,depparse',use_gpu=True,verbose=False)
                    try:
                        key=kind+'_'+mode
                        outputs[key],documents[key]=run_rows(sample,pipeline,key)
                    finally:
                        if isinstance(pipeline,MemorySafeDependencyPipeline):pipeline.close()
                        del pipeline
                        gc.collect();torch.cuda.empty_cache();memory.restore()
                    proof[key+'_seconds']=time.perf_counter()-started
                    proof[key+'_result_sha256']=digest(outputs[key])
                    proof[key+'_documents_sha256']=digest(documents[key])
                    proof['status']=key+'_complete'
                    common.atomic_json(proof_path,proof)
                    print(common.utc(),key,'complete',flush=True)
            proof['identical_full_results']=all(outputs[k+'_reference']==outputs[k+'_compact'] for k in ('standard','nonstandard'))
            proof['identical_classla_documents']=all(documents[k+'_reference']==documents[k+'_compact'] for k in ('standard','nonstandard'))
            committed=[(json.loads(r[7]),json.loads(r[8]),r[9]) for r in rows]
            proof['identical_to_committed']=outputs['standard_reference']==committed
            if not all(proof[k] for k in ('identical_full_results','identical_classla_documents','identical_to_committed')):
                raise RuntimeError('Decoder parity failed')
            memory.install()
            pipeline=classla.Pipeline('hr',type='standard',
                processors='tokenize,pos,lemma,depparse',use_gpu=True,verbose=False)
            from classla.models.depparse import trainer
            original_one_root=trainer.chuliu_edmonds_one_root
            captured=[]
            def capture(scores):
                target=common.workdir()/('large_dependency_scores_'+str(len(captured))+'.npy')
                if target.exists():raise RuntimeError('Preserve previous decoder score capture')
                np.save(target,scores)
                captured.append(dict(path=target.name,shape=list(scores.shape),sha256=common.file_sha(target)))
                return original_one_root(scores)
            trainer.chuliu_edmonds_one_root=capture
            started=time.perf_counter()
            try:
                result,raw=run_rows(trigger,pipeline,'large_input')
            finally:
                trainer.chuliu_edmonds_one_root=original_one_root
                del pipeline
                gc.collect();torch.cuda.empty_cache();memory.restore()
            tokens=result[0][0]
            sentence_text=trigger[0][1]
            bad=sum(not 0 <= t['start'] < t['end'] <= len(sentence_text)
                    or sentence_text[t['start']:t['end']]!=t['surface'] for t in tokens)
            proof['large_sentence']=dict(item_id=trigger[0][0],characters=len(trigger[0][1]),
                seconds=time.perf_counter()-started,tokens=len(tokens),bad_literal_offsets=bad,
                result_sha256=digest(result),documents_sha256=digest(raw),captured_scores=captured,
                passed=len(tokens)==4380 and bad==0 and len(captured)==1,
                caveat='Original full decoder could not complete safely on this input; operation-equivalence and separate exact-output qualification support the compact-stack repair.')
            common.atomic_json(common.workdir()/'large_dependency_probe_result.json',
                dict(item_id=trigger[0][0],results=result,document_digests=raw))
        proof.update(passed=proof['large_sentence']['passed'],status='complete',finished_utc=common.utc())
        common.atomic_json(proof_path,proof)
        print(json.dumps(proof),flush=True)
        if not proof['passed']:raise RuntimeError('Large input probe failed')
    except BaseException as exc:
        proof.update(passed=False,status='failed',error_type=type(exc).__name__,error=str(exc)[:1000])
        common.atomic_json(proof_path,proof)
        raise
    finally:
        memory.restore()


if __name__=='__main__':main()
