"""Interruption/retry semantics using synthetic replies, no model or network."""
import contextlib,json,tempfile,unittest
from pathlib import Path
from unittest.mock import patch,Mock
import duckdb
import coded_calls as calls

class Persistence(unittest.TestCase):
    def harness(self,folder,reply):
        stack=contextlib.ExitStack()
        stack.enter_context(patch.object(calls,'workdir',lambda:folder))
        stack.enter_context(patch.object(calls,'gpu_lock',lambda:contextlib.nullcontext()))
        stack.enter_context(patch.object(calls.validation.old,'server',lambda:contextlib.nullcontext()))
        stack.enter_context(patch.object(calls.validation,'runtime',lambda model:dict(digest='synthetic',ollama_version='fixture')))
        stack.enter_context(patch.object(calls,'safe_call',reply))
        stack.enter_context(patch.object(calls.requests,'post',return_value=Mock()))
        return stack
    def row(self,item,name):return (item,name+' govori.','',None,json.dumps([dict(surface=name,entity_id='Q'+item)]))
    def success(self):return dict(seconds=.01,payload=dict(response='{"s":[]}',done_reason='stop'),errors=[],expanded=[])
    def test_transport_failure_remains_pending_but_completed_reply_is_reused(self):
        attempts={}
        def reply(model,bundle,attempt):
            name=bundle['candidates'][0]['surface'];attempts[name]=attempts.get(name,0)+1
            if name=='Ivo' and attempts[name]==1:return dict(transport=dict(type='ConnectionError',message='synthetic interruption'))
            return self.success()
        with tempfile.TemporaryDirectory() as directory:
            folder=Path(directory);path=folder/'fixture.duckdb';rows=[self.row('1','Ana'),self.row('2','Ivo')]
            with self.harness(folder,reply):
                con=duckdb.connect(str(path))
                with self.assertRaises(RuntimeError):calls.run_model(con,'fixture','qwen3:14b',rows)
                self.assertEqual(con.execute('SELECT count(*) FROM llm_calls').fetchone()[0],1)
                con.close()
                con=duckdb.connect(str(path));calls.run_model(con,'fixture','qwen3:14b',rows);calls.run_model(con,'fixture','qwen3:14b',rows)
                self.assertEqual(attempts,{'Ana':1,'Ivo':2})
                self.assertEqual(con.execute('SELECT count(*) FROM llm_calls').fetchone()[0],2)
                quality=calls.call_quality(con,'fixture','qwen3:14b')
                self.assertEqual(quality['transport_errors'],1);self.assertEqual(quality['grounding_failure_share'],0)
                con.close()
    def test_bad_received_reply_gets_only_one_retry_and_stays_in_denominator(self):
        attempts=[]
        def reply(model,bundle,attempt):
            attempts.append(attempt);result=self.success();result['errors']=['schema'];return result
        with tempfile.TemporaryDirectory() as directory:
            folder=Path(directory);con=duckdb.connect(str(folder/'fixture.duckdb'))
            with self.harness(folder,reply):
                rows=[self.row('1','Ana')]
                calls.run_model(con,'fixture','qwen3:14b',rows);calls.run_model(con,'fixture','qwen3:14b',rows)
                self.assertEqual(attempts,[0,1])
                self.assertEqual(calls.call_quality(con,'fixture','qwen3:14b')['grounding_failure_share'],1)
                self.assertEqual(calls.final_results(con,'fixture','qwen3:14b')['1']['errors'],['schema'])
            con.close()

if __name__=='__main__':unittest.main()
