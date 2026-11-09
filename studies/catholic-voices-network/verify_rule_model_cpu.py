"""CPU-only constructed preflight; never substitutes for the corpus/GPU gates."""
import os
os.environ['CUDA_VISIBLE_DEVICES'] = ''
import gc
import importlib
import importlib.metadata
import json
from pathlib import Path
import classla
import torch
from voices_common import atomic_json, file_sha, utc, STUDY


def main():
    torch.set_num_threads(2)
    rules = importlib.import_module('30_quote_rules')
    result = dict(created_utc=utc(), scope='constructed_cpu_preflight',
                  qualifies_publication=False, corpus_processed=False,
                  classla=importlib.metadata.version('classla'),
                  code_sha256=file_sha(STUDY / '30_quote_rules.py'),
                  rules_sha256=file_sha(STUDY / 'speech_rules.py'), models=[])
    destination = STUDY / 'output/private/rule_cpu_preflight.json'
    destination.parent.mkdir(parents=True, exist_ok=True)
    for kind in ['standard', 'nonstandard']:
        nlp = classla.Pipeline('hr', type=kind, processors='tokenize,pos,lemma,depparse',
                              use_gpu=False, verbose=False)
        text = 'Ivan Horvat je rekao: "Vjera traži odgovornost."'
        mention = dict(start=0, end=11, surface='Ivan Horvat', entity_id='SYNTHETIC_PERSON',
                       **{'class': 'contemporary', 'type': 'PER'})
        tokens, quoted, _ = rules.execute_sentence(nlp, text, 0, text, [mention], None)
        own = 'Molim svakoga jutra.'
        own_tokens, personal, _ = rules.execute_sentence(nlp, own, 0, own, [], 'SYNTHETIC_AUTHOR')
        passed = (any(r['entity_id'] == 'SYNTHETIC_PERSON' and r['mode'] == 'direct' for r in quoted)
                  and any(r['mode'] == 'first_person' for r in personal))
        result['models'].append(dict(model_type=kind, passed=passed, quote=quoted,
                                    first_person=personal, tokens=tokens, own_tokens=own_tokens))
        result['complete'] = len(result['models']) == 2
        result['passed'] = result['complete'] and all(m['passed'] for m in result['models'])
        atomic_json(destination, result)
        print(json.dumps(dict(model_type=kind, passed=passed)), flush=True)
        del nlp
        gc.collect()
    if not result['passed']:
        raise SystemExit('Constructed CPU preflight failed; inspect saved diagnostics')


if __name__ == '__main__':
    main()
