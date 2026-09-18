# Rebuild the PROPOSED registry from metadata only. No corpus passages or topic queries.
source("studies/demokrscanstvo-barometar/lib/io.R", encoding = "UTF-8")

barometar_build_outlet_registry <- function(workdir = NULL) {
  workdir <- barometar_workdir(workdir)
  config <- "studies/demokrscanstvo-barometar/config"
  read_chars <- function(path) read.csv(path, fileEncoding = "UTF-8-BOM", check.names = FALSE,
    colClasses = "character", na.strings = character(), strip.white = FALSE)
  inventory <- read_chars(file.path(workdir, "outlet_continuity_inventory.csv"))
  hosts <- read_chars(file.path(workdir, "outlet_host_inventory.csv"))
  secular_path <- "explorations/okvir-katolicanstva-prototype/secular_outlets.csv"
  confessional_path <- "resources/dictionaries/source_labels.csv"
  products_path <- "studies/news-gap/source_registry.csv"
  secular <- read_chars(secular_path)
  confessional <- read_chars(confessional_path)
  products <- read_chars(products_path)
  reviews <- read_chars(file.path(config, "outlet_registry_review.csv"))
  domain <- function(x) stringi::stri_detect_regex(x, "^[a-z0-9][a-z0-9.-]+\\.[a-z]{2,}$")
  secular <- secular[domain(secular$from), ]
  confessional <- confessional[confessional$label == "confessional" & domain(confessional$from), ]
  review_from <- inventory$from_value[inventory$raw_continuity_1 == "TRUE"]
  explicit <- list(
    non_news = c("bongacams.com", "namjestaj.hr", "uzishop.hr", "eljekarna24.hr",
      "superknjizara.hr", "svijetkladjenja.com", "google.com", "mirovina.hr", "inmemoriam.hr",
      "game-game.com.hr", "igre123.net", "lyricstranslate.com", "tekstovi.net"),
    institutional = c("gov.hr", "morh.hr", "unizg.hr", "hajduk.hr", "nk-rijeka.hr",
      "biskupija-varazdinska.hr", "djos.hr"),
    aggregator = c("novine.hr", "infokiosk.net", "news.leportale.com", "dailyadvent.com",
      "crovijesti.com", "stripovi.com", "tvprofil.com"))
  explicit$non_news <- unique(c(explicit$non_news, review_from[startsWith(review_from, "antikvarijat")]))
  all_from <- sort(unique(c(review_from, secular$from, confessional$from, products$raw_from,
    reviews$from_value, unlist(explicit))))
  registry <- data.frame(outlet_id = stringi::stri_replace_all_regex(all_from, "[^a-z0-9]+", "_"),
    from_values = all_from, url_hosts = all_from, display_name = all_from, segment = "",
    editorial = "NA", croatia_link = "NA", evidence_note = "needs_review: publisher identity and editorial/Croatia status not established; excluded from proposed eligibility.",
    seed_source = "raw_continuity_review", panel_v1 = "FALSE", status = "proposed",
    proposed_eligible = "FALSE", stringsAsFactors = FALSE)
  # Seeds are evidence for a proposal, never a ratified label. Social aliases are not imported.
  for (i in seq_len(nrow(secular))) {
    j <- match(secular$from[i], registry$from_values)
    registry$display_name[j] <- secular$brand[i]
    registry$seed_source[j] <- secular_path
    type <- secular$type[i]
    if (type %in% c("national", "regional", "public_service", "exclude_political", "tabloid_lifestyle")) {
      registry$segment[j] <- switch(type, exclude_political = "political_portal", tabloid_lifestyle = "national", type)
      registry$editorial[j] <- "TRUE"
      registry$croatia_link[j] <- if (secular$from[i] == "n1info.com") "NA" else "TRUE"
      registry$evidence_note[j] <- paste0("Proposed seed classification: ", secular$note[i],
        if (type == "exclude_political") "; D2 reverses the sandbox exclusion and admits this segment subject to continuity." else "; PI G1 ratification required.")
      if (secular$from[i] == "n1info.com") registry$evidence_note[j] <- "needs_review: cross-country N1 host; Croatia-specific host/product mapping is unresolved."
    }
  }
  for (i in seq_len(nrow(confessional))) {
    j <- match(confessional$from[i], registry$from_values)
    registry$seed_source[j] <- confessional_path
    registry$evidence_note[j] <- paste0("needs_review: confessional seed label alone does not establish a news publisher; ", confessional$description[i])
  }
  for (i in seq_len(nrow(products))) {
    j <- match(products$raw_from[i], registry$from_values)
    registry$seed_source[j] <- paste(unique(c(strsplit(registry$seed_source[j], ";", fixed = TRUE)[[1]], products_path)), collapse = ";")
  }
  for (segment in names(explicit)) {
    j <- match(explicit[[segment]], registry$from_values)
    registry$segment[j] <- segment
    registry$editorial[j] <- "FALSE"
    registry$evidence_note[j] <- paste0("Excluded by BRIEF 4.2 ", segment, " rule; this is a scope exclusion, not an assessment of quality. PI G1 ratification required.")
    registry$seed_source[j] <- "BRIEF.md#4.2"
  }
  for (i in seq_len(nrow(reviews))) {
    j <- match(reviews$from_value[i], registry$from_values)
    for (field in c("display_name", "segment", "editorial", "croatia_link")) registry[[field]][j] <- reviews[[field]][i]
    registry$evidence_note[j] <- paste(reviews$evidence_note[i], reviews$evidence_url[i])
    registry$seed_source[j] <- paste0(registry$seed_source[j], ";outlet_registry_review.csv")
  }
  # Only hosts actually observed under that FROM, and its own domain/subdomains, are aliases.
  # Foreign/malformed/redirect hosts remain outside the override map; never map all co-occurring hosts.
  hosts$url_host <- stringi::stri_replace_first_regex(tolower(hosts$url_host), "^www\\.", "")
  for (i in seq_len(nrow(registry))) {
    from <- registry$from_values[i]
    candidates <- hosts$url_host[hosts$from_value == from]
    candidates <- candidates[candidates == from | endsWith(candidates, paste0(".", from))]
    registry$url_hosts[i] <- paste(sort(unique(c(from, candidates[nzchar(candidates)]))), collapse = ";")
  }
  # Existing product registry documents these grouped products even if a snapshot omits a host.
  hkm <- match("hkm.hr", registry$from_values)
  registry$outlet_id[hkm] <- "hkm"
  registry$url_hosts[hkm] <- paste(sort(unique(c(strsplit(registry$url_hosts[hkm], ";", fixed = TRUE)[[1]],
    "hkm.hr", "ika.hkm.hr", "hkr.hkm.hr"))), collapse = ";")
  # Exact lower(FROM) alias reported by the denominator audit; preserve its trailing space explicitly.
  zupcica <- match("zupcica.hr", registry$from_values)
  registry$from_values[zupcica] <- "zupcica.hr;zupcica.hr "
  registry$evidence_note[zupcica] <- paste0(registry$evidence_note[zupcica], " Explicit trailing-space FROM alias; no global whitespace trim.")
  allowed <- c("national", "regional", "public_service", "confessional", "political_portal")
  registry$proposed_eligible <- ifelse(registry$editorial == "TRUE" & registry$croatia_link == "TRUE" &
    registry$segment %in% allowed, "TRUE", "FALSE")
  stopifnot(!anyDuplicated(registry$outlet_id), all(registry$status == "proposed"), all(registry$panel_v1 == "FALSE"))
  aliases <- unlist(strsplit(registry$from_values, ";", fixed = TRUE))
  url_hosts <- unlist(strsplit(registry$url_hosts, ";", fixed = TRUE))
  stopifnot(!anyDuplicated(aliases), !anyDuplicated(url_hosts), all(review_from %in% aliases))
  barometar_write_csv(registry, file.path(config, "outlet_registry.csv"))
  message("Proposed registry: ", nrow(registry), " outlets; ", length(review_from),
    " continuity review FROM values; ", sum(registry$proposed_eligible == "TRUE"), " editorial-scope candidates. No panel frozen.")
  invisible(registry)
}

if (barometar_script_main("build_outlet_registry.R")) invisible(barometar_build_outlet_registry())
