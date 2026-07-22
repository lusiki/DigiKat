#!/usr/bin/env Rscript
# moral-economy — SHARED LEXICON MODULE (single source of truth; sourced by every pipeline stage).
# Owns: (1) the 11 economy-domain regexes (v3, register-neutral, homonym-fixed per CODEBOOK.md),
#       (2) the ECONOMIC-HOMONYM-TIGHTENED religion regex built from R/religious_terms.R,
#       (3) shared constants (WINDOW, tiers).
# NO copy-paste: 01/02/03 all source THIS file. Editing a regex here re-fingerprints downstream caches.
#
# Sourced, not run:  source(here::here("studies/moral-economy/lexicon.R"))
suppressPackageStartupMessages({ library(here); library(stringr) })

# --- shared constants --------------------------------------------------------------------------
ME_WINDOW <- 220L   # sister-validated linkage window (PAPER_v1: recall 0.89 at +/-220)

# --- 1. ECONOMY DOMAIN LEXICON (v3) ------------------------------------------------------------
# DESIGN RULE (referee finding): domain membership is defined by REGISTER-NEUTRAL economic
# vocabulary ONLY — no CST/justice terms (dostojanstvo rada, radnicka prava), no charity-operations
# terms (banka hrane, pucka kuhinja). Registers are assigned at Stage-B coding, never by the tagger.
# v3 homonym fixes folded in from CODEBOOK.md (poverty hand-pass, 2026-07-07):
#   * debt: bare du[zž]ni[kc] dropped (caught "misa zadužnica" = requiem); replaced by dužnik NOUN
#     at a word boundary + zaduženost/prezaduženost (indebtedness) — economic, not liturgical.
#   * siroma[sš] kept broad for RECALL but routed at coding via Axis-5 (economic vs doctrinal poverty);
#     the tagger does not try to disambiguate spiritual poverty — the codebook does.
ME_ECON <- list(
  # --- tier A: aggregates / system ---
  macro_aggregates = "\\bbdp\\w{0,3}\\b|bruto\\s+doma[cćč]\\w+|gospodarsk\\w+\\s+rast|gospodarstv|recesij|javn\\w+\\s+dug|dr[zž]avn\\w+\\s+dug|prora[cč]unsk\\w+\\s+(manjk|deficit)|\\bdeficit|kamatn\\w+\\s+stop|monetarn\\w+\\s+politik|fiskaln",
  euro_changeover  = "eurozon|uvo[dđ]enj\\w*\\s+eura|(prijelaz|prelaz)\\w*\\s+na\\s+euro|zamjen\\w+\\s+kun|konverzij\\w+\\s+(kun|cijen)|dvojn\\w+\\s+iskaz|te[cč]ajn",
  taxes_fiscal     = "porezn|\\bporez\\w{0,3}\\b|\\bpdv\\b|fiskaliz|redistribuc|socijaln\\w+\\s+davanj|tro[sš]arin\\w*|doprinos\\w*|prirez\\w*|carin\\w*",
  business_comp    = "poduzetni|poduze[cć]\\w*|konkuren\\w*|investi\\w*|ulagan\\w*|tvrtk\\w*|obrtni[kc]\\w*|\\bobrt\\w*",
  # --- tier B: sectoral / transitional ---
  green_energy     = "energetsk\\w+\\s+(kriz|tranzicij|siroma[sš])|cijen\\w*\\s+(struje|plina|energenata|goriva)|zelen\\w+\\s+tranzicij|obnovljiv\\w+\\s+izvor|dekarboniz|klimatsk\\w+\\s+(promjen|politik)|green\\s+deal",
  housing          = "stanovanj|najamnin|nekretnin|stamben|cijen\\w*\\s+stanov|priu[sš]tiv",
  # ECONOMIC anchors ONLY (deliberate, from the 1st review round): natalitet/iseljavanje/depopulacija
  # are moralized pro-natalist/national-emigration discourse, NOT demography-as-economy — kept OUT on
  # purpose (recall-vs-confound tradeoff; nlp-review M2 wanted them added, domain-review said exclude).
  # manjk\\w* covers the fleeting-a genitive "zbog manjka radnika".
  demography_econ  = "radn\\w+\\s+snag|stran\\w+\\s+radnik|uvoz\\w*\\s+radnik|odljev\\w*\\s+mozgov|nedostat\\w+\\s+radnik|manjk\\w*\\s+radnik|mirovinsk\\w+\\s+sustav",
  # --- tier C: lived / person-level ---
  inflation_prices = "inflacij|poskup|(rast|porast|skok)\\w*\\s+cijen|tro[sš]\\w*\\s+[zž]ivota|kupovn\\w*\\s+mo[cć]",
  unemployment     = "nezaposlen|zapo[sš]ljavanj|otpu[sš]tanj\\w*\\s+(radnik|zaposlen|djelatnik)|masovn\\w+\\s+otpu[sš]tanj|\\botkaz(a|e|i|u|om|ima)?\\b|tr[zž]i[sš]t\\w*\\s+rada|radn\\w+\\s+mjest",
  # NOTE: no BARE pla[cć]e form (plače='(s)he weeps' homonym, 1st-review C1) — wage terms carry an
  # economic collocate or a bruto/neto qualifier; income NOUNS (dohodak/prihod/primanja/nadnica) added.
  wages_income     = "(minimaln|prosje[cč]n|nisk|visok)\\w*\\s+(bruto\\s+|neto\\s+)?pla[cć]|rast\\w*\\s+pla[cć]|pove[cć]anj\\w*\\s+pla[cć]|neispla[cć]en\\w*\\s+pla[cć]|\\bdohod\\w*|\\bdohotk\\w*|\\bprihod\\w*|primanj\\w*|nadnic\\w*|mirovin(a|e|i|u|om|ama)?\\b|sindika\\w*|prekarn",
  # zadu[zž]en\\w* covers zadužen/zadužena/zaduženost; still rejects requiem 'zadušnica'/'zadužnica'
  # (\\b before du[zž]ni[kc] rejects za-dužnica; zadu[zž]en needs 'en', absent in zadužnica).
  poverty_social   = "siroma[sš]|socijaln\\w+\\s+(pomo[cć]|skrb|ugro[zž]en)|be[sz]ku[cć]ni|\\bovrh|ovr[sš]n|\\bdu[zž]ni[kc]\\w*|zadu[zž]en\\w*|prezadu[zž]en\\w*|dugovanj\\w*"
)
ME_TIER <- c(macro_aggregates="A", euro_changeover="A", taxes_fiscal="A", business_comp="A",
             green_energy="B", housing="B", demography_econ="B",
             inflation_prices="C", unemployment="C", wages_income="C", poverty_social="C")

# --- inflation metaphor guard (Stage A) --------------------------------------------------------
# Sister study (PAPER_v1:119-123) drops figurative "inflacija rijeci/vrijednosti/titula/ocjena".
# Applied as a POST-match exclusion on the inflation_prices domain only (never touches other domains).
ME_INFLATION_METAPHOR <- "inflacij\\w*\\s+(rije[cč]|vrijednost|titul|ocjen|ega|diplom|informacij)"

# --- coarse FOREIGN hint (Stage A stratification aid, NOT a decision — Axis 2 coding decides) ----
# Presence of a foreign-country/leader token in the linkage window => flag for the coder's attention.
# NB: text is lowercased before matching, so bare "sad" (=USA) collides with the adverb "sad" (=now)
# and bare "kina" (=China) with "kina" (=of the cinema) — BOTH DROPPED (nlp-review M4). Use the
# unambiguous "sjedinjen ... država" and the derived adjective "kinesk" instead.
ME_FOREIGN_HINT <- paste(
  "sjedinjen\\w+\\s+dr[zž]av|amerik|washington|\\beu\\b|europsk\\w+\\s+unij|bruxelles|brisel",
  "njema[cč]k|francusk|talijansk|[sš]panjolsk|gr[cč]k|britan|velik\\w+\\s+britanij",
  "kinesk|rusij|rusk|ukrajin|srbij|srpsk", "vatikan\\w*\\s+(financ|prora|banka)",
  sep = "|")

# --- 2. RELIGION LINKAGE REGEX (economic-homonym-tightened 95-term lexicon) ---------------------
# Builds the linkage religion regex from the FROZEN R/religious_terms.R, then applies the 5
# economic-homonym tightenings the sister paper documented (Gospa/gospodarstvo, papa/papir,
# demon/demonstracije, kapitul/kapitulira, misa/misao). Without this, the un-anchored committed
# patterns match "gospo"->gospodarstvo etc. INSIDE the economy window and re-inflate the exact bug
# that halved the sister headline. caritas/karitas is NOT in the 95-term list and is held SEPARATE
# so Stage A can report linkage with/without the religion-as-actor term (CODEBOOK Axis 3, Rule 2).
#
# KNOWN LIMITATION (nlp-review M6, documented not "fixed"): the religion patterns from
# R/religious_terms.R carry BARE diacritics (đakon, križ, kršćan) while the economy patterns use
# defensive classes ([cč] etc.). On ASCII-FOLDED text (mostly the ~3% forum/reddit/twitter slice) the
# economy side matches but religion may not, biasing linkage DOWNWARD there. We do NOT diacritic-fold
# the religion patterns because folding creates worse FALSE POSITIVES (križ 'cross' -> "kriz" would
# match kriza 'crisis'). Stage A reports the folded-text share so the bias is measured, not hidden.
# Returns list(core=<regex, no caritas>, with_caritas=<regex>, n_terms=<int>, tightened=<chr>).
me_build_religion_regex <- function(verbose = TRUE) {
  # sys.source + by-name lookup (r-review Minor 4): robust to any trailing statement in the sourced
  # file, unlike source(...)$value which returns only the LAST expression. Assert term count too.
  e <- new.env(); sys.source(here::here("R/religious_terms.R"), envir = e)
  rt <- e$religious_terms
  stopifnot(is.data.frame(rt), "regex" %in% names(rt), nrow(rt) >= 90)
  rx <- rt$regex

  # exact committed patterns we replace (warn on drift so a lexicon edit can't silently un-fix this)
  # NB (nlp-review m8): the gosp fix intentionally drops "Gospodin/Gospodine" (=the Lord) because it
  # collides with secular gospodin (=Mr.) and gospodarstvo — a documented, deliberate loss, not a bug.
  fixes <- list(
    "pap[aeiou][jmnstz]*"       = "\\bpap(a|e|i|u|o|om|ama)\\b|papin\\w*",     # Pope incl. 's papom'/'papama' (nlp-review M5), not papir/papar
    "gosp[aeiou][jmsz]*"        = "\\bgosp(a|e|i|u|o|om|ama)\\b|gospin\\w*",    # Gospa, not gospodarstvo/gospodin
    "demon[aeiou]?[jmstz]*"     = "\\bdemon(a|i|u|e|om|ima)?\\b|demonsk\\w*",   # demon, not demonstracije
    "kapitul[aeiou]?[jmstz]*"   = "\\bkapitul(a|u|i|e|om)?\\b|kaptol\\w*",      # chapter, not kapitulira/kapitulacija
    "mis[aeiou][jmz]*"          = "\\bmis(a|e|i|u|om|ama)\\b"                   # Mass, not misao/misija/misli
  )
  tightened <- character(0)
  for (target in names(fixes)) {
    hit <- which(rx == target)
    if (length(hit) == 1L) { rx[hit] <- fixes[[target]]; tightened <- c(tightened, target) }
    else if (verbose) warning("me_build_religion_regex: expected pattern not found (lexicon drift?): ", target)
  }
  # FAIL LOUD (nlp-review C1): if ANY tightening did not apply, the un-tightened broad pattern would
  # silently re-enter and match gospodarstvo/papir/etc. as RELIGION inside the economy window —
  # re-arming the bug that halved the sister headline. A frozen census must abort, not warn-and-run.
  if (length(tightened) != length(fixes))
    stop("me_build_religion_regex: ", length(fixes) - length(tightened),
         " homonym tightening(s) FAILED to apply — R/religious_terms.R drifted. Refusing to build a ",
         "fail-open religion regex. Re-check the target patterns before running the census.")
  core <- paste(rx, collapse = "|")
  list(core = core,
       with_caritas = paste(core, "caritas|karitas", sep = "|"),
       n_terms = length(rx), tightened = tightened)
}

# quick self-test when run directly (Rscript studies/moral-economy/lexicon.R)
if (identical(environment(), globalenv()) && !interactive() &&
    length(commandArgs(trailingOnly = TRUE)) == 0 && sys.nframe() == 0) {
  r <- me_build_religion_regex()
  cat("religion terms:", r$n_terms, "| tightenings applied:", length(r$tightened), "\n")
  cat("domains:", length(ME_ECON), "| tiers:", paste(names(table(ME_TIER)), table(ME_TIER), collapse=" "), "\n")
  # homonym self-test: economy words must NOT match the tightened religion core; religion words MUST.
  low <- function(x) str_to_lower(x, locale = "hr")
  must_not <- c("gospodarstvo raste","papir i tinta","demonstracije u zagrebu","vlada kapitulira","duboka misao")
  must_yes <- c("gospa sinjska","sveti otac papa","razgovor s papom o siromaštvu","misa u katedrali",
                "zagrebački nadbiskup","družba isusova")   # 's papom' = the M5 over-tighten regression test
  fp <- must_not[str_detect(low(must_not), regex(r$core))]
  fn <- must_yes[!str_detect(low(must_yes), regex(r$core))]
  cat("homonym FALSE POSITIVES (should be none):", if(length(fp)) paste(fp, collapse=" | ") else "OK", "\n")
  cat("religion FALSE NEGATIVES (should be none):", if(length(fn)) paste(fn, collapse=" | ") else "OK", "\n")
  # economy-domain self-tests: poverty rejects the requiem homonym; new recall forms now match.
  chk <- function(lab, txt, dom, want=TRUE) cat(sprintf("%-46s %s\n", lab,
    identical(str_detect(low(txt), regex(ME_ECON[[dom]])), want)))
  chk("poverty rejects 'misa zadužnica'", "misa zadužnica služit će se", "poverty_social", FALSE)
  chk("poverty accepts 'ovršni dužnik'", "ovršni postupak nad dužnikom", "poverty_social", TRUE)
  chk("wages accepts 'prosječna neto plaća'", "prosječna neto plaća raste", "wages_income", TRUE)
  chk("wages accepts 'dohodak'", "raspoloživi dohodak kućanstava", "wages_income", TRUE)
  chk("business accepts 'poduzeće'", "malo poduzeće u problemima", "business_comp", TRUE)
  chk("business accepts 'konkurencija'", "nelojalna konkurencija na tržištu", "business_comp", TRUE)
  chk("macro accepts 'bruto domaći proizvod'", "bruto domaći proizvod pao je", "macro_aggregates", TRUE)
}
