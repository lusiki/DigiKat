"""Exercise the full report on isolated synthetic analysis results, never delivery data."""
import json
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock
import pandas as pd
import test_analysis
import build_report as b
from prepare import OUT as actual_out

root=Path('tmp/pdfs').resolve();root.mkdir(parents=True,exist_ok=True)
out=Path(tempfile.mkdtemp(prefix='theological-v2-full-layout-',dir=root))
manager=MagicMock();manager.__enter__.return_value=str(out)
with patch.object(test_analysis.tempfile,'TemporaryDirectory',return_value=manager):
    test_analysis.AnalysisTest().test_uncertainty_partial_and_missing_sources_have_distinct_bases()
for name in ['frame_month.csv','sample_allocation.csv','frame_language.csv','frame_location.csv']:
    (out/'tables'/name).write_bytes((actual_out/'tables'/name).read_bytes())
frame=json.loads((actual_out/'freeze.json').read_text(encoding='utf-8'))
d=json.loads((out/'report_data.json').read_text(encoding='utf-8'))
d['frame']=frame;d.pop('report_policy',None)
d['reuse']={'eligible_publications':250000,'publications_in_repeated_families':80000,'publications_in_cross_outlet_families':35000}
(out/'report_data.json').write_text(json.dumps(d,ensure_ascii=False),encoding='utf-8')
(out/'coder_freeze.json').write_text(json.dumps({'config_hash':'synthetic'}),encoding='utf-8')
fixture=Path('tmp/pdfs/theological-v2-limited-layout')
for name in ['development_review.json','challenge_disagreements.json']:
    (out/name).write_bytes((fixture/name).read_bytes())
b.OUT=out;b.REPORT=out;b.FIG=out/'figures';b.PNG=out/'pages';b.CFG={**b.CFG,'sample_size':6}
original=b.Report
class SyntheticReport(original):
    def new(self,kicker,title,deck=''):super().new('SINTETSKI TEST / '+kicker,title,deck)
    def finish(self):
        self.c.setTitle('SYNTHETIC FULL LAYOUT — NOT THE REPORT')
        super().finish()
b.Report=SyntheticReport
b.build()
(out/'tko-dobiva-rijec-o-vjeri-v2.pdf').rename(out/'SYNTHETIC-layout-test.pdf')
print('Synthetic layout directory:',out)
