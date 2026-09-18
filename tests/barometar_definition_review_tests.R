# Independent pre-G2 review: invented sentences and definition metadata only.
# No corpus input, empirical indicators, engine edits, or human-evaluation claims.
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/barometar_engine.R", encoding = "UTF-8")

run_barometar_definition_review_tests <- function() {
  definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
  results <- list()
  record <- function(id, ok, detail = "") {
    results[[length(results) + 1L]] <<- data.frame(id=id, pass=isTRUE(ok), detail=detail)
    invisible(ok)
  }
  filler <- paste(rep("Ovo je izmišljeni dodatak za provjeru duljine teksta.", 5L), collapse=" ")
  classify <- function(sentence, day="2025-06-01")
    barometar_classify("Izmišljeni naslov", paste(sentence, filler), definition, day=day)
  routes <- function(id, sentence, required=character(), forbidden=character(), day="2025-06-01") {
    result <- classify(sentence, day)
    record(id, all(required %in% result$routes) && !any(forbidden %in% result$routes),
      paste("required", paste(required,collapse=";"), "forbidden", paste(forbidden,collapse=";"),
        "actual", paste(result$routes,collapse=";")))
    invisible(result)
  }
  hit <- function(id, text, entry, expected=TRUE, day="2025-06-01") {
    h <- barometar_field_evidence(text, definition, "body", day=day)$hits
    actual <- any(h$entry_id==entry & is.na(h$excluded_reason))
    record(id, identical(actual,expected), paste(entry,"expected",expected,"actual",actual))
  }

  routes("idea_instrumental_plural", "Stranka se vodi demokršćanskim načelima.", "A1", "A2")
  routes("idea_adjective", "Demokršćanska svjetonazorska orijentacija oblikuje raspravu.", "A1")
  routes("teaching_plural", "U skladu s katoličkim socijalnim učenjima Vlada predlaže poreznu reformu.", "B")
  routes("church_genitive_plural", "Socijalna učenja Crkava zahtijevaju poreznu reformu.", "B")
  hit("pobacajem", "pobačajem", "family_life_policy")
  hit("odgojem", "odgojem", "theme_family")
  hit("europom", "Europom", "theme_europe")
  hit("analiticarem", "analitičarem", "other_speaker_reviewed_forms")
  for (role in c("ministrica", "premijerka", "zastupnica", "gradonačelnica", "kancelarka")) {
    routes(paste0("female_party_",role), paste("Demokršćanska",role,"održala je sastanak."), "A2", "A1")
    routes(paste0("female_incidental_",role),
      paste(role,"je rekla da je pročitala socijalni nauk Crkve."), forbidden=c("B","C"))
  }
  for (role in c("ministra", "ministricu", "premijerku", "zastupnicu", "gradonačelnicu", "kancelarku", "novinarku")) {
    rel <- if(role=="ministra") "koji" else "koja"
    routes(paste0("relative_rival_",role), paste("Biskup je upozorio",role,rel,
      "ističe da supsidijarnost zahtijeva poreznu reformu."), forbidden=c("B","C"))
  }
  routes("bishop_own_argument", "Biskup ističe da supsidijarnost zahtijeva poreznu reformu.", "C")
  routes("female_explicit_application", "Ministrica se pozvala na socijalni nauk Crkve pri izradi porezne reforme.", "B")
  routes("bound_past_feminine", "Vlada je u socijalnoj doktrini Crkve našla temelj te predložila poreznu reformu.", "B")
  routes("bound_infinitive", "Prema socijalnom nauku Crkve treba uvesti minimalnu plaću.", "B")
  routes("unbound_action", "Ministrica je u socijalnom nauku Crkve predložila novu naslovnicu.", forbidden=c("B","C"))
  routes("unbound_invitation", "Ministrica je pozvala na izložbu o socijalnom nauku Crkve.", forbidden=c("B","C"))
  routes("bound_plural_invitation", "Pozivamo na poreznu reformu u skladu sa socijalnim naukom Crkve.", "B")
  routes("falsefriend_personalized", "Vlada zahtijeva personalizirane elektroničke usluge.", forbidden=c("A1","A2","A?","B","C","D"))
  routes("falsefriend_legal_subsidiary", "Biskup kaže da je odobrena supsidijarna zaštita strancu.", forbidden=c("B","C"))
  routes("falsefriend_theological_court", "Socijalni nauk Crkve kaže da se Posljednji sud odnosi na svakog čovjeka.", forbidden=c("B","C"))
  routes("falsefriend_church_minister", "Ministrica Franjevačkoga svjetovnog reda kaže da socijalni nauk Crkve zahtijeva molitvu.", forbidden=c("B","C"))
  routes("falsefriend_orgname", "Centar za promicanje socijalnog nauka Crkve navodi da je ministrica otvorila izložbu.", forbidden=c("B","C"))
  routes("falsefriend_pucko", "Pučko otvoreno učilište najavilo je program obrazovanja.", forbidden=c("A1","A2","A?","B","C","D"))

  registry <- definition$documents[["actors.yaml"]]$registry
  pending <- Filter(function(a) a$status=="excluded_pending_evidence", registry)
  record("pending_inventory", length(pending)==11L, paste("pending records",length(pending)))
  for (actor in pending) {
    record(paste0("pending_no_compiled_id_",actor$id),
      !paste0("actor_",actor$id) %in% vapply(definition$compiled,function(x)x$id,character(1L)))
    # Named church bodies can independently match generic church-role vocabulary.
    routes(paste0("pending_no_D_",actor$id),
      paste(actor$name_hr,"se poziva na demokršćanska načela."), "A1", "D")
  }
  actors <- c(hdz="actor_hdz", hbk="actor_hbk", cdu="actor_foreign_codes",
    csu="actor_foreign_codes", ovp="actor_foreign_codes", nsi="actor_foreign_codes",
    cdv="actor_foreign_codes", hdz_bih="actor_hdz_bih")
  for (id in names(actors)) {
    actor <- Filter(function(a) a$id==id,registry)[[1L]]
    alias <- actor$aliases[[1L]]
    for (edge in c("valid_from","valid_to"))
      hit(paste("actor_date",id,edge,sep="_"),alias,actors[[id]],TRUE,actor[[edge]])
    hit(paste0("actor_date_",id,"_before"),alias,actors[[id]],FALSE,
      as.character(as.Date(actor$valid_from)-1L))
    hit(paste0("actor_date_",id,"_after"),alias,actors[[id]],FALSE,
      as.character(as.Date(actor$valid_to)+1L))
  }
  routes("D_first_day", "HDZ se poziva na demokršćanska načela.", "D",day="2024-10-20")
  routes("D_previous_day", "HDZ se poziva na demokršćanska načela.", "A1","D",day="2024-10-19")
  routes("D_last_day", "HDZ se poziva na demokršćanska načela.", "D",day="2026-09-18")
  routes("D_following_day", "HDZ se poziva na demokršćanska načela.", "A1","D",day="2026-09-19")
  routes("D_missing_day", "HDZ se poziva na demokršćanska načela.", "A1","D",day=NA_character_)
  for (day in c("2023-05-05","2023-05-06","2025-06-01","2026-09-19"))
    routes(paste0("foreign_not_domestic_",day), "HDZ BiH se poziva na demokršćanska načela.", "A1","D",day)

  # The sensitivity flag concerns only the declared organisation/role vocabulary,
  # and all article fields, rather than complete named-entity recognition.
  sole <- classify("HDZ se poziva na demokršćanska načela.")
  record("hdz_only_positive", isTRUE(sole$hdz_only) && "D" %in% sole$routes)
  for (other in c("Premijerka je došla na sastanak.", "Zastupnica je došla na sastanak.",
    "Biskup je došao na sastanak.", "HBK je održao sastanak.",
    "CDU je održao sastanak.", "Novinarka je došla na sastanak.")) {
    mixed <- classify(paste("HDZ se poziva na demokršćanska načela.", filler, other))
    record(paste0("hdz_only_other_",strsplit(other," ",fixed=TRUE)[[1L]][1L]),
      identical(mixed$hdz_only,FALSE) && "D" %in% mixed$routes)
  }
  incidental_hdz <- classify("HDZ je održao sastanak.")
  record("hdz_only_requires_D", identical(incidental_hdz$hdz_only,FALSE))
  expired_hdz <- classify("HDZ se poziva na demokršćanska načela.", "2024-10-19")
  record("hdz_only_requires_active_record", identical(expired_hdz$hdz_only,FALSE))

  results <- do.call(rbind,results)
  print(results[!results$pass,,drop=FALSE], row.names=FALSE)
  cat(sum(results$pass), "/", nrow(results), " independent synthetic review checks passed.\n",sep="")
  cat("Definition:",definition$definition_version,"\n")
  cat("Engine:",digest::digest(file="R/lib/barometar_engine.R",algo="sha256",serialize=FALSE),"\n")
  if(any(!results$pass))stop("Independent definition review regressions failed.",call.=FALSE)
  invisible(results)
}

if(sys.nframe()==0L)run_barometar_definition_review_tests()
