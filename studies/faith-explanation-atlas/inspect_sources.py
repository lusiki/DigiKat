import csv,json,pathlib,sys,unicodedata
import pyarrow.parquet as pq
sys.stdout.reconfigure(encoding='utf-8')
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/'studies/faith-explanation-atlas/output/private'
OUT.mkdir(parents=True,exist_ok=True)
B=ROOT/'studies/theological-voices-v2/output/private'
A=pathlib.Path('C:/Users/lsikic/Luka C/DigiKat_voices_work')
rows=list(csv.DictReader((B/'tables/voices.csv').open(encoding='utf-8-sig')))
def norm(s): return ''.join(c for c in unicodedata.normalize('NFD',s.lower()) if unicodedata.category(c)!='Mn')
if len(sys.argv)>1:
 ids=[int(i) for i in sys.argv[1:]]
 df=pq.read_table(B/'main_inputs.parquet').to_pandas().set_index('publication_id')
 for i in ids:
  r=rows[i]; print('\nROW',i,r['name'],r['publication_id'],r['outlet_name'],r['published_at'],r['role'],r['interprets_faith']);print('FULL TEXT',df.loc[r['publication_id'],'body_clean'])
else:
 for name in ['Franjo','Lav XIV','Kutleša','Bozanić','Hranić','Košić','Uzinić','Križić','Sente','Tomislav Pervan','Stojić','Tanjić','Vukman','Vučković','Grbeš','Matulić','Baloban','Markić','Vučetić','Lončar']:
  rs=[(i,r) for i,r in enumerate(rows) if norm(name) in norm(r['name']) and r['task_valid']=='True' and r['complete_article_base']=='True']
  print(name,len(rs),[(i,r['name'],r['interprets_faith'],r['published_at'],r['outlet_name'],r['title'][:70]) for i,r in rs[:18]])
 a=json.loads((A/'report_data.json').read_text(encoding='utf8'))
 print('NETWORK KEYS',a['evidence']['network_metrics'].keys())
 print('REGISTER KEYS',[(k,len(v) if isinstance(v,(list,dict)) else v) for k,v in json.loads((A/'office_register.json').read_text(encoding='utf8')).items()])
 print('CIRCULATION',a['values']['circulation_sizes'])
