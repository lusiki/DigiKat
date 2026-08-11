# The Layer-1 actor typology. ONE definition, shared by every surface that shows it.
#
# The rule is a per-platform median split of recorded interactions against estimated reach, as
# drawn in pages/mapa/mapa.qmd. It is deliberately RELATIVE: the medians are taken within the set
# of actors passed in, so the same absolute result can land in a different quadrant on a different
# platform. Callers must therefore pass one platform's actors at a time.
#
# This file exists because the rule is now read off in three places (the map, the source catalogue
# and the "Moj medij" lookup). A copied median split that drifts would let two pages of the same
# site call the same outlet by two different names.

DIGIKAT_TYPOLOGY <- c("Divovi", "Graditelji zajednica", "Megafoni", "Specijalizirani akteri")

# df needs total_interactions and total_reach. Returns one label per row.
digikat_classify_typology <- function(df) {
  mi <- stats::median(df$total_interactions, na.rm = TRUE)
  mr <- stats::median(df$total_reach, na.rm = TRUE)
  hi_i <- df$total_interactions >= mi
  hi_r <- df$total_reach >= mr
  ifelse(hi_i & hi_r, "Divovi",
  ifelse(hi_i & !hi_r, "Graditelji zajednica",
  ifelse(!hi_i & hi_r, "Megafoni", "Specijalizirani akteri")))
}

# Reader-visible gloss for each archetype, in the site's Croatian.
DIGIKAT_TYPOLOGY_READ <- c(
  "Divovi"                 = "visok doseg i visok angažman — među vodećim akterima ekosustava.",
  "Graditelji zajednica"   = "nizak doseg uz vrlo visok angažman — gradi dubok odnos s vjernom publikom.",
  "Megafoni"               = "visok doseg uz nizak angažman — sadržaj doseže široku publiku bez intenzivne interakcije.",
  "Specijalizirani akteri" = "umjeren doseg i angažman — usmjeren na užu, specifičnu publiku."
)

# Editorial label vocabulary from resources/dictionaries/source_labels.csv. The labels are the PI's
# proposals, not measurements; every surface must present them as indicative.
DIGIKAT_LABEL_HR <- c(confessional = "konfesionalni izvor", secular = "sekularni izvor",
                      other = "ostalo")

# FROM values that are not actors at all. Shared with pages/mapa/evolucija.qmd.
DIGIKAT_NON_ACTOR_FROM <- c(".", "anonymous_user")
