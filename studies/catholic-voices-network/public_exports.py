"""Narrow disclosure rules for derived public identity maps and graph edges."""
import re
from name_forms import clean_name


def safe_alias(surface):
    # An alias is a short name form, never a passage/account/URL. Ambiguous
    # morphology and weak-count aliases are separately excluded by the query.
    cleaned=clean_name(surface)
    words=cleaned.split()
    word=r"[^\W\d_]+(?:[’'\-][^\W\d_]+)*\.?"
    return bool(2<=len(words)<=5 and len(surface)<=100 and
      re.fullmatch(word+r'(?: '+word+r'){1,4}',cleaned,re.UNICODE))


def public_edges(network,allowed):
    edges=[]
    for row in network['edges']:
        if row['from'] not in allowed or row['to'] not in allowed:raise ValueError('Network contains non-D6 identity')
        if row['shared_contexts']<5:continue
        documents=row.get('independent_documents')
        if documents is not None and documents<5:continue
        if not row['display']:continue
        edges.append(dict(from_qid=row['from'],to_qid=row['to'],shared_contexts=row['shared_contexts'],
          independent_documents=documents))
    return sorted(edges,key=lambda r:(r['from_qid'],r['to_qid']))


def office_in_period(row):
    # Preserve actual bounds; unknown starts are not dated office records.
    return bool(row['date_usable'] and row['start_latest'] and
      row['start_earliest']<='2026-12-31' and
      (not row['end_latest'] or row['end_latest']>='2021-01-01') and
      int(row['start_latest'][:4])>=2021-110)
