"""Documented JSON Schema subset, validated locally without new dependencies."""
import csv
import json
from evidence_io import *

S={"type":"string"}
N={"type":["number","null"]}
I={"type":"integer"}
B={"type":"boolean"}
A={"type":"array"}
O={"type":"object"}


def obj(properties, required=None):
    return {"type":"object","required":required or list(properties),"properties":properties}


SOURCE=obj({"path":S,"sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"}})
RECORD=obj({
    "id":S,"kind":{"enum":["principal_finding","supporting_measure","illustration","diagnostic","fixed_metadata"]},
    "wording":S,"value":{"type":["string","number","null"]},"display_value":S,
    "unit":S,"scope":S,"period":obj({"start":S,"end":S}),
    "numerator":N,"denominator":N,"source_files":{"type":"array","items":SOURCE,"minItems":1},
    "source_locators":{"type":"array","items":S,"minItems":1},"calculation_id":S,
    "upstream_claim_ids":{"type":"array","items":S},"upstream_publication_statuses":O,
    "report_eligibility":{"enum":["eligible","appendix_only"]},"limitations":{"type":"array","items":S,"minItems":1},
})
SCHEMAS={
 "claim_register.json":obj({"schema_version":S,"records":{"type":"array","items":RECORD,"minItems":1}}),
 "report_data.json":obj({"schema_version":S,"config_hash":S,"claims":O,"equality_checks":A,"number_format":O}),
 "editorial_decision.json":obj({"schema_version":S,"mode":{"enum":["short_evidence_note","editorial_edition"]},
    "qualifying_finding_ids":{"type":"array","items":S},"domains":{"type":"array","items":S},
    "independence_rationale":O,"threshold_passed":B,"decision_reason":S}),
 "source_manifest.json":obj({"schema_version":S,"hash_algorithm":{"enum":["SHA-256"]},
    "files":{"type":"array","items":SOURCE,"minItems":1}}),
 "environment.lock.json":obj({"schema_version":S,"observed":O,"brief_baseline":O,
    "version_differences":A,"executables":O,"executable_sha256":O,"packages_used":O}),
 "font_manifest.json":obj({"schema_version":S,"profile":S,"fonts":{"type":"array","items":SOURCE,"minItems":1},
    "redistributed":B,"fallback_allowed":B,"open_alternatives":O}),
 "figure_manifest.json":obj({"schema_version":S,"figures":{"type":"array","items":obj({
    "id":S,"page":I,"series":{"type":"array","items":obj({"claim_ids":{"type":"array","items":S},"unit":S})},
    "label_claim_ids":{"type":"array","items":S},"axis":O})}}),
 "verification.json":obj({"schema_version":S,"status":{"enum":["passed","failed"]},
    "checks":A,"failure_tests":A,"pdf_sha256":S,"pdf_numeric_reconciliation":O}),
 "visual_review.json":obj({"schema_version":S,"reviewer_type":S,"reviewed_at":S,
    "pdf_sha256":S,"page_count":I,"reviewed_pages":{"type":"array","items":I},
    "unresolved_issues":A,"status":{"enum":["passed","failed","pending"]}}),
 "release_status.json":obj({"schema_version":S,"artifact_status":{"enum":["complete","in_progress","verification_failed"]},
    "human_editorial_review":{"enum":["pending","approved"]},"external_release_authorised":B,
    "pdf_sha256":{"type":["string","null"]}}),
 "display_manifest.json":obj({"schema_version":S,"pages":A,"exceptions":A}),
 "numeric_exceptions.json":obj({"schema_version":S,"exceptions":A}),
 "baseline_verification.json":obj({"schema_version":S,"status":S,"config_hash":S,"checks":A}),
 "manuscript.json":obj({"schema_version":S,"pages":{"type":"array","items":obj({
    "page":I,"location":{"enum":["cover","main","appendix"]},"typst":S})}}),
}


def validate(value,schema,at="$"):
    import re
    if "enum" in schema and value not in schema["enum"]: raise ValueError(f"{at}: enum violation")
    checks={"string":lambda x:isinstance(x,str),
            "number":lambda x:isinstance(x,(int,float)) and not isinstance(x,bool),
            "integer":lambda x:isinstance(x,int) and not isinstance(x,bool),
            "boolean":lambda x:isinstance(x,bool),"null":lambda x:x is None,
            "array":lambda x:isinstance(x,list),"object":lambda x:isinstance(x,dict)}
    if "type" in schema:
        types=schema["type"] if isinstance(schema["type"],list) else [schema["type"]]
        if not any(checks[t](value) for t in types):raise ValueError(f"{at}: type violation")
    if isinstance(value,dict):
        for k in schema.get("required",[]):
            if k not in value:raise ValueError(f"{at}: missing {k}")
        for k,s in schema.get("properties",{}).items():
            if k in value:validate(value[k],s,at+"."+k)
    if isinstance(value,list):
        if len(value)<schema.get("minItems",0):raise ValueError(f"{at}: too few items")
        for i,item in enumerate(value):
            if "items" in schema:validate(item,schema["items"],f"{at}[{i}]")
    if isinstance(value,str) and "pattern" in schema and not re.search(schema["pattern"],value):
        raise ValueError(f"{at}: pattern violation")


def write_schemas():
    for name,schema in SCHEMAS.items():
        write_json(OUT/"schemas"/(name+".schema.json"),{
            "$schema":"https://json-schema.org/draft/2020-12/schema",
            "title":name, **schema})
    write_json(OUT/"schemas/page_map.csv.schema.json",{
        "schema_version":"1.0","format":"CSV","columns":[
            "original_page","original_section","original_question","treatment",
            "new_section","new_question","supporting_claim_ids","decision_reason"],
        "original_page":{"type":"integer","minimum":1,"maximum":34,"unique":True},
        "treatment":{"enum":["retain","adapt","replace","omit"]}})


def validate_package(include_review=False):
    checked=[]
    for name,schema in SCHEMAS.items():
        if name in {"visual_review.json","release_status.json"} and not include_review:continue
        path=OUT/name
        if not path.exists():raise ValueError("Missing deliverable: "+name)
        validate(json.loads(path.read_text(encoding="utf-8")),schema)
        checked.append(name)
    with (OUT/"page_map.csv").open(encoding="utf-8",newline="") as stream:
        reader=csv.DictReader(stream);rows=list(reader)
        expected=["original_page","original_section","original_question","treatment",
                  "new_section","new_question","supporting_claim_ids","decision_reason"]
        assert reader.fieldnames==expected
        assert [int(r["original_page"]) for r in rows]==list(range(1,35))
        assert all(r["treatment"] in {"retain","adapt","replace","omit"} for r in rows)
    checked.append("page_map.csv")
    return {"status":"passed","files":checked}
