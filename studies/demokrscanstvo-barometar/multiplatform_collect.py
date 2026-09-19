"""Read-only all-platform extraction. Restricted records stay outside the repo.

Run from the repository root after multiplatform_prepare.R. Checkpoints are
bound to source size/mtime, retrieval contract and this script's SHA256.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import time
import duckdb

DEFAULT_DB = Path(r"C:/Users/lsikic/Luka C/DetermDB/determDB_merged.duckdb")
DEFAULT_WORK = Path(r"C:/Users/lsikic/Luka C/DigiKat_barometar_work/multiplatform-v1")


def quote(value):
    return "'" + str(value).replace("'", "''") + "'"


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write_json(path, value):
    partial = path.with_suffix(path.suffix + ".partial")
    partial.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    partial.replace(path)


def prepared_sql(table):
    # Unicode whitespace and letters keep short posts eligible without treating
    # blank/emoji-only captures as searchable language. Never strip diacritics.
    nonblank = lambda col: f"regexp_matches(coalesce({col},''), '[^\\s\\p{{Z}}]')"
    body = f"CASE WHEN {nonblank('FULL_TEXT')} THEN FULL_TEXT WHEN {nonblank('MENTION_SNIPPET')} THEN MENTION_SNIPPET ELSE '' END"
    basis = f"CASE WHEN {nonblank('FULL_TEXT')} THEN 'full_text' WHEN {nonblank('MENTION_SNIPPET')} THEN 'snippet' WHEN {nonblank('TITLE')} THEN 'title' ELSE 'none' END"
    # New IDs are namespaced by platform and collection. Old exports have no
    # item ID; only identical capture identities are collapsed. Parent URLs
    # alone are deliberately never used as identity.
    key = "CASE WHEN ITEM_ID IS NOT NULL THEN sha256(to_json(list_value(SOURCE_BATCH,SOURCE_TYPE,CAST(ITEM_ID AS VARCHAR)))) ELSE sha256(to_json(list_value(SOURCE_BATCH,SOURCE_TYPE,coalesce(\"FROM\",''),coalesce(URL,''),coalesce(\"DATE\",''),coalesce(\"TIME\",''),sha256(coalesce(TITLE,'')),sha256(coalesce(FULL_TEXT,'')),sha256(coalesce(MENTION_SNIPPET,''))))) END"
    return f"""SELECT rowid AS source_row, {key} AS record_key,
      try_cast(\"DATE\" AS DATE)::VARCHAR AS day, SOURCE_TYPE AS platform,
      SOURCE_BATCH AS source_batch, coalesce(\"FROM\",'') AS source_name,
      replace(coalesce(TITLE,''),chr(0),'�') AS TITLE,
      replace(({body}),chr(0),'�') AS FULL_TEXT, {basis} AS text_basis
      FROM {table}"""


def collect(db, work):
    work.mkdir(parents=True, exist_ok=True)
    contract = json.loads((work / "contract.json").read_text(encoding="utf-8"))
    stat = db.stat()
    identity = {"source_bytes": stat.st_size, "source_mtime_ns": stat.st_mtime_ns,
                "contract_sha256": sha(work / "contract.json"), "collector_sha256": sha(__file__),
                "duckdb_version": duckdb.__version__}
    signature = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()[:20]
    folder = work / signature
    folder.mkdir(exist_ok=True)
    write_json(work / "active.json", {"folder": str(folder), "identity": identity, "signature": signature})
    con = duckdb.connect(str(folder / "private.duckdb"))
    con.execute("SET threads=8")
    con.execute("SET memory_limit='10GB'")
    con.execute("SET preserve_insertion_order=false")
    con.execute(f"SET temp_directory={quote(folder / 'tmp')}")
    con.execute(f"ATTACH {quote(db)} AS archive (READ_ONLY)")
    tables = {r[0] for r in con.execute("SHOW TABLES").fetchall()}
    if "records" not in tables:
        print("Scanning all archived text and building capture identities...", flush=True)
        started = time.monotonic()
        con.execute(f"""CREATE TABLE records AS WITH prepared AS ({prepared_sql('archive.main.media_data_all')})
          SELECT source_row,record_key,day,substr(day,1,7) AS month,platform,source_batch,
          text_basis,length(FULL_TEXT) AS body_chars,
          regexp_matches(TITLE || chr(10) || FULL_TEXT, '[\\p{{L}}\\p{{N}}]') AS eligible,
          {contract['prefilter']['sql_condition']} AS candidate
          FROM prepared""")
        print(f"Archive scan complete in {time.monotonic()-started:.1f}s", flush=True)
    if "representatives" not in tables:
        con.execute("""CREATE TABLE representatives AS SELECT * EXCLUDE(rn) FROM
          (SELECT *,row_number() OVER (PARTITION BY record_key ORDER BY
          eligible DESC, CASE text_basis WHEN 'full_text' THEN 0 WHEN 'snippet' THEN 1 ELSE 2 END,
          body_chars DESC,day,source_row) AS rn FROM records) WHERE rn=1""")
    invalid = con.execute("SELECT count(*) FROM records WHERE day IS NULL OR platform IS NULL").fetchone()[0]
    if invalid:
        raise ValueError(f"{invalid} records with invalid dates/platforms require explicit handling")
    audit = dict(zip(["raw_records", "unique_records", "eligible_records", "candidate_records"],
        con.execute("""SELECT (SELECT count(*) FROM records),count(*),sum(eligible::INTEGER),
        sum((eligible AND candidate)::INTEGER) FROM representatives""").fetchone()))
    audit["platforms"] = [dict(zip(["platform","records","eligible_records","first_day","last_day"], r))
        for r in con.execute("SELECT platform,count(*),sum(eligible::INTEGER),min(day),max(day) FROM representatives GROUP BY 1 ORDER BY 2 DESC").fetchall()]
    audit["duplicates_removed"] = audit["raw_records"]-audit["unique_records"]
    audit["identity"] = identity
    audit["definition_version"] = contract["definition_version"]
    write_json(folder / "audit.json", audit)
    print(json.dumps(audit, ensure_ascii=True), flush=True)
    denom = folder / "denominator.parquet"
    if not denom.exists():
        con.execute(f"""COPY (SELECT platform,day,month,source_batch,text_basis,
          count(*) AS records,sum(eligible::INTEGER) AS eligible_records,
          sum((eligible AND candidate)::INTEGER) AS candidates
          FROM representatives GROUP BY ALL) TO {quote(denom)} (FORMAT PARQUET)""")
    months = [r[0] for r in con.execute("SELECT DISTINCT month FROM representatives ORDER BY 1").fetchall()]
    candidates = folder / "candidates"
    candidates.mkdir(exist_ok=True)
    for month in months:
        target = candidates / f"{month}.parquet"
        if target.exists():
            continue
        temp = target.with_suffix(".partial")
        con.execute(f"""COPY (WITH prepared AS ({prepared_sql('archive.main.media_data_all')})
          SELECT r.record_key,r.day,r.month,r.platform,r.source_batch,r.text_basis,
          p.source_name,p.TITLE,p.FULL_TEXT FROM representatives r
          JOIN prepared p USING(source_row) WHERE r.month={quote(month)} AND r.eligible AND r.candidate
          AND p.day>={quote(month+'-01')} AND p.day<cast(cast({quote(month+'-01')} AS DATE)+INTERVAL 1 MONTH AS DATE)::VARCHAR
          ORDER BY r.record_key) TO {quote(temp)} (FORMAT PARQUET, COMPRESSION ZSTD)""")
        temp.replace(target)
        print(f"Candidate month extracted: {month}", flush=True)
    after = db.stat()
    assert (stat.st_size,stat.st_mtime_ns)==(after.st_size,after.st_mtime_ns), "Source changed during extraction"
    write_json(folder / "extraction_complete.json", {"months": months, "signature": signature, "audit": audit})
    con.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--work", type=Path, default=DEFAULT_WORK)
    args = parser.parse_args()
    collect(args.db, args.work)
