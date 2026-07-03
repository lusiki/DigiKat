#!/usr/bin/env Rscript
# =====================================================================================
# R/export_network_video.R
# Export the six-platform source network as a square, gently-animated MP4 for social
# media (LinkedIn autoplays muted video in-feed; it does NOT accept HTML or animate GIFs).
#
# INPUT  (single source of truth — the SAME aggregates the site's pages/izvori network reads):
#   data/processed/<platform>_actors.rds   (web, youtube, facebook, instagram, tiktok, twitter)
#   resources/dictionaries/source_labels.csv   (PI-owned publish/entity sidecar)
#   R/theme_digikat.R                            (brand colours: dk_col, dk_platform_colors)
#
# OUTPUT:
#   preview/mreza_linkedin.mp4  — 1080x1080, H.264 / yuv420p, 30 fps, ~6 s seamless loop
#
# HOW IT WORKS:
#   Builds the exact vis.js graph of the network partial, renders it in a headless Chromium
#   (chromote), then drives N deterministic frames where every node floats on its own sine
#   cycle (frame N wraps to frame 0 -> seamless loop), and encodes with ffmpeg bundled in `av`.
#
# DEPENDENCIES: dplyr, jsonlite, visNetwork (supplies vis.js), chromote (+ a Chrome/Edge
#   browser on the machine), av (bundled ffmpeg). No system ffmpeg required.
#
# RUN (from the REPO ROOT):
#   Rscript R/export_network_video.R
#   # If the browser isn't auto-found, point to it explicitly:
#   CHROMOTE_CHROME="C:/Program Files/Google/Chrome/Application/chrome.exe" Rscript R/export_network_video.R
#
# Re-run whenever the actor aggregates are refreshed. Reproducible from the tracked data;
# needs a headless-capable Chromium (Chrome or Edge).
# =====================================================================================

## ---- tunable knobs -------------------------------------------------------------------
OUT      <- "preview/mreza_linkedin.mp4"
N_FRAMES <- 180        # 6 s at 30 fps
FPS      <- 30
DIM      <- 1080       # square output px (layout below is tuned for 1080)
SCALE    <- 2          # headless supersample factor (crisper text); downscaled on encode
SEED     <- 123        # deterministic layout
AMP_MIN  <- 5          # node float amplitude (px): nodes sway between AMP_MIN..AMP_MIN+3*2

## ---- guards --------------------------------------------------------------------------
for (p in c("dplyr", "jsonlite", "visNetwork", "chromote", "av")) {
  if (!requireNamespace(p, quietly = TRUE))
    stop(sprintf("Missing R package '%s'. install.packages('%s')", p, p), call. = FALSE)
}
if (!dir.exists("data/processed"))
  stop("Run from the repo root: data/processed/ not found.", call. = FALSE)
suppressMessages({ library(dplyr); library(jsonlite) })
source("R/theme_digikat.R")

## ---- pick a headless browser (avoids chromote::find_chrome, which can be flaky) -------
pick_chrome <- function() {
  env <- Sys.getenv("CHROMOTE_CHROME")
  if (nzchar(env) && file.exists(env)) return(env)
  cand <- c("C:/Program Files/Google/Chrome/Application/chrome.exe",
            "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
            "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
            "C:/Program Files/Microsoft/Edge/Application/msedge.exe")
  hit <- cand[file.exists(cand)]
  if (length(hit)) hit[1] else ""
}
chrome <- pick_chrome()
if (nzchar(chrome)) Sys.setenv(CHROMOTE_CHROME = chrome)

## ---- build the graph (identical to pages/izvori/_mreza_graf.qmd) ----------------------
platforms <- c(web="web_actors.rds", youtube="youtube_actors.rds", facebook="facebook_actors.rds",
               instagram="instagram_actors.rds", tiktok="tiktok_actors.rds", twitter="twitter_actors.rds")
plat_display <- c(web="Web", youtube="YouTube", facebook="Facebook",
                  instagram="Instagram", tiktok="TikTok", twitter="Twitter")
side <- read.csv("resources/dictionaries/source_labels.csv", fileEncoding = "UTF-8",
                 stringsAsFactors = FALSE, colClasses = "character", na.strings = "NA")
side[is.na(side)] <- ""; for (col in names(side)) side[[col]] <- trimws(side[[col]])
classify_typology <- function(df) {
  mi <- median(df$total_interactions, na.rm = TRUE); mr <- median(df$total_reach, na.rm = TRUE)
  ifelse(df$total_interactions >= mi & df$total_reach >= mr, "Divovi",
  ifelse(df$total_interactions >= mi & df$total_reach <  mr, "Graditelji zajednica",
  ifelse(df$total_interactions <  mi & df$total_reach >= mr, "Megafoni", "Specijalizirani akteri")))
}
actors <- lapply(names(platforms), function(pk) {
  df <- as.data.frame(readRDS(file.path("data/processed", platforms[[pk]])), stringsAsFactors = FALSE)
  df$FROM <- enc2utf8(as.character(df$FROM)); df$typology <- classify_typology(df); df$platform <- pk
  idx <- match(df$FROM, side$from)
  df$publish <- ifelse(is.na(idx), "no", side$publish[idx])
  df$entity  <- ifelse(is.na(idx), "",   side$entity[idx])
  df[df$publish == "yes", ]
}) %>% bind_rows()
actors$node_id <- paste0(actors$platform, "::", actors$FROM)

hub_nodes <- data.frame(node_id = paste0("HUB::", names(plat_display)), label = unname(plat_display),
  platform = names(plat_display), size = max(actors$total_posts, na.rm = TRUE) * 1.3, is_hub = TRUE,
  stringsAsFactors = FALSE)
actor_nodes <- data.frame(node_id = actors$node_id, label = actors$FROM, platform = actors$platform,
  size = actors$total_posts, is_hub = FALSE, stringsAsFactors = FALSE)
nodes <- bind_rows(hub_nodes, actor_nodes)
nodes$platform_disp <- unname(plat_display[nodes$platform])

edge_membership <- data.frame(from = actors$node_id, to = paste0("HUB::", actors$platform),
                              type = "mem", stringsAsFactors = FALSE)
bridge <- actors[actors$entity != "", c("node_id", "platform", "entity")]
bb <- merge(bridge, bridge, by = "entity")
bb <- bb[bb$node_id.x < bb$node_id.y & bb$platform.x != bb$platform.y, ]
edge_brand <- data.frame(from = bb$node_id.x, to = bb$node_id.y, type = "brand", stringsAsFactors = FALSE)
edges <- bind_rows(edge_membership, edge_brand)

plat_cols <- setNames(unname(dk_platform_colors[c("web","youtube","facebook","instagram","tiktok","twitter")]),
                      c("Web","YouTube","Facebook","Instagram","TikTok","Twitter"))
node_list <- lapply(seq_len(nrow(nodes)), function(i) {
  hub <- nodes$is_hub[i]
  list(id = nodes$node_id[i], label = enc2utf8(nodes$label[i]),
       color = unname(plat_cols[nodes$platform_disp[i]]), shape = "dot", value = nodes$size[i],
       borderWidth = if (hub) 4 else 1,
       font = list(size = if (hub) 34 else 15, color = dk_col$ink,
                   strokeWidth = if (hub) 5 else 3, strokeColor = "#F5F4F0",
                   face = "Georgia, 'Times New Roman', serif"))
})
edge_list <- lapply(seq_len(nrow(edges)), function(i) {
  brand <- edges$type[i] == "brand"
  list(from = edges$from[i], to = edges$to[i],
       color = if (brand) dk_col$accent_200 else dk_col$faint, width = if (brand) 3 else 1)
})
nodes_json <- toJSON(node_list, auto_unbox = TRUE)
edges_json <- toJSON(edge_list, auto_unbox = TRUE)

## ---- obtain vis.js assets straight from the installed visNetwork package --------------
vislib <- file.path(tempdir(), "digikat_vislib")
unlink(vislib, recursive = TRUE); dir.create(vislib, recursive = TRUE)
dummy <- visNetwork::visNetwork(data.frame(id = 1, label = "x"),
                                data.frame(from = integer(0), to = integer(0)))
visNetwork::visSave(dummy, file.path(vislib, "dummy.html"), selfcontained = FALSE)
vis_js  <- list.files(vislib, pattern = "vis-network\\.min\\.js$",  recursive = TRUE, full.names = TRUE)[1]
vis_css <- list.files(vislib, pattern = "vis-network\\.min\\.css$", recursive = TRUE, full.names = TRUE)[1]
if (is.na(vis_js) || is.na(vis_css)) stop("Could not locate vis.js assets from visNetwork.", call. = FALSE)
vis_js  <- paste(readLines(vis_js,  warn = FALSE, encoding = "UTF-8"), collapse = "\n")
vis_css <- paste(readLines(vis_css, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

## ---- assemble a frame-drivable capture page (window.ready / window.renderFrame) -------
html <- paste0(
'<!doctype html><html><head><meta charset="utf-8"><style>', vis_css,
'\nhtml,body{margin:0;padding:0}',
'#frame{width:', DIM, 'px;height:', DIM, 'px;background:#F5F4F0;position:relative;overflow:hidden;',
'font-family:Georgia,"Times New Roman",serif}',
'#title{position:absolute;top:26px;width:', DIM, 'px;text-align:center;font-size:34px;font-weight:600;color:#2b2b2b}',
'#sub{position:absolute;top:78px;width:', DIM, 'px;text-align:center;font-size:18px;color:#6b6b6b}',
'#net{position:absolute;top:120px;left:0;width:', DIM, 'px;height:900px}',
'#footer{position:absolute;bottom:24px;width:', DIM, 'px;text-align:center;font-size:14px;color:#9a9a9a}',
'</style><script>', vis_js, '</script></head><body>',
'<div id="frame">',
'<div id="title">Mreža izvora katoličke tematike</div>',
'<div id="sub">Hrvatski digitalni medijski prostor · 2021.–2026.</div>',
'<div id="net"></div>',
'<div id="footer">DigiKat · Hrvatsko katoličko sveučilište</div>',
'</div><script>',
'var nodes=new vis.DataSet(', nodes_json, ');',
'var edges=new vis.DataSet(', edges_json, ');',
'var options={nodes:{scaling:{min:8,max:44}},edges:{smooth:false},',
'physics:{solver:"barnesHut",barnesHut:{gravitationalConstant:-5500,centralGravity:0.45,',
'springLength:85,springConstant:0.03,damping:0.3},stabilization:{iterations:500}},',
'interaction:{dragNodes:false,dragView:false,zoomView:false},layout:{randomSeed:', SEED, '}};',
'var net=new vis.Network(document.getElementById("net"),{nodes:nodes,edges:edges},options);',
'window.net=net;window.ready=false;window.base={};window.phase={};',
'net.once("stabilized",function(){',
'  net.fit({animation:false});',
'  net.moveTo({scale:net.getScale()*0.9,animation:false});',
'  window.base=net.getPositions();',
'  net.setOptions({physics:false});',
'  var ids=Object.keys(window.base);',
'  for(var k=0;k<ids.length;k++){window.phase[ids[k]]={a:(k*0.7)%6.2832,b:(k*1.3)%6.2832,amp:', AMP_MIN, '+(k%4)*2};}',
'  window.ready=true;',
'});',
'window.renderFrame=function(i,N){',
'  var t=2*Math.PI*(i/N);var ids=Object.keys(window.base);',
'  for(var k=0;k<ids.length;k++){var id=ids[k];var p=window.base[id];var ph=window.phase[id];',
'    var n=net.body.nodes[id];if(n){n.x=p.x+ph.amp*Math.sin(t+ph.a);n.y=p.y+ph.amp*Math.cos(t+ph.b);}}',
'  net.redraw();return true;};',
'</script></body></html>')

cap_html <- file.path(tempdir(), "digikat_net_capture.html")
con <- file(cap_html, open = "wb"); writeBin(charToRaw(enc2utf8(html)), con); close(con)
cat(sprintf("graph: %d nodes, %d edges\n", nrow(nodes), nrow(edges)))

## ---- capture frames headlessly --------------------------------------------------------
frames_dir <- file.path(tempdir(), "digikat_net_frames")
unlink(frames_dir, recursive = TRUE); dir.create(frames_dir)
url <- paste0("file:///", normalizePath(cap_html, winslash = "/"))

b <- chromote::ChromoteSession$new()
on.exit(try(b$close(), silent = TRUE), add = TRUE)
b$Emulation$setDeviceMetricsOverride(width = DIM, height = DIM, deviceScaleFactor = SCALE, mobile = FALSE)
b$Page$navigate(url, wait_ = TRUE)
ok <- FALSE
for (i in 1:150) {
  v <- tryCatch(b$Runtime$evaluate("window.ready===true")$result$value, error = function(e) NA)
  if (isTRUE(v)) { ok <- TRUE; break }
  Sys.sleep(0.2)
}
if (!ok) stop("Graph never stabilized in the headless browser.", call. = FALSE)
t0 <- Sys.time()
for (i in 0:(N_FRAMES - 1)) {
  b$Runtime$evaluate(sprintf("window.renderFrame(%d,%d)", i, N_FRAMES))
  b$screenshot(sprintf(file.path(frames_dir, "frame_%04d.png"), i))
}
cat(sprintf("captured %d frames in %.0fs\n", N_FRAMES,
            as.numeric(difftime(Sys.time(), t0, units = "secs"))))

## ---- encode to MP4 (av bundles ffmpeg; yuv420p for universal playback) ----------------
dir.create(dirname(OUT), showWarnings = FALSE, recursive = TRUE)
frames <- sort(list.files(frames_dir, pattern = "^frame_.*\\.png$", full.names = TRUE))
av::av_encode_video(frames, output = OUT, framerate = FPS,
                    vfilter = sprintf("scale=%d:%d:flags=lanczos,format=yuv420p", DIM, DIM))
info <- av::av_video_info(OUT)
cat(sprintf("WROTE %s  |  %dx%d  %.1fs  %s  %.0f KB\n", OUT,
            info$video$width, info$video$height, info$duration, info$video$codec,
            file.info(OUT)$size / 1024))
