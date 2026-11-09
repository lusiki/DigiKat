"""Checkpoint-aware entry point; immutable NER v1 engine is byte-preserved.

Export completed constructed-case diagnostics and run bounded v5 checks before
the long GPU phase. The original implementation hash remains checked by
10_ner_v1.main(). Coder failure does not cancel the independent NER stage.
"""
import importlib,subprocess,sys
from diagnose_coder_checks import main as diagnose
from voices_common import STUDY,workdir,atomic_json,utc,CORPUS_HASH,CONFIG_HASH

if __name__=='__main__':
    diagnose()
    if '--limit' not in sys.argv and '--retry-failed' not in sys.argv:
        outcomes=[]
        for model in ['qwen3:14b','qwen3:8b','gemma3:12b']:
            result=subprocess.run([sys.executable,'-u',str(STUDY/'44_validate_coder_v5.py'),'--model',model])
            outcomes.append(dict(model=model,exit_code=result.returncode))
            atomic_json(workdir()/'v5_constructed_checks_checkpoint.json',dict(created_utc=utc(),
              corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,outcomes=outcomes,
              note='Bounded constructed checks only; semantic failure does not block independent name detection.'))
        diagnose()
        # This summary is a publication restriction, not a prerequisite for the
        # independent name-detection pass. A missing diagnostic remains visible
        # in its exit status/log and must be resolved before final reporting.
        subprocess.run([sys.executable,'-u',str(STUDY/'47_model_gate_summary.py')])
    importlib.import_module('10_ner_v1').main()
