"""Only deterministic metadata aggregates and exact-body equality are used."""
import calendar
import csv
import hashlib
import json
import math
from datetime import date

from evidence_io import *
from baseline import baseline, csv_rows

NBSP = "\u00a0"
MONTHS = ["siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
          "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca"]


def display(value, fmt):
    if fmt == "integer":
        return f"{int(value):,}".replace(",", NBSP)
    if fmt == "percent":
        return f"{value:.1f}".replace(".", ",") + NBSP + "%"
    if fmt == "date":
        d = date.fromisoformat(value[:10])
        return f"{d.day}. {MONTHS[d.month-1]} {d.year}."
    if fmt == "year":
        return str(value) + "."
    if fmt == "month":
        return value
    return str(value)


def compute():
    """Recompute every value from unchanged, registered inputs."""
    configure_environment()
    import pandas as pd
    import pyarrow.parquet as pq

    freeze = read_json(EVIDENCE / "freeze.json")
    report = read_json(EVIDENCE / "report_data.json")
    policy = read_json(EVIDENCE / "report_policy.json")
    upstream = {c["id"]: c for c in read_json(EVIDENCE / "claims.json")}
    frame = pd.read_parquet(checked_path(EVIDENCE / "frame.parquet"), columns=[
        "publication_id", "outlet_id", "outlet_name", "published_at",
        "text_hash", "text_length", "month", "collection_era"])
    assert len(frame) == frame.publication_id.nunique() == freeze["publications"]
    assert str(frame.published_at.min())[:10] == freeze["assignment"]["period_start"]
    assert str(frame.published_at.max())[:10] == freeze["assignment"]["period_end"]
    # The saved source table retains spelling/case variants of outlet_name
    # within the same outlet_id; reproduce that exact grouping.
    source = frame.groupby(["outlet_id", "outlet_name"]).size().sort_values(ascending=False)
    saved_source = csv_rows("tables/source_concentration.csv")
    assert {(r["outlet_id"], r["outlet_name"]): int(r["publications"]) for r in saved_source} == source.to_dict()
    for r in saved_source:
        assert abs(float(r["share_pct"]) - 100 * int(r["publications"]) / len(frame)) < 1e-10
    eligible = frame[frame.text_length >= 400]
    families = eligible.groupby("text_hash").agg(n=("publication_id", "size"),
                                                 outlets=("outlet_id", "nunique"))
    repeated = families[families.n > 1]
    cross = repeated[repeated.outlets > 1]
    reuse = {
        "eligible_publications": len(eligible),
        "repeated_families": len(repeated),
        "publications_in_repeated_families": int(repeated.n.sum()),
        "cross_outlet_families": len(cross),
        "publications_in_cross_outlet_families": int(cross.n.sum()),
    }
    assert reuse == report["reuse"]
    saved_families = csv_rows("tables/exact_reuse_families.csv")
    assert {r["exact_text_family"]: (int(r["publications"]), int(r["outlets"]))
            for r in saved_families} == {
                k: (int(r.n), int(r.outlets)) for k, r in repeated.iterrows()}
    monthly = frame.groupby("month").size().to_dict()
    month_rows = csv_rows("tables/frame_month.csv")
    for row in month_rows:
        assert monthly.get(row[""], 0) == int(float(row["publications"]))
    assert frame.groupby("collection_era").size().to_dict() == {
        r["collection_era"]: int(r["publications"]) for r in csv_rows("tables/frame_collection_era.csv")}
    cases = read_json(EVIDENCE / "deterministic_reuse_cases.json")["cases"]
    equality_checks = []
    # Only selected families' bodies enter local memory; no body or passage is emitted.
    for case in cases:
        body_rows = pq.read_table(checked_path(EVIDENCE / "frame.parquet"),
            filters=[("text_hash", "=", case["text_hash"])],
            columns=["publication_id", "body_clean", "text_hash", "text_length"]).to_pylist()
        assert len(body_rows) == case["publications"]
        assert len({r["body_clean"] for r in body_rows}) == 1
        assert {r["publication_id"] for r in body_rows} == {
            r["publication_id"] for r in case["members"]}
        for row in body_rows:
            assert len(row["body_clean"]) == row["text_length"]
            assert hashlib.sha256(row["body_clean"].encode("utf-8")).hexdigest() == case["text_hash"]
        equality_checks.append({"case_id": case["id"], "publications_checked": len(body_rows),
                                "hash_length_equality_membership": "passed"})
        del body_rows

    values = {}
    specs = {}
    # One fingerprint per file in this calculation pass. All sources are checked
    # before and after the build, so hundreds of claims need not rehash the same
    # large frozen parquet file independently.
    source_digests = {}

    def fingerprint(path):
        key=str(Path(path).resolve())
        if key not in source_digests:
            source_digests[key]=sha256(path)
        return source_digests[key]

    def add(cid, value, *, kind="supporting_measure", fmt="integer", wording="",
            unit="objave", scope="frozen captured web publication frame",
            num=None, den=None, parents=("frame",), files=("freeze.json",),
            locators=None, calc="read_saved_metadata", limitation=None, domain=None):
        values[cid] = value
        specs[cid] = {
            "id": cid, "kind": kind, "wording": wording or cid,
            "value": value, "display_value": display(value, fmt), "format": fmt,
            "unit": unit, "scope": scope,
            "period": {"start": freeze["assignment"]["period_start"],
                       "end": freeze["assignment"]["period_end"]},
            "numerator": num, "denominator": den,
            "source_files": [{"path": relative(EVIDENCE / f), "sha256": fingerprint(EVIDENCE / f)}
                             for f in dict.fromkeys((*files, *(("claims.json",) if parents else ())))],
            "source_locators": locators or [f"{f}: {calc}" for f in files],
            "calculation_id": calc,
            "upstream_claim_ids": list(parents),
            "upstream_publication_statuses": {p: upstream[p]["publication_status"] for p in parents},
            "report_eligibility": "appendix_only" if kind == "diagnostic" else "eligible",
            "limitations": limitation or [
                "Captured publications only; archive membership does not confirm substantive religious relevance.",
                "Counts do not measure audience, influence or independent editorial decisions."],
            "domain": domain,
        }
        return cid

    n = len(frame)
    add("frame_n", n, num=n, den=n, wording="U zamrznutom okviru nalazi se broj web objava.",
        files=("freeze.json", "frame.parquet"), calc="count_unique_publication_id")
    add("sources_n", frame.outlet_id.nunique(), unit="izvori",
        files=("freeze.json", "tables/frame_source.csv", "frame.parquet"),
        calc="count_unique_outlet_id")
    for cid, value in (("period_start", freeze["assignment"]["period_start"]),
                       ("period_end", freeze["assignment"]["period_end"])):
        add(cid, value, kind="fixed_metadata", fmt="date", unit="datum",
            parents=(), locators=[f"freeze.json: assignment.{cid}"])
    add("period_years", "2021.–2026.", kind="fixed_metadata", fmt="text",
        unit="godine", parents=(), locators=["freeze.json: assignment.period_start/period_end"])
    add("gap_date", "veljača–svibanj 2024.", kind="fixed_metadata", fmt="text", unit="razdoblje",
        parents=(), files=("source_audit.json",), locators=["corpus_manifest.caveats.text_gap"])
    add("change_date", "srpnja 2024.", kind="fixed_metadata", fmt="text", unit="razdoblje",
        parents=(), files=("source_audit.json",), locators=["corpus_manifest.caveats.instrument_change_2024",
                                                          "corpus_manifest.eras"])
    for year in range(2021, 2027):
        add(f"year_{year}", year, kind="fixed_metadata", fmt="year", unit="godina",
            parents=(), files=("tables/frame_month.csv",), calc="calendar_axis_year")
    top5 = sum(int(r["publications"]) for r in saved_source[:5])
    assert upstream["source_concentration"]["numerator"] == top5
    add("source_top5_share", 100 * top5 / n, kind="principal_finding", fmt="percent",
        num=top5, den=n, parents=("source_concentration",), domain="source_concentration",
        wording="Pet izvora nosi 29,5 % zabilježenih objava.",
        files=("tables/source_concentration.csv", "frame.parquet"),
        calc="sum_top_five_source_counts_divide_frame_times_100")
    add("source_top5_n", top5, num=top5, den=n, parents=("source_concentration",),
        files=("tables/source_concentration.csv", "frame.parquet"), calc="sum_top_five_source_counts")
    add("top_group_size", 5, unit="izvori", parents=("source_concentration",),
        files=("tables/source_concentration.csv",), calc="count_top_five_rows")
    for rank, row in enumerate(saved_source[:50], 1):
        for suffix, val, fmt, unit in (("rank", rank, "integer", "redni broj"),
                                      ("name", row["outlet_name"], "text", "naziv izvora"),
                                      ("n", int(row["publications"]), "integer", "objave"),
                                      ("share", 100*int(row["publications"])/n, "percent", "udio objava")):
            add(f"source_{rank}_{suffix}", val, fmt=fmt, unit=unit,
                num=int(row["publications"]), den=n, parents=("source_concentration",),
                files=("tables/source_concentration.csv", "frame.parquet"),
                locators=[f"tables/source_concentration.csv: outlet_id={row['outlet_id']}; {suffix}"],
                calc=f"source_rank_{rank}_{suffix}")
    add("source_rest_n", n-top5, num=n-top5, den=n, parents=("source_concentration",),
        files=("tables/source_concentration.csv", "frame.parquet"), calc="frame_minus_top_five_counts")
    add("source_rest_share", 100*(n-top5)/n, fmt="percent", num=n-top5, den=n,
        parents=("source_concentration",), files=("tables/source_concentration.csv", "frame.parquet"),
        calc="frame_minus_top_five_share")
    for row in month_rows:
        m = row[""]
        # Collection gaps are null in the plotted series, never zero observations.
        val = None if m in {"2024-02", "2024-03", "2024-04", "2024-05"} else int(float(row["publications"]))
        add("month_"+m.replace("-", "_"), val, fmt="text" if val is None else "integer",
            num=val, den=n, files=("tables/frame_month.csv", "source_audit.json", "frame.parquet"),
            calc="monthly_publication_count_with_collection_gap_null",
            locators=[f"tables/frame_month.csv: month={m}"])
    add("month_axis_max", math.ceil(max(monthly.values())/10000)*10000,
        kind="fixed_metadata", unit="objave; gornja granica skale",
        parents=(), files=("tables/frame_month.csv",), calc="ceil_max_month_count_to_next_ten_thousand")
    add("month_axis_mid", math.ceil(max(monthly.values())/10000)*5000,
        kind="fixed_metadata", unit="objave; srednja oznaka skale",
        parents=(), files=("tables/frame_month.csv",), calc="half_month_axis_max")
    add("axis_zero", 0, kind="fixed_metadata", unit="ishodište skale",
        parents=(), files=("tables/frame_month.csv",), calc="zero_based_count_axis")
    for era in ("pre2024","post2024"):
        era_n=int((frame.collection_era==era).sum())
        add("era_"+era+"_n",era_n,num=era_n,den=n,files=("tables/frame_collection_era.csv","frame.parquet"),
            calc="count_saved_collection_era",locators=[f"collection_era={era}"])
    by_id=frame.groupby("outlet_id").size().sort_values(ascending=False)
    half_count=int((by_id.cumsum()<n/2).sum()+1)
    add("sources_for_half",half_count,unit="identifikatori izvora",num=half_count,den=len(by_id),
        parents=("source_concentration",),files=("frame.parquet","tables/source_concentration.csv"),
        calc="minimum_ranked_source_ids_to_reach_half_frame")
    for k in (5,20,50,100):
        subtotal=int(by_id.head(k).sum())
        for suffix,val,fmt,unit in (("k",k,"integer","izvori"),
                                    ("n",subtotal,"integer","objave"),
                                    ("share",100*subtotal/n,"percent","udio objava")):
            add(f"cumulative_{k}_{suffix}",val,fmt=fmt,unit=unit,num=subtotal,den=n,
                parents=("source_concentration",),files=("frame.parquet","tables/source_concentration.csv"),
                calc=f"top_{k}_existing_outlet_ids_{suffix}")
    for key, cid in (
        ("eligible_publications", "reuse_base"), ("repeated_families", "reuse_families"),
        ("publications_in_repeated_families", "reuse_n"),
        ("cross_outlet_families", "cross_families"),
        ("publications_in_cross_outlet_families", "cross_n"),
    ):
        add(cid, reuse[key], num=reuse[key], den=len(eligible), parents=("exact_reuse",),
            unit="skupine teksta" if "families" in key else "objave",
            files=("tables/exact_reuse_families.csv", "report_data.json", "frame.parquet"),
            calc="exact_reuse_"+key)
    add("reuse_share", 100*reuse["publications_in_repeated_families"]/len(eligible),
        fmt="percent", kind="principal_finding", num=reuse["publications_in_repeated_families"],
        den=len(eligible), parents=("exact_reuse",), domain="exact_text_reuse",
        wording="Identičan arhivirani tekst s drugom objavom dijeli 0,8 % prihvatljivih objava.",
        files=("tables/exact_reuse_families.csv", "report_data.json", "frame.parquet"),
        calc="repeated_publications_divide_text_eligible_times_100")
    add("cross_share", 100*reuse["publications_in_cross_outlet_families"]/len(eligible),
        fmt="percent", num=reuse["publications_in_cross_outlet_families"], den=len(eligible),
        parents=("exact_reuse",), files=("tables/exact_reuse_families.csv", "frame.parquet"),
        calc="cross_outlet_repeated_publications_divide_text_eligible_times_100")
    same=repeated[repeated.outlets==1]
    for cid,val,fmt,unit in (
        ("same_source_n",int(same.n.sum()),"integer","objave"),
        ("same_source_families",len(same),"integer","skupine teksta"),
        ("same_source_repeat_share",100*int(same.n.sum())/int(repeated.n.sum()),"percent","udio ponovljenih objava"),
        ("cross_repeat_share",100*int(cross.n.sum())/int(repeated.n.sum()),"percent","udio ponovljenih objava"),
    ):
        add(cid,val,fmt=fmt,unit=unit,
            num=len(same) if cid=="same_source_families" else int(same.n.sum()) if cid.startswith("same") else int(cross.n.sum()),
            den=len(repeated) if cid=="same_source_families" else int(repeated.n.sum()),
            parents=("exact_reuse",),files=("tables/exact_reuse_families.csv","frame.parquet"),
            calc=cid+"_within_repeated_publications")
    size_counts=repeated.n.value_counts().sort_index()
    for size,count in size_counts.items():
        for suffix,val,unit in (("size",int(size),"objave po skupini"),("groups",int(count),"skupine teksta")):
            add(f"family_{size}_{suffix}",val,unit=unit,num=int(count),den=len(repeated),
                parents=("exact_reuse",),files=("tables/exact_reuse_families.csv","frame.parquet"),
                calc=f"count_exact_families_of_size_{size}")
    add("family_pairs_share",100*int(size_counts[2])/len(repeated),fmt="percent",
        unit="udio skupina",num=int(size_counts[2]),den=len(repeated),parents=("exact_reuse",),
        files=("tables/exact_reuse_families.csv","frame.parquet"),calc="families_with_two_members_divide_all_repeated_families_times_100")
    add("reuse_threshold", 400, kind="fixed_metadata", unit="znakovi", parents=("exact_reuse",),
        files=("freeze.json",), locators=["freeze.json: exact_reuse"], calc="saved_text_length_threshold")
    add("reuse_excluded", n-len(eligible), num=n-len(eligible), den=n, parents=("exact_reuse",),
        files=("frame.parquet", "report_data.json"), calc="count_text_shorter_than_saved_threshold")
    for c in cases:
        p = ("exact_reuse_case_"+c["id"],)
        for field in ("publications", "outlets"):
            add("case_"+c["id"]+"_"+field, c[field], kind="illustration", parents=p,
                unit="objave" if field=="publications" else "izvori", scope="purposefully selected exact-text family",
                files=("deterministic_reuse_cases.json", "frame.parquet"),
                locators=[f"cases[id={c['id']}].{field}"], calc="saved_purposeful_case_metadata",
                limitation=["Purposeful illustration, not a representative sample; no copying direction."])
        member_field="members" if c["id"]=="same_day" else "display_members"
        for i, m in enumerate(c[member_field]):
            for field in ("title", "outlet_name", "published_at", "url"):
                value = m[field]
                if field == "title":
                    words = value.split()
                    value = " ".join(words[:20]) + ("…" if len(words) > 20 else "")
                add(f"case_{c['id']}_{i}_{field}", value, kind="illustration",
                    fmt="date" if field=="published_at" else "text", unit=field,
                    scope="selected publication identifier only", parents=p,
                    files=("deterministic_reuse_cases.json", "frame.parquet"),
                    locators=[f"cases[id={c['id']}].{member_field}[publication_id={m['publication_id']}].{field}"],
                    calc="saved_metadata_title_fragment_max_twenty_words" if field=="title" else "saved_member_metadata",
                    limitation=["Titles identify the selected record; they do not establish substantive content."])
    for cid, value in (("sample_n", report["sample"]), ("complete_n", report["status_counts"]["complete"]),
                       ("partial_n", report["status_counts"]["partial_processing"]),
                       ("failed_n", 0), ("missing_n", 0)):
        add(cid, value, kind="diagnostic", num=value, den=report["sample"], parents=(),
            scope="completed main processing sample", files=("report_data.json", "main_manifest.csv", "tables/articles.csv"),
            calc="verified_main_processing_status_count", limitation=["Processing outcomes do not measure semantic correctness."])
    chash=policy["config_hash"]
    add("coding_version", read_json(EVIDENCE/f"configs/{chash}.json")["configuration"]["version"],
        fmt="text", kind="fixed_metadata", parents=(), unit="verzija",
        files=(f"configs/{chash}.json",), locators=["configuration.version"])
    return {"values": values, "records": list(specs.values()), "upstream": upstream,
            "equality_checks": equality_checks, "config_hash": chash}


def decide(records):
    findings = [r for r in records if r["kind"] == "principal_finding"]
    domains = sorted({r["domain"] for r in findings})
    threshold = len(findings) >= 3 and len(domains) >= 2
    return {
        "schema_version": "1.0",
        "mode": "editorial_edition",
        "qualifying_finding_ids": [r["id"] for r in findings], "domains": domains,
        "independence_rationale": {
            "source_top5_share": "How is captured publication volume distributed among sources?",
            "reuse_share": "How often does an eligible archived body exactly recur in another publication?",
        },
        "threshold_passed": threshold,
        "decision_reason": (
            "Two independent principal findings qualify. Top-one and top-five shares are one concentration finding; "
            "cross-outlet reuse and purposeful examples are supporting views of the same reuse measure. "
            "Frame size and monthly coverage are scope/context, not additional findings. "
            "The collection break cannot support a trend in media attention. The user subsequently rejected "
            "the short note and explicitly requested a report like the initial report with the new data. "
            "That instruction supersedes the short-format selection rule, not the evidence-eligibility rules. "
            "The full editorial treatment presents these same two principal findings, supporting descriptive "
            "views, examples, scope, questions and methods without claiming the original threshold passed."),
        "format_override": {
            "authorised_by": "explicit user follow-up in this conversation",
            "instruction": "i want the report like the initial one but with this new data",
            "scope": "Full report architecture and visual treatment; no change to upstream eligibility or withheld statuses.",
            "previous_mode": "short_evidence_note",
        },
    }


def prepare():
    baseline()
    data = compute()
    write_json(OUT/"claim_register.json", {"schema_version": "1.0", "records": data["records"]})
    write_json(OUT/"editorial_decision.json", decide(data["records"]))
    write_json(OUT/"report_data.json", {
        "schema_version": "1.0", "config_hash": data["config_hash"],
        "claims": {r["id"]: {"value": r["value"], "display": r["display_value"]} for r in data["records"]},
        "equality_checks": data["equality_checks"],
        "number_format": {"thousands": "U+00A0", "decimal": ",", "percent_space": "U+00A0", "percent_decimals": 1},
    })
    return data


if __name__ == "__main__":
    data=prepare()
    print(json.dumps({"claims":len(data["records"]),"decision":decide(data["records"]),
                      "equality_checks":data["equality_checks"]}, ensure_ascii=False))
