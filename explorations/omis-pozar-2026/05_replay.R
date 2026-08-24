# 05_replay.R — a self-contained interactive HTML replay of the story: press play and watch the
# media fire build hour by hour, with the fire's own events, the sources entering, and the frames
# carrying the story at that hour. Vanilla JS + inline SVG; no external requests, so it works on a
# blog, GitHub Pages, or opened from disk.
#
#   Rscript 05_replay.R
#
# Reads output/agg/*.csv + derived.json; writes output/replay.html

setwd(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))))
source("lib.R")

D <- read_json(file.path(AGG_DIR, "derived.json"), simplifyVector = TRUE)
SYNTH <- isTRUE(D$synthetic)
rd <- function(name) fread(file.path(AGG_DIR, paste0(name, ".csv")), encoding = "UTF-8")

type_levels <- c("lokalni", "drustveni", "nacionalni", "sluzbeni", "ostali_web", "strani")
PAL_TYPE <- c(sluzbeni = "#2E6FB7", lokalni = "#E4572E", nacionalni = "#8B1A1A", ostali_web = "#B39C86", strani = "#6C5B7B", drustveni = "#F5A623")
LAB_TYPE <- c(sluzbeni = "Službeni izvori", lokalni = "Lokalni (Dalmacija)", nacionalni = "Nacionalni mediji", ostali_web = "Ostali web", strani = "Strani mediji", drustveni = "Društvene mreže")
LAB_FRAME <- sapply(FRAMES, `[[`, "hr")

hourly <- rd("hourly")[, .(n = sum(n)), by = .(hb, outlet_type)]
tot <- rd("hourly_total")
H_MAX <- max(tot$hb)
grid <- CJ(hb = 0:H_MAX, outlet_type = type_levels)
hourly <- merge(grid, hourly, by = c("hb", "outlet_type"), all.x = TRUE)[is.na(n), n := 0L]
vol <- dcast(hourly, hb ~ outlet_type, value.var = "n")[order(hb)]
setcolorder(vol, c("hb", type_levels))
inter <- tot[order(hb), .(hb, interactions)]
cas <- rd("cascade")[, .(FROM, outlet_type, first_hb = floor(first_h), n)]
fh <- rd("frames_hourly")[, .(hb3, frame, share)]
fh_w <- dcast(fh, hb3 ~ frame, value.var = "share")[order(hb3)]
ev <- copy(FIRE_EVENTS)[, h := round(hours_since(t), 2)][, .(h, label = label_hr, phase, clock = format(t, "%a %d.%m. %H:%M", tz = TZ))]

payload <- list(
  synthetic = SYNTH, t0 = format(T0, "%Y-%m-%dT%H:%M:00", tz = TZ), t0_label = format(T0, "%d.%m.%Y. %H:%M", tz = TZ), h_max = H_MAX,
  types = type_levels, type_labels = unname(LAB_TYPE[type_levels]), type_colors = unname(PAL_TYPE[type_levels]),
  vol = vol, inter = inter, sources = cas, frames_bins = fh_w, frame_labels = as.list(LAB_FRAME), events = ev,
  totals = list(items = D$n_items, sources = D$n_sources, span = D$span_hours, peak_hour = D$peak_hour, peak_n = D$peak_n, t50 = D$t50_hours, t80 = D$t80_hours,
                share_items_24 = D$share_items_first_24h, share_inter_24 = D$share_interactions_first_24h)
)
js <- toJSON(payload, auto_unbox = TRUE, dataframe = "rows", na = "null", digits = NA)

hours_labels <- vapply(0:H_MAX, function(hh) format(T0 + hh * 3600, "%a %d.%m. %H:%M", tz = TZ), character(1))
js_hours <- toJSON(hours_labels)

TPL <- '<!doctype html>
<html lang="hr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dva požara — replay medijske priče o požaru kod Omiša</title>
<style>
  :root { --paper:#FBF6EE; --panel:#FFFFFF; --ink:#1F1A17; --body:#3A332E; --muted:#6B625B; --faint:#9A9086; --grid:#EADFD0; --night:#F1EAE0; --ember:#E4572E; --amber:#F5A623; --deep:#8B1A1A; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--paper); color:var(--body); font: 15px/1.45 "Source Sans 3", "Segoe UI", system-ui, sans-serif; }
  .wrap { max-width: 1180px; margin: 0 auto; padding: 28px 22px 40px; }
  h1 { font-family: "Source Serif 4", Georgia, serif; font-size: 30px; line-height:1.15; color:var(--ink); margin: 0 0 6px; }
  .sub { color: var(--muted); max-width: 900px; margin: 0 0 14px; }
  .synth { display:inline-block; background:#FFE9A8; color:var(--deep); font-family: "IBM Plex Mono", Consolas, monospace; font-size: 12px; padding: 3px 8px; border-radius: 3px; margin-bottom: 10px; }
  .controls { display:flex; align-items:center; gap:14px; flex-wrap:wrap; margin: 8px 0 10px; }
  button { background: var(--ink); color: var(--paper); border:0; border-radius: 4px; padding: 8px 14px; font: inherit; cursor:pointer; }
  button.secondary { background: transparent; color: var(--ink); border: 1px solid var(--grid); }
  input[type=range] { flex: 1 1 320px; accent-color: var(--ember); }
  .clock { font-family: "IBM Plex Mono", Consolas, monospace; font-size: 14px; color: var(--ink); min-width: 250px; }
  .clock b { font-size: 20px; }
  .layout { display: grid; grid-template-columns: minmax(0, 2.2fr) minmax(280px, 1fr); gap: 18px; align-items: start; }
  .card { background: var(--panel); border: 1px solid var(--grid); border-radius: 6px; padding: 12px 14px; }
  .card h3 { margin: 0 0 8px; font-family: "Source Serif 4", Georgia, serif; font-size: 16px; color: var(--ink); }
  svg { width: 100%; height: auto; display:block; }
  .legend { display:flex; flex-wrap:wrap; gap: 6px 14px; font-size: 13px; margin: 6px 0 2px; }
  .legend span::before { content:""; display:inline-block; width:11px; height:11px; border-radius:2px; margin-right:5px; vertical-align:-1px; background: var(--c); }
  .kpis { display:grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 10px; }
  .kpi { background: var(--paper); border-radius: 4px; padding: 8px 10px; }
  .kpi b { display:block; font-family: "IBM Plex Mono", Consolas, monospace; font-size: 20px; color: var(--ink); }
  .kpi small { color: var(--muted); }
  .ev { border-left: 3px solid var(--ember); padding: 4px 10px; margin: 6px 0; font-size: 14px; }
  .ev small { display:block; color: var(--muted); font-family: "IBM Plex Mono", Consolas, monospace; font-size: 12px; }
  .ev.past { border-left-color: var(--grid); color: var(--muted); }
  .bar { display:grid; grid-template-columns: 150px 1fr 40px; gap: 8px; align-items:center; font-size: 13px; margin: 3px 0; }
  .bar .track { background: var(--paper); height: 10px; border-radius: 5px; overflow:hidden; }
  .bar .fill { height: 100%; background: var(--ember); border-radius: 5px; transition: width .25s; }
  .bar .val { font-family: "IBM Plex Mono", Consolas, monospace; text-align:right; color: var(--muted); }
  .src { font-size: 13px; }
  .src span { display:inline-block; margin: 2px 6px 2px 0; padding: 1px 7px; border-radius: 10px; background: var(--paper); border: 1px solid var(--grid); }
  .foot { color: var(--faint); font-family: "IBM Plex Mono", Consolas, monospace; font-size: 12px; margin-top: 18px; }
  @media (max-width: 800px) { .layout { grid-template-columns: 1fr; } .kpis { grid-template-columns: repeat(3, 1fr);} }
</style>
</head>
<body>
<div class="wrap">
  {{BANNER}}
  <h1>Dva požara: kako se širila medijska priča o požaru kod Omiša</h1>
  <p class="sub">Pritisnite <b>▶ Pokreni</b> ili povucite klizač. Gore raste broj objava po satu, po vrsti izvora; dolje (žuto) interakcije koje je skupio sadržaj objavljen u tom satu. Desno: što se u tom trenutku događalo na terenu, tko je do tada ušao u priču i o čemu se pisalo. Sat 0 je dojava o požaru, {{T0}}.</p>
  <div class="controls">
    <button id="play">▶ Pokreni</button>
    <button id="reset" class="secondary">⟲ Početak</button>
    <input type="range" id="scrub" min="0" max="{{HMAX}}" value="0" step="1">
    <div class="clock">sat <b id="hh">0</b> · <span id="clk"></span></div>
  </div>
  <div class="layout">
    <div>
      <div class="card">
        <div class="legend" id="legend"></div>
        <svg id="chart" viewBox="0 0 900 430" preserveAspectRatio="xMidYMid meet" role="img" aria-label="Objave i interakcije po satu"></svg>
      </div>
    </div>
    <div>
      <div class="kpis">
        <div class="kpi"><b id="k_items">0</b><small>objava do sada</small></div>
        <div class="kpi"><b id="k_sources">0</b><small>izvora ušlo</small></div>
        <div class="kpi"><b id="k_inter">0</b><small>interakcija do sada</small></div>
      </div>
      <div class="card"><h3>Na terenu</h3><div id="events"></div></div>
      <div class="card" style="margin-top:10px"><h3>O čemu se piše (zadnja 3 sata)</h3><div id="frames"></div></div>
      <div class="card" style="margin-top:10px"><h3>Tko je ušao u priču</h3><div id="sources" class="src"></div></div>
    </div>
  </div>
  <p class="foot">Izvor: izvoz servisa za praćenje medija (Determ) · vrijeme Europe/Zagreb · analiza: L. Šikić · Sve je opisno: „tko je bio prvi” je usporedba vremenskih oznaka, ne dokaz utjecaja; interakcije su vrijednosti servisa i razlikuju se po platformi.{{FOOT}}</p>
</div>
<script>
const DATA = {{DATA}};
const HOURS = {{HOURS}};
const fmt = n => Math.round(n).toString().replace(/\\B(?=(\\d{3})+(?!\\d))/g, "\\u00a0");
const T = DATA.types, TL = DATA.type_labels, TC = DATA.type_colors, HMAX = DATA.h_max;
const vol = DATA.vol, inter = DATA.inter;
const maxUp = Math.max(...vol.map(r => T.reduce((s,t) => s + (r[t]||0), 0)));
const maxDn = Math.max(1, ...inter.map(r => r.interactions||0));
const W = 900, H = 430, L = 54, R = 12, TOP = 18, MID = 250, BOT = 400;
const x = h => L + (h / (HMAX + 1)) * (W - L - R);
const bw = (W - L - R) / (HMAX + 1);
const yUp = v => MID - (v / maxUp) * (MID - TOP);
const yDn = v => MID + (v / maxDn) * (BOT - MID);
const svg = document.getElementById("chart");
const NS = "http://www.w3.org/2000/svg";
const el = (n, a) => { const e = document.createElementNS(NS, n); for (const k in a) e.setAttribute(k, a[k]); return e; };
// static: nights, axes
const t0 = new Date(DATA.t0);
for (let h = -24; h <= HMAX + 24; h++) { const d = new Date(t0.getTime() + h*3600e3); if (d.getHours() === 22) { const x0 = Math.max(0, h), x1 = Math.min(HMAX + 1, h + 8); if (x1 > 0 && x0 < HMAX+1) svg.appendChild(el("rect", {x: x(x0), y: TOP, width: x(x1)-x(x0), height: BOT-TOP, fill: "#F1EAE0"})); } }
for (let h = 0; h <= HMAX; h += 12) { svg.appendChild(el("line", {x1: x(h), x2: x(h), y1: TOP, y2: BOT, stroke: "#EADFD0"})); const t = el("text", {x: x(h)+2, y: BOT + 14, "font-size": 11, fill: "#6B625B", "font-family": "IBM Plex Mono, Consolas, monospace"}); t.textContent = h + " h"; svg.appendChild(t); const t2 = el("text", {x: x(h)+2, y: BOT + 26, "font-size": 10, fill: "#9A9086", "font-family": "IBM Plex Mono, Consolas, monospace"}); t2.textContent = HOURS[h].slice(-5); svg.appendChild(t2); }
svg.appendChild(el("line", {x1: L, x2: W - R, y1: MID, y2: MID, stroke: "#1F1A17", "stroke-width": 1}));
[[0.5,"↑ objave / sat"],[1,""]].forEach(()=>{});
const yl = el("text", {x: L - 4, y: MID - 6, "font-size": 10, "text-anchor": "end", fill: "#6B625B"}); yl.textContent = "objave ↑"; svg.appendChild(yl);
const yl2 = el("text", {x: L - 4, y: MID + 14, "font-size": 10, "text-anchor": "end", fill: "#6B625B"}); yl2.textContent = "interakcije ↓"; svg.appendChild(yl2);
[maxUp, Math.round(maxUp/2)].forEach(v => { const t = el("text", {x: L - 4, y: yUp(v) + (v === maxUp ? 10 : 4), "font-size": 10, "text-anchor": "end", fill: "#9A9086", "font-family": "IBM Plex Mono, Consolas, monospace"}); t.textContent = v; svg.appendChild(t); svg.appendChild(el("line", {x1: L, x2: W-R, y1: yUp(v), y2: yUp(v), stroke: "#EADFD0"})); });
[maxDn, Math.round(maxDn/2)].forEach(v => { const t = el("text", {x: L - 4, y: yDn(v) + 4, "font-size": 10, "text-anchor": "end", fill: "#9A9086", "font-family": "IBM Plex Mono, Consolas, monospace"}); t.textContent = fmt(v); svg.appendChild(t); });
// dynamic groups
const gUp = el("g", {}); const gDn = el("g", {}); const gEv = el("g", {}); const cursor = el("line", {x1: 0, x2: 0, y1: TOP, y2: BOT, stroke: "#E4572E", "stroke-width": 1.5, "stroke-dasharray": "4 3"});
svg.appendChild(gUp); svg.appendChild(gDn); svg.appendChild(gEv); svg.appendChild(cursor);
// event ticks (numbers) placed at their hour, revealed when reached
DATA.events.forEach((e, i) => { const g = el("g", {opacity: 0}); g.appendChild(el("line", {x1: x(e.h), x2: x(e.h), y1: TOP + 4, y2: MID, stroke: "#1F1A17", "stroke-dasharray": "2 3", "stroke-width": 0.8})); g.appendChild(el("circle", {cx: x(e.h), cy: TOP + 8, r: 8, fill: "#FBF6EE", stroke: "#1F1A17"})); const t = el("text", {x: x(e.h), y: TOP + 11.5, "font-size": 10, "text-anchor": "middle", fill: "#1F1A17", "font-family": "IBM Plex Mono, Consolas, monospace"}); t.textContent = i + 1; g.appendChild(t); gEv.appendChild(g); });
// legend
const lg = document.getElementById("legend"); T.forEach((t, i) => { const s = document.createElement("span"); s.style.setProperty("--c", TC[i]); s.textContent = TL[i]; lg.appendChild(s); });
const ic = document.createElement("span"); ic.style.setProperty("--c", "#F5A623"); ic.textContent = "interakcije (dolje)"; lg.appendChild(ic);
// draw hour h
const drawn = new Set();
function drawHour(h) {
  if (drawn.has(h)) return; drawn.add(h);
  const r = vol[h] || {}; let acc = 0;
  T.forEach((t, i) => { const v = r[t] || 0; if (v > 0) { gUp.appendChild(el("rect", {x: x(h), y: yUp(acc + v), width: Math.max(1, bw - 0.6), height: yUp(acc) - yUp(acc + v), fill: TC[i]})); acc += v; } });
  const iv = (inter[h] && inter[h].interactions) || 0; if (iv > 0) gDn.appendChild(el("rect", {x: x(h), y: MID, width: Math.max(1, bw - 0.6), height: yDn(iv) - MID, fill: "#F5A623", opacity: 0.9}));
}
function render(h) {
  gUp.innerHTML = ""; gDn.innerHTML = ""; drawn.clear();
  for (let i = 0; i <= h; i++) drawHour(i);
  cursor.setAttribute("x1", x(h + 1)); cursor.setAttribute("x2", x(h + 1));
  DATA.events.forEach((e, i) => gEv.children[i].setAttribute("opacity", e.h <= h + 1 ? 1 : 0));
  document.getElementById("hh").textContent = h; document.getElementById("clk").textContent = HOURS[h];
  // KPIs
  let items = 0, inters = 0; for (let i = 0; i <= h; i++) { const r = vol[i] || {}; items += T.reduce((s,t) => s + (r[t]||0), 0); inters += (inter[i] && inter[i].interactions) || 0; }
  const srcs = DATA.sources.filter(s => s.first_hb <= h);
  document.getElementById("k_items").textContent = fmt(items); document.getElementById("k_sources").textContent = fmt(srcs.length); document.getElementById("k_inter").textContent = fmt(inters);
  // events panel: last 3 reached, next one greyed
  const evd = document.getElementById("events"); evd.innerHTML = "";
  const reached = DATA.events.filter(e => e.h <= h + 1), next = DATA.events.find(e => e.h > h + 1);
  reached.slice(-3).forEach(e => { const d = document.createElement("div"); d.className = "ev"; d.innerHTML = "<small>" + e.clock + " · sat " + e.h + "</small>" + e.label; evd.appendChild(d); });
  if (next) { const d = document.createElement("div"); d.className = "ev past"; d.innerHTML = "<small>slijedi · sat " + next.h + "</small>" + next.label; evd.appendChild(d); }
  if (!reached.length && !next) evd.textContent = "—";
  // frames panel: the 3-h bin containing h
  const b = Math.floor(h / 3) * 3; const row = DATA.frames_bins.find(r => r.hb3 === b); const fd = document.getElementById("frames"); fd.innerHTML = "";
  if (row) { Object.keys(DATA.frame_labels).map(k => [k, row[k] == null ? 0 : row[k]]).sort((a,b) => b[1]-a[1]).forEach(([k, v]) => { const d = document.createElement("div"); d.className = "bar"; d.innerHTML = "<span>" + DATA.frame_labels[k] + "</span><div class=\\"track\\"><div class=\\"fill\\" style=\\"width:" + Math.min(100, v) + "%\\"></div></div><span class=\\"val\\">" + Math.round(v) + "%</span>"; fd.appendChild(d); }); } else fd.textContent = "premalo objava u ovom pojasu";
  // sources panel: by type counts + last 8 names
  const sd = document.getElementById("sources"); sd.innerHTML = "";
  T.forEach((t, i) => { const n = srcs.filter(s => s.outlet_type === t).length; if (n) { const s = document.createElement("span"); s.style.borderColor = TC[i]; s.textContent = TL[i] + ": " + n; sd.appendChild(s); } });
  const last = srcs.slice().sort((a,b) => b.first_hb - a.first_hb).slice(0, 8);
  if (last.length) { const p = document.createElement("div"); p.style.marginTop = "6px"; p.style.color = "#6B625B"; p.textContent = "zadnji ušli: " + last.map(s => s.FROM).join(", "); sd.appendChild(p); }
}
let cur = 0, timer = null;
const scrub = document.getElementById("scrub"), play = document.getElementById("play");
function setHour(h) { cur = Math.max(0, Math.min(HMAX, h)); scrub.value = cur; render(cur); }
function stop() { if (timer) { clearInterval(timer); timer = null; } play.textContent = "▶ Pokreni"; }
play.addEventListener("click", () => { if (timer) { stop(); return; } if (cur >= HMAX) cur = -1; play.textContent = "❚❚ Pauza"; timer = setInterval(() => { if (cur >= HMAX) { stop(); return; } setHour(cur + 1); }, 140); });
document.getElementById("reset").addEventListener("click", () => { stop(); setHour(0); });
scrub.addEventListener("input", e => { stop(); setHour(+e.target.value); });
const hm = /[#&]h=(\\d+)/.exec(location.hash || ""); setHour(hm ? +hm[1] : 0);   // #h=30 opens the replay at hour 30
</script>
</body>
</html>'
fill <- c(BANNER = if (SYNTH) paste0('<div class="synth">', SYNTH_TAG_HR, '</div>') else "",
          T0 = format(T0, "%d.%m.%Y. u %H:%M", tz = TZ), HMAX = as.character(H_MAX),
          FOOT = if (SYNTH) paste0(" · ", SYNTH_TAG_HR) else "", DATA = as.character(js), HOURS = as.character(js_hours))
html <- TPL
for (k in names(fill)) html <- stri_replace_all_fixed(html, paste0("{{", k, "}}"), fill[[k]])
stopifnot(!grepl("\\{\\{[A-Z0-9]+\\}\\}", html))
writeLines(html, file.path(OUT_DIR, "replay.html"), useBytes = TRUE)
cat("Wrote", file.path(OUT_DIR, "replay.html"), sprintf("(%.0f KB)\n", file.size(file.path(OUT_DIR, "replay.html")) / 1024))
if (SYNTH) cat(">>> ", SYNTH_TAG_EN, " <<<\n")
