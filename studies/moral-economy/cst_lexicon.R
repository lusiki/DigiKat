#!/usr/bin/env Rscript
# moral-economy — CST CENSUS LEXICON (single source of truth for the doctrine probe).
#
# SOURCE this; never run it. `12_cst_census.R` counts with it and `16_cst_viewer.R` renders what it
# matched. If the two held separate copies, the viewer could show a post the census never counted —
# exactly the drift lexicon.R and sem_lib.R exist to prevent.
#
#   source(here::here("studies/moral-economy/cst_lexicon.R"))
#
# TWO TIERS, and the tiering is the methodological point:
#   Tier 1 — UNAMBIGUOUS. Magisterial titles and doctrine-specific coinages with no ordinary Croatian
#            sense ("supsidijarnost", "integralna ekologija", "socijalni nauk"). A hit is a genuine
#            invocation of the teaching. This is the hard count the paper's claims rest on.
#   Tier 2 — AMBIGUOUS, deliberately over-broad. "solidarnost", "opće dobro", "dostojanstvo rada" are
#            CST principles that are ALSO ordinary secular political vocabulary. Tier 2 cannot establish
#            presence — it can only BOUND it, so the paper can say that even counting every generic echo
#            as doctrine the ceiling stays low. Reporting Tier 2 as CST presence is the one error this
#            design exists to prevent.
suppressPackageStartupMessages({ library(stringi) })

# Document titles are Latin/Italian and enter Croatian text untranslated and undeclined, so fixed
# lowercase substrings suffice. "laudato si" is left unterminated: "Laudato si'" appears with a straight
# quote, a typographic quote, or nothing at all.
CST_DOCS <- c(
  rerum_novarum         = "rerum novarum",
  quadragesimo_anno     = "quadragesimo anno",
  mater_et_magistra     = "mater et magistra",
  pacem_in_terris       = "pacem in terris",
  gaudium_et_spes       = "gaudium et spes",
  populorum_progressio  = "populorum progressio",
  octogesima_adveniens  = "octogesima adveniens",
  laborem_exercens      = "laborem exercens",
  sollicitudo_rei_soc   = "sollicitudo rei socialis",
  centesimus_annus      = "centesimus annus",
  caritas_in_veritate   = "caritas in veritate",
  evangelii_gaudium     = "evangelii gaudium",
  laudato_si            = "laudato si",
  fratelli_tutti        = "fratelli tutti",
  laudate_deum          = "laudate deum",
  dignitas_infinita     = "dignitas infinita"
)

# Doctrine markers. Croatian declension via \\w* suffixes; [cć]/[sš] classes absorb the diacritic
# stripping that is routine on social platforms.
CST_MARKERS <- c(
  socijalni_nauk        = "socijaln\\w*\\s+nauk\\w*",
  socijalna_doktrina    = "socijaln\\w*\\s+doktrin\\w*",
  kompendij_ksn         = "kompendij\\w*\\s+socijaln\\w*",
  supsidijarnost        = "supsidijarn\\w*",
  integralna_ekologija  = "integraln\\w*\\s+ekologij\\w*",
  univ_namjena_dobara   = "univerzaln\\w*\\s+namjen\\w*\\s+dobar\\w*",
  opcija_za_siromasne   = "opcij\\w*\\s+za\\s+siroma[sš]\\w*|prvenstven\\w*\\s+opcij\\w*"
)

# Generic "enciklika": the genre is named without the teaching necessarily being social. Kept SEPARATE
# from Tier 1 proper so it can never inflate the headline count.
CST_GENRE <- c(enciklika = "enciklik\\w*")

CST_AMBIG <- c(
  solidarnost           = "solidarn\\w*",
  opce_dobro            = "op[cć]\\w+\\s+dobr\\w+",
  dostojanstvo_rada     = "dostojanstv\\w*\\s+(rada|radnik\\w*|[cč]ovjek\\w*)",
  socijalna_pravda      = "socijaln\\w*\\s+pravd\\w*"
)

CST_TERMS <- c(CST_DOCS, CST_MARKERS, CST_GENRE, CST_AMBIG)
CST_TIER  <- c(rep("1_document", length(CST_DOCS)), rep("1_marker", length(CST_MARKERS)),
               rep("1b_genre", length(CST_GENRE)), rep("2_ambiguous", length(CST_AMBIG)))
names(CST_TIER) <- names(CST_TERMS)
CST_FIXED <- names(CST_TERMS) %in% names(CST_DOCS)   # document titles match as fixed substrings
names(CST_FIXED) <- names(CST_TERMS)

# PERIODIZATION — the paper's second headline. CST is not one undifferentiated body: the classical
# labour-capital line (Rerum Novarum -> Centesimus Annus) is the tradition built FOR economic questions;
# the Francis-era documents are ecological/fraternal. Splitting them tests whether the tradition has been
# re-indexed away from labour. Conciliar/development texts are the middle period, reported separately so
# they cannot be silently folded into either side of the contrast.
CST_FRANCIS   <- c("laudato_si", "fratelli_tutti", "evangelii_gaudium", "laudate_deum", "dignitas_infinita")
CST_CLASSICAL <- c("rerum_novarum", "quadragesimo_anno", "laborem_exercens", "centesimus_annus",
                   "sollicitudo_rei_soc")
CST_CONCILIAR <- c("mater_et_magistra", "pacem_in_terris", "gaudium_et_spes", "populorum_progressio",
                   "octogesima_adveniens")

# Caritas in Veritate (Benedict XVI, 2009) belongs to none of the three: it is not Francis, not the
# 1891-1991 labour-capital line, and not conciliar. Leaving it unassigned made it behave like a marker,
# so posts whose ONLY document was CiV were counted "marker_only" — understating document-citation.
CST_BENEDICT <- c("caritas_in_veritate")

CST_ERA <- setNames(rep("—", length(CST_TERMS)), names(CST_TERMS))
CST_ERA[CST_FRANCIS]   <- "francis"
CST_ERA[CST_CLASSICAL] <- "classical"
CST_ERA[CST_CONCILIAR] <- "conciliar"
CST_ERA[CST_BENEDICT]  <- "benedict"

# Detect every term over a character vector. Returns a logical matrix (length(x) x length(CST_TERMS)).
# Callers MUST pass text that is already lowercased (MEMORY.md: lowercase before matching, or Croatian
# casing splits the same token two ways).
cst_detect <- function(txt_lower) {
  m <- matrix(FALSE, nrow = length(txt_lower), ncol = length(CST_TERMS),
              dimnames = list(NULL, names(CST_TERMS)))
  for (j in seq_along(CST_TERMS)) {
    m[, j] <- if (CST_FIXED[j]) stri_detect_fixed(txt_lower, CST_TERMS[j])
              else stri_detect_regex(txt_lower, CST_TERMS[j])
  }
  m
}

invisible(TRUE)
