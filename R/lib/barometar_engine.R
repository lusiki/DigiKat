# Pure ICU classification. Restricted text is supplied by the private pipeline.
# A loaded definition is proposed until the separate development gates pass.
if (!exists("barometar_normalize_text", mode = "function")) source("R/lib/barometar_text.R", encoding = "UTF-8")
if (!exists("barometar_load_definition", mode = "function")) source("R/lib/barometar_rules.R", encoding = "UTF-8")

barometar_sentences <- function(txt, segmenter) {
  if (length(txt) != 1L || is.na(txt)) stop("One nonmissing field is required.")
  n <- stringi::stri_length(txt)
  if (!n) return(data.frame(start = integer(), end = integer(), sentence_id = integer()))
  cuts <- stringi::stri_locate_all_regex(txt,
    '[.!?…]["”’»\\)\\]]*[ \\n]+(?=[\\p{Lu}\\p{N}"“„«\\(\\-–—])', omit_no_match = TRUE)[[1L]]
  accepted <- integer()
  if (nrow(cuts)) for (i in seq_len(nrow(cuts))) {
    at <- cuts[i, 1L]
    before <- stringi::stri_sub(txt, to = at - 1L)
    punct <- stringi::stri_sub(txt, at, at)
    if (punct == ".") {
      last <- stringi::stri_extract_last_regex(before, "[\\p{L}\\p{N}]+$")
      if (!is.na(last) && stringi::stri_trans_tolower(last, "hr") %in% unlist(segmenter$abbreviations)) next
      after <- stringi::stri_sub(txt, from = cuts[i, 2L] + 1L)
      # Dialogue/parenthesized sentences can start without a capital letter.
      # A list number, ordinal or initial before such a marker is not a sentence.
      if(!is.na(last) && stringi::stri_detect_regex(after,"^[\\(\\-–—]") &&
         stringi::stri_detect_regex(last,"^(?:[0-9]{1,4}|[IVXLCDM]+|\\p{Lu})$")) next
      if (!is.na(last) && stringi::stri_detect_regex(last, "^\\p{Lu}$") &&
          stringi::stri_detect_regex(after, "^\\p{Lu}\\p{Ll}")) next
      # Ordinals before lowercase words are not candidates. Roman numerals
      # before named months/stoljeća also remain inside their sentence.
      first <- stringi::stri_extract_first_regex(after, "^[\\p{L}]+")
      if (!is.na(last) && stringi::stri_detect_regex(last, "^(?:[0-9]{1,4}|[IVXLCDM]+)$") &&
          !is.na(first) && stringi::stri_trans_tolower(first, "hr") %in%
          c(unlist(segmenter$month_genitives), "stoljeća", "st")) next
    }
    accepted <- c(accepted, cuts[i, 2L])
  }
  ends <- unique(c(accepted, n))
  starts <- c(1L, head(ends, -1L) + 1L)
  data.frame(start = starts, end = ends, sentence_id = seq_along(starts))
}

barometar_mask_boilerplate <- function(body, keys = character()) {
  if (!length(keys) || is.na(body) || !nzchar(body)) return(list(body = body, masked_chars = 0L))
  positions <- stringi::stri_locate_all_regex(body, BAROMETAR_BOILERPLATE_SPLIT_PATTERN, omit_no_match = TRUE)[[1L]]
  starts <- c(1L, if (nrow(positions)) positions[, 2L] + 1L else integer())
  ends <- c(if (nrow(positions)) positions[, 1L] - 1L else integer(), stringi::stri_length(body))
  segments <- stringi::stri_sub(body, starts, ends)
  hashes <- vapply(barometar_boilerplate_key_text(segments), digest::digest, character(1L), algo = "md5", serialize = FALSE)
  mask <- which(hashes %in% keys & ends >= starts)
  masked_chars <- 0L
  for (i in rev(mask)) {
    count <- ends[i] - starts[i] + 1L
    stringi::stri_sub(body, starts[i], ends[i]) <- strrep(" ", count)
    masked_chars <- masked_chars + count
  }
  list(body = body, masked_chars = masked_chars)
}

barometar_field_evidence <- function(txt, definition, field, active = NULL, day = NA_character_) {
  fields <- barometar_text_fields(txt)
  txt <- fields$txt
  compiled <- definition$compiled
  # Skip expressions with no hit before constructing offset evidence.
  if(is.null(active))active <- vapply(compiled, function(rule) stringi::stri_detect_regex(
    if (rule$case_sensitive) txt else fields$low, rule$pattern), logical(1L))
  if(length(active)!=length(compiled) || anyNA(active))stop("Invalid precomputed rule activation.")
  compiled <- compiled[active]
  attr(compiled, "context_engine") <- TRUE
  hits <- barometar_match_literals(txt, fields$low, compiled)
  tokens <- barometar_tokens(txt)
  sentences <- barometar_sentences(txt, definition$documents[["segmenter.yaml"]])
  hits$field <- rep(field, nrow(hits))
  hits$sentence_id <- if (nrow(hits)) findInterval(hits$start, sentences$start) else integer()
  clauses <- stringi::stri_locate_all_regex(txt, ";|, +(?:a|ali|dok) +", omit_no_match = TRUE)[[1L]]
  hits$clause_id <- if (nrow(hits)) findInterval(hits$start, c(1L, if (nrow(clauses)) clauses[,2L]+1L else integer())) else integer()
  hits$token_start <- if (nrow(hits)) pmax(1L, findInterval(hits$start, tokens$start)) else integer()
  hits$token_end <- if (nrow(hits)) pmax(1L, findInterval(hits$end, tokens$start)) else integer()
  ids <- vapply(definition$compiled, `[[`, character(1L), "id")
  rules <- definition$compiled[match(hits$entry_id, ids)]
  hits$tier <- vapply(rules, `[[`, character(1L), "tier")
  hits$source_group <- vapply(rules, `[[`, character(1L), "source_group")
  hits$principle <- vapply(rules, function(r) if (is.null(r$entry$principle)) "" else r$entry$principle, character(1L))
  # Explicit contextual exclusions operate locally, never across an article.
  for (i in seq_len(nrow(hits))) {
    excluded <- rules[[i]]$exclude_if
    conflict <- hits$entry_id %in% excluded & hits$sentence_id == hits$sentence_id[i] &
      pmax(hits$token_end, hits$token_end[i]) - pmin(hits$token_start, hits$token_start[i]) < 80L
    if (any(conflict)) hits$excluded_reason[i] <- paste0("context:", hits$entry_id[which(conflict)[1L]])
    if (hits$source_group[i] %in% c("doctrinal_anchors.yaml", "concept_families.yaml")) {
      nearby <- hits$sentence_id == hits$sentence_id[i] &
        pmax(hits$token_end, hits$token_end[i]) - pmin(hits$token_start, hits$token_start[i]) < 80L
      applied <- any(nearby & hits$family == "policy_action") ||
        (any(nearby & hits$family=="connector") && any(nearby & hits$entry_id %in% c("policy_reforms","public_policy","public_phrases")))
      if (hits$family[i] == "document" && !applied && any(nearby & hits$family %in% c("notice", "papal_naming"))) {
        hits$excluded_reason[i] <- "publication_or_papal_naming"
      }
      if (hits$family[i] %in% c("subsidiarity", "common_good") && any(nearby & hits$family == "legal_sense" &
          hits$start <= hits$end[i] & hits$end >= hits$start[i])) {
        hits$excluded_reason[i] <- "legal_sense"
      }
    }
    if (hits$family[i] == "church_speaker" && any(hits$family == "toponym" &
      hits$start <= hits$end[i] & hits$end >= hits$start[i])) hits$excluded_reason[i] <- "toponym"
    if(hits$family[i]=="public" && any(hits$family=="ecclesial_council" &
       hits$start<=hits$start[i] & hits$end>=hits$end[i]))hits$excluded_reason[i] <- "ecclesial_not_parliamentary_council"
    if(hits$source_group[i]=="doctrinal_anchors.yaml" && any(hits$family=="cst_organisation_name" &
       hits$start<=hits$start[i] & hits$end>=hits$end[i]))hits$excluded_reason[i] <- "doctrine_inside_organisation_name"
    if (hits$family[i] == "actor_cd" && any(hits$family == "actor_foreign" &
        hits$start <= hits$start[i] & hits$end >= hits$end[i])) hits$excluded_reason[i] <- "nested_foreign_actor"
    if(hits$family[i] %in% c("actor_cd","actor_church","actor_foreign") && !is.na(day)) {
      canonical <- function(x)stringi::stri_replace_all_regex(x,"[\\x{2010}-\\x{2015}]","-")
      actor <- Filter(function(record)record$status!="excluded_pending_evidence" &&
        canonical(hits$form[i]) %in% canonical(unlist(record$aliases)),definition$documents[["actors.yaml"]]$registry)
      if(!length(actor) || !any(vapply(actor,function(record)day>=record$valid_from && day<=record$valid_to,logical(1L))))
        hits$excluded_reason[i] <- "outside_documented_actor_interval"
    }
  }
  list(txt = txt, tokens = tokens, sentences = sentences, hits = hits)
}

# Conservative grammatical attachment proxy shared by inclusion and facets.
# Use the same reviewed role family for incidental mentions, competing speakers
# and the HDZ-only sensitivity flag; gender and case must not change attachment.
barometar_public_actor <- function(h) {
  h$entry_id=="public_institutions" & stringi::stri_detect_regex(h$form,
    "(?i)^(?:minist(?:ar|r)|premijer|zastupni|gradonačelni|kancelar|vlad)[\\p{L}]*$")
}

barometar_application_hits <- function(h, indices, actor_only=FALSE) {
  selected <- indices[h$family[indices] %in% c("connector","attribution","policy_action")]
  if(actor_only) {
    selected <- selected[h$family[selected]!="attribution"]
    # Inviting somebody to a cultural event is not policy application. An
    # invitation needs a separate policy object; reflexive doctrinal reference
    # ("poziva se na") and "na temelju" retain their ordinary meaning.
    invitation <- stringi::stri_detect_regex(h$form[selected],"(?i)^poz(?:iv|va)") &
      !stringi::stri_detect_regex(h$form[selected],"(?i)(?:\\bse\\b|temelju)")
    selected <- selected[!invitation]
  }
  selected
}

# The speaker and attribution must share a sentence/clause and be within twelve
# tokens. A closer minister/office holder blocks attribution to a church role.
barometar_attributed_speakers <- function(h, indices, family) {
  speakers <- indices[h$family[indices] %in% family]
  if(identical(family,"public"))speakers <- speakers[barometar_public_actor(h[speakers,,drop=FALSE])]
  verbs <- indices[h$family[indices] %in% c("attribution", "connector")]
  result <- integer()
  for (sp in speakers) for (verb in verbs) {
    same <- h$sentence_id == h$sentence_id[sp] & h$clause_id == h$clause_id[sp]
    if (!same[verb]) next
    distance <- function(index) pmax(0L, h$token_start[index] - h$token_end[verb], h$token_start[verb] - h$token_end[index])
    if (distance(sp) > 12L) next
    rivals <- indices[same[indices] & (h$family[indices]=="other_speaker" |
      barometar_public_actor(h[indices,,drop=FALSE]))]
    if (length(rivals) && any(distance(rivals) < distance(sp))) next
    # Attendance language before a later assertion is not speaker attribution.
    result <- c(result, sp, verb)
  }
  unique(result)
}

barometar_linked_indices <- function(indices, evidence) {
  h <- evidence$hits
  sentences <- sort(unique(h$sentence_id[indices]))
  if (length(sentences) == 1L) return(length(unique(h$clause_id[indices])) == 1L)
  if (max(sentences)-min(sentences) > 2L) return(FALSE)
  # An explicit anaphoric bridge is required for each intervening sentence.
  # A generic argument verb in an unrelated following sentence is insufficient.
  for (s in seq.int(min(sentences)+1L,max(sentences))) {
    sentence <- stringi::stri_sub(evidence$txt,evidence$sentences$start[s],evidence$sentences$end[s])
    if (!stringi::stri_detect_regex(sentence,
      "(?i)^ *[\"“„«]?(?:zato|stoga|prema tome|u skladu s tim|na temelju toga|polazeći od toga)(?:[ ,]|$)")) return(FALSE)
  }
  TRUE
}

# A window records actual supporting hits. Its inclusive token span is bounded,
# and its sentences lie in s-1..s+1. Nothing crosses title/body fields.
barometar_route_windows <- function(evidence, definition, day = NA_character_) {
  h <- evidence$hits
  valid <- which(is.na(h$excluded_reason))
  output <- list()
  if (!length(valid)) return(output)
  max_tokens <- as.integer(definition$documents[["rules.yaml"]]$max_tokens)
  add <- function(route, indices) {
    indices <- sort(unique(indices))
    if (!length(indices) || max(h$token_end[indices]) - min(h$token_start[indices]) + 1L > max_tokens ||
        max(h$sentence_id[indices]) - min(h$sentence_id[indices]) > 2L) return(invisible(NULL))
    centre <- as.integer(floor((min(h$sentence_id[indices]) + max(h$sentence_id[indices]))/2))
    token_low <- max(1L, min(h$token_start[indices]) - 12L,
      which(evidence$tokens$start >= evidence$sentences$start[max(1L,centre-1L)])[1L])
    token_high <- min(nrow(evidence$tokens), token_low + max_tokens - 1L,
      max(which(evidence$tokens$end <= evidence$sentences$end[min(nrow(evidence$sentences),centre+1L)])))
    # If the optional left context would cut required right evidence, shift it.
    if (token_high < max(h$token_end[indices])) {
      token_high <- max(h$token_end[indices]); token_low <- max(1L, token_high-max_tokens+1L)
    }
    output[[length(output) + 1L]] <<- list(route = route, field = h$field[indices[1L]],
      start = min(h$start[indices]), end = max(h$end[indices]), hits = indices,
      token_low=token_low,token_high=token_high,centre=centre)
    invisible(NULL)
  }
  label_hits <- valid[h$family[valid] == "cd_label"]
  if (length(label_hits)) for (i in label_hits) {
    close <- valid[h$sentence_id[valid] == h$sentence_id[i] & h$clause_id[valid] == h$clause_id[i] &
      pmax(0L, h$token_start[valid] - h$token_end[i], h$token_start[i] - h$token_end[valid]) <= 5L]
    idea <- close[h$family[close] == "idea_cue"]
    party <- close[h$family[close] %in% c("party_cue", "actor_foreign")]
    if (h$entry_id[i] == "cd_noun" || length(idea)) add("A1", c(i, head(idea, 1L)))
    else if (length(party)) add("A2", c(i, party[1L]))
    else add("A?", i)
  }
  anchors <- valid[h$source_group[valid] %in% c("doctrinal_anchors.yaml", "concept_families.yaml", "identity_register.yaml")]
  visited <- new.env(hash=TRUE,parent=emptyenv())
  for (i in anchors) {
    # Enumerate windows beginning at any hit no more than max_tokens before
    # the anchor. This avoids accepting individually near hits that are 159 apart.
    beginnings <- unique(h$token_start[valid][h$token_start[valid] <= h$token_start[i] &
      h$token_start[valid] >= h$token_end[i] - max_tokens + 1L])
    for (lo in beginnings) {
      key <- paste(h$sentence_id[i],lo,sep=":")
      if(!is.null(visited[[key]]))next
      visited[[key]] <- TRUE
      w <- valid[h$token_start[valid] >= lo & h$token_end[valid] < lo + max_tokens &
        abs(h$sentence_id[valid] - h$sentence_id[i]) <= 1L]
      public <- w[h$family[w] == "public"]
      if (!length(public)) next
      connectors <- w[h$family[w] == "connector"]
      attribution <- w[h$family[w] == "attribution"]
      strong <- w[h$source_group[w] == "doctrinal_anchors.yaml" & h$tier[w] == "strong"]
      # B's anchor must be applied in the same sentence, or through a connector
      # in the interval spanning the two relevant sentences.
      for (a in strong) for (p in public) {
        actor_only <- barometar_public_actor(h[p,,drop=FALSE])
        between <- barometar_application_hits(h,w,actor_only)
        between <- between[h$sentence_id[between] >= min(h$sentence_id[c(a,p)]) &
                           h$sentence_id[between] <= max(h$sentence_id[c(a,p)]) &
                           h$clause_id[between] == h$clause_id[a]]
        if (length(between) && barometar_linked_indices(c(a,p,between[1L]),evidence)) {
          add("B", c(a, p, between[1L]))
        }
      }
      grounding <- w[h$family[w] == "grounding"]
      speakers <- w[h$family[w] %in% c("church_speaker", "actor_church")]
      # A church role grounds only an attributed argument, not mere attendance.
      attributed <- barometar_attributed_speakers(h, w, c("church_speaker", "actor_church"))
      if (!length(grounding) && !length(attributed)) next
      if (!length(connectors)) next
      concepts <- w[h$source_group[w] == "concept_families.yaml" | h$family[w] == "identity_family" |
        (h$source_group[w] == "doctrinal_anchors.yaml" & h$tier[w] == "strong")]
      distinctive <- concepts[h$tier[concepts] %in% c("strong", "distinctive")]
      families <- h$family[concepts]
      families[families == "identity_family"] <- "family_life"
      if (!length(distinctive) && length(unique(families)) < 2L) next
      chosen <- if (length(distinctive)) distinctive[1L] else concepts[!duplicated(families)][1:2]
      connection <- connectors[1L]
      # Conservative relation proxy: connector must share a sentence with at
      # least one supporting term; distant generic connective prose cannot link.
      support <- c(public[1L], chosen, head(grounding, 1L), attributed)
      if (!barometar_linked_indices(c(connection,support),evidence)) next
      add("C", c(support, connection))
    }
  }
  if (length(output)) {
    keys <- vapply(output, function(w) paste(w$route, w$start, w$end, sep = ":"), character(1L))
    output <- output[!duplicated(keys)]
  }
  output
}

barometar_near_miss_conditions <- function(evidence,max_tokens=80L) {
  h <- evidence$hits;valid <- which(is.na(h$excluded_reason));failures <- character()
  if(!length(valid))return(failures)
  all_concepts <- valid[h$source_group[valid]=="concept_families.yaml" | h$family[valid]=="identity_family" |
    (h$source_group[valid]=="doctrinal_anchors.yaml" & h$tier[valid]=="strong")]
  all_families <- h$family[all_concepts];all_families[all_families=="identity_family"] <- "family_life"
  present_anywhere <- c(strong_anchor=any(h$source_group[valid]=="doctrinal_anchors.yaml" & h$tier[valid]=="strong"),
    political_anchor=any(h$family[valid]=="public"),application=any(h$family[valid] %in% c("connector","attribution","policy_action")),
    grounding=any(h$family[valid]=="grounding") || length(barometar_attributed_speakers(h,valid,c("church_speaker","actor_church")))>0L,
    concepts=any(h$tier[all_concepts] %in% c("strong","distinctive")) || length(unique(all_families))>=2L,
    argument=any(h$family[valid]=="connector"))
  # Conservative diagnostic frame: a complete sentence/clause's relevant hits
  # must fit the ordinary window. Never create a missing condition by slicing
  # off a hit from an otherwise complete argument. Distance/attachment failures
  # are not sampled here; the independent recall-probe frame can reveal them.
  keys <- paste(h$sentence_id[valid],h$clause_id[valid],sep=":")
  for(key in unique(keys)) {
    w <- valid[keys==key]
    relevant <- w[h$family[w] %in% c("public","connector","attribution","policy_action","grounding","church_speaker","actor_church","identity_family") |
      h$source_group[w] %in% c("doctrinal_anchors.yaml","concept_families.yaml")]
    if(!length(relevant) || max(h$token_end[relevant])-min(h$token_start[relevant])+1L>max_tokens)next
    strong <- w[h$source_group[w]=="doctrinal_anchors.yaml" & h$tier[w]=="strong"]
    public <- w[h$family[w]=="public"]
    connectors <- w[h$family[w]=="connector"]
    actions <- w[h$family[w]=="policy_action"]
    attribution <- w[h$family[w]=="attribution"]
    actor_only <- length(public)>0L && all(barometar_public_actor(h[public,,drop=FALSE]))
    application <- length(barometar_application_hits(h,w,actor_only))>0L
    grounded <- any(h$family[w]=="grounding") || length(barometar_attributed_speakers(h,w,c("church_speaker","actor_church")))>0L
    concepts <- w[h$source_group[w]=="concept_families.yaml" | h$family[w]=="identity_family" |
      (h$source_group[w]=="doctrinal_anchors.yaml" & h$tier[w]=="strong")]
    families <- h$family[concepts];families[families=="identity_family"] <- "family_life"
    concept_ok <- any(h$tier[concepts] %in% c("strong","distinctive")) || length(unique(families))>=2L
    sets <- list(B=c(strong_anchor=length(strong)>0L,political_anchor=length(public)>0L,application=application),
      C=c(grounding=grounded,political_anchor=length(public)>0L,concepts=concept_ok,argument=length(connectors)>0L))
    for(route in names(sets)) {
      absent <- names(sets[[route]])[!sets[[route]]]
      if(length(absent)==1L && !present_anywhere[[absent]])failures <- union(failures,paste(route,absent,sep=":"))
    }
  }
  failures
}

barometar_classify <- function(title, full_text, definition, day = NA_character_, boilerplate_keys = character(), .active = NULL) {
  prepared <- barometar_prepare_text(title, full_text, min_chars = 200L, cap = definition$text_cap)
  if (nrow(prepared) != 1L) stop("Classify exactly one article at a time.")
  if (!prepared$eligible) return(list(eligible = FALSE, routes = character(), evidence = data.frame(), windows = list()))
  mask <- barometar_mask_boilerplate(prepared$body, boilerplate_keys)
  fields <- list(title = if (is.na(title)) "" else title, body = mask$body)
  evidence <- lapply(names(fields), function(field) barometar_field_evidence(fields[[field]], definition, field,
    active=if(is.null(.active))NULL else .active[[field]],day=day))
  names(evidence) <- names(fields)
  windows <- unlist(lapply(evidence, barometar_route_windows, definition = definition, day = day), recursive = FALSE)
  all_routes <- unique(vapply(windows, `[[`, character(1L), "route"))
  direct <- if ("A1" %in% all_routes) "A1" else if ("A?" %in% all_routes) "A?" else if ("A2" %in% all_routes) "A2" else character()
  routes <- c(direct, intersect(c("B", "C"), all_routes))
  qualifying <- windows[vapply(windows, function(w) w$route %in% intersect(c("A1", "B", "C"), routes), logical(1L))]
  themes <- principles <- registers <- geography <- speakers <- character()
  facets <- list()
  diagnostic_d <- FALSE
  for (w in qualifying) {
    h <- evidence[[w$field]]$hits
    context <- which(h$start >= w$start & h$end <= w$end & is.na(h$excluded_reason))
    # Facets use the qualifying three-sentence/80-token window, not whole text.
    supporting <- h[w$hits, , drop = FALSE]
    context <- which(h$token_start >= w$token_low & h$token_end <= w$token_high &
      abs(h$sentence_id - w$centre) <= 1L & is.na(h$excluded_reason))
    # Theme matches wholly coinciding with inclusion evidence do not restate the rule.
    domain <- context[startsWith(h$family[context], "theme_")]
    domain <- domain[!vapply(domain, function(i) any(h$start[i] >= supporting$start & h$end[i] <= supporting$end), logical(1L))]
    themes <- c(themes, substring(h$family[domain], 7L))
    principles <- c(principles, h$principle[context][nzchar(h$principle[context])])
    identity <- any(h$family[context] %in% c("identity_family", "identity_other"))
    substance <- any(h$source_group[context] %in% c("doctrinal_anchors.yaml", "concept_families.yaml")) || w$route == "A1"
    registers <- c(registers, if (identity && substance) "oba" else if (identity) "identitarni" else "supstancijski")
    foreign <- any(h$family[context] %in% c("actor_foreign", "geography_foreign")) || any(h$entry_id[context] == "cd_foreign") ||
      any(stringi::stri_detect_regex(h$form[context], "^(?:njemačk|austrijsk|talijansk|bavarsk|demohrišć)"))
    eu <- any(h$family[context] == "geography_eu")
    domestic <- any(h$family[context]=="geography_domestic")
    geography <- c(geography, if ((foreign && eu) || (domestic && (foreign || eu))) "mješovito" else if (foreign) "inozemno" else if (eu) "EU" else "domaće")
    # Attribution must concern a sentence of the qualifying argument.
    passage <- context[h$sentence_id[context] %in% supporting$sentence_id]
    church <- barometar_attributed_speakers(h, passage, c("church_speaker", "actor_church"))
    cd <- barometar_attributed_speakers(h, passage, "actor_cd")
    political <- barometar_attributed_speakers(h,passage,"public")
    # The proposed HDZ role is only evidenced from the current statute date.
    registry <- definition$documents[["actors.yaml"]]$registry
    record <- Filter(function(x) identical(x$id,"hdz"),registry)[[1L]]
    cd_valid <- length(cd) && !is.na(day) && day >= record$valid_from && day <= record$valid_to
    speaker <- if (length(church)) "crkveni govornik" else if (cd_valid) "demokršćanski akter" else if(length(political)) "drugi politički akter" else "ostalo / nepripisano"
    speakers <- c(speakers, speaker)
    diagnostic_d <- diagnostic_d || identical(speaker, "demokršćanski akter")
    facets[[length(facets)+1L]] <- data.frame(route=w$route,field=w$field,start=w$start,end=w$end,
      themes=paste(sort(unique(substring(h$family[domain],7L))),collapse=";"),
      principles=paste(sort(unique(h$principle[context][nzchar(h$principle[context])])),collapse=";"),
      register=tail(registers,1L),reference_geography=tail(geography,1L),speaker_type=speaker,
      stringsAsFactors=FALSE)
  }
  if (diagnostic_d) routes <- c(routes, "D")
  combined <- do.call(rbind,lapply(evidence,`[[`,"hits"))
  valid_hits <- combined[is.na(combined$excluded_reason),,drop=FALSE]
  grounding_any <- any(valid_hits$family %in% c("grounding","church_speaker","actor_church"))
  public_any <- any(valid_hits$family=="public")
  concept_any <- any(valid_hits$source_group=="concept_families.yaml")
  broad_candidate <- any(c("A1","B","C") %in% routes)
  # Sensitivity flag refers to identified organisation/role vocabulary. It does
  # not claim complete named-entity recognition or infer individual ideology.
  hdz_only <- diagnostic_d && any(valid_hits$family=="actor_cd") &&
    !any(valid_hits$family %in% c("actor_foreign","actor_church","church_speaker","other_speaker")) &&
    !any(valid_hits$entry_id=="public_institutions" & stringi::stri_detect_regex(valid_hits$form,
      "(?i)^(?:minist|premijer|gradonačeln|zastupn|kancelar|vlada|vlade|vladi|vladom|sabor|parlament)"))
  near_conditions <- if(!broad_candidate)unique(unlist(lapply(evidence,barometar_near_miss_conditions,
    max_tokens=as.integer(definition$documents[["rules.yaml"]]$max_tokens)))) else character()
  near_miss <- length(near_conditions)>0L
  if(!broad_candidate && (mask$masked_chars>0L || prepared$cap_applied)) {
    # Independent recall frame can reveal losses caused by the primary mask/cap.
    raw <- barometar_prepare_text(title,full_text,cap=.Machine$integer.max)
    raw_fields <- barometar_text_fields(c(if(is.na(title))"" else title,raw$body))
    present <- vapply(definition$compiled,function(rule)any(stringi::stri_detect_regex(
      if(rule$case_sensitive)raw_fields$txt else raw_fields$low,rule$pattern)),logical(1L))
    raw_rules <- definition$compiled[present]
    grounding_any <- any(vapply(raw_rules,function(rule)rule$family %in% c("grounding","church_speaker","actor_church"),logical(1L)))
    public_any <- any(vapply(raw_rules,function(rule)rule$family=="public",logical(1L)))
    concept_any <- any(vapply(raw_rules,function(rule)rule$source_group=="concept_families.yaml",logical(1L)))
  }
  list(eligible = TRUE, routes = routes, a1 = "A1" %in% routes, broad_candidate = any(c("A1", "B", "C") %in% routes),
    near_miss=near_miss,near_miss_conditions=near_conditions,recall_probe=!broad_candidate && grounding_any && public_any && concept_any,
    themes = if (length(themes)) sort(unique(themes)) else "unclassified", principles = sort(unique(principles)),
    register = if ("oba" %in% registers || length(unique(registers)) > 1L) "oba" else if (length(registers)) registers[1L] else NA_character_,
    reference_geography = if (length(unique(geography)) > 1L) "mješovito" else if (length(geography)) geography[1L] else NA_character_,
    speaker_type = if (length(unique(speakers)) > 1L) "ostalo / nepripisano" else if (length(speakers)) speakers[1L] else NA_character_,
    hdz_only=hdz_only,cap_applied = prepared$cap_applied, masked_chars = mask$masked_chars,
    text_sha256 = digest::digest(full_text, algo = "sha256", serialize = FALSE),
    evidence = combined, windows = windows, facets=if(length(facets))unique(do.call(rbind,facets)) else data.frame())
}

barometar_development_split <- function(article_key) {
  hashes <- vapply(article_key, digest::digest, character(1L), algo = "md5", serialize = FALSE)
  strtoi(substr(hashes, 1L, 7L), base = 16L) %% 10L < 3L
}

# Vector activation compiles each ICU expression once per chunk rather than
# once per article. The exact per-item evidence and route engine are unchanged.
barometar_classify_batch <- function(rows,definition,boilerplate) {
  if(!nrow(rows))return(list())
  prepared <- barometar_prepare_text(rows$TITLE,rows$FULL_TEXT)
  keys <- lapply(seq_len(nrow(rows)),function(i)boilerplate$segment_key[
    boilerplate$outlet_id==rows$outlet_id[i] & boilerplate$month==substr(rows$day[i],1L,7L)])
  body <- vapply(seq_len(nrow(rows)),function(i)barometar_mask_boilerplate(prepared$body[i],keys[[i]])$body,character(1L))
  fields <- list(title=barometar_text_fields(ifelse(is.na(rows$TITLE),"",rows$TITLE)),body=barometar_text_fields(body))
  active <- lapply(fields,function(field)matrix(vapply(definition$compiled,function(rule)stringi::stri_detect_regex(
    if(rule$case_sensitive)field$txt else field$low,rule$pattern),logical(nrow(rows))),nrow=nrow(rows)))
  lapply(seq_len(nrow(rows)),function(i)barometar_classify(rows$TITLE[i],rows$FULL_TEXT[i],definition,rows$day[i],keys[[i]],
    .active=lapply(active,function(matrix)matrix[i,])))
}
