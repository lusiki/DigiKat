"""Conservative temporal plausibility filter; raw office facts stay unchanged."""
from office_register import holder as unbounded_holder

MAX_TENURE_YEARS=110

def holder(rows,office_qid,date,place_qid=None):
    # A missing end on a medieval record must not imply possible incumbency for
    # centuries. This explicit machine plausibility assumption is not a new end
    # date. Unknown starts and competing recent incumbencies remain ambiguous.
    cutoff_year=int(date[:4])-MAX_TENURE_YEARS
    plausible=[row for row in rows if not row['start_latest'] or
               int(row['start_latest'][:4])>=cutoff_year]
    return unbounded_holder(plausible,office_qid,date,place_qid)
