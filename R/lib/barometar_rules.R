# Generic, proposed barometer definition infrastructure (BRIEF 3.2 and 3.6).
# No route engine, actor attribution, document classification, DB calls or real
# dictionaries live here. A successful load/compile is NOT a G2 definition freeze.
# Dependencies: stringi, yaml, digest, barometar_text.R, and the shared
# digikat_hash_object helper.
# YAML schema: dictionaries contain `entries: [...]`; other named files contain
# their own quoted metadata. Scalars use single quotes, sequences may use flow
# syntax, and mappings use block syntax. Tags/anchors/block scalars are rejected.
# Entry `provenance` is a mapping with the seven fields listed below. `exclude_if`
# is a list of entry ids retained for the future contextual engine; the primitive
# matcher refuses it. Phrase slots are lists of enumerated single-token forms.
# `order: 'any'` supports two slots only; fixed order supports two or more slots.

BAROMETAR_DEFINITION_FILES <- c(
  "direct_terms.yaml", "doctrinal_anchors.yaml", "christian_grounding.yaml",
  "concept_families.yaml", "domain_themes.yaml", "public_context.yaml",
  "identity_register.yaml", "actors.yaml", "argument_connectors.yaml",
  "exclusions.yaml", "segmenter.yaml", "rules.yaml", "README.md"
)
BAROMETAR_ENTRY_FIELDS <- c("id", "family", "tier", "kind", "forms", "slots",
                            "gap_max", "order", "case_sensitive", "ascii_variants",
                            "exclude_if", "excluded_forms", "provenance", "principle")
BAROMETAR_REQUIRED_ENTRY_FIELDS <- c("id", "family", "tier", "kind", "forms",
                                     "case_sensitive", "ascii_variants", "exclude_if",
                                     "excluded_forms", "provenance")
BAROMETAR_PROVENANCE_FIELDS <- c("source_file", "source_object", "source_line",
                                "source_sha256", "added", "reviewed_by", "known_defects")

.barometar_rules_scalar <- function(value, field) {
  if (!is.character(value) || length(value) != 1L || is.na(value) || !nzchar(value)) {
    stop(field, " must be one nonempty quoted string.", call. = FALSE)
  }
  value
}

.barometar_rules_strings <- function(value, field, allow_empty = TRUE) {
  if (is.null(value) || (is.list(value) && length(value) == 0L)) value <- character()
  if (is.list(value) && is.null(names(value))) {
    valid <- vapply(value, function(x) is.character(x) && length(x) == 1L && !is.na(x), logical(1L))
    if (all(valid)) value <- unlist(value, use.names = FALSE)
  }
  if (!is.character(value) || anyNA(value) || any(!nzchar(value)) ||
      (!allow_empty && !length(value))) {
    stop(field, " must be an enumerated list of quoted strings.", call. = FALSE)
  }
  if (anyDuplicated(value)) stop(field, " has duplicate forms.", call. = FALSE)
  unname(enc2utf8(value))
}

.barometar_rules_integer <- function(value, field, min_value = 0L, max_value = 80L) {
  value <- .barometar_rules_scalar(value, field)
  if (!stringi::stri_detect_regex(value, "^(0|[1-9][0-9]*)$")) {
    stop(field, " must be a quoted nonnegative integer.", call. = FALSE)
  }
  number <- suppressWarnings(as.numeric(value))
  if (!is.finite(number) || number < min_value || number > max_value) {
    stop(field, " is outside its supported range.", call. = FALSE)
  }
  as.integer(number)
}

# This deliberately narrow YAML style avoids implicit yes/no/on/off conversion,
# executable tags and parser-dependent aliases. Keys may be quoted or identifiers.
barometar_validate_yaml_style <- function(lines, label = "definition") {
  key_prefix <- "^[ \\t]*(?:-[ \\t]+)?(?:[A-Za-z_][A-Za-z0-9_]*|'(?:[^']|'')*')[ \\t]*:[ \\t]*"
  remaining <- stringi::stri_replace_first_regex(lines, key_prefix, "")
  remaining <- stringi::stri_replace_all_regex(remaining, "'(?:[^']|'')*'", "")
  remaining <- stringi::stri_replace_first_regex(remaining, "#.*$", "")
  valid <- stringi::stri_detect_regex(remaining, "^[ \\t\\[\\]{},-]*$")
  if (any(!valid)) {
    stop(label, ": unsupported YAML or unquoted scalar at line(s) ",
         paste(which(!valid), collapse = ", "), ". Use single-quoted scalars and block mappings.",
         call. = FALSE)
  }
  invisible(TRUE)
}

.barometar_validate_scalar_types <- function(value, label) {
  if (is.list(value)) {
    for (part in value) .barometar_validate_scalar_types(part, label)
  } else if (!is.null(value) && !is.character(value)) {
    stop(label, " contains an implicit non-string scalar; quote every value.", call. = FALSE)
  }
  invisible(TRUE)
}

.barometar_validate_forms <- function(forms, label, allow_empty = FALSE) {
  forms <- .barometar_rules_strings(forms, label, allow_empty)
  if (length(forms) && any(!stringi::stri_detect_regex(forms, "^[\\p{Ll}\\p{Lu}\\p{M}'’. &-]+$"))) {
    stop(label, " contains a wildcard, regex or unsupported character.", call. = FALSE)
  }
  if (any(forms != stringi::stri_trim_both(forms)) ||
      any(forms != stringi::stri_trans_nfc(forms)) ||
      any(forms != barometar_normalize_text(forms))) {
    stop(label, " must be trimmed, normalized NFC surface forms.", call. = FALSE)
  }
  if (any(!stringi::stri_detect_regex(forms, "[\\p{Ll}\\p{Lu}]"))) {
    stop(label, " must contain a letter.", call. = FALSE)
  }
  forms
}

barometar_validate_entries <- function(entries) {
  if (!is.list(entries) || !is.null(names(entries))) {
    stop("entries must be an unnamed YAML sequence.", call. = FALSE)
  }
  result <- lapply(seq_along(entries), function(i) {
    entry <- entries[[i]]
    label <- paste0("entry[", i, "]")
    if (!is.list(entry) || is.null(names(entry)) || anyDuplicated(names(entry))) {
      stop(label, " must be a mapping with unique fields.", call. = FALSE)
    }
    missing <- setdiff(BAROMETAR_REQUIRED_ENTRY_FIELDS, names(entry))
    extra <- setdiff(names(entry), BAROMETAR_ENTRY_FIELDS)
    if (length(missing) || length(extra)) {
      stop(label, ": missing fields [", paste(missing, collapse = ","),
           "]; unsupported fields [", paste(extra, collapse = ","), "].", call. = FALSE)
    }
    for (field in c("id", "family", "tier", "kind", "case_sensitive")) {
      entry[[field]] <- .barometar_rules_scalar(entry[[field]], paste(label, field))
    }
    if (!stringi::stri_detect_regex(entry$id, "^[a-z][a-z0-9_]*$") ||
        !stringi::stri_detect_regex(entry$family, "^[a-z][a-z0-9_]*$")) {
      stop(label, " id/family must be stable lowercase identifiers.", call. = FALSE)
    }
    if (!entry$tier %in% c("strong", "distinctive", "generic") ||
        !entry$kind %in% c("token", "phrase") ||
        !entry$case_sensitive %in% c("true", "false")) {
      stop(label, " has an invalid tier, kind, or quoted boolean.", call. = FALSE)
    }
    for (field in c("forms", "ascii_variants", "excluded_forms")) {
      entry[[field]] <- .barometar_validate_forms(entry[[field]], paste(label, field), field != "forms")
    }
    if (length(entry$ascii_variants) &&
        any(!stringi::stri_detect_regex(entry$ascii_variants, "^[A-Za-z'. &-]+$"))) {
      stop(label, " ascii_variants must be explicit ASCII forms.", call. = FALSE)
    }
    combined <- c(entry$forms, entry$ascii_variants)
    if (entry$case_sensitive == "false") combined <- stringi::stri_trans_tolower(combined, locale = "hr")
    if (anyDuplicated(combined)) stop(label, " has duplicate normalized alternatives.", call. = FALSE)
    entry$exclude_if <- .barometar_rules_strings(entry$exclude_if, paste(label, "exclude_if"))
    if (!is.null(entry$principle)) .barometar_rules_scalar(entry$principle, paste(label, "principle"))
    provenance <- entry$provenance
    if (!is.list(provenance) || is.null(names(provenance)) || anyDuplicated(names(provenance)) ||
        !setequal(names(provenance), BAROMETAR_PROVENANCE_FIELDS)) {
      stop(label, " needs complete provenance with the documented fields.", call. = FALSE)
    }
    for (field in names(provenance)) {
      .barometar_rules_scalar(provenance[[field]], paste(label, "provenance", field))
    }
    if (!stringi::stri_detect_regex(provenance$source_sha256, "^[a-f0-9]{64}$") ||
        !stringi::stri_detect_regex(provenance$added, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$") ||
        is.na(as.Date(provenance$added, format = "%Y-%m-%d")) ||
        stringi::stri_detect_regex(provenance$source_file, "^(?:[A-Za-z]:|[/\\\\]|~)")) {
      stop(label, " provenance needs a SHA256, ISO date and relative source/citation id.", call. = FALSE)
    }
    if (entry$kind == "token") {
      if (length(entry$slots) || !is.null(entry$gap_max) || !is.null(entry$order) ||
          any(stringi::stri_detect_fixed(c(entry$forms, entry$ascii_variants), " "))) {
        stop(label, " token forms cannot contain spaces or phrase configuration.", call. = FALSE)
      }
    } else {
      entry$gap_max <- .barometar_rules_integer(entry$gap_max, paste(label, "gap_max"))
      entry$order <- .barometar_rules_scalar(entry$order, paste(label, "order"))
      if (!entry$order %in% c("fixed", "any")) stop(label, " order must be fixed or any.", call. = FALSE)
      if (is.null(entry$slots)) entry$slots <- list()
      if (!is.list(entry$slots) || !is.null(names(entry$slots))) stop(label, " slots must be a sequence.", call. = FALSE)
      entry$slots <- lapply(seq_along(entry$slots), function(j) {
        slot <- .barometar_validate_forms(entry$slots[[j]], paste(label, "slot", j))
        if (any(!stringi::stri_detect_regex(slot, "^[\\p{L}\\p{M}]+$"))) {
          stop(label, " each explicit slot must enumerate single letter tokens.", call. = FALSE)
        }
        slot
      })
      if (length(entry$slots) == 1L || (entry$order == "any" && length(entry$slots) != 2L)) {
        stop(label, " any-order requires two explicit slots; fixed order needs zero or at least two.", call. = FALSE)
      }
    }
    entry
  })
  ids <- vapply(result, `[[`, character(1L), "id")
  if (anyDuplicated(ids)) stop("Duplicate entry ids across definition files.", call. = FALSE)
  refs <- unlist(lapply(result, `[[`, "exclude_if"), use.names = FALSE)
  if (any(!refs %in% ids)) stop("exclude_if contains an unknown entry id.", call. = FALSE)
  result
}

.barometar_literal_alternation <- function(forms) {
  forms <- unique(forms)
  forms <- forms[order(-stringi::stri_length(forms), forms, method = "radix")]
  paste0("(?:", paste(paste0("\\Q", forms, "\\E"), collapse = "|"), ")")
}

.barometar_phrase_join <- function(slots, gap_max, any_order = FALSE) {
  separator <- "(?: +| *[\\-\\x{2010}-\\x{2015}] *)"
  gap <- paste0("(?:", separator, "[\\p{L}\\p{M}\\p{N}]+){0,", gap_max, "}", separator)
  pieces <- vapply(slots, .barometar_literal_alternation, character(1L))
  pattern <- paste(pieces, collapse = gap)
  if (any_order) pattern <- paste0("(?:", pattern, "|", paste(rev(pieces), collapse = gap), ")")
  pattern
}

.barometar_entry_pattern <- function(entry, forms = c(entry$forms, entry$ascii_variants),
                                      use_slots = TRUE) {
  if (entry$case_sensitive == "false") forms <- stringi::stri_trans_tolower(forms, locale = "hr")
  forms <- forms[order(-stringi::stri_length(forms), forms, method = "radix")]
  if (entry$kind == "token") {
    core <- .barometar_literal_alternation(forms)
  } else {
    patterns <- vapply(forms, function(form) {
      words <- stringi::stri_split_regex(form, "[ -]+", omit_empty = TRUE)[[1L]]
      .barometar_phrase_join(as.list(words), if (use_slots) entry$gap_max else 0L)
    }, character(1L))
    if (use_slots && length(entry$slots)) {
      slots <- entry$slots
      if (entry$case_sensitive == "false") slots <- lapply(slots, stringi::stri_trans_tolower, locale = "hr")
      patterns <- c(patterns, .barometar_phrase_join(slots, entry$gap_max, entry$order == "any"))
    }
    core <- paste0("(?:", paste(unique(patterns), collapse = "|"), ")")
  }
  paste0("(?<![\\p{L}\\p{M}\\p{N}_])", core, "(?![\\p{L}\\p{M}\\p{N}_])")
}

barometar_compile_entries <- function(entries) {
  entries <- barometar_validate_entries(entries)
  lapply(entries, function(entry) {
    pattern <- .barometar_entry_pattern(entry)
    # Force ICU to validate every generated expression at compile time.
    stringi::stri_detect_regex("", pattern)
    list(id = entry$id, family = entry$family, tier = entry$tier,
         case_sensitive = entry$case_sensitive == "true", pattern = pattern,
         excluded_patterns = lapply(entry$excluded_forms, function(form) {
           list(form = form, pattern = .barometar_entry_pattern(entry, form, use_slots = FALSE))
         }), exclude_if = entry$exclude_if, entry = entry)
  })
}

# Primitive hit evidence ONLY. The caller provides matching normalized txt/low;
# field, sentence, max-80-token windows, routes and contextual exclusions are G2 work.
# Explicit excluded_forms retain the hit, with exclusion winning on overlap.
barometar_match_literals <- function(txt, low, compiled) {
  if (!is.character(txt) || !is.character(low) || length(txt) != 1L || length(low) != 1L ||
      is.na(txt) || is.na(low) || stringi::stri_length(txt) != stringi::stri_length(low)) {
    stop("Supply one nonmissing normalized txt/low field with equal code-point lengths.", call. = FALSE)
  }
  rows <- list()
  for (rule in compiled) {
    if (length(rule$exclude_if) && !isTRUE(attr(compiled, "context_engine"))) {
      stop("Contextual exclude_if requires the route engine.", call. = FALSE)
    }
    field <- if (rule$case_sensitive) txt else low
    hits <- stringi::stri_locate_all_regex(field, rule$pattern, omit_no_match = TRUE)[[1L]]
    if (!nrow(hits)) next
    excluded_reason <- rep(NA_character_, nrow(hits))
    for (exclusion in rule$excluded_patterns) {
      excluded <- stringi::stri_locate_all_regex(field, exclusion$pattern, omit_no_match = TRUE)[[1L]]
      if (!nrow(excluded)) next
      for (j in seq_len(nrow(excluded))) {
        overlaps <- hits[, 1L] <= excluded[j, 2L] & hits[, 2L] >= excluded[j, 1L]
        excluded_reason[overlaps & is.na(excluded_reason)] <- paste0("excluded_form:", exclusion$form)
      }
    }
    rows[[length(rows) + 1L]] <- data.frame(
      entry_id = rule$id, family = rule$family, start = hits[, 1L], end = hits[, 2L],
      form = stringi::stri_sub(txt, hits[, 1L], hits[, 2L]), excluded_reason = excluded_reason,
      stringsAsFactors = FALSE)
  }
  if (!length(rows)) return(data.frame(entry_id = character(), family = character(), start = integer(),
                                      end = integer(), form = character(), excluded_reason = character()))
  result <- do.call(rbind, rows)
  result <- result[order(result$start, result$entry_id, result$end, method = "radix"), , drop = FALSE]
  rownames(result) <- NULL
  result
}

barometar_assert_re2_safe <- function(pattern) {
  forbidden <- c("\\b", "\\B", "\\w", "\\W", "\\s", "\\S", "(?=", "(?!", "(?<=", "(?<!")
  if (any(vapply(forbidden, function(value) any(stringi::stri_detect_fixed(pattern, value)), logical(1L)))) {
    stop("SQL-bound pattern contains forbidden ASCII boundaries/classes or lookaround.", call. = FALSE)
  }
  invisible(TRUE)
}

# Candidate superset: all entries are included, not an inferred route subset.
# Selecting a longest letter run for each listed form is conservative; explicit
# slots add every alternative from one selective required slot. No ASCII folding.
barometar_build_prefilter <- function(compiled) {
  longest_literal <- function(form) {
    tokens <- stringi::stri_extract_all_regex(stringi::stri_trans_tolower(form, locale = "hr"),
                                               "[\\p{Ll}]+", omit_no_match = TRUE)[[1L]]
    if (!length(tokens)) stop("Required form has no safe trigger literal.", call. = FALSE)
    tokens[order(-stringi::stri_length(tokens), tokens, method = "radix")][1L]
  }
  triggers <- character()
  required_forms <- character()
  for (rule in compiled) {
    entry <- rule$entry
    forms <- c(entry$forms, entry$ascii_variants)
    required_forms <- c(required_forms, forms)
    triggers <- c(triggers, vapply(forms, longest_literal, character(1L)))
    if (length(entry$slots)) {
      scores <- vapply(entry$slots, function(slot) min(stringi::stri_length(slot)), integer(1L))
      selected <- entry$slots[[which.max(scores)]]
      required_forms <- c(required_forms, selected)
      triggers <- c(triggers, vapply(selected, longest_literal, character(1L)))
    }
  }
  triggers <- unique(triggers)
  triggers <- triggers[order(-stringi::stri_length(triggers), triggers, method = "radix")]
  if (!length(triggers)) stop("No trigger forms: cannot construct a candidate prefilter.", call. = FALSE)
  covered <- vapply(required_forms, function(form) {
    any(stringi::stri_detect_fixed(stringi::stri_trans_tolower(form, locale = "hr"), triggers))
  }, logical(1L))
  if (!all(covered)) stop("Static prefilter superset coverage failed.", call. = FALSE)
  literal_pattern <- paste0("(?i)(?:", paste(triggers, collapse = "|"), ")")
  normalization_pattern <- "[\\p{M}\\p{Cf}\\x{01C4}-\\x{01CC}\\x{FB00}-\\x{FB06}\\x{FF01}-\\x{FF5E}ðİ]"
  barometar_assert_re2_safe(c(literal_pattern, normalization_pattern))
  sql_quote <- function(value) paste0("'", stringi::stri_replace_all_fixed(value, "'", "''"), "'")
  expression <- "coalesce(TITLE,'') || chr(10) || coalesce(FULL_TEXT,'')"
  condition <- paste0("(regexp_matches(", expression, ", ", sql_quote(literal_pattern),
                      ") OR regexp_matches(", expression, ", ", sql_quote(normalization_pattern), "))")
  list(triggers = triggers, literal_pattern = literal_pattern,
       normalization_pattern = normalization_pattern, sql_condition = condition,
       static_superset_verified = TRUE,
       re2_property_verified = FALSE, empirical_rejected_rows_verified = FALSE)
}

barometar_load_definition <- function(directory, text_cap = 32000L, require_complete = TRUE) {
  if (!dir.exists(directory)) stop("Definition directory is missing.", call. = FALSE)
  if (!is.numeric(text_cap) || length(text_cap) != 1L || is.na(text_cap) || !is.finite(text_cap) ||
      text_cap < 1 || text_cap != floor(text_cap) || text_cap > .Machine$integer.max) {
    stop("text_cap must be a positive integer.", call. = FALSE)
  }
  if (!is.logical(require_complete) || length(require_complete) != 1L || is.na(require_complete)) {
    stop("require_complete must be TRUE or FALSE.", call. = FALSE)
  }
  files <- list.files(directory, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  files <- files[order(files, method = "radix")]
  if (!length(files)) stop("Definition directory is empty.", call. = FALSE)
  if ("masked_days.csv" %in% basename(files)) stop("Day mask must be versioned outside the definition.", call. = FALSE)
  if (require_complete && length(setdiff(BAROMETAR_DEFINITION_FILES, files))) {
    stop("Definition is incomplete: ", paste(setdiff(BAROMETAR_DEFINITION_FILES, files), collapse = ", "), call. = FALSE)
  }
  docs <- list()
  entries <- list()
  manifest <- data.frame(file = files, sha256 = vapply(file.path(directory, files), function(path) {
    digest::digest(file = path, algo = "sha256", serialize = FALSE)
  }, character(1L)), stringsAsFactors = FALSE, row.names = NULL)
  yaml_files <- files[stringi::stri_detect_regex(files, "\\.ya?ml$")]
  for (file in yaml_files) {
    lines <- readLines(file.path(directory, file), encoding = "UTF-8", warn = FALSE)
    barometar_validate_yaml_style(lines, file)
    parsed <- yaml::yaml.load(paste(lines, collapse = "\n"), eval.expr = FALSE)
    .barometar_validate_scalar_types(parsed, file)
    if (!is.list(parsed) || is.null(names(parsed))) stop(file, " needs a YAML mapping.", call. = FALSE)
    if (!is.null(parsed$entries)) entries <- c(entries, parsed$entries)
    docs[[file]] <- parsed
  }
  if (!length(entries)) stop("Definition has no entries to compile.", call. = FALSE)
  if(require_complete) {
    settings <- docs[["rules.yaml"]]
    for(name in c("max_tokens","cue_distance","text_cap","min_body_chars")) {
      .barometar_rules_integer(settings[[name]],paste("rules",name),1L,if(name=="text_cap")32000L else if(name=="min_body_chars")200L else 80L)
    }
    if(!identical(settings$route_d,"diagnostic_only") || !identical(settings$identity_choice,"family_life_one_family"))stop("Unsupported route/identity semantics.")
    if(as.integer(settings$text_cap)!=text_cap)stop("Definition text cap differs from runtime cap.")
    segmenter <- docs[["segmenter.yaml"]]
    if(length(segmenter$abbreviations)<10L || length(segmenter$month_genitives)!=12L)stop("Incomplete segmenter configuration.")
    registry <- docs[["actors.yaml"]]$registry
    if(!is.list(registry)||!length(registry))stop("Missing actor registry.")
    actor_ids <- vapply(registry,function(actor) {
      for(name in c("id","name_hr","role","country","status")) .barometar_rules_scalar(actor[[name]],paste("actor",name))
      if(!actor$role %in% c("cd_self_identified","epp_affiliated","christian_conservative_non_cd","church_body","catholic_civil_society","identity_civil_society","historical_cd","foreign_cd_party") ||
         !length(actor$aliases) || any(!nzchar(unlist(actor$aliases))))stop("Invalid actor role/aliases.")
      if(!identical(actor$status,"excluded_pending_evidence")) {
        for(name in c("valid_from","valid_to")) .barometar_rules_scalar(actor[[name]],paste("actor",name))
        if(is.na(as.Date(actor$valid_from))||is.na(as.Date(actor$valid_to))||actor$valid_from>actor$valid_to||!length(actor$sources))stop("Invalid actor dates/evidence.")
      }
      actor$id
    },character(1L))
    if(anyDuplicated(actor_ids))stop("Duplicate registry actors.")
    roles <- c(actor_cd="cd_self_identified",actor_church="church_body",actor_foreign="foreign_cd_party")
    for(entry in docs[["actors.yaml"]]$entries)if(entry$family %in% names(roles)) {
      records <- Filter(function(record)record$role==roles[[entry$family]] && record$status!="excluded_pending_evidence",registry)
      aliases <- unlist(lapply(records,`[[`,"aliases"))
      if(!all(unlist(entry$forms) %in% aliases))stop("Active actor alias lacks a dated registry record: ",entry$id)
    }
  }
  compiled <- barometar_compile_entries(entries)
  groups <- setNames(rep(NA_character_, length(compiled)), vapply(compiled, `[[`, character(1L), "id"))
  for (file in names(docs)) {
    ids <- vapply(docs[[file]]$entries, `[[`, character(1L), "id")
    groups[ids] <- file
  }
  for (i in seq_along(compiled)) compiled[[i]]$source_group <- unname(groups[[compiled[[i]]$id]])
  # Every A route requires a direct label; B a doctrinal anchor; C explicit
  # Christian grounding or an attributed church speaker. D adds no articles.
  # Context/theme/connector words never independently retrieve candidates.
  anchor_ids <- which(vapply(compiled, function(x) {
    x$family == "cd_label" || x$source_group %in% c("doctrinal_anchors.yaml", "christian_grounding.yaml") ||
      x$family == "actor_church"
  }, logical(1L)))
  prefilter <- barometar_build_prefilter(if (require_complete) compiled[anchor_ids] else compiled)
  fingerprint <- list(schema = "barometar_definition_proposed_v1", text_cap = as.integer(text_cap),
                      files = manifest, documents = docs, compiled = compiled,
                      prefilter = prefilter)
  if(require_complete)fingerprint$algorithms <- setNames(lapply(c("R/lib/barometar_engine.R","R/lib/barometar_text.R","R/lib/barometar_rules.R"),function(path)digest::digest(file=path,algo="sha256",serialize=FALSE)),c("engine","text","compiler"))
  if (!exists("digikat_hash_object", mode = "function", inherits = TRUE)) {
    stop("Source R/lib/digikat_utils.R before loading a definition.", call. = FALSE)
  }
  hash <- digikat_hash_object(fingerprint)
  list(definition_version = paste0("1.0.0+", stringi::stri_sub(hash, to = 12L)),
       definition_hash = hash, text_cap = as.integer(text_cap), file_manifest = manifest,
       documents = docs, compiled = compiled, prefilter = prefilter,
       status = "proposed", route_engine_implemented = isTRUE(require_complete))
}
