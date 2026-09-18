source("R/lib/barometar_disclosure.R",encoding="UTF-8")
stopifnot(length(barometar_public_inspect(list(outer=list(text="invented")))$issues)>0L,
  length(barometar_public_inspect(list(label_hr="https://example.invalid/article"))$issues)>0L,
  length(barometar_public_inspect(list(label_hr="C:/Users/example/private"))$issues)>0L,
  !length(barometar_public_inspect(list(label_hr="Izmišljeni primjer",total_articles=100))$issues))
invented <- "Ovo je potpuno izmišljena rečenica namijenjena provjeri javnoga sadržaja."
stopifnot(length(barometar_text_overlap(invented,paste("Uvod",invented,"Zaključak")))>0L,
  !length(barometar_text_overlap(invented,"Ovo je potpuno druga izmišljena rečenica.")))
cat("Barometer nested disclosure and eight-token overlap checks passed.\n")
