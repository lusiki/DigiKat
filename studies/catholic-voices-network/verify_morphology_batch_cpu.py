"""Constructed CPU-only batching preflight; never opens the actual database."""
import os
os.environ['CUDA_VISIBLE_DEVICES']=''
import gc
import importlib
import json
import time
import classla
import torch
from morphology_batch import analyze_contexts,fingerprint
from voices_common import STUDY,atomic_json,file_sha,utc

ner=importlib.import_module('02_pilot_ner')


def main():
    torch.set_num_threads(2)
    examples=[
      'Biskup Ivan Marić govorio je o pomoći susjedima.',
      'S Anom Šimić razgovarali smo nakon susreta. Ona je odgovorila.',
      '„Ovo je važan razgovor”, rekao je mons. Dražen Kutleša.',
      'Predavanje Josipa Bozanića najavljeno je za sutra.',
      'Petar, Ivan i Marija dolaze u Zagreb; fra Marko ostaje.',
      'PAPA FRANJO: „Budimo blizu jedni drugima!”',
      'Čćžšđ — Ana-Maria i Ivo Horvat, prof. dr. Jurić.',
      'Uvod.\n\nNadbiskup Tomo Vukšić govori.\n\nDrugi odlomak.',
    ]
    texts=[text+f' To je primjer broj {i}.' for i in range(8) for text in examples]
    results=[]
    for kind in ['standard','nonstandard']:
        print(utc(),kind,'CPU batching preflight started',flush=True)
        pipeline=classla.Pipeline('hr',type=kind,processors='tokenize,pos,lemma',use_gpu=False,verbose=False)
        started=time.perf_counter()
        expected=[fingerprint(ner.align_document_offsets(pipeline(text),text)) for text in texts]
        serial=time.perf_counter()-started
        timings={}
        for size in [8,16,32]:
            started=time.perf_counter();actual=[]
            for offset in range(0,len(texts),size):
                batch=texts[offset:offset+size]
                documents=analyze_contexts(pipeline,batch)
                actual.extend(fingerprint(ner.align_document_offsets(doc,text)) for doc,text in zip(documents,batch))
            timings[str(size)]=time.perf_counter()-started
            assert actual==expected,(kind,size,'Token/POS/lemma/offset outputs changed')
        results.append(dict(model_type=kind,contexts=len(texts),identical=True,
                            serial_seconds=serial,batch_seconds=timings))
        print(utc(),kind,'all CPU output comparisons identical',flush=True)
        del pipeline;gc.collect()
    result=dict(created_utc=utc(),scope='constructed CPU-only preflight, not production authorization or accuracy validation',
                passed=True,batch_code_sha256=file_sha(STUDY/'morphology_batch.py'),models=results)
    atomic_json(STUDY/'output/private/morphology_batch_cpu.json',result)
    print(json.dumps(result))


if __name__=='__main__':main()
