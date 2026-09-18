#!/usr/bin/env Rscript
# Generic rules only: all entries, prose and YAML below are invented test data.
local({
  source("R/lib/digikat_utils.R", local = TRUE, encoding = "UTF-8")
  source("R/lib/barometar_text.R", local = TRUE, encoding = "UTF-8")
  source("R/lib/barometar_rules.R", local = TRUE, encoding = "UTF-8")
  checks <- 0L
  failures <- character()
  equal <- function(actual, expected, label) {
    checks <<- checks + 1L
    if (!identical(actual, expected)) failures <<- c(failures, label)
  }
  okay <- function(actual, label) equal(isTRUE(actual), TRUE, label)
  errors <- function(expr, label) okay(inherits(try(expr, silent = TRUE), "try-error"), label)
  entry <- function(id = "blue_word", forms = c("plav", "plavi")) list(
    id = id, family = "invented", tier = "generic", kind = "token", forms = forms,
    case_sensitive = "false", ascii_variants = character(), exclude_if = character(),
    excluded_forms = character(), provenance = list(
      source_file = "invented-test-fixture", source_object = "invented", source_line = "1",
      source_sha256 = stringi::stri_dup("a", 64L), added = "2026-09-18",
      reviewed_by = "test-only", known_defects = "not empirical"
    ))
  first <- entry()
  compiled <- barometar_compile_entries(list(first))
  okay(stringi::stri_detect_fixed(compiled[[1L]]$pattern, "\\Qplavi\\E|\\Qplav\\E"),
       "literal alternatives longest first")
  hits <- function(text, rules = compiled) {
    fields <- barometar_text_fields(text)
    barometar_match_literals(fields$txt, fields$low, rules)
  }
  equal(hits("Plavi plav plavilo replav x_plav plav2 čplav")$form,
        c("Plavi", "plav"), "Unicode letter/number/underscore boundaries")
  equal(hits("😀plavi, PLAV.")$start, c(2L, 9L), "primitive hit offsets are code points")
  equal(nrow(hits("samo zeleno")), 0L, "no invented lexical hit")
  sensitive <- entry("case_word", "ABC")
  sensitive$case_sensitive <- "true"
  equal(hits("ABC abc Abc", barometar_compile_entries(list(sensitive)))$form, "ABC", "case-sensitive field")
  ascii <- entry("diacritic_word", "čudan")
  equal(nrow(hits("čudan cudan", barometar_compile_entries(list(ascii)))), 1L, "no implicit ASCII folding")
  ascii$ascii_variants <- "cudan"
  equal(nrow(hits("čudan cudan", barometar_compile_entries(list(ascii)))), 2L, "enumerated ASCII twin only")
  escaped <- entry("punctuation_word", "a.b")
  equal(hits("a.b aXb", barometar_compile_entries(list(escaped)))$form, "a.b", "ICU literal quotes metacharacters")
  apostrophe <- entry("apostrophe_word", "d'oro")
  equal(hits("d'oro dXoro", barometar_compile_entries(list(apostrophe)))$form, "d'oro", "literal apostrophe")

  phrase <- entry("blue_work", "plavi rad")
  phrase$kind <- "phrase"
  phrase$slots <- list(c("plavi", "plavog"), c("rad", "rada"))
  phrase$gap_max <- "2"
  phrase$order <- "fixed"
  phrase_rules <- barometar_compile_entries(list(phrase))
  for (separator in c(" ", "-", " – ", "—", "  ")) {
    equal(nrow(hits(paste0("plavi", separator, "rad"), phrase_rules)), 1L, paste("phrase separator", separator))
  }
  equal(hits("plavog novog važnog rada", phrase_rules)$form,
        "plavog novog važnog rada", "two-token gap allowed with slot forms")
  equal(nrow(hits("plavi vrlo posve sasvim rad", phrase_rules)), 0L, "three tokens exceed gap two")
  for (punctuation in c(".", "!", "?", ";", ":", ",", "\n")) {
    equal(nrow(hits(paste0("plavi", punctuation, " rad"), phrase_rules)), 0L,
          paste("phrase gap never crosses", punctuation))
  }
  equal(nrow(hits("rad plavi", phrase_rules)), 0L, "fixed phrase order")
  phrase$order <- "any"
  equal(nrow(hits("rada novog plavog", barometar_compile_entries(list(phrase)))), 1L, "two-slot any order")
  phrase$slots <- c(phrase$slots, list("dan"))
  errors(barometar_compile_entries(list(phrase)), "any-order three slots explicitly unsupported")
  phrase <- entry("exact_phrase", "plavi rad")
  phrase$kind <- "phrase"
  phrase$gap_max <- "0"
  phrase$order <- "fixed"
  equal(nrow(hits("plavi–rad", barometar_compile_entries(list(phrase)))), 1L, "exact phrase without explicit slots")
  longer_phrase <- phrase
  longer_phrase$forms <- c("plavi rad", "plavi rad ljudi")
  equal(hits("plavi rad ljudi", barometar_compile_entries(list(longer_phrase)))$form,
        "plavi rad ljudi", "phrase alternatives are also longest first")

  excluded <- first
  excluded$excluded_forms <- "plavi"
  retained <- hits("plav plavi", barometar_compile_entries(list(excluded)))
  equal(retained$excluded_reason, c(NA_character_, "excluded_form:plavi"), "excluded hit retained with reason")
  contextual <- first
  contextual$exclude_if <- "other"
  errors(barometar_compile_entries(list(contextual)), "unknown contextual reference rejected")
  contextual_rules <- barometar_compile_entries(list(contextual, entry("other", "zelen")))
  errors(hits("plavi", contextual_rules), "contextual decision fails closed without route engine")
  errors(barometar_match_literals("I", "ii", compiled), "offset-changing low input rejected")
  errors(barometar_match_literals(NA_character_, NA_character_, compiled), "primitive matcher requires field")

  errors(barometar_compile_entries(list(first, first)), "duplicate entry ids")
  invalid <- first
  invalid$forms <- c("plav", "plav")
  errors(barometar_compile_entries(list(invalid)), "duplicate forms")
  invalid$forms <- c("plav", "PLAV")
  errors(barometar_compile_entries(list(invalid)), "duplicate case-insensitive forms")
  for (form in c("plav*", "plav[ai]", "plav\\w+", "123", " plav", "plav\n", "c\u030Cudan", "ﬂava")) {
    invalid <- first
    invalid$forms <- form
    errors(barometar_compile_entries(list(invalid)), paste("reject invalid or unnormalized form", form))
  }
  invalid <- first
  invalid$provenance <- NULL
  errors(barometar_compile_entries(list(invalid)), "missing provenance")
  invalid <- first
  invalid$provenance$source_sha256 <- "not-a-hash"
  errors(barometar_compile_entries(list(invalid)), "bad source fingerprint")
  invalid <- first
  invalid$provenance$added <- "2026-99-99"
  errors(barometar_compile_entries(list(invalid)), "invalid provenance date")
  invalid <- first
  invalid$provenance$source_file <- "C:/private/input.qmd"
  errors(barometar_compile_entries(list(invalid)), "absolute source path rejected")
  invalid <- first
  invalid$case_sensitive <- FALSE
  errors(barometar_compile_entries(list(invalid)), "implicit YAML logical rejected")
  invalid$case_sensitive <- "no"
  errors(barometar_compile_entries(list(invalid)), "quoted but ambiguous boolean rejected")
  invalid <- first
  invalid$ascii_variants <- "čudan"
  errors(barometar_compile_entries(list(invalid)), "ASCII list must be ASCII")
  invalid <- first
  invalid$surprise <- "value"
  errors(barometar_compile_entries(list(invalid)), "unknown field rejected")

  prefilter <- barometar_build_prefilter(barometar_compile_entries(list(ascii, apostrophe, phrase)))
  okay(prefilter$static_superset_verified, "static required-form trigger coverage")
  okay(!prefilter$re2_property_verified && !prefilter$empirical_rejected_rows_verified,
       "unrun RE2 and empirical tests never claim passed")
  okay(all(stringi::stri_detect_regex(prefilter$triggers, "^[\\p{Ll}'-]+$")), "triggers use approved alphabet")
  okay(stringi::stri_detect_fixed(prefilter$sql_condition, "coalesce(FULL_TEXT,'')"), "SQL only constructs candidate condition")
  for (pattern in c("\\bword", "\\w+", "\\s", "(?<=x)y", "x(?!y)", "(?=x)")) {
    errors(barometar_assert_re2_safe(pattern), paste("SQL RE2 lint rejects", pattern))
  }
  pure_prefilter <- function(raw, filter) {
    stringi::stri_detect_regex(raw, filter$literal_pattern) |
      stringi::stri_detect_regex(raw, filter$normalization_pattern)
  }
  property_rules <- barometar_compile_entries(list(ascii, phrase))
  property_filter <- barometar_build_prefilter(property_rules)
  variants <- c("čudan", "ČUDAN", "Čudan", "c\u030Cudan", "ču\u00ADdan", "ču\u200Bdan",
                "plavi rad", "plavi\u00A0rad", "PLAVI RAD", "Plavi Rad", "plavi–rad",
                "plavirad", "ｐｌａｖｉ ｒａｄ")
  for (variant in variants) {
    hit <- nrow(hits(variant, property_rules)) > 0L
    okay(!hit || pure_prefilter(variant, property_filter), paste("pure ICU prefilter implication", variant))
  }
  normalization_rules <- barometar_compile_entries(list(
    entry("ligature_probe", "flava"), entry("eth_probe", "đak"),
    entry("digraph_probe", "džem"), entry("dotted_i_probe", "ideja")))
  normalization_filter <- barometar_build_prefilter(normalization_rules)
  normalization_variants <- c("ﬂava", "ðak", "ǅem", "İdeja")
  for (variant in normalization_variants) {
    okay(nrow(hits(variant, normalization_rules)) == 1L && pure_prefilter(variant, normalization_filter),
         paste("normalization-created match has prefilter arm", variant))
  }
  # This optional integration check sees invented strings only, in an in-memory
  # database. No live feed is opened and the libraries themselves never import DBI.
  if (requireNamespace("DBI", quietly = TRUE) && requireNamespace("duckdb", quietly = TRUE)) {
    connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
    tryCatch({
      for (i in seq_along(c(variants, normalization_variants))) {
        raw <- c(variants, normalization_variants)[i]
        rules <- if (i <= length(variants)) property_rules else normalization_rules
        filter <- if (i <= length(variants)) property_filter else normalization_filter
        query <- paste0("WITH candidate AS (SELECT CAST(? AS VARCHAR) AS TITLE, ",
                        "CAST(? AS VARCHAR) AS FULL_TEXT) SELECT ", filter$sql_condition,
                        " AS selected FROM candidate")
        selected <- DBI::dbGetQuery(connection, query, params = list("", raw))$selected[1L]
        okay(nrow(hits(raw, rules)) == 0L || isTRUE(selected), paste("actual RE2 superset fixture", i))
      }
    }, finally = DBI::dbDisconnect(connection, shutdown = TRUE))
  } else {
    cat("Optional RE2 in-memory checks skipped: DBI/duckdb unavailable.\n")
  }

  # All file creation is contained in one test-specific temporary directory.
  definition_dir <- tempfile("barometar-invented-definition-")
  dir.create(definition_dir)
  stopifnot(startsWith(normalizePath(definition_dir, winslash = "/"),
                      paste0(normalizePath(tempdir(), winslash = "/"), "/")))
  on.exit(unlink(definition_dir, recursive = TRUE), add = TRUE)
  yaml_lines <- c(
    "entries:", "  - id: 'blue_word'", "    family: 'invented'", "    tier: 'generic'",
    "    kind: 'token'", "    forms: ['plav', 'plavi']", "    case_sensitive: 'false'",
    "    ascii_variants: []", "    exclude_if: []", "    excluded_forms: []", "    provenance:",
    "      source_file: 'invented-test-fixture'", "      source_object: 'invented'",
    "      source_line: '1'", paste0("      source_sha256: '", stringi::stri_dup("a", 64L), "'"),
    "      added: '2026-09-18'", "      reviewed_by: 'test-only'", "      known_defects: 'not empirical'"
  )
  yaml_path <- file.path(definition_dir, "direct_terms.yaml")
  write_utf8 <- function(lines, path) {
    connection <- file(path, open = "wb")
    on.exit(close(connection))
    writeLines(enc2utf8(lines), connection, useBytes = TRUE)
  }
  write_utf8(yaml_lines, yaml_path)
  write_utf8("Izmišljeni primjer.", file.path(definition_dir, "README.md"))
  loaded <- barometar_load_definition(definition_dir, require_complete = FALSE)
  loaded_again <- barometar_load_definition(definition_dir, require_complete = FALSE)
  equal(loaded$definition_hash, loaded_again$definition_hash, "deterministic reload fingerprint")
  okay(stringi::stri_detect_regex(loaded$definition_version, "^1\\.0\\.0\\+[a-f0-9]{12}$"), "definition version contract")
  equal(loaded$status, "proposed", "generic loader cannot freeze definition")
  equal(loaded$route_engine_implemented, FALSE, "generic loader discloses no route engine")
  errors(barometar_load_definition(definition_dir), "production loader requires complete file inventory")
  changed_cap <- barometar_load_definition(definition_dir, text_cap = 31999L, require_complete = FALSE)
  okay(changed_cap$definition_hash != loaded$definition_hash, "cap affects definition hash")
  write_utf8("Izmišljeni primjer promijenjen.", file.path(definition_dir, "README.md"))
  changed_readme <- barometar_load_definition(definition_dir, require_complete = FALSE)
  okay(changed_readme$definition_hash != loaded$definition_hash, "README bytes affect definition hash")
  write_utf8(c(yaml_lines, "# byte-only comment"), yaml_path)
  changed_comment <- barometar_load_definition(definition_dir, require_complete = FALSE)
  okay(changed_comment$definition_hash != changed_readme$definition_hash, "all file bytes including comments hashed")
  write_utf8(stringi::stri_replace_first_fixed(yaml_lines, "case_sensitive: 'false'", "case_sensitive: false"), yaml_path)
  errors(barometar_load_definition(definition_dir, require_complete = FALSE), "loader rejects unquoted false")
  write_utf8(stringi::stri_replace_first_fixed(yaml_lines, "forms: ['plav', 'plavi']", "forms: [on, no]"), yaml_path)
  errors(barometar_load_definition(definition_dir, require_complete = FALSE), "loader rejects YAML implicit on/no")
  write_utf8(stringi::stri_replace_first_fixed(yaml_lines, "family: 'invented'", "family: invented"), yaml_path)
  errors(barometar_load_definition(definition_dir, require_complete = FALSE), "loader enforces quoted ordinary strings")
  write_utf8(yaml_lines, yaml_path)
  write_utf8(yaml_lines, file.path(definition_dir, "second.yaml"))
  errors(barometar_load_definition(definition_dir, require_complete = FALSE), "loader catches duplicate ids across files")
  okay(barometar_validate_yaml_style(c("'name': 'd''oro' # comment", "forms: ['on', 'no']")),
       "quote checker preserves doubled apostrophes and quoted YAML booleans")
  errors(barometar_validate_yaml_style("source: !expr 'stop()'"), "YAML executable tags rejected")
  errors(barometar_validate_yaml_style("source: &copy 'value'"), "YAML anchors rejected")
  errors(barometar_validate_yaml_style("source: |"), "YAML block scalars explicitly unsupported")

  if (length(failures)) stop(paste(c("Barometer rules tests failed:", failures), collapse = "\n"), call. = FALSE)
  cat("Barometer generic-rules tests: ", checks, " checks passed (invented definitions only).\n", sep = "")
})
