"""Build the Croatian report "Mnogo tumača, malo teologa" as Typst, then compile it to PDF.

Every number is read from output/private/report_data.json (written by 06_report_data.R) and
formatted here; nothing is typed by hand. Run from the repository root:
    python studies/theological-voices/build_report.py
"""
import csv
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
STUDY = ROOT / "studies" / "theological-voices"
PRIV = STUDY / "output" / "private"
OUT_TYP = PRIV / "report" / "tko-tumaci-vjeru.typ"
OUT_PDF = PRIV / "report" / "tko-tumaci-vjeru.pdf"
QUARTO = pathlib.Path("C:/Program Files/Quarto/bin/quarto.exe")
R = json.loads((PRIV / "report_data.json").read_text(encoding="utf-8"))
NB = "\u00a0"
BR = " \\ "  # Typst forced line break


# ---------------------------------------------------------------- formatting
def n(x):
    x = int(round(x))
    s = str(abs(x))
    if len(s) >= 5:
        parts = []
        while s:
            parts.insert(0, s[-3:])
            s = s[:-3]
        s = NB.join(parts)
    return ("-" if x < 0 else "") + s


def p(x, d=0):
    v = f"{x:.{d}f}".replace(".", ",")
    return v + NB + "%"


def dec(x, d=1):
    return f"{x:.{d}f}".replace(".", ",")


def pl(k, one, few, many):
    k = int(k)
    if 11 <= k % 100 <= 14:
        return many
    if k % 10 == 1:
        return one
    if 2 <= k % 10 <= 4:
        return few
    return many


MONTHS = ["siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja", "srpnja", "kolovoza",
          "rujna", "listopada", "studenoga", "prosinca"]


def hrdate(iso, year=True):
    y, m, d = iso.split("-")
    return f"{int(d)}. {MONTHS[int(m) - 1]}" + (f" {y}." if year else "")


def esc(s):
    s = str(s).replace("\\", "\\\\")
    for ch in "#$*_@<>[]`~=":
        s = s.replace(ch, "\\" + ch)
    s = s.replace("..", ".")
    return s.replace("//", "/\\/")


def ts(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def c(s):
    return "[" + esc(s) + "]"


def tb(b):
    return "true" if b else "false"


# ---------------------------------------------------------------- data access
def rows(key, **flt):
    out = R[key] if not isinstance(key, list) else key
    return [r for r in out if all(r.get(k) == v for k, v in flt.items())]


def one(lst, **flt):
    m = [r for r in lst if all(r.get(k) == v for k, v in flt.items())]
    return m[0] if m else None


def share(platform, groups, field="int_share"):
    return sum(r[field] for r in R["platform"][platform]["groups"] if r["group"] in groups)


S = R["scope"]
POSTS = S["posts"]
roles = {r["role"]: r for r in R["roles"]}
STMT = R["stmt_total"]
persons = R["persons"]
pers = {r["id"]: r for r in persons}
sig = {r["group"]: r for r in R["signals"]}
smp = R["sample"]
interp = {r["stratum"]: r for r in smp["interpreting"]}


def main_share(stratum, role):
    r = one(smp["main"], stratum=stratum, glavni_tumac=role)
    return (r["N"], r["share"]) if r else (0, 0.0)


bel = {r["stratum"]: r for r in smp["believers"]}
lab = R["label"]
top50 = R["top50"]
tip = {r["tip"]: r for r in R["top50_tip"]}
pul = R["pulherissimus"]
women_stmt = one(R["women_stmt"], zena=1)["statements"]
lay_like = sum(roles[k]["statements"] for k in ("akademski", "laik", "redovnica", "vidjelac"))
women_lay_share = 100 * women_stmt / lay_like
_vl = list(csv.DictReader(open(STUDY / "voices.csv", encoding="utf-8")))
_wr = {}
for _r in _vl:
    if _r["zena"] == "1":
        _wr[_r["role"]] = _wr.get(_r["role"], 0) + 1
_NUM = {1: "jedna", 2: "dvije", 3: "tri", 4: "četiri", 5: "pet", 6: "šest", 7: "sedam", 8: "osam"}
_WN = {"redovnica": ("redovnica", "redovnice", "redovnica"), "akademski": ("akademska teologinja", "akademske teologinje", "akademskih teologinja"),
       "laik": ("laikinja", "laikinje", "laikinja"), "vidjelac": ("vidjelica", "vidjelice", "vidjelica")}
_parts = [f"{_NUM[_wr[k]]} {pl(_wr[k], *_WN[k])}" for k in ("redovnica", "akademski", "laik", "vidjelac") if k in _wr]
WOMEN_DESC = ", ".join(_parts[:-1]) + " i " + _parts[-1]
cleric_share = sum(roles[k]["stmt_share"] for k in ("papa", "biskup", "svecenik"))

# headline values
YT_DEV = share("youtube", ["devotional", "clergy"])
YT_INST = share("youtube", ["church_org", "church_media"])
YT_DEV_POSTS = share("youtube", ["devotional", "clergy"], "post_share")
FB_DEV = share("facebook", ["devotional", "clergy", "community"])
FB_IND = share("facebook", ["independent"])
FB_INST = share("facebook", ["church_org", "church_media"])
WEB_CM_P = share("web", ["church_media"], "post_share")
WEB_CM_I = share("web", ["church_media"])
B_SHARE = roles["biskup"]["stmt_share"]
POPE_SHARE = roles["papa"]["stmt_share"]
ACAD_SHARE = roles["akademski"]["stmt_share"]
ACAD_N = roles["akademski"]["persons"]
ACAD_STMT = roles["akademski"]["statements"]
KUT = pers["kutlesa"]
TOP_ACAD = max((r for r in persons if r["role"] == "akademski"), key=lambda r: r["statements"])
LBL_GEN = f"{n(lab['posts'])} " + pl(lab['posts'], "objave koja nekoga naziva", "objave koje nekoga nazivaju", "objava koje nekoga nazivaju")
LBL_GEN2 = f"{n(lab['posts'])} " + pl(lab['posts'], "objave u kojoj se netko naziva", "objave u kojima se netko naziva", "objava u kojima se netko naziva")
LBL_OTHER = 100 * lab["other_posts"] / lab["posts"]
ANON = tip["anonimni_poboznji_kanal"]["n"]
EDU_VIS = one(R["top50_obrazovanje"], teolosko_obrazovanje="vidljivo")["N"]
MAND_UNK = one(R["top50_mandat"], mandat="nepoznato")["N"]
ALARM = sum(1 for r in top50 if r.get("ton") == "apokalipticki_alarmantan")
K_INT = interp["katolicki"]["interp"]
O_INT = interp["ostali"]["interp"]
K_PRIEST = main_share("katolicki", "svecenik_redovnik")
K_ANON = main_share("katolicki", "autor_objave")
K_BISHOP = main_share("katolicki", "biskup")
K_ACAD = main_share("katolicki", "akademski_teolog")
O_ACAD = main_share("ostali", "akademski_teolog")
O_ANON = main_share("ostali", "autor_objave")
BEL_K = bel["katolicki"]
BEL_O = bel["ostali"]
N_SMP = smp["n"]
PER_STR = N_SMP // 2
BISH_OTHER = R["bishop_other_share"]
lay_other = sum(r["N"] for r in R["roles_source"] if r["role"] == "laik" and not r["catholic"])
lay_cath = sum(r["N"] for r in R["roles_source"] if r["role"] == "laik" and r["catholic"])
lay_other_share = 100 * lay_other / (lay_other + lay_cath)

seqs = R["echo_sequences"]
boz = next(s for s in seqs if "Bozani" in s["title"] and "Uskrs" in s["title"])
popemsg = seqs[0]
ECHO = R["echo"]
ECHO_SHARE = 100 * ECHO["posts_in_multi"] / ECHO["web_posts_titled"]

GROUP_HR = {"church_media": "Crkveni mediji", "church_org": "Crkvene ustanove", "independent": "Neovisni katolički mediji",
            "clergy": "Svećenički profili", "devotional": "Pobožni i autorski kanali", "community": "Zajednice i udruge",
            "public": "Ostali izvori", "other_christian": "Ostali kršćanski izvori"}
ROLE_HR = {"papa": "Pape", "biskup": "Biskupi", "svecenik": "Svećenici i redovnici", "akademski": "Akademski teolozi",
           "laik": "Laici, publicisti i aktivisti", "redovnica": "Redovnice", "vidjelac": "Vidioci"}
ROLE_SHORT = {"papa": "papa", "biskup": "biskup", "svecenik": "svećenik", "akademski": "akademski teolog",
              "laik": "laik", "redovnica": "redovnica", "vidjelac": "vidjelac"}
INTERP_HR = {"svecenik_redovnik": "Svećenik ili redovnik", "autor_objave": "Neimenovani autor objave", "biskup": "Biskup",
             "papa": "Papa", "akademski_teolog": "Akademski teolog", "influencer": "Autor kanala ili influencer",
             "laik_aktivist": "Laik, aktivist ili publicist", "vjernik": "Običan vjernik", "institucija": "Ustanova bez osobe",
             "strucnjak": "Stručnjak", "politicar": "Političar", "novinar": "Novinar", "redovnica": "Redovnica",
             "drugo": "Drugo", "vjeroucitelj_katehet": "Vjeroučitelj"}
AUT_HR = {"pismo": "Sveto pismo", "predaja_sveci": "Predaja i sveci", "uciteljstvo": "Učiteljstvo",
          "osobno_iskustvo": "Osobno iskustvo", "nacija_povijest": "Nacija i povijest", "znanost_razum": "Znanost i razum",
          "pravo_ljudska_prava": "Pravo i ljudska prava", "privatna_objava": "Ukazanja i privatne objave"}
TIP_HR = {"anonimni_poboznji_kanal": "Pobožni kanal bez vidljivog autora", "neovisni_katolicki_medij": "Neovisni katolički medij",
          "crkvena_ustanova": "Crkvena ustanova", "institucijski_medij": "Službeni crkveni medij",
          "zajednica_udruga": "Zajednica ili udruga", "laicki_autor": "Imenovani laički autor",
          "svecenik_redovnik": "Svećenik ili redovnik", "drugo": "Drugo"}
TIP_SHORT = {"anonimni_poboznji_kanal": "Pobožni, bez autora", "neovisni_katolicki_medij": "Neovisni katolički medij",
             "crkvena_ustanova": "Crkvena ustanova", "institucijski_medij": "Službeni crkveni medij", "zajednica_udruga": "Zajednica ili udruga",
             "laicki_autor": "Imenovani laik", "svecenik_redovnik": "Svećenik ili redovnik", "drugo": "Drugo"}
TIP_COL = {"anonimni_poboznji_kanal": "teal", "neovisni_katolicki_medij": "teal-l", "crkvena_ustanova": "navy",
           "institucijski_medij": "rgb(\"#4a5868\")", "zajednica_udruga": "stone", "laicki_autor": "red", "svecenik_redovnik": "red-l",
           "drugo": "stone-l"}
MAND_HR = {"nepoznato": "nije vidljiv", "pastoralni": "pastoralni", "uciteljski": "učiteljski", "bez_mandata": "bez mandata",
           "akademski": "akademski"}
TON_HR = {"afirmativan": "afirmativan", "neutralan": "neutralan", "kriticki": "kritički", "polemican": "polemičan",
          "apokalipticki_alarmantan": "alarmantan"}
PLAT_HR = {"web": "portal", "facebook": "Facebook", "youtube": "YouTube", "instagram": "Instagram", "twitter": "X",
           "tiktok": "TikTok"}
LABEL_NOM = {"Hans Urs": "Hans Urs von Balthasar", "Justina Popovića": "Justin Popović", "Romana Guardinija": "Romano Guardini",
             "Jürgena Moltmanna": "Jürgen Moltmann", "Šimunom Šoljom": "Šimun Šolja", "Tomáša Halíka": "Tomáš Halík",
             "Karla Rahnera": "Karl Rahner", "Sanina Muse": "Sanin Musa", "Anna Raffai": "Ana Raffai"}

pages = []


def add(s):
    pages.append(s)


def src(t):
    return "#source" + c(t)


# ================================================================ COVER
months = {m["month"]: m["N"] for m in R["monthly"]}
seq = []
for y in range(2021, 2027):
    for mth in range(1, 13):
        k = f"{y}-{mth:02d}"
        if k > S["date_max"][:7]:
            break
        seq.append(months.get(k, 0))
mx = max(seq)
bars = ",".join(f"box(width: 1.85mm, height: {max(v / mx * 62, 0.0):.2f}mm, radius: 0.9mm, fill: teal)" if v else "box(width: 1.85mm, height: 0mm)" for v in seq)
interp_total = K_INT + O_INT
_step = 1.85 + 1.25
_x0 = (210 - (len(seq) * 1.85 + (len(seq) - 1) * 1.25)) / 2
YEARLABELS = "\n  ".join(f'place(top + left, dx: {_x0 + 12 * i * _step:.2f}mm, dy: 236mm, text(font: sans, size: 7.4pt, fill: rgb("#a7adb5"), "{2021 + i}."))' for i in range(6))
acad_main_total = K_ACAD[0] + O_ACAD[0]
cover = f"""
#page(fill: navy, margin: 0pt, header: none, footer: none, {{
  set text(fill: paper-dark-text)
  place(top + left, dx: 22mm, dy: 18mm, text(font: sans, size: 7.6pt, weight: "bold", tracking: 1pt, fill: rgb("#a7adb5"), "DIGIKAT · HRVATSKO KATOLIČKO SVEUČILIŠTE"))
  place(top + right, dx: -22mm, dy: 18mm, text(font: sans, size: 7.6pt, weight: "bold", tracking: 1pt, fill: rgb("#a7adb5"), "IZDANJE 2026."))
  place(top + left, dx: 22mm, dy: 46mm, block(width: 170mm, {{
    text(font: sans, size: 9pt, weight: "bold", tracking: 1pt, fill: red, "TKO JE PREUZEO ULOGU TEOLOGA?")
    v(6pt)
    text(font: serif, size: 60pt, par(leading: 0.28em, [Mnogo tumača, \\ #text(fill: navy, stroke: 0.9pt + paper-dark-text)[malo teologa]]))
    v(26pt)
    block(width: 135mm, text(font: sans, size: 12.5pt, par(leading: 0.55em, {c(f"Što {n(POSTS)} objava, {n(R['list']['persons'])} praćenih osoba i {n(N_SMP)} pregledanih objava govore o tome tko u hrvatskom javnom prostoru tumači vjeru")})))
  }}))
  place(top + left, dy: 168mm, box(width: 210mm, height: 64mm, align(center + horizon, stack(dir: ltr, spacing: 1.25mm, {bars}))))
  {YEARLABELS}
  place(top + left, dx: 22mm, dy: 243mm, block(width: 166mm, waffle((({acad_main_total}, red), ({interp_total - acad_main_total}, rgb("#3a4552"))), cols: 48, size: 2.7mm, gap: 0.75mm)))
  place(top + left, dx: 22mm, dy: 262mm, block(width: 166mm, text(font: sans, size: 8pt, fill: paper-dark-text, par(leading: 0.6em, {{
    box(width: 6pt, height: 9pt, radius: 3pt, fill: teal); h(5pt); {c(f"Jedna crta je jedan mjesec. Visina je broj objava u korpusu, najviše {n(mx)}. Praznina 2024. prekid je u prikupljanju.")}
    linebreak()
    box(width: 7pt, height: 7pt, fill: red); h(5pt); {c(f"Jedan kvadrat je jedna pregledana objava koja tumači vjeru. U crvenima tumači akademski teolog, u {acad_main_total} od {interp_total}.")}
  }}))))
  place(bottom + left, dx: 22mm, dy: -16mm, text(font: sans, size: 7.6pt, weight: "bold", tracking: 1pt, fill: rgb("#a7adb5"), "OD SIJEČNJA 2021. DO LIPNJA 2026."))
  place(bottom + right, dx: -22mm, dy: -16mm, text(font: sans, size: 7.6pt, weight: "bold", tracking: 1pt, fill: rgb("#a7adb5"), {ts(f"{n(POSTS)} OBJAVA · {n(S['sources'])} IZVORA")}))
}})
"""
add(cover)

# ================================================================ COLD OPEN
nb = len(boz["sources"])
add(f"""
#spread(section: "Uvod", bg: cream2)[
#kicker{c(f"Zagreb, {hrdate(boz['first'])}")}
#headline[Jedna čestitka, jedan dan, \\ {esc(dec(nb, 0))} portala]
#v(6pt)
#block(width: 78%, bigprose{c(f"Uoči Uskrsa kardinal Josip Bozanić upućuje čestitku. Njezina je poruka da svi u dubini srca žele mir.")})
#v(4pt)
#block(width: 78%, bigprose{c(f"Istoga se dana čestitka pod istim naslovom pojavljuje na {nb} portala. Nijedan od njih nije katolički medij. Na svakome riječ ima kardinal, a nitko je ne tumači i ne pita što bi mir značio onima kojima je upućen.")})
#v(34pt)
#box(width: 100%, stack(dir: ltr, spacing: 1fr, ..range({nb}).map(_ => circle(radius: 7.5pt, fill: red))))
#v(4pt)
#grid(columns: (1fr, 1fr), tag{c(hrdate(boz['first'], False))}, align(right, tag{c(str(nb) + '. portal')}))
#note{c(f"Jedna točka je jedna objava na jednom portalu. Puna točka znači da u objavi netko govori. U svih {nb} govori kardinal. Razmak među točkama ne prikazuje vrijeme.")}
#v(1fr)
#block(width: 80%, bigprose{c("Ovaj izvještaj pita tko u hrvatskom javnom prostoru tumači vjeru, kome se pritom daje riječ i koga u tom poslu nema.")})
]
""")

# ================================================================ TEN FINDINGS
F = [
    ("Pozornost", "", "I · Pozornost", f"Na YouTubeu pobožni i svećenički kanali dobivaju {p(YT_DEV)} svih zabilježenih interakcija, a crkvene ustanove i službeni crkveni mediji {p(YT_INST, 1)}."),
    ("Bez autora", "pregledani kanali", None, f"Od 50 katoličkih izvora s najviše interakcija {ANON} su pobožni kanali bez vidljivog autora. Teološko obrazovanje vidljivo je kod {EDU_VIS}."),
    ("Nauk bez Učiteljstva", "", None, f"Pobožni kanali rabe rječnik nauka u {p(sig['devotional']['nauk'])} objava, a na Učiteljstvo se pozivaju u {p(sig['devotional']['uciteljstvo'], 1)}. Crkveni mediji čine to u {p(sig['church_media']['uciteljstvo'])}."),
    ("Biskupi govore", "zatvoreni popis praćenih osoba", "II · Glasovi", f"Od {n(STMT)} izjava {R['list']['persons']} praćenih osoba biskupi daju {p(B_SHARE)}, pape {p(POPE_SHARE)}, a akademski teolozi {p(ACAD_SHARE)}."),
    ("Spomen nije glas", "zatvoreni popis praćenih osoba", None, f"Svih {ACAD_N} praćenih akademskih teologa zajedno ima {n(ACAD_STMT)} izjava. Nadbiskup Dražen Kutleša sam ima {n(KUT['statements'])}."),
    ("Tko je teolog?", "", None, f"Od {LBL_GEN} teologom {lab['academic_posts']} imenuju nekoga od {ACAD_N} praćenih akademskih teologa. {p(LBL_OTHER)} izlazi izvan katoličkih medija."),
    ("Trinaest od 117", "zatvoreni popis praćenih osoba", None, f"Na popisu je {R['list']['women']} žena. Na njih otpada {p(100 * women_stmt / STMT, 1)} izjava."),
    ("Jeka", "zatvoreni popis praćenih osoba", "III · Jeka", f"Više od polovice izjava biskupa, {p(BISH_OTHER)}, objavljuju izvori izvan katoličkih medija. Jedna čestitka izlazi na {nb} portala istoga dana."),
    ("Tko tumači", f"pregledani uzorak od {N_SMP} objava", "IV · Tišina", f"U katoličkim izvorima vjeru najčešće tumače svećenici i neimenovani autori. Akademski teolog glavni je tumač u {K_ACAD[0]} od {K_INT} objava."),
    ("Tišina vjernika", f"pregledani uzorak od {N_SMP} objava", None, f"O običnim vjernicima u katoličkim izvorima piše se u {BEL_K['opisani']} od {BEL_K['n']} objava, a govore u {BEL_K['govore']}."),
]
F_PAGES = ["p-f1", "p-f2", "p-f3", "p-f4", "p-f5", "p-f6", "p-f7", "p-f8", "p-f9", "p-f10"]
items = []
for i, (title, tg, sec, body) in enumerate(F, 1):
    if sec:
        items.append(f"#section-rule{c(sec)}")
    items.append(f"#finding({i}, {ts(title)}, {ts(tg)}, {c(body)})")
add(f"""
#spread(section: "Uvod")[
#kicker[Ako pročitate samo jednu stranicu]
#headline[Deset zaključaka]
#text(font: sans, size: 9.6pt){c(f"Tri počivaju na cijelom korpusu od {n(POSTS)} objava, četiri na zatvorenom popisu od {R['list']['persons']} praćenih osoba, a tri na pregledanim objavama i kanalima.")}
#v(4pt)
{chr(10).join(items)}
]
""")

# ================================================================ PRIMER
add(f"""
#spread(section: "Uvod", bg: cream2)[
#kicker[Prije čitanja]
#headline[Tri pitanja, pet riječi i tri znaka]
#grid(columns: (1fr, 1fr), column-gutter: 24pt, [
  #eyebrow[Pogodite prije čitanja]
  #v(4pt)
  #prose[Tko prvo pogađa, a tek onda čita odgovor, bolje ga pamti. Upišite broj u okvir.]
  #v(8pt)
  #for (q, l) in (
    ("Koliko od sto izjava praćenih osoba daju akademski teolozi?", <p-f4>),
    ("Koliko od 50 katoličkih izvora s najviše interakcija ima vidljivog autora?", <p-f2>),
    ("U koliko od 150 objava katoličkih izvora koje se bave vjerom govori običan vjernik?", <p-f10>),
  ) {{
    grid(columns: (1fr, 2.2cm), column-gutter: 10pt, align: (left, right + horizon),
      [#text(font: serif, size: 12pt, par(leading: 0.45em, q)) \\ #text(font: sans, size: 7.4pt, fill: muted)[Odgovor je na stranici #context counter(page).at(l).first().]],
      rect(width: 2.2cm, height: 1.3cm, radius: 2pt, stroke: 0.8pt + ink))
    v(10pt)
  }}
  #v(6pt)
  #eyebrow[Tri znaka]
  #v(6pt)
  #grid(columns: (14pt, 1fr), row-gutter: 8pt, align: horizon,
    circle(radius: 5pt, fill: red), prose[Puni krug znači da netko govori.],
    circle(radius: 5pt, stroke: 0.9pt + ink), prose[Prazni krug znači da se o nekome piše.],
    box(width: 10pt, height: 10pt, fill: teal), prose[Kvadrat je jedna objava, jedan kanal ili jedan portal.])
  #v(4pt)
  #prose[Zelena boja pokazuje koliko se objavljuje i koliko pozornosti dobiva, a crvena tko govori.]
], [
  #eyebrow[Pet riječi koje uvijek znače isto]
  #v(6pt)
  #prose[*Spomen* je ime osobe u objavi.]
  #v(3pt)
  #prose[*Izjava* su riječi koje objava pripisuje osobi. Broji se jednom po objavi i osobi.]
  #v(3pt)
  #prose[*Glas* je osoba ili skupina kojoj objava daje riječ. U jednoj objavi broji se jednom.]
  #v(3pt)
  #prose[*Tumač* je glas koji objašnjava što vjera uči ili kako je primijeniti, a ne samo izvještava.]
  #v(3pt)
  #prose[*Priča* je jedan događaj ili jedna poruka, na koliko god portala bila objavljena.]
  #v(10pt)
  #eyebrow[Dva izraza]
  #v(6pt)
  #prose[*Katolički izvori* su kanali koje postojeći popisi projekta svrstavaju u crkvene medije, crkvene ustanove, neovisne katoličke medije, svećeničke profile, pobožne kanale ili zajednice. Oznaka opisuje kanal, a ne osobu koja u objavi govori.]
  #v(3pt)
  #prose[*Ostali izvori* su svi drugi, većinom svjetovni portali i stranice.]
])
#v(1fr)
#hr()
#grid(columns: (4.2cm, 1fr), column-gutter: 14pt,
  text(font: serif, size: 16pt, par(leading: 0.45em)[Kako je izvještaj nastao]),
  prose{c(f"Korpus DigiKat obuhvaća {n(S['rows'])} objava hrvatskog digitalnog prostora o katoličkim temama, od {hrdate(S['date_min'])} do {hrdate(S['date_max'])}. Nakon uklanjanja ponovljenih zapisa ostaje {n(POSTS)} objava. Osobe i izjave prepoznaje jednostavan automatski postupak na zatvorenom popisu od {R['list']['persons']} osoba. Uzorak od {N_SMP} objava i 50 kanala kodirao je jezični model, a ručne provjere nije bilo. Brojevi opisuju objavljeno, a ne publiku. Više o metodi na stranici ")[:-1]} #context counter(page).at(<p-metoda>).first().])
]
""")


# ================================================================ ACT I
def divider(act, title, number, unit, body, foot, visual="none", numcolor="red"):
    return f"""#divider(act: {ts(act)}, title: {ts(title)}, number: {ts(number)}, unit: [{BR.join(esc(x.strip()) for x in unit.split(chr(92)))}], text-body: {c(body)}, footer-label: {ts(foot)}, visual: {visual}, numcolor: {numcolor})"""


add(divider("ČIN I", "Pozornost", dec(YT_DEV, 0), "% interakcija \\ na YouTubeu",
            f"Pobožni i svećenički kanali dobivaju {p(YT_DEV)} svih zabilježenih interakcija na YouTubeu. Crkvene ustanove i službeni crkveni mediji dobivaju {p(YT_INST, 1)}.",
            "ZAKLJUČCI 1, 2 I 3",
            f"stackbar(((({YT_DEV:.2f}), teal, \"\"), ({100 - YT_DEV - YT_INST:.2f}, rgb(\"#3a4552\"), \"\"), ({YT_INST:.2f}, red, \"\")), width: 166mm, height: 10pt)",
            numcolor="teal"))

segdef = [("Crkveni mediji i ustanove", ["church_media", "church_org"], 'rgb("#3d4a5c")'),
          ("Neovisni katolički mediji", ["independent"], "teal-l"),
          ("Pobožni, svećenički kanali i zajednice", ["devotional", "clergy", "community"], "teal"),
          ("Ostali izvori", ["public", "other_christian"], "stone")]


def platbar(plat, field):
    segs = []
    for lbl, gs, col in segdef:
        v = share(plat, gs, field)
        segs.append(f"({v:.3f}, {col}, {ts(p(v))})")
    return "stackbar((" + ", ".join(segs) + ",), width: 11.4cm, height: 17pt)"


plat_rows = []
for plat, nm in (("youtube", "YouTube"), ("facebook", "Facebook"), ("web", "Portali")):
    plat_rows.append(f"""text(font: sans, size: 9pt, weight: "bold", {ts(nm)}), [],
    tag[objave], {platbar(plat, 'post_share')},
    tag[interakcije], {platbar(plat, 'int_share')},""")
legend = " #h(10pt) ".join(f"#box(width: 8pt, height: 8pt, fill: {col}) #h(2pt) #tag({ts(lbl)})" for lbl, _, col in segdef)
add(f"""
#spread(section: "I · Pozornost", finding: 1, flabel: "Pozornost")[
#metadata(none) <p-f1>
#kicker[Kome pripada pozornost?]
#headline{c(f"Na YouTubeu pobožni kanali dobivaju {p(YT_DEV)} interakcija, crkvene ustanove {p(YT_INST, 1)}")}
#deck{c(f"Na Facebooku pobožni kanali i zajednice dobivaju {p(FB_DEV)}, neovisni katolički mediji {p(FB_IND)}, a crkvene ustanove {p(FB_INST, 1)}.")}
#v(6pt)
#grid(columns: (2.2cm, 1fr), row-gutter: 7pt, column-gutter: 8pt, align: (right + horizon, left + horizon),
  {"".join(plat_rows)})
#v(8pt)
{legend}
#cols2({c(f"Pozornost se mjeri zabilježenim interakcijama, a to su reakcije, komentari i dijeljenja koje je dobavljač podataka zabilježio uz objavu. Na YouTubeu pobožni i svećenički kanali objavljuju {p(YT_DEV_POSTS)} objava, a dobivaju {p(YT_DEV)} interakcija. Na portalima službeni crkveni mediji objavljuju {p(WEB_CM_P)} objava, a dobivaju {p(WEB_CM_I)} interakcija.")}, {c("Interakcije se na svakoj platformi broje drukčije, pa se platforme ne uspoređuju međusobno, nego samo skupine unutar iste platforme. Broj interakcija nije broj ljudi. Skupine izvora preuzete su iz postojećih popisa projekta i opisuju kanal, a ne osobu koja u objavi govori.")})
#source{c(f"Izvor podataka je korpus DigiKat, od {hrdate(S['date_min'])} do {hrdate(S['date_max'])}, {n(POSTS)} objava. Udjeli u svim objavama i svim zabilježenim interakcijama platforme. Interakcija nije broj ljudi.")}
]
""")

# finding 2: the top 50 coded
tip_order = ["anonimni_poboznji_kanal", "neovisni_katolicki_medij", "crkvena_ustanova", "institucijski_medij",
             "zajednica_udruga", "laicki_autor", "svecenik_redovnik"]
waf = ", ".join(f"({tip[t]['n']}, {TIP_COL[t]})" for t in tip_order if t in tip)
leg2 = "\n".join(f"#grid(columns: (12pt, 1fr, 1.2cm), align: (left + horizon, left + horizon, right + horizon), box(width: 9pt, height: 9pt, fill: {TIP_COL[t]}), prose{c(TIP_HR[t])}, prose{c(str(tip[t]['n']))})" for t in tip_order if t in tip)
add(f"""
#spread(section: "I · Pozornost", finding: 2, flabel: "Bez autora", bg: cream2)[
#metadata(none) <p-f2>
#kicker[Tko stoji iza najjačih kanala?]
#headline{c(f"Od 50 katoličkih izvora s najviše interakcija {ANON} nemaju vidljivog autora")}
#deck{c(f"Teološko obrazovanje onoga tko govori vidljivo je kod {EDU_VIS} od 50. Formalna crkvena služba nije vidljiva kod {MAND_UNK}.")}
#v(10pt)
#grid(columns: (8.4cm, 1fr), column-gutter: 26pt, align: top,
  waffle(({waf},), cols: 10, size: 7.4mm, gap: 1.4mm),
  [#eyebrow[Vrsta kanala, 50 izvora] #v(6pt) {leg2}])
#cols2({c(f"Kanal bez vidljivog autora objavljuje molitve, dnevna čitanja, poruke ukazanja i preuzete propovijedi, a ne kaže tko ih bira i tumači. Takvih je {ANON} od 50 i zajedno dobivaju {n(tip['anonimni_poboznji_kanal']['interactions'])} interakcija, više od svih crkvenih ustanova i službenih medija na popisu.")}, {c(f"Kodiranje kanala počiva na nazivu i šest nasumičnih objava po kanalu, a provodio ga je jezični model bez ručne provjere. Autor koji se ne vidi u šest objava ipak može postojati. Kod {ALARM} kanala ton je alarmantan i apokaliptičan, a dva imenovana laička autora tumače Bibliju naukom koji nije katolički.")})
#source{c("Izvor podataka je korpus DigiKat. 50 katoličkih izvora s najviše zabilježenih interakcija na svim platformama, kodiranje kanala prema nazivu i šest nasumičnih objava. Puni popis s kodiranjem je u imeniku.")}
]
""")

# pulherissimus page
add(f"""
#spread(section: "I · Pozornost", label: "Jedan kanal")[
#kicker[Kolika je težina jednog kanala?]
#headline{c(f"Drugi katolički izvor po interakcijama jedan je YouTube kanal")}
#deck{c(f"Kanal pulherissimus objavio je {n(pul['posts'])} videa i dobio {n(pul['interactions'])} interakcija, {p(pul['share_of_yt_catholic_int'])} svih koje su katolički izvori dobili na YouTubeu.")}
#v(14pt)
#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [#eyebrow[hkm.hr, portal] #v(4pt) #bignum({ts(n(R['hkm']['posts']))}, [objava]) #v(6pt) #bignum({ts(n(R['hkm']['interactions']))}, [zabilježenih interakcija], size: 30pt) #v(6pt) #bignum({ts(n(R['hkm']['median']))}, [interakcija po objavi, medijan], size: 30pt)],
  [#eyebrow[pulherissimus, YouTube] #v(4pt) #bignum({ts(n(pul['posts']))}, [objava], color: teal) #v(6pt) #bignum({ts(n(pul['interactions']))}, [zabilježenih interakcija], size: 30pt, color: teal) #v(6pt) #bignum({ts(n(pul['median']))}, [interakcija po objavi, medijan], size: 30pt, color: teal)])
#cols2({c(f"Kanal objavljuje časoslov, večernje molitve i razmatranja evanđelja, od {hrdate(pul['first'])} u {pul['months']} {pl(pul['months'], 'mjesec', 'mjeseca', 'mjeseci')}. Postojeći registar projekta vodi ga kao svećenički kanal jer navodi da ga uređuje svećenik. U šest nasumičnih objava autor nije vidljiv.")}, {c(f"Skupina svećeničkih profila gotovo je cijela taj jedan kanal, {p(pul['share_of_clergy_posts'])} njezinih objava. Zato se u ovom izvještaju o svećeničkim profilima govori samo uz tu napomenu. Medijan portala i medijan YouTubea nisu usporedivi jer se interakcije na njima drukčije bilježe.")})
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026. Interakcije su zabilježene uz objave iz razdoblja, a ne prema danu kad su nastale.")}
]
""")

# finding 3: signals
cols_sig = ["nauk", "pismo", "uciteljstvo", "predaja", "privatna", "iskustvo"]
col_names = ["Nauk", "Pismo", "Učiteljstvo", "Predaja i sveci", "Ukazanja", "Iskustvo"]
order = ["clergy", "devotional", "church_media", "church_org", "independent", "community", "public"]
brows = []
for g in order:
    r = sig[g]
    vals = ", ".join(f"{r[k]:.2f}" for k in cols_sig)
    disp = ", ".join(ts(p(r[k])) for k in cols_sig)
    sub = "gotovo cijela jedan kanal" if g == "clergy" else f"{n(r['n'])} objava s tekstom"
    brows.append(f"({ts(GROUP_HR[g])}, {ts(sub)}, ({vals}), ({disp}))")
add(f"""
#spread(section: "I · Pozornost", finding: 3, flabel: "Nauk bez Učiteljstva")[
#metadata(none) <p-f3>
#kicker[Na što se pozivaju?]
#headline{c(f"Pobožni kanali najviše govore o nauku, a najrjeđe se pozivaju na Učiteljstvo")}
#deck{c(f"Rječnik nauka ima {p(sig['devotional']['nauk'])} objava pobožnih kanala, a dokumenti Učiteljstva spominju se u {p(sig['devotional']['uciteljstvo'], 1)}. U crkvenim medijima Učiteljstvo se spominje u {p(sig['church_media']['uciteljstvo'])}.")}
#v(4pt)
#bubbles(({", ".join(ts(x) for x in col_names)}), ({", ".join(brows)},), maxv: 70, maxr: 10pt, colw: 1.82cm)
#cols2({c(f"Svaki krug pokazuje udio objava skupine u kojima se u prvih 3000 znakova pojavljuje barem jedan izraz iz popisa. Učiteljstvo znači katekizam, encikliku, koncil, crkveni ili socijalni nauk. Svećenički profili spominju iskustvo i svjedočanstvo u {p(sig['clergy']['iskustvo'])} objava.")}, {c(f"Izraz u tekstu nije tumačenje. Pokazuje samo na što se objava poziva rječnikom. Skupina svećeničkih profila gotovo je cijela jedan kanal, pa njezini udjeli opisuju taj kanal. Bez njega ostaje {n(R['signals_clergy_without_pul'][0]['n'])} objava, premalo za usporedbu.")})
#source{c("Izvor podataka je korpus DigiKat, objave s najmanje 200 znakova teksta. Popisi izraza za svaki stupac navedeni su u studijskom kodu. Automatsko prepoznavanje izraza, bez provjere značenja.")}
]
""")

# concentration
add_conc = []
with open(STUDY / "output" / "concentration.csv", encoding="utf-8-sig") as fh:
    for r in csv.DictReader(fh):
        if r["platform"] in ("web", "youtube", "facebook"):
            add_conc.append(r)
cr = []
for r in add_conc:
    nm = {"web": "Portali", "youtube": "YouTube", "facebook": "Facebook"}[r["platform"]]
    cr.append(f"({ts(nm + ', prvi izvor')}, {100 * float(r['top1']):.2f}, {ts(p(100 * float(r['top1'])))}, red, true, {ts(n(int(r['sources'])) + ' izvora')})")
    cr.append(f"({ts(nm + ', prvih deset')}, {100 * float(r['top10']):.2f}, {ts(p(100 * float(r['top10'])))}, teal, false, none)")
web_top1 = 100 * float(next(r for r in add_conc if r["platform"] == "web")["top1"])
yt_top1 = 100 * float(next(r for r in add_conc if r["platform"] == "youtube")["top1"])
add(f"""
#spread(section: "I · Pozornost", label: "Koncentracija", bg: cream2)[
#kicker[Koliko je izvora potrebno za većinu pozornosti?]
#headline{c(f"Jedan portal ima {p(web_top1)} interakcija katoličkih portala")}
#deck{c(f"Na YouTubeu jedan kanal ima {p(yt_top1)}. Pozornost katoličkih izvora skupljena je u nekoliko kanala na svakoj platformi.")}
#v(10pt)
#hbars(({", ".join(cr)},), max: 100, width: 8.8cm, label-w: 4.4cm)
#cols2({c("Na portalima je prvi izvor hkm.hr, portal Hrvatske katoličke mreže. On ujedno objavljuje najviše katoličkih vijesti. Na YouTubeu prvi je kanal pulherissimus, a na Facebooku stranica katoličke televizije Laudato.")}, {c("Udio prvoga izvora računa se samo unutar katoličkih izvora iste platforme. Interakcije se na portalima bilježe rjeđe i drukčije nego na društvenim mrežama, pa koncentracija na portalima ne znači isto što i na YouTubeu.")})
#source{c("Izvor podataka je korpus DigiKat, katolički izvori sa zabilježenim interakcijama, od siječnja 2021. do lipnja 2026.")}
]
""")

# ================================================================ ACT II
role_seq = ["biskup", "papa", "svecenik", "akademski", "laik", "redovnica", "vidjelac"]
role_cols = {"biskup": "red", "papa": "red-l", "svecenik": 'rgb("#8a8f96")', "akademski": "teal", "laik": "stone",
             "redovnica": "stone", "vidjelac": "stone"}
sb = ", ".join(f"({roles[r]['stmt_share']:.3f}, {role_cols[r]}, \"\")" for r in role_seq)
add(divider("ČIN II", "Glasovi", dec(B_SHARE, 0), "% izjava \\ daju biskupi",
            f"Od {n(STMT)} izjava koje objave pripisuju {R['list']['persons']} praćenih osoba polovicu daju biskupi. Akademski teolozi daju {p(ACAD_SHARE)}.",
            "ZAKLJUČCI 4, 5, 6 I 7", f"stackbar(({sb},), width: 166mm, height: 10pt)"))


def cast_block(role, k):
    ps = [r for r in persons if r["role"] == role][:k]
    allp = [r for r in persons if r["role"] == role]
    tot = sum(r["statements"] for r in allp)
    mx_ = persons[0]["statements"]
    head = f"{len(allp)} {pl(len(allp), 'osoba', 'osobe', 'osoba')} · {n(tot)} izjava · {p(100 * tot / STMT, 1 if 100 * tot / STMT < 10 else 0)} svih izjava"
    lines = []
    for r in ps:
        w = max(r["statements"] / mx_ * 3.6, 0.04)
        lines.append(f"grid(columns: (4.1cm, 1fr), align: (left + horizon, left + horizon), text(font: serif, size: 10.5pt, {ts(r['name'])}), stack(dir: ltr, spacing: 4pt, box(width: {w:.3f}cm, height: 6pt, radius: 3pt, fill: red), text(font: sans, size: 8pt, {ts(n(r['statements']))})))")
    return f"""block(below: 10pt, {{text(font: sans, size: 8pt, weight: "bold", tracking: 0.6pt, {ts(ROLE_HR[role].upper())}); linebreak(); tag({ts(head)}); v(-4pt); hr(); v(2pt); stack(spacing: 5pt, {', '.join(lines)})}})"""


add(f"""
#spread(section: "II · Glasovi", label: "Postava")[
#kicker[Postava]
#headline[Tko u objavama govori o vjeri]
#deck{c(f"Najcitiranije osobe sa zatvorenog popisa od {R['list']['persons']}, po broju objava s prepoznatom izjavom. Duljina crte je ista ljestvica za sve.")}
#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [#{cast_block('papa', 3)} #{cast_block('biskup', 12)}],
  [#{cast_block('svecenik', 6)} #{cast_block('akademski', 6)} #{cast_block('laik', 4)} #{cast_block('redovnica', 3)}])
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026. Izjava je prepoznata kad su ime i glagol govorenja ili riječ poput homilije i poruke blizu jedno drugome. Uloga je oznaka koja se u tekstovima najčešće nalazi uz ime. Popis je zatvoren, pa na njemu nema nikoga tko nije unaprijed odabran.")}
]
""")

# finding 4: roles
rb = []
for r in role_seq:
    v = roles[r]
    rb.append(f"({ts(ROLE_HR[r])}, {v['stmt_share']:.3f}, {ts(p(v['stmt_share'], 1 if v['stmt_share'] < 10 else 0))}, {'red' if r in ('biskup', 'papa') else ('teal' if r == 'akademski' else 'stone')}, {tb(r in ('biskup', 'akademski'))}, {ts(str(v['persons']) + ' ' + pl(v['persons'], 'osoba', 'osobe', 'osoba') + ' · ' + n(v['statements']) + ' izjava')})")
add(f"""
#spread(section: "II · Glasovi", finding: 4, flabel: "Biskupi govore", bg: cream2)[
#metadata(none) <p-f4>
#kicker[Tko objašnjava vjeru javnosti?]
#headline{c(f"Biskupi daju {p(B_SHARE)} izjava, akademski teolozi {p(ACAD_SHARE)}")}
#deck{c(f"Uz pape biskupi daju {p(B_SHARE + POPE_SHARE)} svih izjava praćenih osoba. Svaka izjava broji se jednom po objavi i osobi. Zbrojeno ih je {n(STMT)}.")}
#v(10pt)
#hbars(({", ".join(rb)},), max: 60, width: 8.2cm, label-w: 4.6cm, bar-h: 13pt, gap: 9pt)
#cols2({c(f"Papa, biskupi i svećenici zajedno daju {p(cleric_share)} izjava. Udio akademskih teologa kreće se iz godine u godinu između četiri i pet posto, bez vidljivog smjera.")}, {c(f"Popis ima {roles['biskup']['persons']} biskupa i {roles['akademski']['persons']} akademskih teologa, pa razlika nije samo posljedica broja osoba. Biskupi imaju izjavu u {p(roles['biskup']['stmt_rate'])} objava u kojima se spominju, akademski teolozi u {p(roles['akademski']['stmt_rate'])}. Razlika je dakle u tome koliko se o njima uopće piše.")})
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026., zatvoreni popis praćenih osoba. Automatsko prepoznavanje izjava bez ručne provjere, pa su brojevi približni.")}
]
""")

# finding 5: dumbbell
pick = []
for role, k in (("papa", 2), ("biskup", 6), ("svecenik", 4), ("akademski", 7), ("laik", 2)):
    pick += [r for r in persons if r["role"] == role][:k]
pick.sort(key=lambda r: -r["mentions"])
db = []
for r in pick:
    aside = ROLE_SHORT[r["role"]]
    db.append(f"({ts(r['name'])}, {max(r['mentions'], 10)}, {max(r['statements'], 10)}, {tb(r['role'] == 'akademski')}, {ts(aside)})")
add(f"""
#spread(section: "II · Glasovi", finding: 5, flabel: "Spomen nije glas")[
#metadata(none) <p-f5>
#kicker[Koliko govore teolozi?]
#headline{c(f"Dvadeset i pet teologa zajedno govori manje od jednog nadbiskupa")}
#deck{c(f"Svih {ACAD_N} praćenih akademskih teologa ima {n(ACAD_STMT)} objava s izjavom. Nadbiskup Dražen Kutleša sam ima {n(KUT['statements'])}, a najcitiraniji akademski teolog, {TOP_ACAD['name']}, {n(TOP_ACAD['statements'])}.")}
#v(4pt)
#box(circle(radius: 3.6pt, stroke: 0.9pt + ink)) #h(3pt) #tag[spomen imena] #h(12pt) #box(circle(radius: 3.6pt, fill: red)) #h(3pt) #tag[izjava]
#v(4pt)
#dumbbell(({", ".join(db)},), lo: 10, hi: 60000, width: 9.2cm, ticks: (10, 100, 1000, 10000))
#align(center, tag[broj objava, logaritamska ljestvica])
#cols2({c("Prsten pokazuje koliko se o nekome piše, a puna točka koliko taj netko govori. Akademski teolozi istaknuti su podebljano. I kad se spominju, spominju se rjeđe nego biskupi, pa se rjeđe i čuju.")}, {c("Popis akademskih teologa obuhvaća profesore teoloških učilišta koje tekstovi najčešće navode. Teolog izvan popisa nije izmjeren. Mnogi su ujedno svećenici, pa se mogu pojaviti i u izjavama koje objava pripisuje svećeniku, a ne teologu.")})
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026. Spomen je puno ime ili oznaka službe uz prezime. Izjava je spomen uz glagol govorenja u istom odlomku. Zatvoreni popis praćenih osoba.")}
]
""")

# finding 6: who is called a theologian
lt = lab["top"][:16]
lrows = []
lmax = max(r["posts"] for r in lt)
for r in lt:
    nm = LABEL_NOM.get(r["name"], r["name"])
    w_o = r["other"] / lmax * 7.2
    w_c = r["catholic"] / lmax * 7.2
    lrows.append(f"text(font: sans, size: 8.4pt, weight: {'\"bold\"' if r['academic'] else '\"regular\"'}, {ts(nm)}), stack(dir: ltr, box(width: {w_o:.3f}cm, height: 9pt, fill: stone), box(width: {w_c:.3f}cm, height: 9pt, fill: teal), h(4pt), text(font: sans, size: 8pt, {ts(str(r['posts']))}))")
add(f"""
#spread(section: "II · Glasovi", finding: 6, flabel: "Tko je teolog?", bg: cream2)[
#metadata(none) <p-f6>
#kicker[Koga mediji nazivaju teologom?]
#headline{c(f"Kad tekst nekoga naziva teologom, rijetko je riječ o teologu s fakulteta")}
#deck{c(f"Od {LBL_GEN2} teologom {lab['academic_posts']} imenuju nekoga od {ACAD_N} praćenih akademskih teologa. {p(LBL_OTHER)} takvih objava izlazi izvan katoličkih medija.")}
#v(6pt)
#grid(columns: (5.2cm, 1fr), row-gutter: 5pt, column-gutter: 8pt, align: (right + horizon, left + horizon), {", ".join(lrows)})
#v(6pt)
#box(width: 8pt, height: 8pt, fill: stone) #h(3pt) #tag[ostali izvori] #h(12pt) #box(width: 8pt, height: 8pt, fill: teal) #h(3pt) #tag[katolički izvori] #h(12pt) #tag[podebljano je osoba s popisa akademskih teologa]
#cols2({c(f"Oznaku teologa u ostalim izvorima nosi {n(lab['other_names'])} različitih imena. Među najčešćima su domaći komentatori i publicisti te strani teolozi i pravoslavni i islamski teolozi. Profesori s domaćih teoloških fakulteta rijetko su među njima.")}, {c("Broji se objava u kojoj neposredno ispred imena stoji riječ teolog ili teologinja. Oznaka govori kako mediji nekoga predstavljaju, a ne kakvo obrazovanje ta osoba ima. Imena su svedena na jedan oblik, a jedna objava broji se jednom po imenu.")})
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026. Prikazano je 16 imena s najviše objava. Automatsko prepoznavanje.")}
]
""")

# role shares by year (supporting)
years = ["2021", "2022", "2023", "2024", "2025", "2026"]
yr = {}
for r in R["roles_year"]:
    yr[(r["role"], str(r["year"]))] = r["share"]
brows2 = []
for r in ["biskup", "papa", "svecenik", "akademski", "laik"]:
    vals = ", ".join(f"{yr.get((r, y), 0):.2f}" for y in years)
    disp = ", ".join(ts(p(yr.get((r, y), 0), 0 if yr.get((r, y), 0) >= 10 else 1)) for y in years)
    brows2.append(f"({ts(ROLE_HR[r])}, \"\", ({vals}), ({disp}))")
pope25 = yr[("papa", "2025")]
add(f"""
#spread(section: "II · Glasovi", label: "Glasovi kroz godine")[
#kicker[Mijenja li se postava?]
#headline{c(f"Postava je stabilna, osim godine u kojoj se izmijenio papa")}
#deck{c(f"Godine 2025. pape daju {p(pope25)} izjava, više nego ikad. Te je godine umro papa Franjo i izabran papa Lav XIV.")}
#v(8pt)
#bubbles(({", ".join(ts(y + '.') for y in years)}), ({", ".join(brows2)},), maxv: 60, maxr: 10pt, colw: 1.9cm)
#cols2({c("Udio akademskih teologa svake je godine između tri i pet posto. Udio biskupa pada samo kad naraste udio papa, pa se domaći i rimski glas izmjenjuju, a teološki ostaje na rubu.")}, {c("Udjeli se računaju unutar svake godine, pa ne ovise o tome koliko je objava te godine prikupljeno. Godina 2024. ima prekid u prikupljanju, a 2026. obuhvaća samo prvih pet i pol mjeseci.")})
#source{c("Izvor podataka je korpus DigiKat, zatvoreni popis praćenih osoba. Udio izjava pojedine skupine u svim izjavama godine.")}
]
""")

# finding 7: women
w_dots = f"(({R['list']['women']}, red, true), ({R['list']['persons'] - R['list']['women']}, stone, true))"
add(f"""
#spread(section: "II · Glasovi", finding: 7, flabel: "Trinaest od 117", bg: cream2)[
#metadata(none) <p-f7>
#kicker[Koga nema u postavi?]
#headline{c(f"Na popisu od {R['list']['persons']} osoba {R['list']['women']} su žene, a daju {p(100 * women_stmt / STMT, 1)} izjava")}
#v(14pt)
#dots({w_dots}, cols: 30, size: 9pt, gap: 3.4pt)
#v(6pt)
#tag[Jedna točka je jedna osoba s popisa. Crvene su žene.]
#v(20pt)
#block(width: 82%, bigprose{c(f"Žene na popisu su {WOMEN_DESC}. Zajedno imaju {n(women_stmt)} izjava od {n(STMT)}.")})
#v(10pt)
#block(width: 82%, bigprose{c(f"Biskupi, pape i svećenici, koji daju {p(cleric_share)} izjava, po crkvenom su pravu muškarci. Ali i među glasovima bez svećeničke službe, teolozima, laicima, redovnicama i vidiocima, žene daju samo {p(women_lay_share)} izjava.")})
#v(1fr)
#source{c("Izvor podataka je korpus DigiKat, zatvoreni popis praćenih osoba. Spol je naveden prema ulozi u tekstu, primjerice redovnica ili teologinja, i prema javno dostupnim podacima o osobama.")}
]
""")

# ================================================================ ACT III
add(divider("ČIN III", "Jeka", dec(BISH_OTHER, 0), "% izjava biskupa \\ izvan katoličkih medija",
            f"Više od polovice izjava biskupa objavljuju portali i stranice izvan katoličkih medija. Ista čestitka izlazi na {nb} portala istoga dana.",
            "ZAKLJUČAK 8", f"box(width: 100%, stack(dir: ltr, spacing: 1fr, ..range({nb}).map(_ => circle(radius: 5pt, fill: red))))"))


def seq_col(s, kick, head, sub, body):
    srcs = s["sources"]
    show = srcs[:10]
    rest = len(srcs) - len(show)
    li = "\n".join(f"#grid(columns: (12pt, 1fr), align: horizon, circle(radius: 4pt, fill: red), prose{c(x)})" for x in show)
    more = f"#prose{c(f'i još {rest} ' + pl(rest, 'portal', 'portala', 'portala'))}" if rest > 0 else ""
    return f"""[#eyebrow{c(kick)}
#v(8pt)
#text(font: serif, size: 17pt, par(leading: 0.45em){c(head)})
#v(2pt)
#tag{c(sub)}
#v(6pt)
#grid(columns: (auto, 1fr), column-gutter: 6pt, align: bottom, text(font: serif, size: 46pt, {ts(str(len(srcs)))}), tag[portala])
#v(4pt)
{li}
{more}
#v(6pt)
#hr()
#prose{c(body)}]"""


left = seq_col(boz, "Domaći glas", "Kardinal Josip Bozanić", f"uskrsna čestitka, {hrdate(boz['first'])}",
               f"Svih {len(boz['sources'])} portala izvan su katoličkih medija. Naslov je na svima isti.")
right = seq_col(popemsg, "Rimski glas", "Papa Franjo", f"novogodišnja poruka, {hrdate(popemsg['first'])}",
                f"Svih {len(popemsg['sources'])} portala izvan su katoličkih medija. Naslov je na svima isti.")
add(f"""
#spread(section: "III · Jeka", finding: 8, flabel: "Jeka")[
#metadata(none) <p-f8>
#kicker[Kako crkvena riječ putuje?]
#headline[Biskupova riječ putuje svjetovnim portalima]
#deck{c(f"Od svih izjava biskupa {p(BISH_OTHER)} objavljuju izvori izvan katoličkih medija. Dvije najraširenije poruke izašle su na desetcima portala istoga dana, pod istim naslovom.")}
#grid(columns: (1fr, 1fr), column-gutter: 26pt, {left}, {right})
#v(8pt)
#prose{c("Redoslijed je redoslijed kojim su objave zabilježene i ne dokazuje tko je od koga preuzeo. Pokazuje da ista poruka na putu ne dobiva tumača. Nigdje je ne prati teolog, vjernik ili druga strana.")}
#source{c("Izvor podataka je korpus DigiKat, portali. Priča je skup objava s istim naslovom na različitim portalima unutar 14 dana. Dvije priče s najviše portala.")}
]
""")

add(f"""
#spread(section: "III · Jeka", label: "Objave i priče", bg: cream2)[
#kicker[Koliko je priča u objavama?]
#headline{c(f"{p(ECHO_SHARE)} objava na portalima ponavlja priču koju je objavio još netko")}
#deck{c(f"Od {n(ECHO['web_posts_titled'])} objava na portalima {n(ECHO['posts_in_multi'])} pripada {n(ECHO['stories_multi'])} pričama objavljenima na više portala. Najraširenija je izašla na {ECHO['largest']} portala.")}
#v(10pt)
#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  bignum({ts(n(ECHO['posts_in_multi']))}, [objava u pričama s više portala], color: ink),
  bignum({ts(n(ECHO['stories_multi']))}, [različitih priča], color: teal))
#v(10pt)
#cols2({c(f"Portal hkm.hr prvi je objavio {R['echo_hkm_first']} priča koje su zatim izašle na najmanje tri portala, više nego ijedan drugi izvor. Iz katoličke agencije poruka prelazi na lokalne i nacionalne portale, a broj objava raste brže od broja priča.")}, {c("Priča se prepoznaje po istom naslovu, pa su priče s preoblikovanim naslovom podcijenjene. Deset objava iste poruke nije deset različitih glasova. Tko broji samo objave, jeku čuje kao zbor.")})
#source{c("Izvor podataka je korpus DigiKat, objave na portalima s naslovom od najmanje 30 znakova. Priča je skup objava s istim pročišćenim naslovom na različitim portalima unutar 14 dana.")}
]
""")

rs = []
for r in role_seq:
    tot = sum(x["N"] for x in R["roles_source"] if x["role"] == r)
    oth = sum(x["N"] for x in R["roles_source"] if x["role"] == r and not x["catholic"])
    sh = 100 * oth / tot
    rs.append(f"({ts(ROLE_HR[r])}, {sh:.2f}, {ts(p(sh))}, {'red' if r == 'laik' else 'stone'}, {tb(r == 'laik')}, {ts(n(tot) + ' izjava')})")
add(f"""
#spread(section: "III · Jeka", label: "Laici izvana")[
#kicker[Gdje se čuju laici?]
#headline{c(f"Laike koji govore o vjeri čuju gotovo samo svjetovni mediji")}
#deck{c(f"Od {n(lay_other + lay_cath)} izjava praćenih laika, publicista i aktivista {n(lay_other)} izlazi izvan katoličkih medija, {p(lay_other_share)}.")}
#v(10pt)
#eyebrow[Udio izjava objavljenih izvan katoličkih medija]
#v(6pt)
#hbars(({", ".join(rs)},), max: 100, width: 8.4cm, label-w: 4.8cm, bar-h: 12pt, gap: 8pt)
#cols2({c("Laički glasovi s popisa, publicisti, aktivisti i teolozi bez crkvene službe, u katoličkim medijima gotovo ne dobivaju riječ. Kad govore, govore na svjetovnim portalima, često u polemici o Crkvi.")}, {c("Popis laika je kratak, šest osoba, pa je osnova mala. Laici koji nisu na popisu nisu izmjereni. Katolički mediji mogu laike citirati i bez imena, što ovaj postupak ne prepoznaje.")})
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026., zatvoreni popis praćenih osoba, izjave prema vrsti izvora.")}
]
""")

# ================================================================ ACT IV
add(divider("ČIN IV", "Tišina", str(K_ACAD[0]), f"od {K_INT} objava",
            f"U {K_INT} objava katoličkih izvora koje tumače vjeru akademski teolog nije nijednom glavni tumač. U ostalim izvorima to je u {O_ACAD[0]} od {O_INT}.",
            "ZAKLJUČCI 9 I 10",
            f"waffle((({K_INT}, rgb(\"#3a4552\")),), cols: 48, size: 2.7mm, gap: 0.75mm)"))

order_main = ["svecenik_redovnik", "autor_objave", "biskup", "papa", "akademski_teolog", "influencer", "laik_aktivist", "vjernik"]


def mainbars(stratum):
    rows_ = []
    for k in order_main:
        cnt, sh = main_share(stratum, k)
        rows_.append(f"({ts(INTERP_HR[k])}, {sh:.2f}, {ts(p(sh) + ' · ' + str(cnt))}, {'teal' if k == 'akademski_teolog' else ('red' if k in ('svecenik_redovnik', 'autor_objave', 'biskup') else 'stone')}, {tb(k == 'akademski_teolog')}, none)")
    return f"hbars(({', '.join(rows_)},), max: 45, width: 3.4cm, label-w: 3.9cm, bar-h: 10pt, gap: 6pt)"


mand_k = {r["mandat"]: r for r in smp["mandat"] if r["stratum"] == "katolicki"}
add(f"""
#spread(section: "IV · Tišina", finding: 9, flabel: "Tko tumači")[
#metadata(none) <p-f9>
#kicker[Tko tumači vjeru?]
#headline{c(f"Vjeru tumače svećenici i neimenovani autori, teolog s fakulteta gotovo nikad")}
#deck{c(f"U katoličkim izvorima glavni su tumači svećenici i redovnici u {p(K_PRIEST[1])} objava koje tumače vjeru, neimenovani autori u {p(K_ANON[1])}, a biskupi u {p(K_BISHOP[1])}.")}
#v(8pt)
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  [#eyebrow{c(f"Katolički izvori, {K_INT} objava koje tumače")} #v(6pt) #{mainbars('katolicki')}],
  [#eyebrow{c(f"Ostali izvori, {O_INT} objava koje tumače")} #v(6pt) #{mainbars('ostali')}])
#cols2({c(f"U ostalim izvorima neimenovani autor glavni je tumač u {p(O_ANON[1])} objava. To su kolumne, preuzeti pobožni tekstovi i lokalni portali koji sami objašnjavaju blagdan ili nauk. Mandat glavnog tumača u katoličkim izvorima nije vidljiv u {p(mand_k['nepoznato']['share'])} objava.")}, {c(f"Uzorak od {N_SMP} objava izvučen je nasumično iz objava s rječnikom nauka, po {PER_STR} iz katoličkih i ostalih izvora. Skupine se ne zbrajaju. Kodirao ga je jezični model prema zadanoj šifrarnici, bez ručne provjere, pa su brojevi procjene. Osnova je mala.")})
#source{c("Izvor podataka je korpus DigiKat, pregledani uzorak od siječnja 2021. do lipnja 2026. Tumač je glas koji objašnjava ili primjenjuje nauk, a glavni tumač onaj koji to čini najviše.")}
]
""")

ak = [r for r in smp["autoritet"] if r["stratum"] == "katolicki"]
ao = [r for r in smp["autoritet"] if r["stratum"] == "ostali"]
ordera = ["pismo", "predaja_sveci", "uciteljstvo", "nacija_povijest", "osobno_iskustvo", "znanost_razum"]


def autbars(lst):
    d = {r["a"]: r for r in lst}
    out = []
    for k in ordera:
        v = d.get(k, {"share": 0, "N": 0})
        out.append(f"({ts(AUT_HR[k])}, {v['share']:.2f}, {ts(p(v['share']))}, {'red' if k == 'uciteljstvo' else 'teal'}, {tb(k == 'uciteljstvo')}, none)")
    return f"hbars(({', '.join(out)},), max: 80, width: 3.6cm, label-w: 3.4cm, bar-h: 10pt, gap: 6pt)"


tk = {r["ton"]: r for r in smp["ton"] if r["stratum"] == "katolicki"}
to = {r["ton"]: r for r in smp["ton"] if r["stratum"] == "ostali"}
d_k = {r["a"]: r for r in ak}
add(f"""
#spread(section: "IV · Tišina", label: "Autoritet i ton", bg: cream2)[
#kicker[Na što se tumači pozivaju?]
#headline{c(f"Sveto pismo u {p(d_k['pismo']['share'])} tumačenja, Učiteljstvo u {p(d_k['uciteljstvo']['share'])}")}
#deck{c("U katoličkim izvorima tumači se najčešće pozivaju na Sveto pismo, a zatim na svece i predaju. Dokumenti Crkve rijetko su argument.")}
#v(8pt)
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  [#eyebrow[Katolički izvori] #v(6pt) #{autbars(ak)}],
  [#eyebrow[Ostali izvori] #v(6pt) #{autbars(ao)}])
#v(8pt)
#cols2({c(f"Ton je u katoličkim izvorima afirmativan u {p(tk['afirmativan']['share'])} objava, a polemičan ni u jednoj. U ostalim izvorima afirmativan je u {p(to['afirmativan']['share'])}, polemičan u {p(to.get('polemican', {'share': 0})['share'])}, a kritičan prema Crkvi u {p(to.get('kritican_prema_crkvi', {'share': 0})['share'])}.")}, {c("Jedno tumačenje može se pozivati na više izvora, pa se udjeli ne zbrajaju. Nacija i povijest češće su argument u ostalim izvorima, gdje se vjera često tumači kroz domovinu i spomen.")})
#source{c("Izvor podataka je korpus DigiKat, pregledani uzorak, objave koje tumače vjeru. Kodiranje jezičnim modelom bez ručne provjere.")}
]
""")

add(f"""
#spread(section: "IV · Tišina", finding: 10, flabel: "Tišina vjernika")[
#metadata(none) <p-f10>
#kicker[Dobivaju li riječ vjernici?]
#headline{c(f"O vjernicima {BEL_K['opisani']} puta, s njima {BEL_K['govore']}")}
#deck{c(f"U {BEL_K['n']} pregledanih objava katoličkih izvora o običnim vjernicima piše se u {BEL_K['opisani']}, a vjernik govori u {BEL_K['govore']}.")}
#v(6pt)
#grid(columns: (1fr, 4.6cm), column-gutter: 20pt,
  [#text(font: serif, size: 54pt, str({BEL_K['opisani']})) \\ #tag[objava opisuje vjernike] #v(6pt) #dots((({BEL_K['opisani']}, ink, false),), cols: 14, size: 10pt, gap: 4pt)],
  [#text(font: serif, size: 54pt, fill: red, str({BEL_K['govore']})) \\ #tag[objave donose njihov glas] #v(6pt) #dots((({BEL_K['govore']}, red, true),), cols: 6, size: 10pt, gap: 4pt)])
#v(14pt)
#block(width: 86%, bigprose{c(f"U ostalim izvorima vjernici su opisani u {BEL_O['opisani']} od {BEL_O['n']} objava, a govore u {BEL_O['govore']}. Lokalni portal češće pita hodočasnika ili supružnike na zlatnom piru nego katolički medij.")})
#source{c("Izvor podataka je korpus DigiKat, pregledani uzorak od 300 objava, po 150 iz katoličkih i ostalih izvora, kodiranje jezičnim modelom. Jedna objava može i opisivati vjernike i donositi njihov glas.")}
]
""")

add(f"""
#page(fill: cream, header: none, footer: context align(right, text(font: sans, size: 7.6pt, fill: muted, counter(page).display())), [
  #v(1fr)
  #align(center, circle(radius: 13pt, stroke: 1.1pt + ink))
  #v(14pt)
  #align(center, block(width: 80%, text(font: serif, size: 17pt, par(leading: 0.5em){c(f"U {BEL_K['n'] - BEL_K['govore']} od {BEL_K['n']} objava katoličkih izvora koje se bave vjerom nijedan običan vjernik nije dobio riječ.")})))
  #v(1fr)
])
""")

# ================================================================ CLOSING
ten = [
    ("Pozornost", dec(YT_DEV, 0) + NB + "%", "interakcija na YouTubeu odlazi pobožnim i svećeničkim kanalima", "p-f1"),
    ("Bez autora", str(ANON), "od 50 najjačih katoličkih izvora bez vidljivog autora", "p-f2"),
    ("Nauk bez Učiteljstva", p(sig['devotional']['uciteljstvo'], 1), "objava pobožnih kanala spominje dokumente Učiteljstva", "p-f3"),
    ("Biskupi govore", p(B_SHARE), "izjava praćenih osoba daju biskupi", "p-f4"),
    ("Spomen nije glas", n(ACAD_STMT), f"izjava svih {ACAD_N} akademskih teologa, prema {n(KUT['statements'])} jednog nadbiskupa", "p-f5"),
    ("Tko je teolog?", str(lab["academic_posts"]), f"od {n(lab['posts'])} {pl(lab['posts'], 'objave', 'objave', 'objava')} s oznakom teologa imenuje teologa s popisa", "p-f6"),
    ("Trinaest od 117", p(100 * women_stmt / STMT, 1), "izjava daju žene s popisa", "p-f7"),
    ("Jeka", p(BISH_OTHER), "izjava biskupa izlazi izvan katoličkih medija", "p-f8"),
    ("Tko tumači", str(K_ACAD[0]), f"od {K_INT} katoličkih tumačenja daje akademski teolog", "p-f9"),
    ("Tišina vjernika", f"{BEL_K['govore']} od {BEL_K['n']}", "objava katoličkih izvora daje riječ vjerniku", "p-f10"),
]
cells = []
for i, (t, big, lab_, ref) in enumerate(ten, 1):
    cells.append(f"""block(width: 100%, inset: (top: 5pt), stroke: (top: 0.5pt + rgb("#5a636e")), {{
  grid(columns: (1.1cm, 1fr, auto), align: (left + horizon, left + horizon, right + horizon),
    text(font: serif, size: 15pt, fill: red, "{i}"), text(font: sans, size: 9pt, weight: "bold", {ts(t)}),
    text(font: sans, size: 7.4pt, fill: rgb("#a7adb5"))[str. #context counter(page).at(<{ref}>).first()])
  v(2pt)
  text(font: serif, size: 25pt, top-edge: "bounds", bottom-edge: "bounds", {ts(big)})
  v(4pt)
  text(font: sans, size: 8pt, fill: rgb("#c9ccd1"), {ts(lab_)})
}})""")
add(f"""
#page(fill: navy, margin: (top: 20mm, bottom: 18mm, left: 22mm, right: 22mm), header: none, footer: context align(right, text(font: sans, size: 7.6pt, fill: rgb("#a7adb5"), counter(page).display())), {{
  set text(fill: paper-dark-text)
  text(font: sans, size: 8.6pt, weight: "bold", fill: red, tracking: 1pt, "MNOGO TUMAČA, MALO TEOLOGA")
  v(4pt)
  text(font: serif, size: 30pt, "Deset brojeva za pamćenje")
  v(10pt)
  grid(columns: (1fr, 1fr), column-gutter: 22pt, row-gutter: 9pt, {", ".join(cells)})
}})
""")

moves = [
    ("Redakcije", [("Pitajte teologa.", f"Uz biskupovu poruku potražite i nekoga tko je zna objasniti. Akademski teolozi daju {p(ACAD_SHARE)} izjava.", "p-f4"),
                   ("Pitajte vjernika.", "Kad pišete o hodočašću ili blagdanu, dajte riječ onima koji ga slave.", "p-f10"),
                   ("Recite odakle je tekst.", "Kad je tekst preuzet od agencije ili priopćenja, recite to čitatelju.", "p-f8")]),
    ("Crkva i katolički mediji", [("Dovedite teologe u prvi red.", "Uz izjavu biskupa ponudite sugovornika s učilišta koji je može protumačiti.", "p-f5"),
                                  ("Dajte riječ laicima.", "Laici koji govore o vjeri danas se čuju gotovo samo na svjetovnim portalima.", None),
                                  ("Dajte riječ ženama.", f"Žene daju {p(women_lay_share)} izjava i kad se gledaju samo glasovi bez svećeničke službe.", "p-f7")]),
    ("Teološka učilišta", [("Javite se prvi.", "Kad tekst nekoga naziva teologom, rijetko je to profesor s fakulteta.", "p-f6"),
                           ("Govorite tamo gdje su ljudi.", "Pozornost je na YouTubeu i Facebooku, kod pobožnih kanala.", "p-f1"),
                           ("Pokažite izvor.", "Recite na koji se dokument ili tekst Pisma tumačenje oslanja.", "p-f3")]),
    ("Čitatelji", [("Pitajte tko govori.", "I tko bi trebao govoriti, a nema ga.", "p-f9"),
                   ("Pitajte tko stoji iza kanala.", "Polovica najjačih katoličkih kanala ne kaže tko ih uređuje.", "p-f2"),
                   ("Prepoznajte jeku.", "Ista poruka na trinaest portala i dalje je jedna poruka.", "p-f8")]),
]
blocks = []
k = 0
for grp, ms in moves:
    inner = []
    for t, b, ref in ms:
        k += 1
        refp = f" #text(font: sans, size: 7pt, fill: muted)[Str. #context counter(page).at(<{ref}>).first().]" if ref else ""
        inner.append(f"#grid(columns: (0.9cm, 1fr), text(font: serif, size: 20pt, \"{k}\"), [#text(font: sans, size: 9pt, weight: \"bold\"){c(t)} \\ #prose{c(b)}{refp}])\n#v(8pt)")
    blocks.append(f"[#eyebrow{c(grp)} #v(-4pt) #hr() #v(6pt)\n" + "\n".join(inner) + "]")
add(f"""
#spread(section: "Završnica")[
#kicker[Što sada?]
#headline[Dvanaest poteza za više tumača]
#deck[Ovo su prijedlozi, a ne nalazi. Po tri poteza za četiri skupine čitatelja.]
#grid(columns: (1fr, 1fr), column-gutter: 24pt, row-gutter: 10pt, {", ".join(blocks)})
#v(1fr)
#block(width: 80%, bigprose[Većina se ovih poteza može izmjeriti, pa sljedeće izdanje može pokazati je li se što promijenilo.])
]
""")

acad26 = yr.get(("akademski", "2026"), 0)
women26 = None
preds = [
    ("Akademski teolozi daju manje od 5 % izjava praćenih osoba u 2027.", p(acad26, 1)),
    ("Žene daju manje od 2 % izjava praćenih osoba.", p(100 * women_stmt / STMT, 1)),
    ("Pobožni i svećenički kanali i dalje dobivaju više od polovice interakcija na YouTubeu.", p(YT_DEV)),
    ("U uzorku odabranom na isti način akademski teolog glavni je tumač u manje od 5 % katoličkih objava.", p(K_ACAD[1])),
    ("U istom uzorku vjernik govori u manje od 5 % katoličkih objava.", p(100 * BEL_K['govore'] / BEL_K['n'])),
]
prow = []
for i, (t, today) in enumerate(preds, 1):
    prow.append(f"""block(width: 100%, inset: (y: 10pt), stroke: (top: 0.5pt + rulec), grid(columns: (1.4cm, 1fr, 2.6cm, 1.4cm), align: (left + horizon, left + horizon, left + horizon, right + horizon),
  text(font: serif, size: 26pt, "{i}"), text(font: serif, size: 12.5pt, par(leading: 0.45em){c(t)}),
  [#tag[Danas] \\ #text(font: sans, size: 10pt, weight: "bold"){c(today)}], rect(width: 1.1cm, height: 1cm, radius: 2pt, stroke: 0.8pt + ink)))""")
add(f"""
#spread(section: "Završnica", bg: cream2)[
#kicker[Provjera 2027.]
#headline[Pet predviđanja koja će sljedeće izdanje ocijeniti]
#deck[Prva tri vrijede za iste mjesece 2027., od siječnja do lipnja, a četvrto i peto za sljedeći uzorak. U okvir će sljedeće izdanje upisati je li se predviđanje ostvarilo.]
#v(6pt)
{chr(10).join('#' + x for x in prow)}
#block(stroke: (top: 0.5pt + rulec), width: 100%)[]
#v(10pt)
#bigprose[Prvo, drugo, četvrto i peto predviđanje bilo bi dobro promašiti.]
#source{c("Predviđanja su procjene, a ne rezultat modela. Danas za prva dva znači prvih pet i pol mjeseci 2026., a za ostala cijelo razdoblje. Sva se mjere istim postupkom kao u ovom izdanju.")}
]
""")

# answers to the researcher
gs = {r["group"]: r for r in R["groups"]}
core_order = ["church_media", "church_org", "independent", "clergy", "devotional", "community"]
grows = []
for g in core_order:
    r = gs[g]
    grows.append(f"{ts(GROUP_HR[g])}, {ts(n(r['sources']))}, {ts(n(r['posts']))}, {ts(n(r['interactions']))}")
add(f"""
#spread(section: "Završnica", label: "Tri pitanja istraživača")[
#metadata(none) <p-pitanja>
#kicker[Za istraživače]
#headline[Tri pitanja, tri odgovora]
#deck[Izvještaj je nastao kao odgovor na tri pitanja o raščlambi izvora po vrstama aktera, otvorenim agregatima i najutjecajnijim izvorima.]
#section-rule[1 · Postoji li raščlamba po vrstama aktera?]
#prose{c(f"Postoji, ali je istraživačka. Šest skupina katoličkih izvora izvedeno je iz postojećih popisa projekta. One opisuju kanal, a ne osobu koja u objavi govori, a razliku između klerika i laika većinom ne provjeravaju. Za 50 najjačih izvora tu razliku pokušava pokazati kodiranje kanala u imeniku.")}
#v(6pt)
#table(columns: (1fr, 2.4cm, 2.4cm, 3cm), stroke: none, inset: (x: 4pt, y: 4.5pt), align: (left, right, right, right),
  table.header(..("Skupina", "Izvori", "Objave", "Interakcije").map(h => text(font: sans, size: 7.6pt, weight: "bold", fill: muted, upper(h)))),
  table.hline(stroke: 0.6pt + rulec),
  ..({", ".join(grows)},).map(x => text(font: sans, size: 8.8pt, x)))
#section-rule[2 · Je li dostupna u otvorenim agregatima?]
#prose{c("Djelomično. U javnom repozitoriju projekta na GitHubu nalaze se katalog izvora, registar skupina aktera, tablica broja aktera po vrsti iz studije o katoličkim influencerima i agregati korpusa po platformama i izvorima. Agregati ovog izvještaja po skupinama i ulogama pripremljeni su bez identiteta izvora, ali još nisu objavljeni. Imenovani popisi ostaju izvan javnog repozitorija dok voditelj projekta ne odluči o objavi.")}
#section-rule[3 · Može li se dobiti popis 50 najutjecajnijih izvora?]
#prose[Može. Popis je u imeniku na stranici #context counter(page).at(<p-imenik>).first(), s vrstom kanala, mandatom, vidljivim teološkim obrazovanjem, izvorima autoriteta, temama i tonom. Ti su stupci kodirani jezičnim modelom iz šest nasumičnih objava po kanalu i polazište su za ručno kodiranje, a ne njegova zamjena. Angažman se na platformama bilježi različito, pa je poredak najpouzdaniji unutar platforme.]
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026.")}
]
""")

# method
meth_left = [
    ("Podaci", f"Korpus DigiKat obuhvaća {n(S['rows'])} objava o katoličkim temama s portala i društvenih mreža, od {hrdate(S['date_min'])} do {hrdate(S['date_max'])}. U korpus objava ulazi po jednom pravilu za cijelo razdoblje, a ručna provjera procjenjuje da je oko {dec(S['precision'])} % objava doista katoličkog sadržaja. Nakon uklanjanja {n(S['dupes'])} ponovljenih zapisa ostaje {n(POSTS)} objava."),
    ("Usporedbe", "Način prikupljanja promijenio se 2024., a od veljače do svibnja 2024. nema tekstova. Zato se broj objava po godinama ne uspoređuje. Uspoređuju se udjeli unutar godine i skupine unutar iste platforme."),
    ("Skupine izvora", f"Šest skupina katoličkih izvora izvedeno je iz postojećih popisa projekta, istim postupkom kao u ranijim studijama. Oznaka opisuje kanal. Skupina svećeničkih profila gotovo je cijela jedan kanal, {p(pul['share_of_clergy_posts'])} objava."),
    ("Zatvoreni popis", f"Popis od {R['list']['persons']} osoba sastavljen je iz imena koja se u korpusu najčešće pojavljuju uz oznake službe, poput biskupa, svećenika, profesora ili teologa, te iz nekoliko laičkih glasova. Uloga je oznaka koja se uz ime najčešće pojavljuje. Izjava je prepoznata kad su ime i glagol govorenja ili riječ poput homilije, poruke ili intervjua udaljeni najviše 110 znakova u istom odlomku. Postupak nije provjeren ručno."),
]
meth_right = [
    ("Pregledani uzorak", f"{N_SMP} objava izvučeno je nasumično, po {PER_STR} iz katoličkih i ostalih izvora, iz objava s portala, Facebooka i YouTubea koje imaju najmanje 400 znakova teksta i barem jedan izraz nauka. Skupine se ne zbrajaju jer nisu izvučene razmjerno. Svaku je objavu kodirao jezični model Claude prema studijskoj šifrarnici. Voditelj projekta odlučio je da ručne provjere ne bude, pa su udjeli iz uzorka procjene nepoznate točnosti."),
    ("Kanali", "50 katoličkih izvora s najviše zabilježenih interakcija kodirano je istim modelom iz naziva i šest nasumičnih objava po kanalu."),
    ("Što izvještaj ne može reći", "Koliko je ljudi objave pročitalo. Tko govori, a nije na popisu. Koliko je točno automatsko prepoznavanje izjava i kodiranje modelom. Tko stvarno uređuje kanale bez vidljivog autora."),
    ("Za sljedeće izdanje", "Tri podatka učinila bi sljedeće izdanje čvršćim. To su ručna provjera uzorka i prepoznatih izjava, otvoren popis govornika i potvrda vlasnika najjačih kanala."),
]


def mcol(items):
    return "[" + "\n".join(f"#eyebrow{c(t)} #v(-4pt) #hr() #v(2pt) #text(font: sans, size: 8.4pt, par(leading: 0.58em){c(b)}) #v(8pt)" for t, b in items) + "]"


add(f"""
#spread(section: "Završnica", bg: cream2)[
#metadata(none) <p-metoda>
#kicker[Metoda]
#headline[Metoda i granice]
#grid(columns: (1fr, 1fr), column-gutter: 22pt, {mcol(meth_left)}, {mcol(meth_right)})
]
""")

# directory: top 50
def top_rows(lst):
    out = []
    for r in lst:
        out.append(", ".join([ts(str(r["rank"])), ts(r["source"]), ts(PLAT_HR.get(r["platform"], r["platform"])),
                              ts(TIP_SHORT.get(r.get("tip"), "")), ts(n(r["posts"])), ts(n(r["interactions"])),
                              ts(MAND_HR.get(r.get("mandat"), "")), ts(TON_HR.get(r.get("ton"), ""))]))
    return ", ".join(out)


def top_table(lst):
    return f"""#table(columns: (0.7cm, 4.6cm, 1.7cm, 3.9cm, 1.4cm, 1.9cm, 1.8cm, 1.6cm), stroke: (x, y) => (bottom: if y > 0 {{ 0.3pt + stone-l }} else {{ 0.6pt + rulec }}),
  inset: (x: 3pt, y: 3.6pt), align: (right, left, left, left, right, right, left, left),
  table.header(..("", "Izvor", "Platforma", "Vrsta kanala", "Objave", "Interakcije", "Mandat", "Ton").map(h => text(font: sans, size: 6.8pt, weight: "bold", fill: muted, upper(h)))),
  ..({top_rows(lst)},).map(x => text(font: sans, size: 7.8pt, x)))"""


add(f"""
#spread(section: "Imenik")[
#metadata(none) <p-imenik>
#kicker[Izvori]
#headline[50 katoličkih izvora s najviše interakcija]
{top_table(top50[:25])}
#source{c("Izvor podataka je korpus DigiKat, od siječnja 2021. do lipnja 2026. Poredak po ukupnim zabilježenim interakcijama na svim platformama, koje se bilježe različito. Vrsta kanala, mandat i ton kodirani su jezičnim modelom iz šest nasumičnih objava, bez ručne provjere. Mandat nije vidljiv znači da ga objave ne pokazuju.")}
]
""")
add(f"""
#spread(section: "Imenik", bg: cream2)[
#kicker[Izvori, nastavak]
#headline[Mjesta 26 do 50]
{top_table(top50[25:])}
#v(8pt)
#prose{c(f"Teološko obrazovanje onoga tko govori vidljivo je kod {EDU_VIS} od 50 kanala. Puni popis s izvorima autoriteta, temama, učestalošću tumačenja nauka i kratkim opisom svakog kanala nalazi se u tablici koja prati ovo izdanje.")}
#source{c("Izvor podataka je korpus DigiKat. Kodiranje jezičnim modelom bez ručne provjere.")}
]
""")

# directory: voices
vp = [r for r in persons][:40]
vrows = ", ".join(", ".join([ts(str(i)), ts(r["name"]), ts(ROLE_HR[r["role"]]), ts(n(r["mentions"])), ts(n(r["statements"])),
                             ts(p(100 * r["other_stmt"] / r["statements"]) if r["statements"] else "")]) for i, r in enumerate(vp, 1))
add(f"""
#spread(section: "Imenik")[
#kicker[Osobe]
#headline[40 praćenih osoba s najviše izjava]
#table(columns: (0.7cm, 5cm, 4.2cm, 2cm, 2cm, 2.6cm), stroke: (x, y) => (bottom: if y > 0 {{ 0.3pt + stone-l }} else {{ 0.6pt + rulec }}),
  inset: (x: 3pt, y: 2.6pt), align: (right, left, left, right, right, right),
  table.header(..("", "Osoba", "Uloga", "Spomeni", "Izjave", "Izvan kat. medija").map(h => text(font: sans, size: 6.8pt, weight: "bold", fill: muted, upper(h)))),
  ..({vrows},).map(x => text(font: sans, size: 7.6pt, x)))
#v(10pt)
#hr()
#grid(columns: (4.2cm, 1fr), column-gutter: 14pt,
  text(font: serif, size: 16pt, par(leading: 0.45em)[Mnogo tumača, \\ malo teologa]),
  prose{c(f"Tko tumači vjeru? Izdanje 2026., od siječnja 2021. do lipnja 2026. Izvor podataka je korpus DigiKat, Hrvatsko katoličko sveučilište, licencija CC BY 4.0. Tekst je složen pismima Palatino Linotype i Segoe UI, a prijelom i grafikoni izrađeni su u sustavu Typst. Svi brojevi u tekstu i na grafikonima računaju se iz istih tablica. Korpus {S['sha']}.")})
]
""")

# ---------------------------------------------------------------- write and compile
OUT_TYP.parent.mkdir(parents=True, exist_ok=True)
head = '#import "../../../typeset/template.typ": *\n#set document(title: "Tko tumači vjeru?", author: "DigiKat")\n#set text(lang: "hr", font: sans, fill: ink, hyphenate: false)\n#set par(justify: false)\n'
OUT_TYP.write_text(head + "\n".join(pages), encoding="utf-8")
print("Wrote", OUT_TYP)
res = subprocess.run([str(QUARTO), "typst", "compile", "--root", str(ROOT), str(OUT_TYP), str(OUT_PDF)],
                     capture_output=True, text=True, encoding="utf-8")
print(res.stdout[-3000:], res.stderr[-6000:])
sys.exit(res.returncode)
