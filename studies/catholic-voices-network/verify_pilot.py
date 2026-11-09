"""Machine checks on completed pilot output. Never reports recognition accuracy."""
from voices_common import *
con=connect()
expected=CONFIG['ner_pilot_documents']
assert con.execute('SELECT count(*) FROM pilot_sample').fetchone()[0]==expected
assert con.execute("SELECT count(*) FROM pilot_ner_docs WHERE status='complete'").fetchone()[0]==expected
assert con.execute("SELECT count(*) FROM pilot_ner_docs WHERE status<>'complete'").fetchone()[0]==0
assert con.execute('''SELECT count(*) FROM pilot_mentions m JOIN docs d USING(doc_id)
  WHERE start_char<0 OR end_char<=start_char OR end_char>d.n_chars
    OR substr(d.text_clean,start_char+1,end_char-start_char)<>surface''').fetchone()[0]==0
assert con.execute('''SELECT count(*) FROM pilot_ner_docs r LEFT JOIN
  (SELECT doc_id,count(*) AS n FROM pilot_mentions WHERE type='PER' GROUP BY doc_id) m USING(doc_id)
  WHERE r.person_spans<>coalesce(m.n,0)''').fetchone()[0]==0
atomic_json(workdir()/'pilot_ner_checks.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
    config_hash=CONFIG_HASH,documents=expected,status='passed',checks=['sample_coverage','no_failed_documents',
    'verbatim_offset_grounding','person_span_count_reconciliation'],accuracy='unmeasured'))
con.close()
print('PASS: all pilot documents complete; spans grounded and counts reconciled. Recognition accuracy remains unmeasured.')
