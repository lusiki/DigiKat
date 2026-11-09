# All plotted quantities come from the frozen private report_data.json. No
# numeric coordinates for cells below the publication threshold are plotted.
source("studies/catholic-voices-network/00_common.R", encoding = "UTF-8")
knitr::opts_chunk$set(dev = "svg")
source("R/theme_digikat.R", encoding = "UTF-8")
input_path <- file.path(workdir, "report_data.json")
data <- jsonlite::fromJSON(input_path, simplifyVector = FALSE)
stopifnot(data$corpus_sha256 == manifest$corpus$sha256, data$config_hash == config_hash,
          data$evidence$publication_audit$level_a_identity_gate == "passed")
report_dir <- Sys.getenv("DIGIKAT_VOICES_REPORT_DIR", unset = file.path(study, "output/private/report"))
figure_dir <- file.path(report_dir, "figures"); dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
frame <- function(x) {
  if (!length(x)) return(data.frame())
  jsonlite::fromJSON(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))
}
values <- data$values; figures <- list()
hr <- scales::label_number(big.mark = "\u00a0", decimal.mark = ",")
percent <- scales::label_percent(big.mark = "\u00a0", decimal.mark = ",", accuracy = 0.1)
safe <- function(x, field) x[!is.na(x[[field]]) & x[[field]] >= 5, , drop = FALSE]
era_labels <- c(pre2024 = "Ranije razdoblje prikupljanja", post2024 = "Kasnije razdoblje prikupljanja")
empty <- function() ggplot() + annotate("text", x = 0, y = 0,
  label = "Nema podataka koji zadovoljavaju uvjete prikaza.", family = dk_sans, size = 4) + theme_digikat_void()
register <- function(key, plot, title, note, alt, pointers, height = 5.5) {
  path <- file.path(figure_dir, paste0(key, ".svg"))
  ggsave(path, plot, width = 9, height = height, units = "in", device = svglite::svglite,
    bg = dk_col$paper, limitsize = TRUE)
  figures[[key]] <<- list(path = paste0("figures/", key, ".svg"), sha256 = digest::digest(file = path, algo = "sha256"),
    title = title, source_note = note, alt = alt, data_pointers = pointers)
}

x <- safe(frame(values$platforms), "documents")
p <- if (nrow(x)) ggplot(x, aes(documents, reorder(platform, documents), fill = platform)) +
  geom_col(show.legend = FALSE) + scale_fill_manual(values = dk_platform_colors) +
  scale_x_continuous(labels = hr) + labs(x = "Objave u korpusu", y = NULL) else empty()
register("platforms", p, "Sastav korpusa po platformama",
  "Izvor: službeni korpus. Prikaz obuhvaća sve duljine tekstova. Razlike u zastupljenosti odražavaju prikupljanje podataka, a ne veličinu publike.",
  "Broj prikupljenih objava po platformi.", list("/values/platforms"))

people <- frame(values$people); people <- people[order(-people$documents, people$entity_id), , drop = FALSE]
x <- head(people, 20)
p <- empty()
if (nrow(x)) {
  x$public_name <- factor(x$public_name, levels = rev(x$public_name))
  p <- ggplot(x, aes(documents, public_name)) + geom_point(size = 2.3, color = dk_col$accent) +
    scale_x_continuous(labels = hr) + labs(x = "Objave sa spomenom osobe", y = NULL)
  if (isTRUE(data$display_policy$range_counts)) {
    ranges <- x[x$minimum_documents >= 5, , drop = FALSE]
    p <- p + geom_segment(data = ranges, aes(x = minimum_documents, xend = maximum_documents, yend = public_name), color = dk_col$accent)
  }
}
register("people", p, "Najčešće spominjane javne osobe",
  "Izvor: automatsko prepoznavanje imena i javno povezani identiteti koji zadovoljavaju uvjete objave. Točka označava osnovni broj; eventualni raspon označava osjetljivost na grupiranje imena, ne interval pouzdanosti. Mali rubni brojevi nisu prikazani.",
  "Vodeće osobe prema broju objava koje ih spominju.", list("/values/people", "/display_policy/range_counts"), 7)

x <- safe(frame(values$identity_classes), "spans")
classes <- c(contemporary = "suvremene", historical = "povijesne", sacred = "svete",
  unresolved = "nerazriješene", date_uncertain = "nesiguran datum")
if (nrow(x)) x$life_class <- unname(classes[x$life_class])
p <- if (nrow(x)) ggplot(x, aes(spans, platform, fill = life_class)) + geom_col(position = "dodge") +
  scale_x_continuous(labels = hr) + labs(x = "Prepoznati rasponi imena", y = NULL, fill = "Strojni razred") else empty()
register("identity_classes", p, "Razredi razriješenih i nerazriješenih imena",
  "Izvor: datirano razrješavanje identiteta. Jedna objava može sadržavati više spomena. Izostavljene male ćelije ne znače da pojava nema. Povijesne i svete osobe ne ulaze u mrežu suvremenih osoba.",
  "Broj spomena po platformi i razredu identiteta.", list("/values/identity_classes"), 6)

x <- safe(frame(values$source_distribution), "documents"); x <- head(x, 20)
p <- empty()
if (nrow(x)) {
  x$display_name <- paste(x$public_label, x$platform, sep = " · ")
  p <- ggplot(x, aes(documents, reorder(display_name, documents))) + geom_col(fill = dk_col$accent) +
    scale_x_continuous(labels = hr) + labs(x = "Objave s barem jednom javnom osobom", y = NULL)
}
register("sources", p, "Izvori u kojima se pojavljuju javne osobe",
  "Izvor: korpus i pravila objave izvora. Za neobjavljive račune prikazan je zbroj unutar platforme. U izračunu mreže ti su računi ostali odvojeni izvori.",
  "Izvori i skupine neobjavljivih računa prema broju objava s javnim osobama.", list("/values/source_distribution"), 7)

x <- safe(frame(values$person_platform_eras), "documents")
if (nrow(x)) {
  x <- x[x$entity_id %in% head(people$entity_id, 12), , drop = FALSE]
  denominator <- frame(values$platform_eras)
  x <- merge(x, denominator[c("platform", "era", "documents")], by = c("platform", "era"), suffixes = c("", "_all"))
  x$share <- x$documents/x$documents_all
  x$public_name <- people$public_name[match(x$entity_id, people$entity_id)]
  x$era <- factor(x$era, levels = names(era_labels))
}
p <- if (nrow(x)) ggplot(x, aes(platform, public_name, fill = share)) + geom_tile() +
  facet_wrap(~era, labeller = labeller(era = era_labels)) + scale_fill_gradient(low = dk_col$accent_050, high = dk_col$accent, labels = percent) +
  labs(x = NULL, y = NULL, fill = "Udio objava") + theme(axis.text.x = element_text(angle = 45, hjust = 1)) else empty()
register("platform_presence", p, "Zastupljenost vodećih osoba unutar platforme i razdoblja",
  "Izvor: imenitelji svih objava po platformi i razdoblju. Boja prikazuje udio objava sa spomenom osobe. Prazne ćelije uključuju izostavljene male brojeve; nisu dokazana odsutnost. Razdoblja se ne uspoređuju sirovim volumenom.",
  "Udio objava s vodećim osobama po platformama, odvojeno prema razdoblju prikupljanja.", list("/values/person_platform_eras", "/values/platform_eras", "/values/people"), 7)

x <- safe(frame(values$circulation_sizes), "families")
if (nrow(x)) x$size_group <- factor(x$size_group, levels = c("1", "2–4", "5–9", "10–49", "50+"))
p <- if (nrow(x)) ggplot(x, aes(size_group, families)) + geom_col(fill = dk_col$accent) +
  scale_y_continuous(labels = hr) + labs(x = "Broj objava u obitelji tekstova", y = "Obitelji") else empty()
register("circulation", p, "Veličina obitelji tekstova",
  "Izvor: MinHash kandidati, potvrđene sličnosti i povezane komponente. Obitelj može sadržavati lanac sličnih tekstova; najranija zabilježena objava nije dokaz izvornog autorstva.",
  "Broj obitelji prema broju zabilježenih objava.", list("/values/circulation_sizes"))

x <- frame(data$evidence$network_metrics$temporal)
if (nrow(x)) {
  x <- safe(x, "documents"); x <- x[x$entity_id %in% head(people$entity_id, 6), , drop = FALSE]
  denominators <- frame(values$quarter_denominators)
  denominators <- aggregate(documents ~ era + quarter, denominators, sum)
  x <- merge(x, denominators, by = c("era", "quarter"), suffixes = c("", "_all"))
  x$share <- x$documents/x$documents_all
  x$public_name <- people$public_name[match(x$entity_id, people$entity_id)]
  x$era <- factor(x$era, levels = names(era_labels))
}
p <- if (nrow(x)) ggplot(x, aes(quarter, share, color = public_name, shape = public_name)) + geom_point(size = 2) +
  facet_wrap(~era, scales = "free_x", labeller = labeller(era = era_labels)) + scale_y_continuous(labels = percent) +
  labs(x = NULL, y = "Udio svih objava u tromjesečju", color = "Osoba", shape = "Osoba") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1), legend.position = "bottom") else empty()
register("temporal", p, "Tromjesečna prisutnost vodećih osoba",
  "Izvor: udio svih korpusnih objava unutar tromjesečja, uz odvojena razdoblja prikupljanja. Točke s malim brojevima nisu prikazane. Promjena udjela sama ne utvrđuje uzrok ili učinak događaja.",
  "Tromjesečni udjeli objava s vodećim javnim osobama.", list("/evidence/network_metrics/temporal", "/values/quarter_denominators", "/values/people"), 6)

for (kind in c("outlets", "paragraphs")) {
  network <- data$evidence$network_metrics$networks[[kind]]
  nodes <- frame(network$nodes); edges <- frame(network$edges)
  nodes <- nodes[nodes$entity_id %in% head(people$entity_id, 50), , drop = FALSE]
  p <- empty()
  if (nrow(nodes)) {
    if (nrow(edges)) edges <- edges[edges$display & edges$from %in% nodes$entity_id & edges$to %in% nodes$entity_id, c("from", "to"), drop = FALSE]
    else edges <- data.frame(from = character(), to = character())
    graph <- igraph::graph_from_data_frame(edges, directed = FALSE, vertices = nodes)
    set.seed(config$seed)
    layout <- if (igraph::ecount(graph)) igraph::layout_with_fr(graph) else igraph::layout_in_circle(graph)
    nodes$x <- layout[, 1]; nodes$y <- layout[, 2]
    nodes$label <- ifelse(nodes$entity_id %in% head(people$entity_id, 12), people$public_name[match(nodes$entity_id, people$entity_id)], "")
    p <- ggplot(nodes, aes(x, y)) + theme_digikat_void() +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
    if (nrow(edges)) {
      edges$x <- nodes$x[match(edges$from, nodes$entity_id)]; edges$y <- nodes$y[match(edges$from, nodes$entity_id)]
      edges$xend <- nodes$x[match(edges$to, nodes$entity_id)]; edges$yend <- nodes$y[match(edges$to, nodes$entity_id)]
      p <- p + geom_segment(data = edges, aes(xend = xend, yend = yend), color = dk_col$line, alpha = .4, linewidth = .3)
    }
    p <- p + geom_point(aes(color = factor(community)), size = 2.6, show.legend = FALSE) +
      ggrepel::geom_text_repel(aes(label = label), seed = config$seed, size = 3, family = dk_sans, max.overlaps = Inf) +
      scale_color_manual(values = rep(dk_palette, length.out = length(unique(nodes$community))))
  }
  title <- if (kind == "outlets") "Zajednički izvori javnih osoba" else "Zajedničko pojavljivanje u odlomcima"
  register(paste0("network_", kind), p, title,
    "Izvor: statistički filtrirana mreža spominjanja. Prikazan je podgraf vodećih osoba; male veze izostavljene su iz prikaza. Boje zajednica potječu iz pune mreže. Blizina označava zajedničko pojavljivanje, ne slaganje, suradnju ili utjecaj.",
    "Mrežni prikaz javnih osoba i dopuštenih veza zajedničkog pojavljivanja.",
    list(paste0("/evidence/network_metrics/networks/", kind), "/values/people"), 7)
}

x <- frame(lapply(data$evidence$model_gate_summary$configurations, function(r) list(
  configuration = paste(r$protocol, r$model), passed = r$passed)))
p <- ggplot(x, aes(passed, reorder(configuration, passed))) + geom_point(color = dk_col$accent, size = 3) +
  geom_vline(xintercept = data$constants$synthetic_required, linetype = "dashed", color = dk_col$alert) +
  scale_x_continuous(limits = c(0, data$constants$synthetic_cases)) + labs(x = "Prolazni konstruirani slučajevi", y = NULL)
register("model_checks", p, "Rezultati konstruiranih provjera kodera",
  "Izvor: spremljeni odgovori i nepromijenjena očekivanja konstruiranih slučajeva. Isprekidana crta označava unaprijed zadan prag. Ovo nije procjena točnosti na stvarnim objavama.",
  "Rezultati ispitanih konfiguracija i prag za nastavak glavnog kodiranja.", list("/evidence/model_gate_summary/configurations", "/constants/synthetic_required", "/constants/synthetic_cases"))

output <- list(corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash,
  report_data_sha256 = digest::digest(file = input_path, algo = "sha256"),
  code_sha256 = digest::digest(file = file.path(study, "81_report_figures.R"), algo = "sha256"), figures = figures)
jsonlite::write_json(output, file.path(report_dir, "figures_manifest.json.tmp"), auto_unbox = TRUE, pretty = TRUE)
target <- file.path(report_dir, "figures_manifest.json")
python <- file.path(Sys.getenv("USERPROFILE"), "venvs/digikat-nlp/Scripts/python.exe")
status <- system2(python, c("-c", shQuote("import os,sys; os.replace(sys.argv[1],sys.argv[2])"),
  shQuote(paste0(target, ".tmp")), shQuote(target)))
stopifnot(status == 0L)
cat(length(figures), "figures prepared; visual review and final registry checks remain required.\n")
