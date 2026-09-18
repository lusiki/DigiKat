# Study-local product boundary, applied after the unchanged shared URL key.
# Evidence: quality_reports/2026-09-18_barometar-outlet-review.md (MojTV).
# Movie/programme/schedule/forum records are not editorial news articles.
barometar_outlet_url_policy <- function(canonical_url) {
  host <- stringi::stri_match_first_regex(canonical_url,"^https?://([^/?:]+)")[,2L]
  mojtv <- !is.na(host) & host=="mojtv.hr"
  key <- canonical_url
  reason <- rep(NA_character_,length(key))
  if(any(mojtv)) {
    desktop <- stringi::stri_match_first_regex(key[mojtv],"^https://mojtv\\.hr/magazin/([0-9]+)/[^/?]+\\.aspx$")[,2L]
    mobile <- stringi::stri_match_first_regex(key[mojtv],"^https://mojtv\\.hr/m2/magazin/clanak\\.aspx\\?id=([0-9]+)$")[,2L]
    ids <- ifelse(!is.na(desktop),desktop,mobile)
    i <- which(mojtv)
    good <- !is.na(ids)
    key[i[good]] <- paste0("https://mojtv.hr/magazin/",ids[good])
    reason[i[!good]] <- "mojtv_non_news_product"
  }
  list(article_url_key=key,noneditorial_reason=reason)
}
