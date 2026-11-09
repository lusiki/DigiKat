import importlib,json,unittest,duckdb
audit=importlib.import_module('71_publication_audit')
protocol=importlib.import_module('coder_protocol_v4')

class BenchmarkAudit(unittest.TestCase):
    def test_raw_reconstruction_counts_retry_and_rejects_corruption(self):
        con=duckdb.connect()
        con.execute('CREATE TABLE pilot_llm_sample(item_id VARCHAR)')
        con.execute('CREATE TABLE pilot_window_candidates(item_id VARCHAR,text VARCHAR,author VARCHAR,mentions_json VARCHAR)')
        con.execute('CREATE TABLE coder_check_calls(run VARCHAR,item_id VARCHAR,attempt INTEGER,response_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR)')
        con.execute('CREATE TABLE coder_check_batches(run VARCHAR,seconds DOUBLE,calls INTEGER)')
        run='benchmark_v4_qwen3_14b';bundle=protocol.prepare('Konstruirani tekst.',None,[])
        for item in ['a','b']:
            con.execute('INSERT INTO pilot_llm_sample VALUES (?)',[item])
            con.execute('INSERT INTO pilot_window_candidates VALUES (?,?,?,?)',[item,'Konstruirani tekst.',None,'[]'])
        for item,attempt,raw in [('a',0,'not JSON'),('a',1,'{"s":[]}'),('b',0,'{"s":[]}')]:
            value,errors=protocol.validate(raw,bundle)
            result=dict(payload=dict(response=raw,done_reason='stop'),errors=errors,expanded=protocol.expand(value,bundle) if not errors else [])
            con.execute('INSERT INTO coder_check_calls VALUES (?,?,?,?,?,?)',[run,item,attempt,json.dumps(result),audit.CORPUS_HASH,audit.CONFIG_HASH])
        con.execute('INSERT INTO coder_check_batches VALUES (?,6,3)',[run])
        gate=dict(configurations=[dict(protocol='v4',model='qwen3:14b',benchmark=dict(n=2,completed=2,calls=3,
          json_valid_first=.5,mechanically_accepted_first=.5,final_failed=0,unfinished=0,effective_seconds_per_window=3))])
        result=audit.reconcile_benchmarks(con,gate)[0]
        self.assertEqual(result['calls'],3);self.assertEqual(result['mechanical_failures'],1)
        self.assertEqual(result['final_failed_windows'],0)
        gate['configurations'][0]['benchmark']['calls']=2
        with self.assertRaisesRegex(RuntimeError,'differs from database'):audit.reconcile_benchmarks(con,gate)
        gate['configurations'][0]['benchmark']['calls']=3
        con.execute("UPDATE coder_check_calls SET response_json=? WHERE item_id='a' AND attempt=1",[json.dumps(dict(payload=dict(response='{"s":[]}',done_reason='stop'),errors=['json'],expanded=[]))])
        with self.assertRaisesRegex(RuntimeError,'reconstruction mismatch'):audit.reconcile_benchmarks(con,gate)
        con.close()

if __name__=='__main__':unittest.main()
