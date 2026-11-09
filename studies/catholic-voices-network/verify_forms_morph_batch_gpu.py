"""Offline GPU parity on saved standard forms and actual nonstandard contexts.

Must run with the identity writer/supervisor stopped. No corpus text or model
word outputs are printed/exported. Neither form records nor their gates change.
"""
import gc
import hashlib
import json
import time
import classla
import torch
import forms_bulk
from forms_morph_batch import LookaheadPipeline,BATCH_SIZE
from morphology_batch import fingerprint
import voices_common as common

reference=forms_bulk.reference


def run_sample(pipeline,rows):
    results={};fingerprints=[]
    for key,stripped,raw in rows:
        details=[];lemmas=[]
        for example in json.loads(raw):
            document=reference.ner.align_document_offsets(pipeline(example['text']),example['text'])
            fingerprints.append(fingerprint(document))
            tokens=[]
            for sentence in document.sentences:
                for token in sentence.tokens:
                    if example['start']<=token.start_char<token.end_char<=example['end']:
                        tokens.append(token)
            aligned=bool(tokens and tokens[0].start_char==example['start'] and tokens[-1].end_char==example['end'])
            lemma=reference.clean_name(' '.join(word.lemma or word.text for token in tokens for word in token.words)) if aligned else None
            details.append(dict(doc_id=example['doc_id'],aligned=aligned,lemma=lemma))
            if lemma:lemmas.append(lemma)
        unique={value.casefold():value for value in lemmas}
        status='agreed' if len(unique)==1 and len(lemmas)==len(details) else 'ambiguous' if len(unique)>1 else 'unaligned'
        nominative=next(iter(unique.values())) if status=='agreed' else stripped
        results[key]=(nominative,status,details)
    return results,fingerprints


def main():
    output=common.workdir()/'forms_morph_batch_parity.json'
    con=common.connect()
    pinned=con.execute("SELECT settings_json FROM stage_settings WHERE stage='forms_morph_batch_v1'").fetchone()
    if pinned:
        assert common.file_sha(output)==json.loads(pinned[0])['proof_sha256']
        con.close();print(json.dumps(dict(cached=True,proof_sha256=common.file_sha(output))));return
    settings_hash,settings_json=con.execute("SELECT settings_hash,settings_json FROM stage_settings WHERE stage='forms_v1'").fetchone()
    assert json.loads(settings_json)['code']==common.file_sha(reference.__file__)
    samples={
      'standard':con.execute('''SELECT f.form_id,f.stripped,f.examples_json FROM forms f
        JOIN form_lemmas l USING(form_id) WHERE f.model_type='standard' ORDER BY f.form_id LIMIT 500''').fetchall(),
      'nonstandard':con.execute('''SELECT f.form_id,f.stripped,f.examples_json FROM forms f
        WHERE f.model_type='nonstandard' ORDER BY f.form_id LIMIT 500''').fetchall(),
    }
    assert all(len(rows)==500 for rows in samples.values())
    expected_stored={key:(name,status,json.loads(details)) for key,name,status,details in con.execute(
      'SELECT form_id,nominative,status,details_json FROM form_lemmas WHERE form_id IN (SELECT unnest(?))',
      [[row[0] for row in samples['standard']]]).fetchall()}
    assert len(expected_stored)==500
    completed=con.execute('SELECT count(*) FROM form_lemmas').fetchone()[0]
    prepared=con.execute('SELECT count(*) FROM form_docs').fetchone()[0]
    assert prepared==common.MANIFEST['corpus']['rows']
    con.close()
    torch.set_num_threads(4)
    assert torch.cuda.is_available()
    results={}
    with common.gpu_lock():
        common.ensure_ollama_idle()
        for kind,rows in samples.items():
            print(common.utc(),kind,'GPU serial parity baseline started; 500 actual forms',flush=True)
            pipeline=classla.Pipeline('hr',type=kind,processors='tokenize,pos,lemma',use_gpu=True,verbose=False)
            torch.cuda.synchronize();started=time.perf_counter()
            original,original_fingerprints=run_sample(pipeline,rows)
            torch.cuda.synchronize();serial_seconds=time.perf_counter()-started
            matches_stored=original==expected_stored if kind=='standard' else None
            if kind=='standard':assert matches_stored,'Serial baseline differs from committed standard forms'
            print(common.utc(),kind,'serial baseline finished; testing look-ahead batches',flush=True)
            texts=(example['text'] for _,_,raw in rows for example in json.loads(raw))
            wrapper=LookaheadPipeline(pipeline,texts)
            torch.cuda.synchronize();started=time.perf_counter()
            batched,batched_fingerprints=run_sample(wrapper,rows)
            torch.cuda.synchronize();batch_seconds=time.perf_counter()-started
            result=dict(forms=len(rows),contexts=len(original_fingerprints),
              serial_seconds=serial_seconds,batch_seconds=batch_seconds,speedup=serial_seconds/batch_seconds,
              identical_tokens_tags_lemmas_offsets=original_fingerprints==batched_fingerprints,
              identical_form_results=original==batched,identical_to_committed=matches_stored,
              serial_output_sha256=hashlib.sha256(json.dumps(original,sort_keys=True,ensure_ascii=False).encode()).hexdigest(),
              batched_output_sha256=hashlib.sha256(json.dumps(batched,sort_keys=True,ensure_ascii=False).encode()).hexdigest())
            results[kind]=result
            print(common.utc(),kind,json.dumps(result),flush=True)
            if not (result['identical_tokens_tags_lemmas_offsets'] and result['identical_form_results']):
                common.atomic_json(common.workdir()/'forms_morph_batch_failure.json',dict(created_utc=common.utc(),models=results,passed=False))
                raise RuntimeError('GPU batching parity failed; do not switch production')
            del wrapper,pipeline;gc.collect();torch.cuda.empty_cache()
    proof=dict(created_utc=common.utc(),passed=True,corpus_sha256=common.CORPUS_HASH,config_hash=common.CONFIG_HASH,
      wrapper_sha256=common.file_sha(common.STUDY/'forms_morph_batch.py'),
      batch_code_sha256=common.file_sha(common.STUDY/'morphology_batch.py'),
      reference_sha256=common.file_sha(reference.__file__),verifier_sha256=common.file_sha(__file__),
      forms_stage_settings_hash=settings_hash,batch_size=BATCH_SIZE,models=results,
      committed_standard_forms_verified=500,committed_form_lemmas=completed,prepared_documents=prepared,
      torch_version=torch.__version__,gpu=torch.cuda.get_device_name(),
      caveat='Sampled execution parity and local timing, not recognition/nominative/identity accuracy or a guarantee for every untested context.')
    common.atomic_json(output,proof)
    print('GPU parity passed for both variants; proof saved. No form result was modified.',flush=True)


if __name__=='__main__':main()
