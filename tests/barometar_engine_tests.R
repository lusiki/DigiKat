source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/barometar_engine.R", encoding = "UTF-8")

run_barometar_engine_tests <- function() {
  definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
  segmenter <- definition$documents[["segmenter.yaml"]]
  stopifnot(nrow(barometar_sentences("Prijedlog je odbijen. – O tome se raspravlja.",segmenter))==2L,
    nrow(barometar_sentences("Prijedlog je odbijen. (O tome se raspravlja.)",segmenter))==2L,
    nrow(barometar_sentences("Razmatra se novi\nprijedlog zakona.",segmenter))==1L,
    nrow(barometar_sentences("Prva rečenica.\nDruga rečenica.",segmenter))==2L,
    nrow(barometar_sentences("Točka 1. – Uvodni dio.",segmenter))==1L)
  cases <- utils::read.csv("tests/fixtures/barometar_cases.csv",fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE,na.strings=character())
  filler <- paste(rep("Ovo je izmišljeni dodatak za provjeru duljine teksta.", 5L), collapse = " ")
  classify <- function(sentence, title = "Izmišljeni naslov") {
    barometar_classify(title, paste(sentence, filler), definition, day = "2025-06-01")
  }
  failures <- character()
  for (i in seq_len(nrow(cases))) {
    result <- classify(cases$sentence[i])
    expected <- cases$required[i]
    ok <- if (nzchar(expected)) expected %in% result$routes else !length(result$routes)
    if (!ok) failures <- c(failures, paste(i, "expected", expected, "got", paste(result$routes, collapse = ";")))
  }
  for (variant in c(stringi::stri_trans_toupper(cases$sentence[1L]),
    stringi::stri_replace_all_fixed(cases$sentence[1L], " ", "\u00a0"),
    stringi::stri_replace_all_fixed(cases$sentence[1L], "demokršćanska", "demo\u00adkršćanska"),
    stringi::stri_trans_nfd(cases$sentence[1L]),
    "Kršćansko-demokratski koncept.", "Kršćansko–demokratski koncept.", "Kršćansko demokratski koncept.")) {
    if (!"A1" %in% classify(variant)$routes) failures <- c(failures, "required normalization/compound did not match")
  }
  # A party-resolved instance cannot hide an unresolved instance elsewhere.
  mixed <- classify(paste(cases$sentence[3L], filler, cases$sentence[21L]))
  stopifnot("A?" %in% mixed$routes, !"A2" %in% mixed$routes)
  # No title/body stitching and no remote grounding.
  no_join <- classify("Vlada je predložila poreznu reformu.", "Socijalni nauk Crkve")
  stopifnot(!"B" %in% no_join$routes)
  remote <- classify(paste("Kršćanska etika zahtijeva promjenu.", filler, filler,
    "Solidarnost i ljudsko dostojanstvo važni su za poreznu reformu."))
  stopifnot(!"C" %in% remote$routes)
  # An excluded publication notice does not erase an unrelated qualifying argument.
  local <- classify(paste(cases$sentence[13L], filler, cases$sentence[4L]))
  stopifnot("B" %in% local$routes)
  negatives <- c(
    "Biskup je nazočio skupu; ministar ističe da supsidijarnost zahtijeva poreznu reformu.",
    "Kršćanska etika razmatra se na tribini. Ministar zahtijeva poreznu reformu zbog solidarnosti i ljudskog dostojanstva.",
    "Predavanje o socijalnom nauku Crkve završilo je, a ministar je otputovao.",
    "Kršćanska etika zahtijeva solidarnost i ljudsko dostojanstvo u reformi redovničkoga života.",
    "Socijalni nauk Crkve proučavat će se na duhovnoj obnovi za osobe s malom mirovinom.")
  for (sentence in negatives) if(length(classify(sentence)$routes)) failures <- c(failures,paste("relational false positive:",sentence))
  stopifnot(!"D" %in% classify("HDZ BiH poziva se na demokršćanska načela.")$routes)
  stopifnot("D" %in% classify("HDZ se poziva na demokršćanska načela.")$routes)
  stopifnot("D" %in% classify("Hrvatska demokratska zajednica poziva se na demokršćanska načela.")$routes)
  stopifnot("B" %in% classify("Objavljena analiza Rerum novarum zahtijeva da Vlada poveća minimalnu plaću.")$routes)
  stopifnot("C" %in% classify("Biskup ističe da opće dobro zahtijeva da Vlada uredi pomorsko dobro.")$routes)
  stopifnot("B" %in% classify("Socijalna doktrina Crkve zahtijeva izmjene zakona.")$routes)
  stopifnot("C" %in% classify("Biskup ističe da načelo supsidijarnog djelovanja zahtijeva poreznu reformu.")$routes)
  stopifnot(classify("Europska komisija poziva se na demokršćanska načela.")$reference_geography == "EU")
  stopifnot(classify("U Francuskoj demokršćanska načela nadahnjuju poreznu reformu.")$reference_geography == "inozemno")
  stopifnot(classify("Kršćanska etika zahtijeva da se opće dobro poštuje u poreznoj reformi. Biskup je nazočio skupu.")$speaker_type == "ostalo / nepripisano")
  stopifnot(identical(classify("Njemački demokršćani pobijedili su. Ideja je zatim oduševila slikara.")$routes,"A2"))
  stopifnot(!length(classify("Biskup je upozorio novinara koji ističe da supsidijarnost zahtijeva poreznu reformu.")$routes))
  stopifnot(!"D" %in% classify("HDZ kritizira analitičar koji se poziva na demokršćanska načela.")$routes)
  stopifnot(!length(classify("Ministar traži novi prijevod Rerum novarum.")$routes))
  stopifnot("B" %in% classify("Socijalni nauk Crkve temelj je porezne reforme.")$routes)
  stopifnot(!length(classify("Papa je istaknuo da Evangelii gaudium tumači Drugi vatikanski sabor.")$routes))
  stopifnot("B" %in% classify("Enciklika Fratelli tutti pozvala je na preispitivanje ekonomskih politika.")$routes)
  stopifnot(!length(classify("Socijalni nauk Crkve kaže da se Posljednji sud odnosi na svakog čovjeka.")$routes))
  stopifnot(!length(classify("Ministra Franjevačkoga svjetovnog reda kaže da socijalni nauk Crkve zahtijeva molitvu.")$routes))
  stopifnot(!length(classify("Centar za promicanje socijalnog nauka Crkve navodi da će ministar govoriti na otvaranju izložbe.")$routes))
  stopifnot(!length(classify("Ministar je rekao da je pročitao socijalni nauk Crkve.")$routes))
  stopifnot("B" %in% classify("Socijalni nauk Crkve treba ugraditi u program političke stranke.")$routes)
  stopifnot("B" %in% classify("U skladu sa socijalnim naukom Crkve poslodavac treba isplatiti pravednu plaću.")$routes)
  batch_rows <- data.frame(TITLE=rep("Izmišljeni naslov",3L),FULL_TEXT=paste(cases$sentence[c(1,4,8)],filler),
    day="2025-06-01",outlet_id="synthetic",stringsAsFactors=FALSE)
  empty_boilerplate <- data.frame(outlet_id=character(),month=character(),segment_key=character())
  batched <- barometar_classify_batch(batch_rows,definition,empty_boilerplate)
  singles <- lapply(seq_len(nrow(batch_rows)),function(i)barometar_classify(batch_rows$TITLE[i],batch_rows$FULL_TEXT[i],definition,batch_rows$day[i]))
  stopifnot(identical(batched,singles))
  stopifnot(identical(barometar_classify_batch(batch_rows[1L,,drop=FALSE],definition,empty_boilerplate),singles[1L]))
  if (length(failures)) stop(paste(failures, collapse = "\n"), call. = FALSE)
  cat("Barometer route engine: ", nrow(cases), " cases plus Unicode/window/precedence checks passed.\n", sep = "")
  invisible(definition)
}

run_barometar_engine_tests()
