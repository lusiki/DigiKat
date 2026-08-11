<!doctype html>
<html lang="hr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DigiKat — provjera filtera</title>
<style>
  :root{
    --bg:#faf8f4; --panel:#fff; --ink:#1a1a1a; --muted:#6b6b6b; --line:#e2ddd4;
    --accent:#2f5d8a; --yes:#2e7d52; --mention:#b8860b; --other:#7a5195; --no:#b34a3f; --skip:#6b6b6b;
  }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#16181c; --panel:#1e2126; --ink:#e8e6e3; --muted:#9a9a9a; --line:#31353c;
           --accent:#7aa8d4; --yes:#5cbf8a; --mention:#d9a93c; --other:#b08cd4; --no:#e07a6d; --skip:#9a9a9a; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--ink);
       font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
  header{position:sticky;top:0;z-index:10;background:var(--panel);border-bottom:1px solid var(--line);
         padding:10px 16px;display:flex;gap:14px;align-items:center;flex-wrap:wrap}
  .bar{flex:1;min-width:180px;height:8px;background:var(--line);border-radius:4px;overflow:hidden}
  .bar>i{display:block;height:100%;background:var(--accent);width:0;transition:width .2s}
  .counts{display:flex;gap:10px;flex-wrap:wrap;font-size:12px;color:var(--muted)}
  .counts b{color:var(--ink)}
  main{max-width:900px;margin:0 auto;padding:20px 16px 160px}
  .meta{display:flex;gap:10px;flex-wrap:wrap;font-size:13px;color:var(--muted);margin-bottom:10px}
  .chip{background:var(--panel);border:1px solid var(--line);border-radius:999px;padding:2px 10px}
  h1{font-size:20px;line-height:1.35;margin:.2em 0 .6em}
  .card{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:20px 22px}
  .text{white-space:pre-wrap;word-wrap:break-word;max-height:52vh;overflow-y:auto;
        font-size:15.5px;padding-right:8px;border-top:1px solid var(--line);padding-top:14px;margin-top:6px}
  .reveal{margin-top:14px;font-size:13px;color:var(--muted)}
  .reveal button{font:inherit;background:none;border:1px solid var(--line);border-radius:6px;
                 padding:3px 10px;color:var(--muted);cursor:pointer}
  .hidden{display:none}
  footer{position:fixed;bottom:0;left:0;right:0;background:var(--panel);border-top:1px solid var(--line);
         padding:12px 16px}
  .btns{max-width:900px;margin:0 auto;display:grid;grid-template-columns:repeat(5,1fr);gap:8px}
  .btns button{font:inherit;font-size:14px;padding:12px 6px;border-radius:9px;cursor:pointer;
               border:1.5px solid var(--line);background:var(--panel);color:var(--ink);line-height:1.25}
  .btns button:hover{border-color:var(--accent)}
  .btns button kbd{display:block;font-size:11px;color:var(--muted);margin-top:3px}
  .btns button.on{color:#fff}
  .b1.on{background:var(--yes);border-color:var(--yes)} .b2.on{background:var(--mention);border-color:var(--mention)}
  .b3.on{background:var(--other);border-color:var(--other)} .b4.on{background:var(--no);border-color:var(--no)}
  .b5.on{background:var(--skip);border-color:var(--skip)}
  .nav{max-width:900px;margin:10px auto 0;display:flex;gap:8px;align-items:center;flex-wrap:wrap;font-size:13px}
  .nav button{font:inherit;font-size:13px;padding:6px 12px;border-radius:7px;border:1px solid var(--line);
              background:var(--panel);color:var(--ink);cursor:pointer}
  .nav input{font:inherit;width:70px;padding:5px 8px;border-radius:6px;border:1px solid var(--line);
             background:var(--bg);color:var(--ink)}
  .note{width:100%;margin-top:12px;font:inherit;font-size:14px;padding:8px 10px;border-radius:8px;
        border:1px solid var(--line);background:var(--bg);color:var(--ink)}
  .done{text-align:center;padding:60px 20px;color:var(--muted)}
  a{color:var(--accent)}
</style>
</head>
<body>
<header>
  <strong style="font-size:14px">Provjera filtera</strong>
  <div class="bar"><i id="bar"></i></div>
  <div id="pos" style="font-size:13px;color:var(--muted);white-space:nowrap"></div>
  <div class="counts" id="counts"></div>
</header>

<main>
  <div id="card"></div>
</main>

<footer>
  <div class="btns">
    <button class="b1" data-v="1">Jasno katolički<kbd>1</kbd></button>
    <button class="b2" data-v="2">Samo usputni spomen<kbd>2</kbd></button>
    <button class="b3" data-v="3">Religijski, nije katolički<kbd>3</kbd></button>
    <button class="b4" data-v="4">Nije religijski<kbd>4</kbd></button>
    <button class="b5" data-v="5">Ne može se ocijeniti<kbd>5</kbd></button>
  </div>
  <div class="nav">
    <button id="prev">← natrag</button>
    <button id="next">naprijed →</button>
    <button id="jump">skoči na prvi neocijenjeni</button>
    <input id="goto" type="number" min="1" placeholder="br."><button id="gobtn">idi</button>
    <span style="flex:1"></span>
    <button id="export"><strong>Izvezi CSV</strong></button>
    <button id="reset" style="color:var(--no)">poništi sve</button>
  </div>
</footer>

<script>
const DATA = /*__DATA__*/[];
const KEY  = "__SAMPLE_ID__";
const LABELS = {1:"catholic_clear",2:"catholic_mention",3:"religious_other",4:"not_religious",5:"cannot_tell"};
const NAMES  = {1:"Jasno katolički",2:"Usputni spomen",3:"Religijski, ne katolički",4:"Nije religijski",5:"Ne može se ocijeniti"};

let state = JSON.parse(localStorage.getItem(KEY) || "{}");
let i = 0;
const save = () => localStorage.setItem(KEY, JSON.stringify(state));

function firstUnlabeled(){
  for (let k = 0; k < DATA.length; k++) if (!state[DATA[k].id]) return k;
  return DATA.length - 1;
}

function render(){
  i = Math.max(0, Math.min(i, DATA.length - 1));
  const d = DATA[i], cur = state[d.id];
  document.getElementById("card").innerHTML = `
    <div class="meta">
      <span class="chip">${d.date || "—"}</span>
      <span class="chip">${d.platform || "—"}</span>
      <span class="chip">${esc(d.source) || "—"}</span>
      ${d.url ? `<a class="chip" href="${esc(d.url)}" target="_blank" rel="noopener">otvori original ↗</a>` : ""}
    </div>
    <div class="card">
      <h1>${esc(d.title) || "<em style='color:var(--muted)'>(bez naslova)</em>"}</h1>
      <div class="text">${esc(d.text) || "<em style='color:var(--muted)'>(nema teksta)</em>"}</div>
      <div class="reveal">
        <button onclick="document.getElementById('rv').classList.toggle('hidden')">
          pokaži koje su riječi okinule filter
        </button>
        <div id="rv" class="hidden" style="margin-top:8px">
          pogodaka: <b>${d.match_count}</b> &nbsp;·&nbsp; pojmovi: ${esc(d.matched_terms) || "—"}
        </div>
      </div>
      <input class="note" id="note" placeholder="bilješka (nije obavezno)"
             value="${esc(cur && cur.note || "")}">
    </div>`;
  document.getElementById("note").addEventListener("input", e => {
    state[d.id] = Object.assign({}, state[d.id] || {label:""}, {note: e.target.value}); save();
  });
  document.querySelectorAll(".btns button").forEach(b =>
    b.classList.toggle("on", !!cur && cur.label === LABELS[b.dataset.v]));
  const n = Object.values(state).filter(s => s.label).length;
  document.getElementById("bar").style.width = (100 * n / DATA.length) + "%";
  document.getElementById("pos").textContent = `${i+1} / ${DATA.length} · ocijenjeno ${n}`;
  const tally = {};
  Object.values(state).forEach(s => { if (s.label) tally[s.label] = (tally[s.label]||0)+1; });
  document.getElementById("counts").innerHTML = Object.keys(LABELS)
    .map(k => `<span>${NAMES[k]}: <b>${tally[LABELS[k]]||0}</b></span>`).join("");
}
function esc(s){ return String(s==null?"":s)
  .replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;"); }

function setLabel(v){
  const d = DATA[i];
  state[d.id] = Object.assign({}, state[d.id] || {note:""}, {label: LABELS[v]});
  save();
  if (i < DATA.length - 1) { i++; render(); } else { render(); }
}

document.querySelectorAll(".btns button").forEach(b =>
  b.addEventListener("click", () => setLabel(b.dataset.v)));
document.getElementById("prev").onclick = () => { i--; render(); };
document.getElementById("next").onclick = () => { i++; render(); };
document.getElementById("jump").onclick = () => { i = firstUnlabeled(); render(); };
document.getElementById("gobtn").onclick = () => {
  const v = parseInt(document.getElementById("goto").value, 10);
  if (!isNaN(v)) { i = v - 1; render(); }
};
document.addEventListener("keydown", e => {
  if (e.target.tagName === "INPUT") return;
  if (e.key >= "1" && e.key <= "5") { setLabel(e.key); e.preventDefault(); }
  else if (e.key === "ArrowLeft")  { i--; render(); }
  else if (e.key === "ArrowRight") { i++; render(); }
});

document.getElementById("export").onclick = () => {
  const cols = ["id","label","note","stratum","origin","date","platform","source",
                "title","url","match_count","matched_terms","text"];
  const q = v => '"' + String(v==null?"":v).replace(/"/g,'""') + '"';
  const rows = DATA.map(d => cols.map(c =>
    q(c === "label" ? (state[d.id] && state[d.id].label || "")
    : c === "note"  ? (state[d.id] && state[d.id].note  || "")
    : d[c])).join(","));
  const csv = "﻿" + cols.join(",") + "\n" + rows.join("\n") + "\n";
  const a = document.createElement("a");
  a.href = URL.createObjectURL(new Blob([csv], {type:"text/csv;charset=utf-8"}));
  a.download = "coding_sample_coded.csv";
  a.click();
};
document.getElementById("reset").onclick = () => {
  if (confirm("Obrisati sve ocjene? Ovo se ne može poništiti.")) {
    state = {}; save(); i = 0; render();
  }
};

i = firstUnlabeled();
render();
</script>
</body>
</html>
