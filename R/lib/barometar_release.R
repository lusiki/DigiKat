# Pure release calculations. Inputs contain private IDs but outputs never do.
source("R/lib/barometar_metrics.R",encoding="UTF-8")
source("R/lib/barometar_disclosure.R",encoding="UTF-8")

barometar_scope_articles <- function(decisions,routes) {
  sets <- stringi::stri_split_fixed(decisions$route_set,";",omit_empty=TRUE)
  selected <- which(vapply(sets,function(x)any(x %in% routes),logical(1L)))
  result <- decisions[selected,c("doc_key","day","outlet_id","hdz_only"),drop=FALSE]
  columns <- c("route_set","themes","principles","register","reference_geography","speaker_type")
  for(column in columns)result[[column]] <- rep("",nrow(result))
  result$has_church <- rep(FALSE,nrow(result))
  for(j in seq_along(selected)) {
    i <- selected[j]
    facets <- jsonlite::fromJSON(decisions$facet_data[i])
    if(!is.data.frame(facets) || !nrow(facets))stop("Included article has no passage-level facets.")
    facets <- facets[facets$route %in% routes,,drop=FALSE]
    if(!nrow(facets))stop("Included route has no matching facet passage.")
    union_values <- function(x)sort(unique(unlist(stringi::stri_split_fixed(x,";",omit_empty=TRUE))))
    result$route_set[j] <- paste(c(intersect(routes,sets[[i]]),
      if(any(facets$speaker_type=="demokršćanski akter"))"D"),collapse=";")
    for(column in c("themes","principles"))result[[column]][j] <- paste(union_values(facets[[column]]),collapse=";")
    if(!nzchar(result$themes[j]))result$themes[j] <- "unclassified"
    for(column in c("register","reference_geography","speaker_type")) {
      values <- unique(facets[[column]])
      result[[column]][j] <- if(length(values)==1L)values else switch(column,
        register="oba",reference_geography="mješovito",speaker_type="ostalo / nepripisano")
    }
    result$has_church[j] <- any(facets$speaker_type=="crkveni govornik")
  }
  result
}

barometar_daily_facts <- function(denominator,articles,panel_ids,scope) {
  base <- denominator[denominator$outlet_id %in% panel_ids,,drop=FALSE]
  articles <- articles[articles$outlet_id %in% panel_ids,,drop=FALSE]
  if(anyDuplicated(base[c("day","outlet_id")]) || anyNA(base) || !is.numeric(base$N) ||
     any(!is.finite(base$N) | base$N<1 | base$N!=floor(base$N)))stop("Invalid denominator facts.")
  if(nrow(articles)) {
    d <- aggregate(rep(1L,nrow(articles)),articles[c("day","outlet_id")],sum);names(d)[3L] <- "D"
    if(any(!paste(d$day,d$outlet_id) %in% paste(base$day,base$outlet_id)))stop("Positive count outside denominator.")
    base <- merge(base,d,by=c("day","outlet_id"),all.x=TRUE,sort=TRUE)
    base$D[is.na(base$D)] <- 0L
  } else base$D <- rep(0L,nrow(base))
  base$scope <- scope
  base[c("day","outlet_id","scope","N","D")]
}

barometar_build_tables <- function(denominator,decisions,days,panel,versions,accepted_routes,
                                  available_scopes=c("siri","uze"),theme_validation=NULL,
                                  break_policy="not_comparable_seam",theme_labels) {
  if(!all(c("doc_key","day","outlet_id","route_set","facet_data","hdz_only") %in% names(decisions)) ||
     anyDuplicated(decisions$doc_key) || any(!decisions$outlet_id %in% panel$outlet_id))stop("Invalid classified population.")
  if(!all(accepted_routes %in% c("A1","B","C")) || !length(accepted_routes))stop("No accepted routes.")
  if(!length(available_scopes) || any(!available_scopes %in% c("siri","uze")))stop("No publishable scope.")
  if("uze" %in% available_scopes && !"A1" %in% accepted_routes)stop("Narrow scope requires accepted A1.")
  scopes <- setNames(lapply(available_scopes,function(scope)barometar_scope_articles(decisions,
    if(scope=="uze")intersect("A1",accepted_routes) else accepted_routes)),available_scopes)
  daily <- do.call(rbind,lapply(names(scopes),function(scope)barometar_daily_facts(denominator,scopes[[scope]],panel$outlet_id,scope)))
  frequencies <- c("monthly","weekly","rolling28")
  series <- setNames(lapply(frequencies,function(frequency) {
    table <- barometar_aggregate_daily(daily,days,panel$outlet_id,versions,frequency,break_policy)
    table[table$scope %in% available_scopes,,drop=FALSE]
  }),frequencies)
  themes <- composition <- diagnostics <- sensitivity <- concentration <- list()
  facet_values <- list(speaker_type=c("crkveni govornik","demokršćanski akter","drugi politički akter","ostalo / nepripisano"),
    reference_geography=c("domaće","inozemno","EU","mješovito"),register=c("supstancijski","identitarni","oba"),
    outlet_segment=sort(unique(panel$segment)),principles=c("dostojanstvo_osobe","opce_dobro","opca_namjena_dobara","supsidijarnost","sudjelovanje","solidarnost"))
  for(frequency in c("monthly","weekly"))for(scope in names(scopes)) {
    source <- scopes[[scope]]
    source$outlet_segment <- panel$segment[match(source$outlet_id,panel$outlet_id)]
    periods <- series[[frequency]][series[[frequency]]$scope==scope,,drop=FALSE]
    for(i in seq_len(nrow(periods))) {
      period <- periods[i,,drop=FALSE]
      a <- source[source$day>=period$period_start & source$day<=period$period_end,,drop=FALSE]
      base <- data.frame(frequency=frequency,scope=scope,period_id=period$period_id,stringsAsFactors=FALSE)
      by_outlet <- table(a$outlet_id)
      shares <- if(length(by_outlet))as.numeric(by_outlet)/sum(by_outlet) else numeric()
      concentration[[length(concentration)+1L]] <- data.frame(base,
        top10_share=if(length(shares))sum(head(sort(shares,decreasing=TRUE),10L)) else NA_real_,
        hhi=if(length(shares))sum(shares^2) else NA_real_,definition_version=versions$definition_version)
      for(theme in names(theme_labels)) {
        count <- sum(vapply(stringi::stri_split_fixed(a$themes,";"),function(x)theme %in% x,logical(1L)))
        scoped_validation <- theme_validation
        if(!is.null(scoped_validation)) {
          if("scope" %in% names(scoped_validation))scoped_validation <- scoped_validation[scoped_validation$scope==scope,,drop=FALSE]
          else if(scope=="uze")scoped_validation <- scoped_validation[FALSE,,drop=FALSE]
        }
        status <- if(is.null(scoped_validation))"unconfirmed" else scoped_validation$theme_status[match(theme,scoped_validation$theme_id)]
        if(!length(status)||is.na(status))status <- "unconfirmed"
        themes[[length(themes)+1L]] <- data.frame(base,theme_id=theme,theme_label_hr=theme_labels[[theme]],
          articles_with_theme=count,total_articles=period$total_articles,
          rate_per_10000=if(period$visibility_status=="unavailable")NA_real_ else 1e4*count/period$total_articles,
          theme_status=status,period_status=period$visibility_status,
          panel_version=versions$panel_version,definition_version=versions$definition_version,release_version=versions$release_version)
      }
      for(facet in c("route_set",names(facet_values))) {
        values <- if(facet=="route_set")sort(unique(source$route_set)) else facet_values[[facet]]
        for(value in values) {
          count <- if(facet=="principles")sum(vapply(stringi::stri_split_fixed(a[[facet]],";"),function(x)value %in% x,logical(1L))) else sum(a[[facet]]==value)
          composition[[length(composition)+1L]] <- data.frame(base,facet=facet,value=value,articles=count,
            definition_version=versions$definition_version,panel_version=versions$panel_version,release_version=versions$release_version)
        }
      }
      d <- decisions[decisions$day>=period$period_start & decisions$day<=period$period_end,,drop=FALSE]
      for(route in c("A2","A?"))diagnostics[[length(diagnostics)+1L]] <- data.frame(base,diagnostic=route,
        articles=sum(vapply(stringi::stri_split_fixed(d$route_set,";"),function(x)route %in% x,logical(1L))),
        total_articles=period$total_articles,definition_version=versions$definition_version)
    }
  }
  variants <- c("without_confessional","without_political_portals","without_church_speakers","without_registered_HDZ_only")
  for(variant in variants) {
    ids <- panel$outlet_id[if(variant=="without_confessional")panel$segment!="confessional" else if(variant=="without_political_portals")panel$segment!="political_portal" else rep(TRUE,nrow(panel))]
    if(!length(ids))next
    facts <- do.call(rbind,lapply(names(scopes),function(scope) {
      a <- scopes[[scope]]
      if(variant=="without_church_speakers")a <- a[!a$has_church,,drop=FALSE]
      if(variant=="without_registered_HDZ_only")a <- a[!a$hdz_only,,drop=FALSE]
      barometar_daily_facts(denominator,a,ids,scope)
    }))
    for(frequency in c("monthly","weekly")) {
      table <- barometar_aggregate_daily(facts,days,ids,versions,frequency,break_policy)
      table <- table[table$scope %in% available_scopes,,drop=FALSE];table$variant <- variant
      table$filter_basis <- if(variant %in% variants[1:2])"outlet_subset_N_D_P" else "numerator_only_common_N_P"
      sensitivity[[paste(variant,frequency)]] <- table
    }
  }
  outlet_n <- denominator;outlet_n$year <- substr(outlet_n$day,1L,4L)
  outlet_n <- aggregate(N~outlet_id+year,outlet_n,sum)
  outlets <- merge(panel[c("outlet_id","display_name","outlet_domain","segment")],outlet_n,by="outlet_id",all.x=TRUE,sort=TRUE)
  names(outlets)[names(outlets)=="N"] <- "eligible_articles"
  outlets$in_panel <- TRUE;outlets$panel_version <- versions$panel_version
  output <- c(series,list(themes=as.data.frame(data.table::rbindlist(themes)),composition=as.data.frame(data.table::rbindlist(composition)),
    sensitivity=as.data.frame(data.table::rbindlist(sensitivity)),diagnostics=as.data.frame(data.table::rbindlist(diagnostics)),
    concentration=as.data.frame(data.table::rbindlist(concentration)),outlets=outlets))
  for(name in names(output)) {
    issue <- barometar_public_inspect(output[[name]],name)$issues
    if(length(issue))stop(paste(issue,collapse="\n"))
  }
  output
}

barometar_release_summary <- function(tables,versions,days,panel,validation,synthetic=FALSE,break_policy="not_comparable_seam") {
  latest <- function(table,scope) {
    rows <- table[table$scope==scope & table$visibility_status=="published" & table$breadth_status=="published",,drop=FALSE]
    if(!nrow(rows))return(NULL)
    as.list(tail(rows,1L))
  }
  scope <- validation$release_scope
  month <- latest(tables$monthly,scope);week <- latest(tables$weekly,scope)
  if(is.null(month)||is.null(week))stop("No complete publishable default periods.")
  trailing <- tables$rolling28[tables$rolling28$scope==scope & tables$rolling28$period_end==week$period_end &
    tables$rolling28$visibility_status=="published" & tables$rolling28$breadth_status=="published",,drop=FALSE]
  weekly_card <- if(nrow(trailing)==1L)as.list(trailing) else NULL
  bins <- list()
  for(frequency in c("monthly","weekly"))for(s in unique(tables$themes$scope)) {
    values <- tables$themes$rate_per_10000[tables$themes$frequency==frequency & tables$themes$scope==s]
    values <- values[is.finite(values) & values>0]
    bins[[paste(frequency,s,sep="_")]] <- if(length(values))as.numeric(stats::quantile(values,probs=seq(.2,.8,.2),names=FALSE,type=7)) else rep(0,4L)
  }
  c(list(synthetic=synthetic,panel_outlets=nrow(panel),data_through=max(days$day),
    default_scope=scope,available_scopes=unique(tables$monthly$scope),accepted_routes=validation$accepted_routes,
    human_validation_complete=!synthetic && isTRUE(validation$human_validation_complete),
    latest_publishable_month=month$period_id,latest_publishable_week=week$period_id,
    cards=list(monthly=month,weekly=weekly_card),weekly_comparison=week,matrix_bins=bins,break_policy=break_policy,
    annotations=list(list(day="2024-04-01",label_hr="Promjena prikupljanja",kind="seam")),
    findings=list(),computed_at=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC")),versions)
}
