"""Identity-free baseline denominators; no cross-era volume interpretation."""
from voices_common import *

def main():
    con=connect()
    rows=con.execute('''SELECT platform,era,count(*) AS documents,sum(n_chars) AS characters,
      count(*) FILTER (WHERE n_chars>=300) AS eligible_speech_documents,
      count(*) FILTER (WHERE n_chars=0) AS empty_documents,
      median(n_chars) AS median_characters
      FROM docs GROUP BY platform,era ORDER BY platform,era''').fetchall()
    fields=['platform','era','documents','characters','eligible_speech_documents','empty_documents','median_characters']
    result=[]
    for row in rows:
        item=dict(zip(fields,row))
        item['speech_eligible_share']=item['eligible_speech_documents']/item['documents']
        # Complementary counts are not printed; rare empty cells are suppressed.
        if 0<item['empty_documents']<5: item['empty_documents']=None
        result.append(item)
    out=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      documents=sum(r['documents'] for r in result),characters=sum(r['characters'] for r in result),
      speech_min_characters=300,strata=result,human_validation=False,
      caveat='Collection changed on 2024-01-01; cross-era volume comparisons are not valid. YouTube text is available text, not verified video speech.')
    atomic_json(workdir()/'corpus_profile.json',out)
    print(json.dumps({k:out[k] for k in ['documents','characters','speech_min_characters']}))
    con.close()

if __name__=='__main__': main()
