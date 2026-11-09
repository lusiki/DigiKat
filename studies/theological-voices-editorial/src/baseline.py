"""Check the completed study without executing or importing its builders."""
import csv
import hashlib
import json
from collections import Counter

from evidence_io import *


def csv_rows(name):
    with checked_path(EVIDENCE / name).open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def baseline():
    configure_environment()
    report = read_json(EVIDENCE / "report_data.json")
    freeze = read_json(EVIDENCE / "freeze.json")
    policy = read_json(EVIDENCE / "report_policy.json")
    chash = policy["config_hash"]
    config = read_json(EVIDENCE / "configs" / (chash + ".json"))
    articles = csv_rows("tables/articles.csv")
    main = csv_rows("main_manifest.csv")
    statuses = Counter(row["processing_status"] for row in articles)
    checks = []

    def check(name, expected, observed, locations):
        checks.append({
            "name": name, "expected": expected, "observed": observed,
            "passed": expected == observed,
            "sources": [{"path": relative(EVIDENCE / f), "sha256": sha256(EVIDENCE / f),
                         "locator": loc} for f, loc in locations],
        })

    for key, expected in (("period_start", "2021-01-01"), ("period_end", "2026-06-11")):
        check(key, expected, freeze["assignment"][key], [("freeze.json", f"assignment.{key}")])
    check("frame_size", 282701, freeze["publications"], [("freeze.json", "publications")])
    for field in ("sample", "completed_main"):
        check(field, 2000, report[field], [("report_data.json", field)])
    check("main_manifest_count", 2000, len(main), [("main_manifest.csv", "row count")])
    check("unique_main_ids", 2000, len({r["publication_id"] for r in main}),
          [("main_manifest.csv", "distinct publication_id")])
    check("outcome_ids_match_sample", sorted(r["publication_id"] for r in main),
          sorted(r["publication_id"] for r in articles),
          [("main_manifest.csv", "publication_id"), ("tables/articles.csv", "publication_id")])
    for label, expected in (("complete", 1950), ("partial_processing", 50)):
        check(label, expected, statuses[label], [("tables/articles.csv", "processing_status")])
    check("other_or_wholly_failed_outcomes", 0,
          sum(n for s, n in statuses.items() if s not in {"complete", "partial_processing"}),
          [("tables/articles.csv", "processing_status")])
    check("missing_text_outcomes", 0, sum(int(r["text_length"]) == 0 for r in main),
          [("main_manifest.csv", "text_length")])
    check("summary_status_counts", dict(statuses), report["status_counts"],
          [("report_data.json", "status_counts"), ("tables/articles.csv", "processing_status")])
    check("coding_version", "3.2.0", config["configuration"]["version"],
          [(f"configs/{chash}.json", "configuration.version")])
    recomputed = hashlib.sha256(json.dumps(config["configuration"], ensure_ascii=False,
                                           sort_keys=True).encode()).hexdigest()
    check("configuration_content_hash", chash, recomputed,
          [(f"configs/{chash}.json", "configuration")])
    for name in (
        "report_data.json", "report_policy.json", "coder_freeze.json", "candidate_freeze.json",
        "diagnostic_review.json", "development_review.json", "challenge_disagreements.json",
        "statement_probe_review.json", "status.json", "inference_status.json",
    ):
        check("config_in_" + name, chash, read_json(EVIDENCE / name)["config_hash"],
              [(name, "config_hash")])
    check("candidate_configuration", config["configuration"],
          read_json(EVIDENCE / "candidate_freeze.json")["configuration"],
          [("candidate_freeze.json", "configuration"), (f"configs/{chash}.json", "configuration")])
    check("embedded_policy_configuration", chash, report["report_policy"]["config_hash"],
          [("report_data.json", "report_policy.config_hash")])
    check("analysis_code_matches_saved_report", report["analysis_sha256"], sha256(V2 / "analyse.py"),
          [("report_data.json", "analysis_sha256")])
    check("main_manifest_frozen_hash", freeze["files"]["main_manifest.csv"],
          sha256(EVIDENCE / "main_manifest.csv"), [("freeze.json", "files.main_manifest.csv")])
    register([EVIDENCE / "frame.parquet"])
    check("frame_frozen_hash", freeze["files"]["frame.parquet"], sha256(EVIDENCE / "frame.parquet"),
          [("freeze.json", "files.frame.parquet")])
    months = csv_rows("tables/frame_month.csv")
    check("month_total", 282701, sum(int(float(r["publications"])) for r in months),
          [("tables/frame_month.csv", "sum(publications)")])
    eras = csv_rows("tables/frame_collection_era.csv")
    check("era_total", 282701, sum(int(r["publications"]) for r in eras),
          [("tables/frame_collection_era.csv", "sum(publications)")])
    check("collection_gap_table", [0, 0, 0, 0],
          [int(float(r["publications"])) for r in months
           if r[""] in ["2024-02", "2024-03", "2024-04", "2024-05"]],
          [("tables/frame_month.csv", "February–May 2024")])
    check("saved_analysis_failures", 0, read_json(EVIDENCE / "analysis_verification.json")["failed"],
          [("analysis_verification.json", "failed")])
    # Do not serialize large ID arrays or prompt-bearing configurations into the review.
    for c in checks:
        if c["name"] in {"outcome_ids_match_sample", "candidate_configuration"} and c["passed"]:
            c["expected"] = c["observed"] = "identical (compared locally; raw content omitted)"
    failed = [c for c in checks if not c["passed"]]
    result = {"schema_version": "1.0", "status": "passed" if not failed else "failed",
              "config_hash": chash, "checks": checks}
    write_json(OUT / "baseline_verification.json", result)
    if failed:
        write_json(OUT / "baseline_discrepancy.json", {
            "schema_version": "1.0", "status": "authoring_halted", "discrepancies": failed})
        raise RuntimeError("Baseline discrepancy: publication authoring halted.")
    return result


if __name__ == "__main__":
    r = baseline()
    print(json.dumps({"status": r["status"], "checks": len(r["checks"]), "config_hash": r["config_hash"]}))
