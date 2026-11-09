"""Mechanical traceability gates; none of these establishes semantic truth."""
import copy
import json
import re
from collections import Counter
from datetime import datetime, timezone

from evidence_io import *
from publication_data import compute, decide, display
from environment import verify_fonts

REF = re.compile(r'\b(value|raw|monthbar)\("([^"]+)"\)')
NUMBER = re.compile(r"\d+(?:[ \u00a0\u202f]\d{3})*(?:[.,]\d+)*")


def number_tokens(text):
    return [re.sub(r"[ \u00a0\u202f]", "", n) for n in NUMBER.findall(text)]


def load_output(name):
    return json.loads((OUT/name).read_text(encoding="utf-8"))


def validate_content(pages, records, upstream):
    by_id={r["id"]:r for r in records}
    refs=[]
    for p in pages:
        body=p["typst"]
        matches=list(REF.finditer(body))
        scrubbed=REF.sub("",body)
        if re.search(r"\d",scrubbed):
            raise ValueError(f"Unregistered reader-facing numerical literal on page {p['page']}")
        for m in matches:
            kind,cid=m.groups()
            if cid not in by_id:raise ValueError(f"Unknown claim reference: {cid}")
            c=by_id[cid]
            if c["kind"]=="diagnostic" and p["location"]!="appendix":
                raise ValueError(f"Diagnostic outside appendix: {cid}")
            if c["report_eligibility"] not in {"eligible","appendix_only"}:
                raise ValueError(f"Ineligible claim: {cid}")
            for up_id in c["upstream_claim_ids"]:
                if up_id not in upstream:raise ValueError("Missing upstream claim: "+up_id)
                status=upstream[up_id]["publication_status"]
                if status=="withheld":raise ValueError("Withheld claim: "+up_id)
                if c["upstream_publication_statuses"].get(up_id)!=status:
                    raise ValueError("Upstream status mismatch: "+up_id)
            refs.append({"page":p["page"],"location":p["location"],
                         "reference_type":kind,"claim_id":cid})
    return refs


def validate_registered_values(records, expected_records):
    expected={r["id"]:r for r in expected_records}
    if {r["id"] for r in records}!=set(expected):raise ValueError("Register IDs differ from recomputed IDs")
    if len(records)!=len(expected):raise ValueError("Duplicate register ID")
    for r in records:
        e=expected[r["id"]]
        for field in ("value","display_value","format","numerator","denominator",
                      "source_files","source_locators","calculation_id","upstream_claim_ids",
                      "upstream_publication_statuses","kind","report_eligibility","scope","period","unit"):
            if r.get(field)!=e.get(field):raise ValueError(f"Incorrect registered {field}: {r['id']}")
        if r["display_value"]!=display(r["value"],r["format"]):
            raise ValueError("Incorrect registered formatting: "+r["id"])


def verify_manifest(manifest, root):
    for record in manifest["files"]:
        p=Path(record["path"])
        if not p.is_absolute():p=root/p
        if sha256(p)!=record["sha256"]:raise ValueError("Changed source hash: "+str(p))


def failure_tests(records, upstream):
    results=[]
    base=next(r for r in records if r["id"]=="frame_n")
    p={"page":1,"location":"main","typst":'#prose[#value("frame_n")]'}
    def rejects(name,fn):
        try:fn()
        except (ValueError,RuntimeError) as exc:
            results.append({"name":name,"status":"passed","expected_rejection":str(exc)})
        else:raise AssertionError("Failure fixture was accepted: "+name)
    rejects("unregistered_visible_number",
            lambda:validate_content([{**p,"typst":"#prose[999]"}],records,upstream))
    withheld=copy.deepcopy(base)
    withheld.update(id="fixture_withheld",upstream_claim_ids=["role_academic_theologian"],
                    upstream_publication_statuses={"role_academic_theologian":"withheld"},
                    report_eligibility="eligible")
    rejects("withheld_reference_even_with_local_eligible_status",
        lambda:validate_content([{**p,"typst":'#prose[#value("fixture_withheld")]'}],
                                records+[withheld],upstream))
    fixture=output_path(OUT/"fixtures/hash-source.txt")
    write_text(fixture,"synthetic original\n")
    manifest={"files":[{"path":str(fixture),"sha256":sha256(fixture)}]}
    write_text(fixture,"synthetic changed\n")
    rejects("changed_source_hash",lambda:verify_manifest(manifest,OUT))
    bad=copy.deepcopy(records)
    bad[0]["value"]+=1
    bad[0]["display_value"]=display(bad[0]["value"],bad[0]["format"])
    rejects("incorrect_registered_value_with_consistent_format",
            lambda:validate_registered_values(bad,records))
    rejects("write_path_escape",lambda:output_path(OUT/"../../../../forbidden-fixture.txt"))
    write_json(OUT/"fixtures/results.json",{"schema_version":"1.0","tests":results,
               "evidence_modified":False})
    return results


def prebuild(recomputed=None):
    checks=[]
    checks.append({"name":"source_hashes","result":verify_all()})
    checks.append({"name":"recorded_fonts","result":verify_fonts()})
    current=recomputed or compute()
    records=load_output("claim_register.json")["records"]
    pages=load_output("manuscript.json")["pages"]
    generated='#import "../../src/template.typ": *\n\n'+"\n\n".join(p["typst"] for p in pages)+"\n"
    if (OUT/"publication.typ").read_text(encoding="utf-8")!=generated:
        raise ValueError("Generated Typst content differs from verified manuscript.")
    validate_registered_values(records,current["records"])
    checks.append({"name":"recomputed_values_and_display","status":"passed","claims":len(records)})
    refs=validate_content(pages,records,current["upstream"])
    # Runtime values must exactly match the checked register.
    runtime=load_output("report_data.json")
    expected_runtime={r["id"]:{"value":r["value"],"display":r["display_value"]} for r in records}
    if runtime["claims"]!=expected_runtime:raise ValueError("Runtime values differ from register")
    if load_output("editorial_decision.json")!=decide(records):
        raise ValueError("Format decision no longer matches eligible findings")
    checks.append({"name":"eligibility_location_and_format","status":"passed","references":len(refs)})
    by_id={r["id"]:r for r in records}
    figures=load_output("figure_manifest.json")
    for figure in figures["figures"]:
        used={r["claim_id"] for r in refs if r["page"]==figure["page"]}
        ids=figure["label_claim_ids"]+[cid for s in figure["series"] for cid in s["claim_ids"]]
        for cid in ids:
            if cid not in by_id or cid not in used:raise ValueError("Unlinked figure claim: "+cid)
        for cid in figure["axis"].get("visible_numeric_labels",[]):
            if cid not in used:raise ValueError("Unlinked figure axis label")
        if figure["id"]=="monthly_supply":
            plotted=figure["series"][0]["claim_ids"]
            expected_months=[r["id"] for r in records if re.fullmatch(r"month_\d{4}_\d{2}",r["id"])]
            if plotted!=expected_months:raise ValueError("Monthly series contains missing or non-month values")
            if sum(by_id[cid]["value"] or 0 for cid in plotted)!=by_id["frame_n"]["value"]:
                raise ValueError("Plotted monthly values do not sum to the frame")
    checks.append({"name":"figure_manifest_links","status":"passed","figures":len(figures["figures"])})
    exceptions=[
        {"id":"automatic_page_number","scope":"footer of PDF pages after cover",
         "permitted_values":[p["page"] for p in pages if p["location"]!="cover"],
         "reason":"Navigation, not an empirical claim; exactly one per listed page."},
        {"id":"nonvisible_pdf_metadata","scope":"PDF producer and creation metadata only",
         "reason":"Not reader-facing page content; excluded from page-text extraction."},
    ]
    write_json(OUT/"numeric_exceptions.json",{"schema_version":"1.0","exceptions":exceptions})
    displays=[]
    for p in pages:
        occurrences=[{"claim_id":r["claim_id"],"display_value":by_id[r["claim_id"]]["display_value"]}
                     for r in refs if r["page"]==p["page"] and r["reference_type"]=="value"]
        expected=Counter(t for r in occurrences for t in number_tokens(r["display_value"]))
        if p["location"]!="cover":expected[str(p["page"])]+=1
        displays.append({"page":p["page"],"claim_occurrences":occurrences,
                         "expected_numeric_tokens":dict(sorted(expected.items()))})
    write_json(OUT/"display_manifest.json",{"schema_version":"1.0","pages":displays,"exceptions":exceptions})
    tests=failure_tests(records,current["upstream"])
    return checks,tests


def check_pdf(pdf):
    import pymupdf
    doc=pymupdf.open(pdf)
    expected=load_output("display_manifest.json")
    manuscript_pages=load_output("manuscript.json")["pages"]
    runtime_claims=load_output("report_data.json")["claims"]
    if len(doc)!=len(expected["pages"]):raise ValueError(f"Unexpected page count: {len(doc)}")
    reconciliation=[]
    geometries=[]
    for page,display_page in zip(doc,expected["pages"]):
        text=page.get_text("text")
        found=Counter(number_tokens(text))
        wanted=Counter(display_page["expected_numeric_tokens"])
        missing=dict(wanted-found);extra=dict(found-wanted)
        reconciliation.append({"page":page.number+1,"status":"passed" if found==wanted else "failed",
                               "missing":missing,"unexpected":extra,
                               "expected_tokens":sum(wanted.values()),"observed_tokens":sum(found.values())})
        if "\ufffd" in text:raise ValueError("Replacement glyph detected")
        expected_urls=sorted(runtime_claims[cid]["value"] for kind,cid in
                             REF.findall(manuscript_pages[page.number]["typst"])
                             if kind=="raw" and cid.endswith("_url"))
        actual_urls=sorted(link["uri"] for link in page.get_links() if "uri" in link)
        if expected_urls!=actual_urls:raise ValueError("Saved source URL links differ in PDF")
        outside=[]
        for block in page.get_text("dict")["blocks"]:
            for line in block.get("lines",[]):
                for span in line["spans"]:
                    if not page.rect.contains(pymupdf.Rect(span["bbox"])):
                        outside.append({"text":span["text"],"bbox":span["bbox"]})
        geometries.append({"page":page.number+1,"text_spans_outside_page":outside})
        if outside:raise ValueError("Text outside page boundary")
        write_text(OUT/"extracted"/f"page-{page.number+1:02d}.txt",text)
    result={"status":"passed" if all(p["status"]=="passed" for p in reconciliation) else "failed",
            "normalization":"U+00A0/U+202F spaces normalize within thousands; Croatian decimal comma retained; page numbers explicitly enumerated",
            "pages":reconciliation}
    write_json(OUT/"pdf_numeric_reconciliation.json",result)
    if result["status"]!="passed":raise ValueError("PDF numerical tokens differ from display manifest")
    fonts=sorted({font[3] for p in doc for font in p.get_fonts()})
    for font in fonts:
        family=font.split("+")[-1]
        if not family.startswith(("PalatinoLinotype","SegoeUI")):
            raise ValueError("Unrecorded or fallback font embedded: "+font)
    return result,{"name":"pdf_geometry_and_fonts","status":"passed","pages":geometries,"embedded_fonts":fonts}


def finish_verification(pdf,checks,tests):
    reconc,geometry=check_pdf(pdf)
    checks.append(geometry)
    checks.append({"name":"final_source_hashes","result":verify_all()})
    result={"schema_version":"1.0","status":"passed","checked_at":datetime.now(timezone.utc).isoformat(),
            "checks":checks,"failure_tests":tests,"pdf_sha256":sha256(pdf),
            "pdf_numeric_reconciliation":reconc,
            "meaning":"Traceability and mechanical consistency only; no semantic validation."}
    write_json(OUT/"verification.json",result)
    return result
