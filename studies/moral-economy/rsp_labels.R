#!/usr/bin/env Rscript
# moral-economy — SHARED DISPLAY LABELS AND NUMBER FORMATTING FOR THE RSP SUBMISSION.
#
# The manuscript, its tables (26_rsp_tables.R) and its figures (24_rsp_figures.R) must not drift
# apart in how a domain is named or a number is printed, so both scripts source this file and
# neither carries a private copy.
#
# RSP number rules (Part II of the proposal): decimal COMMA, thousands separated by a SPACE.
# `digikat_format_integer()` in R/lib is Croatian house style (thousands dot) and is therefore the
# wrong formatter here; `rsp_int()` below is the journal's.

DOM <- c(green_energy = "Climate & energy", macro_aggregates = "Macro-economy",
         poverty_social = "Poverty & social", taxes_fiscal = "Taxes & fiscal",
         demography_econ = "Demography & labour supply", unemployment = "Unemployment",
         wages_income = "Wages & income", business_comp = "Business & firms",
         inflation_prices = "Inflation & prices", housing = "Housing",
         euro_changeover = "Euro changeover")

ERA <- c(classical = "Classical (1891–1991)", conciliar = "Conciliar (1961–1971)",
         benedict = "Benedict XVI", francis = "Francis era", mixed = "Mixed eras",
         marker_only = "No document named")

# Tier-1 vocabulary as it should read in print: magisterial titles in Latin italics, Croatian
# doctrinal coinages in italics with an English gloss. Keys are the detector's term ids.
TERM <- c(
  laudato_si = "*Laudato si'*", fratelli_tutti = "*Fratelli tutti*",
  evangelii_gaudium = "*Evangelii gaudium*", gaudium_et_spes = "*Gaudium et spes*",
  rerum_novarum = "*Rerum novarum*", pacem_in_terris = "*Pacem in terris*",
  dignitas_infinita = "*Dignitas infinita*", caritas_in_veritate = "*Caritas in veritate*",
  laudate_deum = "*Laudate Deum*", centesimus_annus = "*Centesimus annus*",
  populorum_progressio = "*Populorum progressio*", mater_et_magistra = "*Mater et magistra*",
  laborem_exercens = "*Laborem exercens*", quadragesimo_anno = "*Quadragesimo anno*",
  sollicitudo_rei_soc = "*Sollicitudo rei socialis*",
  octogesima_adveniens = "*Octogesima adveniens*",
  socijalni_nauk = "*socijalni nauk* (social teaching)",
  supsidijarnost = "*supsidijarnost* (subsidiarity)",
  integralna_ekologija = "*integralna ekologija* (integral ecology)",
  kompendij_ksn = "*kompendij socijalnog nauka* (Compendium)",
  socijalna_doktrina = "*socijalna doktrina* (social doctrine)",
  opcija_za_siromasne = "*opcija za siromašne* (option for the poor)",
  univ_namjena_dobara = "*univerzalna namjena dobara* (destination of goods)")

# Short form for figure axes, where the English gloss will not fit.
TERM_SHORT <- sub(" \\(.*$", "", TERM)
# ggplot draws no markdown, so figure labels carry the same words without the italic markers.
TERM_PLOT <- gsub("\\*", "", TERM)

rsp_int <- function(x) formatC(as.numeric(x), format = "d", big.mark = " ")
rsp_num <- function(x, digits = 2) {
  out <- formatC(as.numeric(x), format = "f", digits = digits, big.mark = " ")
  gsub("\\.", ",", trimws(out))
}
rsp_ci  <- function(lo, hi, digits = 2) sprintf("[%s; %s]", rsp_num(lo, digits), rsp_num(hi, digits))
