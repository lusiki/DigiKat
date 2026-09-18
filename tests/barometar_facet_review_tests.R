# Bounded, independent route-facet regressions. All text is invented.
source("R/lib/digikat_utils.R",encoding="UTF-8")
source("R/lib/barometar_engine.R",encoding="UTF-8")
definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
filler <- paste(rep("Ovo je izmišljeni dodatak za provjeru duljine teksta.",5L),collapse=" ")
classify <- function(x)barometar_classify("Izmišljeni naslov",paste(x,filler),definition,day="2025-06-01")
checks <- list(
  policy_object=c("Socijalni nauk Crkve temelj je porezne reforme.","ostalo / nepripisano"),
  wage_object=c("Socijalni nauk Crkve zahtijeva pravednu plaću.","ostalo / nepripisano"),
  government=c("Vlada se poziva na socijalni nauk Crkve u poreznoj reformi.","drugi politički akter"),
  female_office=c("Ministrica se poziva na socijalni nauk Crkve u poreznoj reformi.","drugi politički akter"),
  church=c("Biskup ističe da supsidijarnost zahtijeva poreznu reformu.","crkveni govornik"),
  party=c("HDZ se poziva na demokršćanska načela.","demokršćanski akter"))
failed <- character()
for(id in names(checks)) {
  result <- classify(checks[[id]][1L])
  if(!identical(result$speaker_type,checks[[id]][2L]))failed <- c(failed,
    paste(id,"expected",checks[[id]][2L],"got",result$speaker_type))
}
separate <- classify(paste("U Njemačkoj demokršćanska načela određuju raspravu o Europi.",
  filler,filler,"Biskup ističe da supsidijarnost zahtijeva poreznu reformu."))
facet_a <- separate$facets[separate$facets$route=="A1",,drop=FALSE]
facet_c <- separate$facets[separate$facets$route=="C",,drop=FALSE]
if(!nrow(facet_a) || any(facet_a$reference_geography!="inozemno") ||
   any(facet_a$speaker_type!="ostalo / nepripisano"))failed <- c(failed,"A1 facet leaked unrelated C context")
if(!nrow(facet_c) || any(facet_c$reference_geography!="domaće") ||
   any(facet_c$speaker_type!="crkveni govornik"))failed <- c(failed,"C facet leaked unrelated A1 context")
cat("Definition:",definition$definition_version,"\n")
if(length(failed))stop(paste(failed,collapse="\n"),call.=FALSE)
cat("8/8 independent synthetic facet checks passed.\n")
