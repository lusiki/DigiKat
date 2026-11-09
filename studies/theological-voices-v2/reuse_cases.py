"""Purposeful exact-text examples from frozen metadata, with no semantic coding."""
import json
import pandas as pd
from prepare import OUT, save_json, file_sha


def select_cases(frame):
    eligible=frame[frame.text_length>=1000].copy()
    eligible['day']=pd.to_datetime(eligible.published_at).dt.normalize()
    families=eligible.groupby('text_hash').agg(publications=('publication_id','size'),
        outlets=('outlet_id','nunique'),first=('day','min'),last=('day','max'))
    families['span_days']=(families['last']-families['first']).dt.days
    # A few outlets keep illustrations readable; no ranking or prevalence inference.
    families=families[families.outlets.between(3,5)].sort_index()
    cases=[]
    for kind,pool in [('same_day',families[families.span_days==0]),
                      ('separated_dates',families[families.span_days>0])]:
        if pool.empty:continue
        text_hash=pool.index[0];family=pool.iloc[0]
        members=eligible[eligible.text_hash==text_hash].sort_values(['day','publication_id'])
        chosen=[members.iloc[0]]
        if kind=='separated_dates':chosen.append(members.iloc[-1])
        for _,row in members.iterrows():
            if row.outlet_id not in {r.outlet_id for r in chosen}:chosen.append(row)
            if len(chosen)>=4:break
        fields=['publication_id','outlet_id','outlet_name','published_at','title','url','text_hash','text_length']
        cases.append({'id':kind,'text_hash':text_hash,'publications':int(family.publications),
            'outlets':int(family.outlets),'first_date':str(family['first'].date()),
            'last_date':str(family['last'].date()),'span_days':int(family.span_days),
            'members':members[fields].to_dict('records'),
            'display_members':pd.DataFrame(chosen)[fields].to_dict('records'),
            'selection':'First lexicographic text hash among bodies >=1000 characters, 3-5 outlets; one same-calendar-day family and one with different recorded dates. An initial >=30-day screen found no eligible family; no long recurrence is asserted.',
            'limitation':'Identical archived cleaned bodies only; no live-page authenticity, origin, copying direction, or semantic topic claim. Purposeful examples, not a prevalence sample.'})
    return cases


def build(frame,out=OUT):
    cases=select_cases(frame)
    save_json(out/'deterministic_reuse_cases.json',{'selection_source_sha256':file_sha(__file__),
              'cases':cases,'method':'Exact existing text_hash groups in the frozen frame; no extra model readings.'})
    return cases


if __name__=='__main__':
    frame=pd.read_parquet(OUT/'frame.parquet',columns=['publication_id','text_length','text_hash','outlet_id','outlet_name','published_at','title','url'])
    cases=build(frame)
    print(json.dumps({'cases':[{'id':c['id'],'publications':c['publications'],'outlets':c['outlets'],'span_days':c['span_days']} for c in cases]}))
