# Shared producers and validators for the three NLP-backed analytical pages.
#
# The expensive document- and token-level work runs here, upstream of Quarto.
# Pages read only the disclosure-safe objects returned by these functions.

digikat_theme_scores <- function(text, dictionaries) {
  text_lower <- tolower(text)
  total_words <- stringr::str_count(text_lower, "\\w+")
  if (total_words == 0L) return(NULL)
  scores <- purrr::map(dictionaries, ~ sum(stringr::str_count(text_lower, .x)))
  normalized_scores <- purrr::map(scores, ~ (.x / total_words) * 1000)
  names(normalized_scores) <- paste0("norm_", names(scores))
  scores_vec <- unlist(scores)
  dominant_topic <- if (all(scores_vec == 0)) "Nema Teme" else names(scores)[which.max(scores_vec)]
  c(as.list(scores), as.list(normalized_scores), dominant_topic = dominant_topic)
}

digikat_enrich_themes <- function(sample, dictionaries) {
  analysis <- purrr::map_dfr(
    sample$FULL_TEXT,
    ~ digikat_theme_scores(.x, dictionaries)
  )
  dplyr::bind_cols(sample, analysis)
}

digikat_load_atmosphere_lexicons <- function(root = ".") {
  negative_path <- file.path(root, "resources", "lexicons", "crosentilex-negatives.txt")
  positive_path <- file.path(root, "resources", "lexicons", "crosentilex-positives.txt")
  gold_path <- file.path(root, "resources", "lexicons", "gs-sentiment-annotations.txt")
  emotion_path <- file.path(root, "resources", "dictionaries", "lilaHR_clean.xlsx")

  crosentilex_full <- dplyr::bind_rows(
    utils::read.delim(
      negative_path,
      header = FALSE,
      sep = " ",
      stringsAsFactors = FALSE,
      fileEncoding = "UTF-8"
    ) |>
      dplyr::rename(word = "V1", sentiment_value = "V2") |>
      dplyr::mutate(sentiment_value = -sentiment_value),
    utils::read.delim(
      positive_path,
      header = FALSE,
      sep = " ",
      stringsAsFactors = FALSE,
      fileEncoding = "UTF-8"
    ) |>
      dplyr::rename(word = "V1", sentiment_value = "V2")
  ) |>
    tibble::as_tibble()

  gold <- utils::read.delim2(
    gold_path,
    header = FALSE,
    sep = " ",
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8"
  ) |>
    dplyr::rename(word = "V1", sentiment_str = "V2") |>
    dplyr::mutate(
      sentiment_value = dplyr::case_when(
        sentiment_str == "+" ~ 1,
        sentiment_str == "-" ~ -1,
        TRUE ~ 0
      )
    ) |>
    dplyr::select(word, sentiment_value) |>
    tibble::as_tibble()

  emotion_translator_hr <- c(
    "Anger" = "Ljutnja",
    "Anticipation" = "Iščekivanje",
    "Disgust" = "Gađenje",
    "Fear" = "Strah",
    "Joy" = "Radost",
    "Sadness" = "Tuga",
    "Surprise" = "Iznenađenje",
    "Trust" = "Povjerenje"
  )
  emotions <- readxl::read_excel(
    emotion_path,
    sheet = "Sheet1",
    .name_repair = "unique_quiet"
  ) |>
    dplyr::select(-"...1") |>
    dplyr::rename(word = HR) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(names(emotion_translator_hr)),
      names_to = "emotion",
      values_to = "value"
    ) |>
    dplyr::filter(value == 1) |>
    dplyr::mutate(emotion = dplyr::recode(emotion, !!!emotion_translator_hr)) |>
    dplyr::select(word, emotion)

  conflict <- unique(c(
    emotions |>
      dplyr::filter(emotion %in% c("Ljutnja", "Gađenje", "Strah")) |>
      dplyr::pull(word),
    crosentilex_full |>
      dplyr::filter(sentiment_value <= -0.75) |>
      dplyr::pull(word),
    c(
      "laž", "skandal", "napad", "radikalan", "ideologija", "licemjerje",
      "sramotno", "mržnja", "podjela", "raskol", "manipulacija", "propaganda",
      "ekstrem", "kontroverz", "sukob", "kriza"
    )
  ))

  list(full = crosentilex_full, gold = gold, emotions = emotions, conflict = conflict)
}

digikat_mapa_stop_words <- function() {
  standard <- c(
    "i", "u", "je", "na", "se", "su", "s", "za", "od", "o", "a", "te", "koji",
    "koja", "koje", "ga", "mu", "joj", "smo", "kao", "bez", "blizu", "do", "duž",
    "ispred", "iza", "između", "iznad", "izvan", "k", "kod", "kraj", "mimo", "nad",
    "nakon", "niže", "oko", "osim", "po", "pod", "pokraj", "poput", "pored",
    "poslije", "povrh", "preko", "prema", "pri", "prije", "protiv", "put", "radi",
    "sa", "skupa", "tijekom", "unatoč", "unutar", "usprkos", "uz", "van", "više",
    "zaradi", "zbog", "ali", "ama", "bilo", "da", "dakle", "dok", "eda", "ili",
    "inače", "jer", "kad", "kako", "li", "makar", "mada", "nego", "negoli", "no",
    "pa", "pak", "premda", "samo", "što", "ter", "već", "zatim", "zato", "ja",
    "ti", "on", "ona", "ono", "mi", "vi", "oni", "one", "sebe", "svoj", "moj",
    "tvoj", "njegov", "njezin", "naš", "vaš", "njihov", "ovaj", "ova", "ovo",
    "taj", "ta", "to", "onaj", "čiji", "čija", "čije", "kakav", "kakva", "kakvo",
    "kolik", "kolika", "koliko", "tko", "nitko", "ništa", "itko", "išta", "svatko",
    "svašta", "svakakav", "nikakav", "ikakav", "nekakav", "ne", "zar", "čak",
    "dapače", "evo", "eto", "eno", "gle", "god", "valjda", "vjerojatno", "zaista",
    "gdje", "kamo", "kuda", "otkud", "odakle", "dokle", "ovdje", "ondje", "onamo",
    "ovamo", "ovuda", "onuda", "tada", "sada", "onda", "nikada", "nekada",
    "ponekad", "često", "rijetko", "uvijek", "stalno", "povremeno", "danas",
    "sutra", "jučer", "preksutra", "prekjučer", "lani", "zimus", "ljetos",
    "proljetos", "jesenas", "tako", "nikako", "nekako", "ovako", "onako", "zašto",
    "stoga", "toliko", "ovoliko", "onoliko", "malo", "puno", "mnogo", "manje",
    "najviše", "najmanje", "brzo", "sporo", "dobro", "loše", "jako", "slabo",
    "vrlo", "prilično", "sasvim", "gotovo", "jedva", "biti", "jesam", "jesi",
    "jest", "jesmo", "jeste", "jesu", "bih", "bi", "bismo", "biste", "biše", "ću",
    "ćeš", "će", "ćemo", "ćete", "hoću", "hoćeš", "hoće", "hoćemo", "hoćete",
    "htjeti", "imam", "imaš", "ima", "imamo", "imate", "imaju", "imati", "nemam",
    "nemaš", "nema", "nemamo", "nemate", "nemaju", "nemati", "ići", "doći",
    "otići", "reći", "kazati", "govoriti", "pitati", "odgovoriti", "vidjeti",
    "gledati", "znati", "misliti", "moći", "morati", "trebati", "željeti", "dati",
    "uzeti", "napraviti", "raditi", "živjeti", "umrijeti", "roditi", "stajati",
    "sjediti", "ležati", "postati", "ostati", "nalaziti", "stvar", "dio", "godina",
    "dan", "vrijeme", "čovjek", "ljudi", "žena", "muškarac", "dijete", "život",
    "svijet", "zemlja", "grad", "kuća", "posao", "ruka", "noga", "oko", "glava",
    "srce", "broj", "primjer", "način", "pitanje", "odgovor", "početak", "kraj",
    "strana", "slučaj", "velik", "malen", "dobar", "loš", "nov", "star", "lijep",
    "ružan", "visok", "nizak", "mlad", "jak", "slab", "brz", "spor", "topao",
    "hladan", "pun", "prazan", "lak", "težak", "isti", "drugi", "različit",
    "jednostavan", "složen", "moguć", "nemoguć", "poznat", "nepoznat", "pravi",
    "krivi"
  )
  religious <- c(
    "bog", "isus", "gospodin", "moliti", "molitva", "amen", "krist", "biblija",
    "sveto pismo", "evanđelje", "crkva", "vjera", "vjernik", "grijeh", "pokajanje",
    "spasenje", "uskrsnuće", "krštenje", "euharistija", "sakrament", "apostol",
    "prorok", "svetac", "anđeo", "đavao", "sotona", "raj", "pakao", "čistilište",
    "milost", "blagoslov", "žrtva", "otkupljenje", "trojstvo", "duh sveti", "gospa",
    "djevica marija", "post", "hodočašće", "župa", "župnik", "biskup", "kardinal",
    "papa", "pastir", "stado", "jaganjac božji", "katolički", "rimokatolički",
    "sveta stolica", "vatikan", "krunica", "misa", "ispovijed", "pričest", "krizma",
    "blaženi", "sveti", "nadbiskup", "opat", "časna sestra", "fratar", "svećenik",
    "kapelan", "celibat", "enciklika", "koncil", "pravoslavni", "patrijarh",
    "episkop", "mitropolit", "ikona", "ikonostas", "liturgija", "pričešće", "krst",
    "slava", "parohija", "paroh", "manastir", "iguman", "monah", "pravoslavlje",
    "protestantski", "evangelički", "reformacija", "luteran", "kalvinist", "baptist",
    "pentekostalac", "adventist", "pastor", "prezbiter", "đakon", "propovijed",
    "slavljenje", "islam", "musliman", "kur'an", "muhamed", "alah", "džamija",
    "minaret", "imam", "hodža", "efendija", "ramazan", "bajram", "hadž", "meka",
    "medina", "šerijat", "suniti", "šijiti", "džihad", "halal", "haram", "salat",
    "zekat", "šehadet", "judaizam", "židov", "tora", "talmud", "sinagoga", "rabin",
    "košer", "šabat", "pasha", "jom kipur", "roš hašana", "hanuka", "menora",
    "jahve", "adonaj", "budizam", "buda", "dharma", "sangha", "karma", "nirvana",
    "reinkarnacija", "meditacija", "zen", "dalaj lama", "sutre", "mantra", "stupa",
    "bodisatva", "hinduizam", "hindus", "vede", "upanišade", "bhagavad gita",
    "brahma", "višnu", "šiva", "krišna", "rama", "šakti", "ganeša", "guru", "svami",
    "ašram", "joga", "mokša", "samsara", "pudža", "religija", "duhovnost",
    "božanstvo", "božica", "mitologija", "obred", "ritual", "hram", "svetište",
    "oltar", "proročanstvo", "otkrivenje", "sudnji dan", "eshatologija", "teologija",
    "filozofija", "etika", "moral", "duša", "duh", "zagrobni život", "vječnost",
    "stvaranje", "stvoritelj", "prosvjetljenje", "spoznaja", "transcendencija",
    "imanencija", "sveto", "profano", "hereza", "sekta", "kult"
  )
  unique(c(standard, religious, "godina", "moći"))
}

digikat_build_mapa_stats_summary <- function(sample, tokens, dictionaries) {
  tokens <- tokens |> dplyr::mutate(doc_id = as.integer(doc_id))
  enriched <- digikat_enrich_themes(sample, dictionaries)

  word_freq_for_cloud <- tokens |>
    dplyr::filter(upos %in% c("NOUN", "ADJ", "VERB")) |>
    dplyr::filter(!lemma %in% digikat_mapa_stop_words()) |>
    dplyr::count(lemma, sort = TRUE)

  topic_trends_guided <- enriched |>
    dplyr::select(year, DUHOVNOST_I_LITURGIJA:ODNOS_S_DRUGIM_RELIGIJAMA_I_POGLEDIMA) |>
    tidyr::pivot_longer(cols = -year, names_to = "topic", values_to = "count") |>
    dplyr::group_by(year, topic) |>
    dplyr::summarise(total_mentions = sum(count), .groups = "drop") |>
    dplyr::group_by(year) |>
    dplyr::mutate(share = total_mentions / sum(total_mentions)) |>
    dplyr::ungroup() |>
    dplyr::group_by(topic) |>
    dplyr::filter(any(share >= 0.05)) |>
    dplyr::ungroup()

  thematic_intensity_data <- enriched |>
    dplyr::select(dplyr::starts_with("norm_")) |>
    tidyr::pivot_longer(dplyr::everything(), names_to = "topic", values_to = "intensity") |>
    dplyr::mutate(topic = stringr::str_remove(topic, "norm_")) |>
    dplyr::filter(intensity > 0)

  engagement_by_topic <- enriched |>
    dplyr::filter(dominant_topic != "Nema Teme") |>
    dplyr::group_by(dominant_topic) |>
    dplyr::summarise(
      avg_interactions = mean(INTERACTIONS, na.rm = TRUE),
      total_articles = dplyr::n()
    ) |>
    dplyr::arrange(dplyr::desc(avg_interactions))

  polarization_by_topic <- enriched |>
    dplyr::filter(TOTAL_REACTIONS_COUNT > 10) |>
    dplyr::group_by(dominant_topic) |>
    dplyr::summarise(
      total_angry = sum(ANGRY_COUNT, na.rm = TRUE),
      total_love = sum(LOVE_COUNT, na.rm = TRUE),
      total_reactions = sum(TOTAL_REACTIONS_COUNT, na.rm = TRUE)
    ) |>
    dplyr::mutate(
      angry_ratio = total_angry / total_reactions,
      love_ratio = total_love / total_reactions
    ) |>
    dplyr::filter(total_reactions > 100)

  top_topics <- enriched |>
    dplyr::filter(dominant_topic != "Nema Teme") |>
    dplyr::count(dominant_topic, sort = TRUE) |>
    dplyr::slice_max(order_by = n, n = 5) |>
    dplyr::pull(dominant_topic)
  top_actors_in_top_topics <- tokens |>
    dplyr::filter(upos == "PROPN") |>
    dplyr::select(doc_id, lemma) |>
    dplyr::inner_join(
      enriched |> dplyr::select(doc_id, dominant_topic),
      by = "doc_id"
    ) |>
    dplyr::filter(dominant_topic %in% top_topics) |>
    dplyr::filter(!lemma %in% c(
      "hrvatska", "OŽALOŠCENI", "bog", "isus", "zagreb", "split", "nedjelja",
      "crkva", "dalmacija"
    )) |>
    dplyr::count(dominant_topic, lemma, sort = TRUE) |>
    dplyr::group_by(dominant_topic) |>
    dplyr::slice_max(order_by = n, n = 10) |>
    dplyr::ungroup()

  topic_pairs <- enriched |>
    dplyr::select(doc_id, dplyr::starts_with("norm_")) |>
    tidyr::pivot_longer(-doc_id, names_to = "topic", values_to = "intensity") |>
    dplyr::mutate(topic = stringr::str_remove(topic, "norm_")) |>
    dplyr::filter(intensity > 0) |>
    widyr::pairwise_cor(item = topic, feature = doc_id, upper = FALSE)

  list(
    word_freq_for_cloud = word_freq_for_cloud,
    topic_trends_guided = topic_trends_guided,
    thematic_intensity_data = thematic_intensity_data,
    engagement_by_topic = engagement_by_topic,
    polarization_by_topic = polarization_by_topic,
    top_actors_in_top_topics = top_actors_in_top_topics,
    topic_pairs = topic_pairs
  )
}

digikat_document_atmosphere <- function(sample, tokens, dictionaries, lexicons) {
  tokens <- tokens |> dplyr::mutate(doc_id = as.integer(doc_id))
  enriched <- digikat_enrich_themes(sample, dictionaries)
  frequencies <- tokens |> dplyr::count(doc_id, lemma, name = "word_frequency")

  sentiment_counts <- frequencies |>
    dplyr::inner_join(lexicons$gold, by = c("lemma" = "word")) |>
    dplyr::filter(sentiment_value != 0) |>
    dplyr::count(doc_id, sentiment_value) |>
    tidyr::pivot_wider(names_from = sentiment_value, values_from = n, values_fill = 0)
  if (!"1" %in% names(sentiment_counts)) sentiment_counts <- sentiment_counts |> dplyr::mutate(`1` = 0)
  if (!"-1" %in% names(sentiment_counts)) sentiment_counts <- sentiment_counts |> dplyr::mutate(`-1` = 0)
  sentiments <- sentiment_counts |>
    dplyr::rename(positive_words = `1`, negative_words = `-1`) |>
    dplyr::mutate(
      sentiment_score_gold =
        (positive_words - negative_words) / (positive_words + negative_words + 1e-6)
    ) |>
    dplyr::select(doc_id, sentiment_score_gold)

  emotions <- frequencies |>
    dplyr::inner_join(
      lexicons$emotions,
      by = c("lemma" = "word"),
      relationship = "many-to-many"
    ) |>
    dplyr::group_by(doc_id, emotion) |>
    dplyr::summarise(total_freq = sum(word_frequency), .groups = "drop") |>
    dplyr::group_by(doc_id) |>
    dplyr::slice_max(order_by = total_freq, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(doc_id, dominant_emotion = emotion)

  cli <- frequencies |>
    dplyr::mutate(is_conflict = lemma %in% lexicons$conflict) |>
    dplyr::group_by(doc_id) |>
    dplyr::summarise(
      total_words = sum(word_frequency),
      conflict_words = sum(word_frequency[is_conflict])
    ) |>
    dplyr::mutate(cli = (conflict_words / total_words) * 1000) |>
    dplyr::ungroup()

  final <- enriched |>
    dplyr::left_join(sentiments, by = "doc_id") |>
    dplyr::left_join(emotions, by = "doc_id") |>
    dplyr::left_join(cli |> dplyr::select(doc_id, cli), by = "doc_id") |>
    dplyr::mutate(
      sentiment_score = ifelse(is.na(sentiment_score_gold), 0, sentiment_score_gold),
      dominant_emotion = ifelse(is.na(dominant_emotion), "Neutralno", dominant_emotion),
      cli = ifelse(is.na(cli), 0, cli)
    )
  avg_cli_media <- final |> dplyr::group_by(FROM) |> dplyr::summarise(avg_cli_media = mean(cli))
  avg_cli_topic <- final |>
    dplyr::group_by(dominant_topic) |>
    dplyr::summarise(avg_cli_topic = mean(cli))
  final <- final |>
    dplyr::left_join(avg_cli_media, by = "FROM") |>
    dplyr::left_join(avg_cli_topic, by = "dominant_topic") |>
    dplyr::mutate(
      expected_cli = 0.5 * avg_cli_media + 0.5 * avg_cli_topic,
      rci = cli - expected_cli
    )

  list(
    tokens = tokens,
    enriched = enriched,
    frequencies = frequencies,
    sentiments = sentiments,
    emotions = emotions,
    cli = cli,
    final = final
  )
}

digikat_build_diskurs_summary <- function(sample, tokens, dictionaries, lexicons) {
  atmosphere <- digikat_document_atmosphere(sample, tokens, dictionaries, lexicons)

  heatmap_data <- atmosphere$enriched |>
    dplyr::left_join(atmosphere$sentiments, by = "doc_id") |>
    dplyr::left_join(atmosphere$emotions, by = "doc_id") |>
    dplyr::mutate(
      sentiment_score = ifelse(is.na(sentiment_score_gold), 0, sentiment_score_gold),
      dominant_emotion = ifelse(is.na(dominant_emotion), "Neutralno", dominant_emotion)
    ) |>
    dplyr::filter(dominant_topic != "Nema Teme") |>
    dplyr::group_by(dominant_topic, dominant_emotion) |>
    dplyr::summarise(
      avg_sentiment = mean(sentiment_score),
      n_articles = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(n_articles > 3)

  # Preserve the page's original RIK strategy calculation, which counts token
  # rows directly rather than using the pre-aggregated word-frequency table.
  strategy_cli <- atmosphere$tokens |>
    dplyr::mutate(is_conflict = lemma %in% lexicons$conflict) |>
    dplyr::group_by(doc_id) |>
    dplyr::summarise(cli = (sum(is_conflict) / dplyr::n()) * 1000) |>
    dplyr::ungroup()
  strategy <- atmosphere$enriched |>
    dplyr::left_join(strategy_cli, by = "doc_id") |>
    dplyr::mutate(cli = ifelse(is.na(cli), 0, cli))
  strategy_media <- strategy |>
    dplyr::group_by(FROM) |>
    dplyr::summarise(avg_cli_media = mean(cli))
  strategy_topic <- strategy |>
    dplyr::group_by(dominant_topic) |>
    dplyr::summarise(avg_cli_topic = mean(cli))
  strategy <- strategy |>
    dplyr::left_join(strategy_media, by = "FROM") |>
    dplyr::left_join(strategy_topic, by = "dominant_topic") |>
    dplyr::mutate(
      expected_cli = 0.5 * avg_cli_media + 0.5 * avg_cli_topic,
      rci = cli - expected_cli
    )
  media_strategy_data <- strategy |>
    dplyr::group_by(FROM) |>
    dplyr::summarise(
      avg_cli = mean(cli, na.rm = TRUE),
      rci_sd = stats::sd(rci, na.rm = TRUE),
      n_articles = dplyr::n()
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(n_articles > 20, !is.na(rci_sd), rci_sd > 0) |>
    dplyr::slice_max(order_by = n_articles, n = 30)

  # Preserve the network's original unnormalised CroSentilex-Gold score.
  network_sentiment <- atmosphere$frequencies |>
    dplyr::inner_join(lexicons$gold, by = c("lemma" = "word")) |>
    dplyr::mutate(
      sentiment_value = as.numeric(sentiment_value),
      word_frequency = as.numeric(word_frequency)
    ) |>
    dplyr::group_by(doc_id) |>
    dplyr::summarise(
      sentiment_score_gold = sum(sentiment_value * word_frequency, na.rm = TRUE)
    ) |>
    dplyr::ungroup()
  network_final <- atmosphere$enriched |>
    dplyr::left_join(network_sentiment, by = "doc_id") |>
    dplyr::left_join(atmosphere$cli |> dplyr::select(doc_id, cli), by = "doc_id") |>
    dplyr::mutate(
      sentiment_score_gold = ifelse(is.na(sentiment_score_gold), 0, sentiment_score_gold),
      cli = ifelse(is.na(cli), 0, cli)
    )
  network_media <- network_final |>
    dplyr::group_by(FROM) |>
    dplyr::summarise(avg_cli_media = mean(cli))
  network_topic <- network_final |>
    dplyr::group_by(dominant_topic) |>
    dplyr::summarise(avg_cli_topic = mean(cli))
  network_final <- network_final |>
    dplyr::left_join(network_media, by = "FROM") |>
    dplyr::left_join(network_topic, by = "dominant_topic") |>
    dplyr::mutate(
      expected_cli = 0.5 * avg_cli_media + 0.5 * avg_cli_topic,
      rci = cli - expected_cli
    )
  network_long <- network_final |>
    dplyr::select(doc_id, sentiment_score_gold, rci, dplyr::starts_with("norm_")) |>
    tidyr::pivot_longer(
      cols = dplyr::starts_with("norm_"),
      names_to = "topic",
      values_to = "intensity"
    ) |>
    dplyr::mutate(topic = stringr::str_remove(topic, "norm_")) |>
    dplyr::filter(intensity > 1.5)
  narrative_pair_data <- dplyr::inner_join(
    network_long,
    network_long,
    by = "doc_id",
    relationship = "many-to-many"
  ) |>
    dplyr::filter(topic.x < topic.y) |>
    dplyr::select(
      doc_id,
      item1 = topic.x,
      item2 = topic.y,
      sentiment_score = sentiment_score_gold.x,
      rci = rci.x
    )
  graph_data <- narrative_pair_data |>
    dplyr::group_by(item1, item2) |>
    dplyr::summarise(
      n = dplyr::n(),
      avg_sentiment = mean(sentiment_score, na.rm = TRUE),
      avg_rci = mean(rci, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::filter(n > 10)

  list(
    heatmap_data = heatmap_data,
    media_strategy_data = media_strategy_data,
    graph_data = graph_data
  )
}

digikat_build_dogadjaji_summary <- function(sample, tokens, dictionaries, lexicons) {
  atmosphere <- digikat_document_atmosphere(sample, tokens, dictionaries, lexicons)
  final <- atmosphere$final

  daily_summary <- final |>
    dplyr::mutate(
      date = as.Date(DATE),
      year = lubridate::year(date)
    ) |>
    dplyr::group_by(date, year) |>
    dplyr::summarise(
      n_articles = dplyr::n(),
      avg_cli = mean(cli, na.rm = TRUE),
      .groups = "drop"
    )
  spikes_detected_z <- daily_summary |>
    dplyr::group_by(year) |>
    dplyr::mutate(
      z_score_volume = (n_articles - mean(n_articles)) / stats::sd(n_articles),
      z_score_cli = (avg_cli - mean(avg_cli)) / stats::sd(avg_cli)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      is_volume_spike = z_score_volume > 3,
      is_cli_spike = z_score_cli > 3
    )
  volume_spike_dates <- spikes_detected_z |>
    dplyr::filter(is_volume_spike) |>
    dplyr::select(date, n_articles, z_score_volume) |>
    dplyr::arrange(dplyr::desc(z_score_volume))
  cli_spike_dates <- spikes_detected_z |>
    dplyr::filter(is_cli_spike) |>
    dplyr::select(date, avg_cli, z_score_cli) |>
    dplyr::arrange(dplyr::desc(z_score_cli))

  event_date <- as.Date("2022-04-17")
  daily_duhovnost_dynamics <- final |>
    dplyr::mutate(date = as.Date(DATE)) |>
    dplyr::group_by(date) |>
    dplyr::summarise(
      duhovnost_share = mean(dominant_topic == "DUHOVNOST_I_LITURGIJA", na.rm = TRUE),
      avg_cli = mean(cli[dominant_topic == "DUHOVNOST_I_LITURGIJA"], na.rm = TRUE),
      avg_sentiment = mean(
        sentiment_score[dominant_topic == "DUHOVNOST_I_LITURGIJA"],
        na.rm = TRUE
      )
    ) |>
    dplyr::filter(
      date >= event_date - lubridate::days(14),
      date <= event_date + lubridate::days(14)
    )

  docs_with_target <- atmosphere$tokens |>
    dplyr::filter(lemma == "stepinac") |>
    dplyr::distinct(doc_id) |>
    dplyr::pull(doc_id)
  associated <- atmosphere$tokens |>
    dplyr::filter(doc_id %in% docs_with_target) |>
    dplyr::filter(upos %in% c("NOUN", "ADJ")) |>
    dplyr::filter(lemma != "stepinac") |>
    dplyr::inner_join(
      final |> dplyr::select(doc_id, year, sentiment_score),
      by = "doc_id"
    ) |>
    dplyr::group_by(year, lemma) |>
    dplyr::summarise(
      total_cooccurrences = dplyr::n(),
      avg_sentiment = mean(sentiment_score, na.rm = TRUE),
      .groups = "drop"
    )
  available_years <- sort(unique(associated$year))
  top_associated_words_final <- associated |>
    dplyr::group_by(year) |>
    dplyr::arrange(dplyr::desc(total_cooccurrences)) |>
    dplyr::slice_head(n = 12) |>
    dplyr::ungroup() |>
    dplyr::mutate(year = factor(year, levels = as.character(available_years)))

  list(
    spikes_detected_z = spikes_detected_z,
    volume_spike_dates = volume_spike_dates,
    cli_spike_dates = cli_spike_dates,
    daily_duhovnost_dynamics = daily_duhovnost_dynamics,
    top_associated_words_final = top_associated_words_final
  )
}

digikat_page_summary_schema <- function() {
  list(
    mapa_stats = c(
      "word_freq_for_cloud", "topic_trends_guided", "thematic_intensity_data",
      "engagement_by_topic", "polarization_by_topic", "top_actors_in_top_topics",
      "topic_pairs"
    ),
    diskurs = c("heatmap_data", "media_strategy_data", "graph_data"),
    dogadjaji = c(
      "spikes_detected_z", "volume_spike_dates", "cli_spike_dates",
      "daily_duhovnost_dynamics", "top_associated_words_final"
    )
  )
}

digikat_validate_page_summary <- function(summary, page, allow_empty = FALSE) {
  expected <- digikat_page_summary_schema()[[page]]
  if (is.null(expected)) stop("Unknown page summary: ", page, call. = FALSE)
  if (!is.list(summary) || !identical(summary$schema_version, 1L) ||
      !identical(summary$page, page) || !is.list(summary$objects)) {
    stop("Invalid page-summary envelope for ", page, ".", call. = FALSE)
  }
  if (!identical(names(summary$objects), expected)) {
    stop("Unexpected page-summary objects for ", page, ".", call. = FALSE)
  }
  if (!isTRUE(allow_empty) && any(vapply(summary$objects, nrow, integer(1L)) == 0L)) {
    stop("Page summary contains an empty object: ", page, ".", call. = FALSE)
  }
  invisible(TRUE)
}

digikat_load_page_summary <- function(path, page, envir = parent.frame()) {
  summary <- readRDS(path)
  digikat_validate_page_summary(summary, page)
  list2env(summary$objects, envir = envir)
  invisible(summary)
}
