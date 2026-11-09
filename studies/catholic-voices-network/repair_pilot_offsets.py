"""Archive initial pilot annotations with line-relative offsets; preserve all original rows."""
from voices_common import *
con=connect()
with transaction(con):
    for table in ('pilot_mentions','pilot_ner_docs'):
        archive=table+'_v1_line_relative_archive'
        exists=con.execute('SELECT count(*) FROM information_schema.tables WHERE table_name=?',[archive]).fetchone()[0]
        if not exists:
            con.execute(f'ALTER TABLE {table} RENAME TO {archive}')
    pin_stage(con,'offset_repair_20261025',dict(reason='Reldi line-relative offsets require monotonic full-text alignment',
      archived=True,recompute='NER pilot only; corpus and frozen sample unchanged'))
con.execute('CHECKPOINT'); con.close()
print('Initial pilot annotations archived; corrected pilot will reuse the frozen sample.')
