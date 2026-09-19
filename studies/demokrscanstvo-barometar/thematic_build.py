"""Fit contextual Croatian topics locally; release aggregate tables only.

Run thematic_prepare.R first. --inspect writes candidate models to the private
work directory. The default build requires reviewed, model-bound topic labels.
"""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import re

import numpy as np
import sklearn
from sklearn.decomposition import NMF
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import adjusted_rand_score
from threadpoolctl import threadpool_limits

from multiplatform_collect import DEFAULT_WORK, sha, write_json

ROOT = Path(__file__).resolve().parents[2]
LABELS = ROOT / "studies/demokrscanstvo-barometar/config/thematic_labels.json"
SEED = 20260919
STOP = set("godina dan put način riječ dio stvar slučaj vrijeme čovjek osoba ljudi velik mali nov prvi drugi treći isti sav svoj naš vaš ovaj taj takav neki svaki dobar loš moguć sam opći ukupan današnji prošli sljedeći hrvatski demokršćanstvo demokršćanski kršćanski demokracija".split())


def clean_terms(lemmas):
    if isinstance(lemmas, str):
        lemmas = [lemmas]
    return [term for term in (lemmas or []) if re.fullmatch(r"[^\W\d_]{3,}", term)
            and term not in STOP and not term.startswith(("demokršć", "demokrsc"))]


def read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]


def load_inputs(work):
    active = json.loads((work / "thematic-active.json").read_text(encoding="utf-8"))
    folder = Path(active["folder"])
    complete = json.loads((folder / "complete.json").read_text(encoding="utf-8"))
    assert complete["identity"] == active["identity"]
    records = sorted(read_jsonl(folder / "contexts.jsonl"), key=lambda r: r["record_key"])
    tokens = {r["context_id"]: clean_terms(r["lemmas"])
              for path in sorted(folder.glob("tokens-*.jsonl")) for r in read_jsonl(path)}
    assert len(records) == len({r["record_key"] for r in records}) == complete["records"]
    ids = sorted({r["context_id"] for r in records})
    assert set(ids) == set(tokens) and len(ids) == complete["distinct_contexts"]
    return folder, records, ids, tokens, active["identity"]


def fit(matrix, k, seed=SEED, init="nndsvda"):
    model = NMF(n_components=k, init=init, random_state=seed, max_iter=1200, tol=1e-4)
    with threadpool_limits(limits=2):
        weights = model.fit_transform(matrix)
    if model.n_iter_ >= model.max_iter:
        raise RuntimeError("NMF did not converge")
    norms = np.linalg.norm(model.components_, axis=1)
    return model, weights * norms, model.components_ / norms[:, None]


def topic_terms(components, vocabulary):
    return [[str(vocabulary[i]) for i in row.argsort()[-16:][::-1]] for row in components]


def csv_write(path, fields, rows):
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def build(work, destination, inspect=False):
    folder, records, ids, tokens, annotation_identity = load_inputs(work)
    vectorizer = TfidfVectorizer(tokenizer=str.split, preprocessor=None, token_pattern=None,
                                 lowercase=False, min_df=5, max_df=.85, max_features=6000,
                                 sublinear_tf=True, norm="l2")
    matrix = vectorizer.fit_transform(" ".join(tokens[key]) for key in ids)
    vocabulary = vectorizer.get_feature_names_out()
    index = {key: i for i, key in enumerate(ids)}
    record_indices = np.array([index[r["context_id"]] for r in records])
    signature = hashlib.sha256(json.dumps({"contexts":sha(folder/"contexts.jsonl"),
        "tokens":{p.name:sha(p) for p in sorted(folder.glob("tokens-*.jsonl"))},
        "vocabulary":vocabulary.tolist(),"stop":sorted(STOP),"seed":SEED,
        "sklearn":sklearn.__version__,"numpy":np.__version__,
        "min_df":5,"max_df":.85,"max_features":6000,"sublinear_tf":True},
        ensure_ascii=False,sort_keys=True).encode()).hexdigest()
    if inspect:
        reports = []
        context = {r["context_id"]:r["context"] for r in records}
        for k in (6,8,10,12):
            model, weights, components = fit(matrix,k)
            assigned = weights.argmax(axis=1)
            counts = Counter(assigned[record_indices])
            terms = topic_terms(components,vocabulary)
            report = {"k":k,"iterations":model.n_iter_,"error":model.reconstruction_err_,
                      "signature":signature,"topics":[]}
            for topic in range(k):
                representative = np.flatnonzero(assigned==topic)
                representative = representative[np.argsort(weights[representative,topic])[::-1]][:6]
                report["topics"].append({"topic":topic,"records":counts[topic],"terms":terms[topic],
                    "examples":[context[ids[i]] for i in representative]})
            reports.append(report)
        write_json(folder/"candidate-models.json",reports)
        for report in reports:
            print(json.dumps({"k":report["k"],"signature":signature,
                "topics":[{key:value for key,value in t.items() if key!="examples"} for t in report["topics"]]},ensure_ascii=False))
        return
    labels = json.loads(LABELS.read_text(encoding="utf-8"))
    assert labels["model_signature"] == signature, "Review labels after an input/model change"
    k = labels["n_components"]
    model, weights, components = fit(matrix,k)
    assert len(labels["topics"]) == k
    assignments = weights.argmax(axis=1)
    assignments[np.asarray(matrix.getnnz(axis=1))==0] = -1
    terms = topic_terms(components,vocabulary)
    stability=[]
    for seed in (23,71,113):
        _, alternative, _ = fit(matrix,k,seed,init="random")
        alternate = alternative.argmax(axis=1)
        nonzero=np.asarray(matrix.getnnz(axis=1))>0
        stability.append(float(adjusted_rand_score(assignments[nonzero],alternate[nonzero])))
    cells=Counter()
    for record,idx in zip(records,record_indices):
        topic=f"t{assignments[idx]+1:02d}" if assignments[idx]>=0 else "unassigned"
        cells[(record["platform"],record["month"],topic)] += 1
    monthly=[dict(platform=p,month=m,topic=t,records=n) for (p,m,t),n in sorted(cells.items())]
    totals=Counter()
    for row in monthly:totals[row["topic"]]+=row["records"]
    topic_rows=[]
    for topic,label in enumerate(labels["topics"]):
        assert label["id"]==f"t{topic+1:02d}"
        topic_rows.append({**label,"records":totals[label["id"]],
                           "share":100*totals[label["id"]]/len(records),"terms":terms[topic][:10]})
    if totals["unassigned"]:
        topic_rows.append({"id":"unassigned","label":"Ostali konteksti","editorial_note":"Kratki ili jezično različiti konteksti bez dovoljno zajedničkog tematskog rječnika.",
            "terms":[],"records":totals["unassigned"],"share":100*totals["unassigned"]/len(records)})
    base=ROOT/"data/barometar/demokrscanstvo-multiplatform/v1"
    base_summary=json.loads((base/"summary.json").read_text(encoding="utf-8"))
    with (base/"monthly.csv").open(encoding="utf-8") as handle:
        expected={(r["platform"],r["month"]):int(r["matching_records"]) for r in csv.DictReader(handle)}
    observed=Counter()
    for row in monthly:observed[(row["platform"],row["month"])]+=row["records"]
    assert all(observed[key]==n for key,n in expected.items()) and not set(observed)-set(expected)
    assert len(records)==sum(totals.values())==base_summary["matching_records"]
    destination.mkdir(parents=True,exist_ok=True)
    csv_write(destination/"topic_monthly.csv",["platform","month","topic","records"],monthly)
    csv_write(destination/"topics.csv",["topic","label","records","share"],
        [dict(topic=r["id"],label=r["label"],records=r["records"],share=round(r["share"],6)) for r in topic_rows])
    summary={"schema":"barometar-themes-v1","records":len(records),"distinct_contexts":len(ids),
        "data_from":base_summary["data_from"],"data_through":base_summary["data_through"],
        "base_manifest_sha256":sha(base/"manifest.json"),"topics":topic_rows,
        "method":{"algorithm":"TF-IDF / NMF","n_components":k,"vocabulary_size":len(vocabulary),
            "min_document_frequency":5,"max_document_frequency":.85,"max_features":6000,
            "sublinear_tf":True,"normalization":"L2","seed":SEED,"iterations":model.n_iter_,
            "fit_unit":"distinct normalized qualifying context; all records counted after assignment",
            "assignment":"largest component contribution after L2 normalization of component vectors",
            "context_policy":"union of original qualifying A1/B/C windows, at most 80 tokens each",
            "parts_of_speech":["NOUN","PROPN","ADJ"],"unassigned_records":totals["unassigned"],
            "random_start_ari":stability,"sklearn":sklearn.__version__,"numpy":np.__version__,
            "udpipe":annotation_identity["udpipe"],"udpipe_model_sha256":annotation_identity["udpipe_model"],
            "model_signature":signature,"generator_sha256":sha(__file__),"labels_sha256":sha(LABELS)}}
    write_json(destination/"summary.json",summary)
    (destination/"README.md").write_text((ROOT/"studies/demokrscanstvo-barometar/THEMATIC.md").read_text(encoding="utf-8"),encoding="utf-8")
    write_json(destination/"manifest.json",{"schema":summary["schema"],
        "files":{name:sha(destination/name) for name in ("topic_monthly.csv","topics.csv","summary.json","README.md")}})
    # Assignment rows and feature matrices remain private.
    write_json(folder/"assignments.json",[{"record_key":r["record_key"],"topic":int(assignments[i])}
        for r,i in zip(records,record_indices)])
    print(json.dumps({"records":len(records),"distinct_contexts":len(ids),"vocabulary":len(vocabulary),
        "topics":[{"label":r["label"],"records":r["records"]} for r in topic_rows],
        "stability_ari":stability},ensure_ascii=False))


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--work",type=Path,default=DEFAULT_WORK)
    parser.add_argument("--destination",type=Path,default=ROOT/"data/barometar/demokrscanstvo-themes/v1")
    parser.add_argument("--inspect",action="store_true")
    args=parser.parse_args()
    build(args.work,args.destination,args.inspect)
