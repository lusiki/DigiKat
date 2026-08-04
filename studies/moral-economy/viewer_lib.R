#!/usr/bin/env Rscript
# moral-economy — VIEWER LIBRARY (shared HTML shell for the local inspection pages).
#
# SOURCE this; never run it. `11_gold_viewer.R` and `12_wta_viewer.R` both render a filterable page of
# post cards, so the escaping, the stylesheet and the filter/preset JS live here once.
#
# Every page built through this shell is RESTRICTED output (row-level text, URLs, outlet identities):
# write it to gitignored output/private/ only. `vw_page()` stamps the restriction banner itself.

vw_esc <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE); gsub("\"", "&quot;", x, fixed = TRUE)
}
vw_nz <- function(x, alt = "—") ifelse(is.na(x) | !nzchar(as.character(x)), alt, as.character(x))

# a <select> whose options are the sorted distinct values of v
vw_select <- function(field, label, v) paste0(
  "<select data-f=\"", field, "\"><option value=\"\">", label, ": all</option>",
  paste0("<option value=\"", vw_esc(sort(unique(v))), "\">", vw_esc(sort(unique(v))),
         "</option>", collapse = ""), "</select>")

# preset chips. presets = named list; each element a named character vector of dataset filters, with
# attribute "label" and optional attribute "tone" ("hot" = green emphasis, "bad" = orange emphasis).
vw_presets_html <- function(presets) paste0(
  vapply(names(presets), function(nm) {
    tone <- attr(presets[[nm]], "tone")
    paste0("<button class=\"pre", if (is.null(tone)) "" else paste0(" ", tone),
           "\" data-p=\"", nm, "\">", vw_esc(attr(presets[[nm]], "label")), "</button>")
  }, ""), collapse = "")

vw_preset_js <- function(presets) paste0("{", paste0(vapply(names(presets), function(nm) {
  p <- presets[[nm]]
  # A no-filter preset (the "all" chip) MUST emit `nm:{}`. paste0() renders a zero-length argument as ""
  # rather than dropping it, so the general branch would yield `nm:{:''}` — a JS syntax error that kills
  # the whole <script>, silently disabling every preset AND every select on the page.
  if (!length(p)) return(paste0(nm, ":{}"))
  paste0(nm, ":{", paste0(names(p), ":'", p, "'", collapse = ","), "}")
}, ""), collapse = ","), "}")

VW_CSS <- "
:root{--bg:#fbfaf7;--fg:#1c1a17;--mut:#6b6560;--line:#e2ddd4;--card:#fff;--acc:#2b5f8e;
--warn:#b4531f;--ok:#2e6b45;--no:#8a8580}
@media(prefers-color-scheme:dark){:root{--bg:#16150f;--fg:#eae6de;--mut:#9c968c;--line:#2f2c26;
--card:#1e1c16;--acc:#7fb2df;--warn:#e08a4e;--ok:#6fbb8c;--no:#77726a}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.6 -apple-system,Segoe UI,Roboto,sans-serif}
header{padding:22px 26px 14px;border-bottom:1px solid var(--line)}
h1{margin:0 0 4px;font-size:20px}
.sub{color:var(--mut);font-size:13px}
.presets{padding:13px 26px 3px;display:flex;flex-wrap:wrap;gap:8px}
.pre{font:13px/1.3 inherit;padding:7px 13px;border-radius:99px;cursor:pointer;
background:var(--card);color:var(--fg);border:1px solid var(--line)}
.pre:hover{border-color:var(--acc)}
.pre.hot{border-color:var(--ok);color:var(--ok);font-weight:600}
.pre.bad{border-color:var(--warn);color:var(--warn);font-weight:600}
.pre.on{background:var(--acc);border-color:var(--acc);color:#fff;font-weight:600}
.pre.hot.on{background:var(--ok);border-color:var(--ok);color:#fff}
.pre.bad.on{background:var(--warn);border-color:var(--warn);color:#fff}
.tools{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);
padding:10px 26px;display:flex;flex-wrap:wrap;gap:8px;align-items:center}
select,input{font:13px/1.4 inherit;padding:5px 7px;background:var(--card);color:var(--fg);
border:1px solid var(--line);border-radius:5px}
input[type=search]{min-width:230px}
#count{margin-left:auto;color:var(--mut);font-size:13px;white-space:nowrap}
main{padding:18px 26px 60px;max-width:1000px;margin:0 auto}
.c{background:var(--card);border:1px solid var(--line);border-radius:9px;padding:15px 17px;margin:0 0 15px}
.bar{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin-bottom:8px}
.n{color:var(--mut);font:600 12px/1 ui-monospace,monospace}
.rid{margin-left:auto;color:var(--no);font:11px/1 ui-monospace,monospace}
.b{font-size:11px;padding:2px 7px;border-radius:99px;border:1px solid var(--line);color:var(--mut)}
.b.dom{border-color:var(--acc);color:var(--acc)}
.b.g-genuine{background:var(--ok);color:#fff;border-color:var(--ok)}
.b.warn{background:var(--warn);color:#fff;border-color:var(--warn)}
.b.good{background:var(--ok);color:#fff;border-color:var(--ok)}
h2{font-size:16px;margin:2px 0 5px;line-height:1.35}
h2 a{color:var(--acc);text-decoration:none} h2 a:hover{text-decoration:underline}
.nolink{color:var(--no);font-size:12px;font-weight:400}
.meta{color:var(--mut);font-size:12px;margin-bottom:10px}
.win,.exc,.full{font-size:13.5px;border-radius:6px;padding:9px 11px;margin-bottom:9px;
white-space:pre-wrap;overflow-wrap:anywhere}
.win{background:rgba(43,95,142,.09);border-left:3px solid var(--acc)}
.exc{background:transparent;border:1px solid var(--line)}
.win b,.exc b{display:block;font-size:10.5px;letter-spacing:.06em;text-transform:uppercase;
color:var(--mut);margin-bottom:5px}
details{margin-bottom:9px} summary{cursor:pointer;color:var(--mut);font-size:12.5px}
.full{background:transparent;border:1px dashed var(--line);margin-top:7px;max-height:420px;overflow:auto}
table.codes{width:100%;border-collapse:collapse;font-size:12.5px;margin-top:4px}
.codes th,.codes td{border-top:1px solid var(--line);padding:5px 7px;text-align:left;vertical-align:top}
.codes thead th{color:var(--mut);font-size:10.5px;letter-spacing:.05em;text-transform:uppercase;border-top:0}
.codes tbody th{font-weight:500;color:var(--mut);white-space:nowrap}
.codes .maj{font-weight:600}
.codes tr.dis td{background:rgba(180,83,31,.10)}
.scores{font:12px/1.5 ui-monospace,monospace;color:var(--mut);margin-bottom:9px}
.scores b{color:var(--fg)}
.hide{display:none}
"

# keys: dataset attributes that the selects/presets filter on. hash: preset auto-selected from #name.
vw_js <- function(keys, presets) paste0("
const KEYS=", paste0("['", paste(keys, collapse = "','"), "']"), ";
const F={q:''}; KEYS.forEach(k=>F[k]='');
const cards=[...document.querySelectorAll('.c')];
const PRESETS=", vw_preset_js(presets), ";
function sync(){
 document.querySelectorAll('select').forEach(s=>{if(s.dataset.f)s.value=F[s.dataset.f]||''});
 document.getElementById('q').value=F.q;
}
function apply(){let n=0;
 for(const c of cards){
  let ok=true;
  // Exact match first; then treat a space-separated dataset value as a TOKEN LIST, so a card carrying
  // several values (a post matching several CST terms, or tagged with several domains) shows under each.
  // Backward compatible: single-token values have no spaces, so the token test only ever adds matches.
  for(const k of KEYS){const v=c.dataset[k]||'';
   if(F[k]&&v!==F[k]&&!(' '+v+' ').includes(' '+F[k]+' '))ok=false;}
  if(ok&&F.q&&!c.textContent.toLowerCase().includes(F.q))ok=false;
  c.classList.toggle('hide',!ok); if(ok)n++;
 }
 document.getElementById('count').textContent=n+' of '+cards.length+' posts';
}
function setPreset(name){
 F.q=''; KEYS.forEach(k=>F[k]='');
 Object.assign(F,PRESETS[name]||{});
 document.querySelectorAll('.pre').forEach(b=>b.classList.toggle('on',b.dataset.p===name));
 sync(); apply(); window.scrollTo(0,0);
}
document.querySelectorAll('.pre').forEach(b=>b.onclick=()=>setPreset(b.dataset.p));
function manual(){document.querySelectorAll('.pre').forEach(b=>b.classList.remove('on'));}
for(const s of document.querySelectorAll('select'))
  s.onchange=e=>{F[e.target.dataset.f]=e.target.value;manual();apply()};
document.getElementById('q').oninput=e=>{F.q=e.target.value.toLowerCase();manual();apply()};
const h=location.hash.replace('#','');
setPreset(PRESETS[h]?h:Object.keys(PRESETS)[0]);
")

vw_page <- function(path, title, subtitle, presets, tools, cards, keys) {
  html <- paste0(
    "<!doctype html><html lang=\"hr\"><head><meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<meta name=\"robots\" content=\"noindex,nofollow\">",
    "<title>", vw_esc(title), "</title><style>", VW_CSS, "</style></head><body>",
    "<header><h1>", vw_esc(title), "</h1><div class=\"sub\">", subtitle, "<br>",
    "<b>RESTRICTED</b> — row-level text, URLs and outlet identities. ",
    "Local viewing only; never commit or publish.</div></header>",
    "<div class=\"presets\">", vw_presets_html(presets), "</div>",
    "<div class=\"tools\"><input type=\"search\" id=\"q\" placeholder=\"search text, title, outlet…\">",
    tools, "<span id=\"count\"></span></div>",
    "<main>", cards, "</main><script>", vw_js(keys, presets), "</script></body></html>")
  con <- file(path, open = "wb"); writeLines(enc2utf8(html), con, useBytes = TRUE); close(con)
  cat(sprintf("\nWrote %s (%.1f MB)\n", path, file.info(path)$size / 1024^2))
  cat("RESTRICTED output — gitignored; do not commit or publish.\n")
}
