"""Build, verify and rasterize the local editorial report. No coding is rerun."""
import argparse
import json
import subprocess
from datetime import datetime, timezone
from evidence_io import *
from publication_data import prepare
from report_narrative import assemble, page_map
from environment import capture_environment, TYPST, FONTS
from verify_publication import prebuild, finish_verification, load_output
from schemas import write_schemas, validate_package

PDF=OUT/"katolicke-teme-u-arhivu-digikat.pdf"


def invalidate_review():
    write_json(OUT/"release_status.json",{
        "schema_version":"1.0","artifact_status":"in_progress","human_editorial_review":"pending",
        "external_release_authorised":False,"pdf_sha256":None})
    write_json(OUT/"visual_review.json",{
        "schema_version":"1.0","reviewer_type":"AI","reviewed_at":"",
        "pdf_sha256":"","page_count":0,"reviewed_pages":[],"unresolved_issues":["Awaiting inspection of current PDF pages"],
        "status":"pending"})


def render():
    import pymupdf
    doc=pymupdf.open(PDF)
    rendered=[]
    for i,page in enumerate(doc):
        path=output_path(OUT/"pages"/f"page-{i+1:02d}.png")
        page.get_pixmap(matrix=pymupdf.Matrix(1.6,1.6),alpha=False).save(path)
        rendered.append({"page":i+1,"path":relative(path),"sha256":sha256(path)})
    write_json(OUT/"render_manifest.json",{
        "schema_version":"1.0","pdf_sha256":sha256(PDF),"pages":rendered,"scale":1.6})


def build():
    configure_environment()
    invalidate_review()
    env=capture_environment()
    data=prepare()
    assemble();page_map();write_schemas()
    checks,tests=prebuild(data)
    command=[str(TYPST),"compile","--root",str(SRC.parent),"--ignore-system-fonts",
             "--font-path",str(FONTS),str(OUT/"publication.typ"),str(output_path(PDF))]
    completed=subprocess.run(command,text=True,capture_output=True,encoding="utf-8")
    write_text(OUT/"logs/typst.stdout.log",completed.stdout)
    write_text(OUT/"logs/typst.stderr.log",completed.stderr)
    if completed.returncode:raise RuntimeError("Typst compilation failed; see logs/typst.stderr.log")
    if completed.stderr.strip():raise RuntimeError("Typst emitted warnings; resolve them before ready.")
    result=finish_verification(PDF,checks,tests)
    render()
    schema_result=validate_package()
    result["checks"].append({"name":"schema_validation","result":schema_result})
    write_json(OUT/"verification.json",result)
    print(json.dumps({"build":"passed","pdf":str(PDF),"sha256":result["pdf_sha256"],
                      "page_count":len(load_output("display_manifest.json")["pages"]),
                      "visual_review":"pending","version_differences":env["version_differences"]}))


def verify():
    configure_environment()
    capture_environment()
    from baseline import baseline
    baseline()
    checks,tests=prebuild()
    result=finish_verification(PDF,checks,tests)
    schemas=validate_package(include_review=True)
    result["checks"].append({"name":"schema_validation","result":schemas})
    review=load_output("visual_review.json")
    release=load_output("release_status.json")
    if release["artifact_status"]=="complete":
        if review["status"]!="passed" or review["pdf_sha256"]!=sha256(PDF):
            raise RuntimeError("Complete artifact lacks a current hash-bound visual review")
        if release["pdf_sha256"]!=sha256(PDF):raise RuntimeError("Release PDF hash mismatch")
        if review["reviewed_pages"]!=list(range(1,review["page_count"]+1)):
            raise RuntimeError("Not every page was reviewed")
    write_json(OUT/"verification.json",result)
    print(json.dumps({"verification":"passed","pdf_sha256":sha256(PDF),
                      "artifact_status":release["artifact_status"],"failure_tests":len(tests)}))


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--verify-only",action="store_true")
    args=parser.parse_args()
    try:
        verify() if args.verify_only else build()
    except Exception as exc:
        # A failure cannot preserve a ready/complete status.
        write_json(OUT/"release_status.json",{
            "schema_version":"1.0","artifact_status":"verification_failed",
            "human_editorial_review":"pending","external_release_authorised":False,
            "pdf_sha256":sha256(PDF) if PDF.exists() else None,
            "reason":str(exc)})
        write_json(OUT/"verification.json",{
            "schema_version":"1.0","status":"failed","checks":[{"error":str(exc)}],
            "failure_tests":[],"pdf_sha256":sha256(PDF) if PDF.exists() else "",
            "pdf_numeric_reconciliation":{}})
        raise
