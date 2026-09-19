"""Build the public aggregate release; never publish source records."""
import argparse
import calendar
from datetime import date, datetime, timezone
import hashlib
import json
from pathlib import Path
import duckdb
from multiplatform_collect import DEFAULT_WORK, quote, sha, write_json

LABELS = {"web":"Web", "facebook":"Facebook", "twitter":"Twitter / X", "forum":"Forumi",
          "youtube":"YouTube", "reddit":"Reddit", "comment":"Komentari", "tiktok":"TikTok",
          "instagram":"Instagram", "print":"Tisak", "radio":"Radio", "tv":"Televizija",
          "bluesky":"Bluesky", "threads":"Threads"}


def query_dicts(con, sql):
    result = con.execute(sql)
    names = [d[0] for d in result.description]
    return [dict(zip(names,row)) for row in result.fetchall()]


def release(work, destination):
    active = json.loads((work/"active.json").read_text(encoding="utf-8"))
    folder = Path(active["folder"])
    classification = json.loads((folder/"classification.json").read_text(encoding="utf-8"))
    decisions = Path(classification["folder"])
    complete = json.loads((decisions/"complete.json").read_text(encoding="utf-8"))
    assert complete["identity"]==classification["identity"]
    audit = json.loads((folder/"audit.json").read_text(encoding="utf-8"))
    contract = json.loads((work/"contract.json").read_text(encoding="utf-8"))
    destination.mkdir(parents=True,exist_ok=True)
    con = duckdb.connect()
    con.execute(f"CREATE VIEW den AS SELECT * FROM read_parquet({quote(folder/'denominator.parquet')})")
    con.execute(f"""CREATE VIEW decisions AS SELECT *,
      regexp_matches(route_set,'(^|;)(A1|B|C)(;|$)') AS included,
      regexp_matches(route_set,'(^|;)A1(;|$)') AS narrow
      FROM read_parquet({quote(decisions/'*.parquet')})""")
    n, unique_n = con.execute("SELECT count(*),count(DISTINCT record_key) FROM decisions").fetchone()
    assert n==unique_n==audit["candidate_records"], "Candidate/decision reconciliation failed"
    assert con.execute("SELECT sum(records),sum(eligible_records),sum(candidates) FROM den").fetchone()==(
        audit["unique_records"],audit["eligible_records"],audit["candidate_records"])
    con.execute("""CREATE TABLE monthly AS WITH platforms AS (SELECT DISTINCT platform FROM den),
      months AS (SELECT strftime(x,'%Y-%m') AS month FROM generate_series(
        (SELECT min(day)::DATE FROM den),(SELECT max(day)::DATE FROM den),INTERVAL 1 MONTH) t(x)),
      d AS (SELECT platform,month,sum(records) AS records,sum(eligible_records) AS eligible_records,
        sum(CASE WHEN text_basis='full_text' THEN eligible_records ELSE 0 END) AS full_text_records,
        sum(CASE WHEN text_basis='snippet' THEN eligible_records ELSE 0 END) AS snippet_records,
        sum(CASE WHEN text_basis='title' THEN eligible_records ELSE 0 END) AS title_records,
        count(DISTINCT day) AS observed_days FROM den GROUP BY 1,2),
      n AS (SELECT platform,month,count(*) FILTER(included) AS matching_records,
        count(*) FILTER(narrow) AS narrow_records,
        count(*) FILTER(narrow AND text_basis='full_text') AS full_text_narrow_records,
        count(*) FILTER(included AND text_basis='full_text') AS full_text_matches
        FROM decisions GROUP BY 1,2)
      SELECT p.platform,m.month,coalesce(d.records,0)::BIGINT AS records,
        coalesce(d.eligible_records,0)::BIGINT AS eligible_records,
        coalesce(d.full_text_records,0)::BIGINT AS full_text_records,
        coalesce(d.snippet_records,0)::BIGINT AS snippet_records,
        coalesce(d.title_records,0)::BIGINT AS title_records,
        coalesce(n.matching_records,0)::BIGINT AS matching_records,
        coalesce(n.narrow_records,0)::BIGINT AS narrow_records,
        coalesce(n.full_text_matches,0)::BIGINT AS full_text_matches,
        coalesce(n.full_text_narrow_records,0)::BIGINT AS full_text_narrow_records,
        coalesce(d.observed_days,0)::INTEGER AS observed_days,
        10000.0*n.matching_records/nullif(d.eligible_records,0) AS per_10000,
        10000.0*n.full_text_matches/nullif(d.full_text_records,0) AS full_text_per_10000
      FROM platforms p CROSS JOIN months m LEFT JOIN d USING(platform,month)
      LEFT JOIN n USING(platform,month) ORDER BY 1,2""")
    # A month with searchable records and no candidates has a measured zero.
    con.execute("UPDATE monthly SET per_10000=0 WHERE eligible_records>0 AND matching_records=0")
    con.execute("UPDATE monthly SET full_text_per_10000=0 WHERE full_text_records>0 AND full_text_matches=0")
    assert not con.execute("SELECT count(*) FROM monthly WHERE matching_records>eligible_records OR narrow_records>matching_records OR full_text_matches>full_text_records").fetchone()[0]
    tables = {
        "monthly":"SELECT * FROM monthly ORDER BY platform,month",
        "platforms":"""SELECT platform,sum(records)::BIGINT AS records,sum(eligible_records)::BIGINT AS eligible_records,
          sum(full_text_records)::BIGINT AS full_text_records,sum(snippet_records)::BIGINT AS snippet_records,
          sum(title_records)::BIGINT AS title_records,sum(matching_records)::BIGINT AS matching_records,
          sum(narrow_records)::BIGINT AS narrow_records,
          10000.0*sum(matching_records)/nullif(sum(eligible_records),0) AS per_10000,
          (SELECT min(day) FROM den d WHERE d.platform=m.platform) AS first_day,
          (SELECT max(day) FROM den d WHERE d.platform=m.platform) AS last_day,
          sum(observed_days)::BIGINT AS observed_days FROM monthly m GROUP BY platform ORDER BY matching_records DESC,platform""",
        "text_availability":"""SELECT platform,month,text_basis,sum(records)::BIGINT AS records,
          sum(eligible_records)::BIGINT AS eligible_records FROM den GROUP BY ALL ORDER BY 1,2,3""",
        "themes":"""SELECT platform,month,theme,count(DISTINCT record_key)::BIGINT AS matching_records
          FROM (SELECT platform,month,record_key,unnest(string_split(themes,';')) AS theme FROM decisions WHERE included)
          GROUP BY 1,2,3 ORDER BY 1,2,3""",
        "routes":"""SELECT platform,month,route,count(DISTINCT record_key)::BIGINT AS records
          FROM (SELECT platform,month,record_key,unnest(string_split(route_set,';')) AS route FROM decisions WHERE route_set<>'')
          GROUP BY 1,2,3 ORDER BY 1,2,3""",
    }
    for name,sql in tables.items():
        target = destination/f"{name}.csv"
        con.execute(f"COPY ({sql}) TO {quote(target)} (FORMAT CSV,HEADER TRUE)")
    platforms = query_dicts(con,tables["platforms"])
    total_matches,total_narrow = con.execute("SELECT sum(matching_records),sum(narrow_records) FROM monthly").fetchone()
    first_day,last_day = con.execute("SELECT min(day),max(day) FROM den").fetchone()
    review_dir = work.parent/"assistant_review_55_2026-09-19"
    summary = {"schema":"barometar-multiplatform-v1","synthetic":False,
        "status":"empirical","human_validation_complete":False,
        "edition":"2026-09-19-all-platforms-v1", "computed_at":datetime.now(timezone.utc).isoformat(),
        "data_from":first_day,"data_through":last_day,"raw_records":audit["raw_records"],
        "unique_records":audit["unique_records"],"duplicates_removed":audit["duplicates_removed"],
        "eligible_records":audit["eligible_records"],"candidate_records":audit["candidate_records"],
        "matching_records":int(total_matches),"narrow_records":int(total_narrow),
        "platform_count":len(platforms),"definition_version":contract["definition_version"],
        "text_policy":contract["policy"],"collection_break":"2024-04-01",
        "platform_labels":LABELS,"platforms":platforms,
        "assistant_review":{"n":55,"coder_type":"AI_assistant","human_validation":False,
          "scope":"earlier web-panel contexts; not a validation sample for this expanded edition",
          "labels_sha256":sha(review_dir/"assistant-coding-55.json")},
        "environment":json.loads((work/"environment.json").read_text(encoding="utf-8")),
        "provenance":{"source_bytes":active["identity"]["source_bytes"],
          "source_mtime_ns":active["identity"]["source_mtime_ns"],"extraction_signature":active["signature"],
          "contract_sha256":active["identity"]["contract_sha256"],
          "collector_sha256":active["identity"]["collector_sha256"],
          "adapter_sha256":classification["identity"]["adapter_sha256"],"release_builder_sha256":sha(__file__)}}
    write_json(destination/"summary.json",summary)
    method = Path("studies/demokrscanstvo-barometar/MULTIPLATFORM.md").read_text(encoding="utf-8")
    (destination/"README.md").write_text(method,encoding="utf-8")
    (destination/"definitions.json").write_bytes((work/"definitions.json").read_bytes())
    manifest = {"schema":summary["schema"],"edition":summary["edition"],"data_through":last_day,
      "synthetic":False,"human_validation_complete":False,
      "files":{name:sha(destination/name) for name in [*(n+".csv" for n in tables),"summary.json","definitions.json","README.md"]}}
    write_json(destination/"manifest.json",manifest)
    print(json.dumps({k:summary[k] for k in ("raw_records","unique_records","duplicates_removed","eligible_records","candidate_records","matching_records","narrow_records","platform_count","data_through")}),flush=True)
    con.close()


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--work",type=Path,default=DEFAULT_WORK)
    parser.add_argument("--destination",type=Path,default=Path("data/barometar/demokrscanstvo-multiplatform/v1"))
    args=parser.parse_args()
    release(args.work,args.destination)
