#!/usr/bin/env Rscript
# =============================================================================
# R/source_network.R  --  Shared builder for the "Mreža izvora" (source network)
# -----------------------------------------------------------------------------
# Single source of truth for the Katalog-izvora network graph. Reads the SAME
# tracked, PII-free aggregates + PI sidecar the wiki generator uses; node metrics
# and typology come from the data, never hand-typed. Used by BOTH
#   - pages/izvori/mreza.qmd  (standalone "Mreža izvora" page, height 760px), and
#   - index.qmd               (homepage two-column feature, height ~540px).
#
# Requires the caller to have already ATTACHED {dplyr, visNetwork} (library())
# and sourced R/theme_digikat.R (so dk_col and dk_platform_colors are in scope) —
# both pages/izvori/mreza.qmd and index.qmd do this in their libraries chunk.
#
#   build_source_network(proc_dir, sidecar) -> list(nodes, edges, n_actors)
#   source_network_widget(sn, height, background) -> a configured visNetwork
#
# Reads ONLY data/processed/*_actors.rds + resources/dictionaries/source_labels.csv
# (no master, no data/nlp). Writes nothing.
# =============================================================================

# Typology identical to pages/mapa/mapa.qmd + R/wiki_sources.R (per-platform median split).
.sn_classify_typology <- function(df) {
  mi <- median(df$total_interactions, na.rm = TRUE)
  mr <- median(df$total_reach, na.rm = TRUE)
  ifelse(df$total_interactions >= mi & df$total_reach >= mr, "Divovi",
  ifelse(df$total_interactions >= mi & df$total_reach <  mr, "Graditelji zajednica",
  ifelse(df$total_interactions <  mi & df$total_reach >= mr, "Megafoni", "Specijalizirani akteri")))
}

# Platform key -> Croatian display label (order = plotting/legend order).
.sn_platforms <- c(web = "web_actors.rds", youtube = "youtube_actors.rds",
                   facebook = "facebook_actors.rds", instagram = "instagram_actors.rds",
                   tiktok = "tiktok_actors.rds", twitter = "twitter_actors.rds")
.sn_plat_display <- c(web = "Web", youtube = "YouTube", facebook = "Facebook",
                      instagram = "Instagram", tiktok = "TikTok", twitter = "Twitter")

# -----------------------------------------------------------------------------
# build_source_network(): read aggregates + sidecar, return visNetwork-ready
# node/edge data frames. Paths are relative to the CALLING .qmd's directory.
# -----------------------------------------------------------------------------
build_source_network <- function(proc_dir = "data/processed",
                                 sidecar  = "resources/dictionaries/source_labels.csv") {
  side <- read.csv(sidecar, fileEncoding = "UTF-8", stringsAsFactors = FALSE,
                   colClasses = "character", na.strings = "NA")
  side[is.na(side)] <- ""
  for (col in names(side)) side[[col]] <- trimws(side[[col]])

  actors <- lapply(names(.sn_platforms), function(pk) {
    df <- as.data.frame(readRDS(file.path(proc_dir, .sn_platforms[[pk]])), stringsAsFactors = FALSE)
    df$FROM     <- enc2utf8(as.character(df$FROM))
    df$typology <- .sn_classify_typology(df)
    df$platform <- pk
    idx <- match(df$FROM, side$from)
    df$kind    <- ifelse(is.na(idx), "unclassified", side$kind[idx])
    df$publish <- ifelse(is.na(idx), "no",           side$publish[idx])
    df$entity  <- ifelse(is.na(idx), "",             side$entity[idx])
    # include institutions AND individuals with publish=yes; only publish=no (noise/held) excluded
    df[df$publish == "yes", ]
  })
  actors <- dplyr::bind_rows(actors)
  actors$node_id <- paste0(actors$platform, "::", actors$FROM)

  # ---- NODES: published actors + platform hubs (all rendered as circles) ----
  # Hubs sized 1.3x the largest actor so the six platform nodes stay the biggest
  # dots (their only visual distinction now that no node is a diamond).
  hub_nodes <- data.frame(
    node_id = paste0("HUB::", names(.sn_plat_display)), label = unname(.sn_plat_display),
    platform = names(.sn_plat_display), size = max(actors$total_posts, na.rm = TRUE) * 1.3,
    is_hub = TRUE, stringsAsFactors = FALSE
  )
  actor_nodes <- data.frame(
    node_id = actors$node_id, label = actors$FROM, platform = actors$platform,
    size = actors$total_posts, is_hub = FALSE, stringsAsFactors = FALSE
  )
  nodes <- dplyr::bind_rows(hub_nodes, actor_nodes)
  nodes$platform_disp <- unname(.sn_plat_display[nodes$platform])

  # ---- EDGES: the wiki's own links (structural only) ----
  edge_membership <- data.frame(from = actors$node_id, to = paste0("HUB::", actors$platform),
                                type = "Pripadnost platformi", stringsAsFactors = FALSE)
  bridge <- actors[actors$entity != "", c("node_id", "platform", "entity")]
  bb <- merge(bridge, bridge, by = "entity")
  bb <- bb[bb$node_id.x < bb$node_id.y & bb$platform.x != bb$platform.y, ]
  edge_brand <- data.frame(from = bb$node_id.x, to = bb$node_id.y,
                           type = "Isti brend", stringsAsFactors = FALSE)
  edges <- dplyr::bind_rows(edge_membership, edge_brand)

  # ---- visNetwork-ready node/edge frames ----
  plat_cols <- setNames(
    unname(dk_platform_colors[c("web","youtube","facebook","instagram","tiktok","twitter")]),
    c("Web","YouTube","Facebook","Instagram","TikTok","Twitter"))

  meta <- actors[, c("node_id", "typology", "total_posts", "total_interactions", "total_reach")]

  nd <- dplyr::left_join(nodes, meta, by = "node_id")
  vis_nodes <- data.frame(
    id          = nd$node_id,
    label       = nd$label,
    # ALL nodes are circles ("dot"); the six platform hubs stay distinct only by
    # being the largest dots (sized 1.3x the top actor) with a thicker border.
    shape       = "dot",
    color       = unname(plat_cols[nd$platform_disp]),
    value       = nd$size,
    borderWidth = ifelse(nd$is_hub, 4, 1),
    font.size   = ifelse(nd$is_hub, 22, 13),
    font.face   = "IBM Plex Mono",
    font.color  = dk_col$ink,
    title = ifelse(nd$is_hub,
      paste0("<b>", nd$label, "</b><br>Platforma"),
      paste0("<b>", nd$label, "</b> · ", nd$platform_disp, "<br>", nd$typology,
             "<br>Volumen: ",  formatC(nd$total_posts,        format = "d", big.mark = ".", decimal.mark = ","),
             "<br>Angažman: ", formatC(nd$total_interactions, format = "d", big.mark = ".", decimal.mark = ","),
             "<br>Doseg: ",    formatC(nd$total_reach,        format = "d", big.mark = ".", decimal.mark = ","))),
    stringsAsFactors = FALSE)

  vis_edges <- data.frame(
    from  = edges$from,
    to    = edges$to,
    color = ifelse(edges$type == "Isti brend", dk_col$accent_200, dk_col$faint),
    width = ifelse(edges$type == "Isti brend", 3, 1),
    stringsAsFactors = FALSE)

  list(nodes = vis_nodes, edges = vis_edges, n_actors = nrow(actors), plat_cols = plat_cols)
}

# -----------------------------------------------------------------------------
# source_network_widget(): configured visNetwork from build_source_network()'s
# output. Only `height` differs between the homepage and the standalone page.
# -----------------------------------------------------------------------------
# NB: bare visNetwork calls (not visNetwork::) — the caller attaches the package
# with library(visNetwork), matching pages/izvori/mreza.qmd's style.
source_network_widget <- function(sn, height = "760px", background = dk_col$paper) {
  visNetwork(sn$nodes, sn$edges, width = "100%", height = height, background = background) |>
    visNodes(scaling = list(min = 8, max = 42)) |>
    visEdges(smooth = FALSE) |>
    visLayout(randomSeed = 123) |>
    visPhysics(solver = "barnesHut",
      barnesHut = list(gravitationalConstant = -5500, centralGravity = 0.45,
                       springLength = 85, springConstant = 0.03, damping = 0.3),
      stabilization = list(iterations = 300)) |>
    visInteraction(dragNodes = TRUE, dragView = TRUE, zoomView = TRUE,
      hover = TRUE, tooltipDelay = 120, navigationButtons = FALSE) |>
    visOptions(highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE)) |>
    visLegend(useGroups = FALSE, position = "right",
      addNodes = data.frame(
        label = c("Web","YouTube","Facebook","Instagram","TikTok","Twitter"), shape = "dot",
        color = unname(sn$plat_cols[c("Web","YouTube","Facebook","Instagram","TikTok","Twitter")]),
        stringsAsFactors = FALSE))
}
