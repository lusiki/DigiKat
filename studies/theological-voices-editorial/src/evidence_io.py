"""Read-only evidence access and confined editorial output.

Run all entry points with Python -B. No original study code is imported.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "studies/theological-voices-editorial/src"
OUT = ROOT / "studies/theological-voices-editorial/output/private"
V2 = ROOT / "studies/theological-voices-v2"
EVIDENCE = V2 / "output/private"
ORIGINAL = ROOT / "studies/theological-voices"


def output_path(path: str | Path) -> Path:
    target = Path(path).resolve()
    if not any(target.is_relative_to(root.resolve()) for root in (SRC, OUT)):
        raise ValueError(f"Write outside editorial roots rejected: {target}")
    target.parent.mkdir(parents=True, exist_ok=True)
    return target


def write_text(path: str | Path, text: str) -> None:
    output_path(path).write_text(text, encoding="utf-8", newline="\n")


def write_json(path: str | Path, obj) -> None:
    write_text(path, json.dumps(obj, ensure_ascii=False, indent=2) + "\n")


def sha256(path: str | Path) -> str:
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def relative(path: str | Path) -> str:
    p = Path(path).resolve()
    return p.relative_to(ROOT).as_posix() if p.is_relative_to(ROOT) else p.as_posix()


def register(paths) -> None:
    manifest_path = OUT / "source_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {
        "schema_version": "1.0",
        "hash_algorithm": "SHA-256",
        "files": [],
    }
    existing = {record["path"]: record for record in manifest["files"]}
    for path in paths:
        path = Path(path).resolve()
        key = relative(path)
        digest = sha256(path)
        if key in existing and existing[key]["sha256"] != digest:
            raise ValueError(f"Source changed: {key}")
        existing[key] = {"path": key, "sha256": digest, "size_bytes": path.stat().st_size}
    manifest["files"] = sorted(existing.values(), key=lambda item: item["path"])
    write_json(manifest_path, manifest)


def checked_path(path: str | Path) -> Path:
    p = Path(path).resolve()
    manifest = json.loads((OUT / "source_manifest.json").read_text(encoding="utf-8"))
    records = {item["path"]: item for item in manifest["files"]}
    key = relative(p)
    if key not in records:
        raise ValueError(f"Source must be registered before use: {key}")
    if sha256(p) != records[key]["sha256"]:
        raise ValueError(f"Source hash mismatch: {key}")
    return p


def read_json(path: str | Path):
    return json.loads(checked_path(path).read_text(encoding="utf-8-sig"))


def read_text(path: str | Path) -> str:
    return checked_path(path).read_text(encoding="utf-8-sig")


def verify_all():
    manifest = json.loads((OUT / "source_manifest.json").read_text(encoding="utf-8"))
    for item in manifest["files"]:
        path = Path(item["path"])
        if not path.is_absolute():
            path = ROOT / path
        if sha256(path) != item["sha256"]:
            raise ValueError(f"Source hash mismatch: {item['path']}")
    return {"status": "passed", "files_checked": len(manifest["files"])}


def configure_environment():
    import sys
    sys.dont_write_bytecode = True
    for name, suffix in (
        ("TEMP", "tmp"), ("TMP", "tmp"), ("TMPDIR", "tmp"),
        ("MPLCONFIGDIR", "cache/matplotlib"), ("XDG_CACHE_HOME", "cache"),
        ("PYTHONPYCACHEPREFIX", "cache/pycache"),
    ):
        p = output_path(OUT / suffix / ".location").parent
        os.environ[name] = str(p)
    os.environ["PYTHONDONTWRITEBYTECODE"] = "1"


if __name__ == "__main__":
    configure_environment()
    docs = [
        ORIGINAL / "README.md",
        ORIGINAL / "build_report.py",
        ORIGINAL / "typeset/template.typ",
        ORIGINAL / "output/private/report/tko-tumaci-vjeru.pdf",
    ]
    docs += [V2 / name for name in (
        "README.md", "BRIEF.md", "CODEBOOK.md", "assignment.json",
        "analyse.py", "prepare.py", "reuse_cases.py", "report_policy.py",
        "verify.py", "archive_config.py",
    )]
    docs += [EVIDENCE / name for name in (
        "source_audit.json", "freeze.json", "main_manifest.csv",
        "report_data.json", "report_policy.json", "claims.json", "denominators.json",
        "deterministic_reuse_cases.json", "analysis_verification.json",
        "diagnostic_review.json", "development_review.json",
        "challenge_disagreements.json", "statement_probe_review.json",
        "coder_freeze.json", "candidate_freeze.json", "status.json",
        "inference_status.json", "pipeline_status.json",
    )]
    docs += sorted((EVIDENCE / "configs").glob("*"))
    docs += sorted((EVIDENCE / "tables").glob("*"))
    register([path for path in docs if path.is_file()])
    print(json.dumps(verify_all()))
