# Top 50 register people per platform, from output/register_mentions.csv. Writes CSV + Markdown.
import csv
rows = list(csv.DictReader(open("output/register_mentions.csv", encoding="utf-8-sig")))
plats = [c[2:] for c in rows[0] if c.startswith("p_")]
def num(v):
    return int(v) if v not in ("", "NA") else 0
out, md = [], ["# Najspominjanije osobe iz registra službi, po platformi\n",
               "Broj dokumenata u kojima se pojavljuje puno ime (s padežnim nastavcima). Samo osobe iz Wikidata registra službi; nije ljudski provjereno.\n"]
for p in plats:
    ranked = sorted((r for r in rows if num(r["p_" + p]) > 0), key=lambda r: (-num(r["p_" + p]), r["name"]))[:50]
    total = sum(1 for r in rows if num(r["p_" + p]) > 0)
    md.append(f"\n## {p} ({total} osoba s barem jednim spomenom)\n\n| # | Osoba | Dokumenata | Katolička služba | Opis | Napomena |\n|---|---|---|---|---|---|")
    for i, r in enumerate(ranked, 1):
        out.append({"platform": p, "rang": i, "osoba": r["name"], "dokumenata": num(r["p_" + p]),
                    "ukupno_svi_kanali": num(r["n_docs"]), "katolicka_sluzba": r["catholic_office"],
                    "ziv": r["alive"], "opis": r["description"], "napomena": r["note"], "qid": r["qid"]})
        md.append(f"| {i} | {r['name']} | {num(r['p_' + p]):,} | {r['catholic_office']} | {r['description'][:60]} | {r['note']} |".replace(",", " "))
with open("output/top50_per_platform.csv", "w", encoding="utf-8-sig", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(out[0])); w.writeheader(); w.writerows(out)
open("output/top50_per_platform.md", "w", encoding="utf-8").write("\n".join(md) + "\n")
for p in plats:
    sub = [o for o in out if o["platform"] == p]
    print(f"== {p}: {len(sub)} listed | " + " ; ".join(f"{o['osoba']} {o['dokumenata']}" for o in sub[:12]))
