# Flatten the Wikidata office register (written by the catholic-voices-network run) to a UTF-8 TSV.
# Read-only on the source; writes only into this exploration's output/.
import csv, json, re, sys
src = sys.argv[1]
d = json.load(open(src, encoding="utf-8"))
offices = {}
for o in d["offices"]:
    lab = o.get("office_label_hr") or o["office_labels"].get("en", "")
    s, e = o.get("start_earliest") or "?", o.get("end_latest") or ""
    offices.setdefault(o["entity_qid"], []).append(f"{lab} ({s}–{e})" if e else f"{lab} (od {s})")
def first_date(v):
    # Wikidata dates arrive as [earliest, latest] pairs; either end may be None.
    for pair in v or []:
        for x in pair or []:
            if x: return x
    return ""
CATH = re.compile(r"biskup|nadbiskup|nuncij|kardinal|papa|apostolsk|vikar|opat|provincijal|bishop|archbishop|pope|cardinal|nuncio|abbot|prelate|eparch", re.I)
with open("output/register_people.tsv", "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t")
    w.writerow(["qid", "name", "name_en", "aliases_hr", "alive", "birth", "death", "description", "catholic_office", "offices"])
    for p in d["people"]:
        name = p["labels"].get("hr") or p["label"]
        offs = offices.get(p["qid"], [])
        desc = p["descriptions"].get("hr") or p["descriptions"].get("en") or ""
        w.writerow([p["qid"], name, p["labels"].get("en", ""), " | ".join(p["aliases"].get("hr", [])),
                    "ne" if first_date(p["death"]) or p["death"] else "da",
                    first_date(p["birth"]), first_date(p["death"]),
                    desc, "da" if any(CATH.search(x) for x in offs) else "ne", " ; ".join(offs)])
print("people", len(d["people"]))
