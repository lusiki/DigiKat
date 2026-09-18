source("R/lib/digikat_utils.R", encoding="UTF-8")
source("R/lib/barometar_engine.R", encoding="UTF-8")
source("R/lib/barometar_metrics.R", encoding="UTF-8")
source("studies/demokrscanstvo-barometar/00_readiness.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/07_bridge.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/08_aggregate.R",encoding="UTF-8")

barometar_sample <- function() {
  root <- tempfile("barometar-synthetic-"); dir.create(root)
  root <- normalizePath(root,winslash="/",mustWork=TRUE)
  if(!startsWith(root,paste0(normalizePath(tempdir(),winslash="/"),"/")))stop("Sample output escaped tempdir().")
  days <- seq(as.Date("2020-12-28"),as.Date("2026-09-10"),by="day")
  panel <- sprintf("izmisljeni-%02d",1:12)
  rows <- data.frame(day=as.character(days),outlet_id=panel[(seq_along(days)-1L)%%12L+1L])
  recent <- expand.grid(day=as.character(tail(days,100)),outlet_id=panel,stringsAsFactors=FALSE)
  rows <- unique(rbind(rows,recent)); rows <- rows[order(rows$day,rows$outlet_id),]
  sentences <- c("Stranka se poziva na demokršćanska načela.",
    "To nema veze s demokršćanstvom.",
    "Njemački demokršćani (CDU/CSU) pobijedili su na izborima.",
    "U skladu sa socijalnim naukom Crkve, Vlada bi trebala povisiti minimalnu plaću.",
    "Zastupnik, pozivajući se na kršćansku etiku, brani ljudsko dostojanstvo i solidarnost u prijedlogu mirovinske reforme.",
    "Ministar govori o solidarnosti u mirovinskom sustavu.",
    "Personalizirana ponuda za vašu obitelj.",
    "Danas je održana izložba izmišljenih predmeta u izmišljenome gradu.")
  expected <- list("A1","A1","A2","B","C",character(),character(),character())
  # Sparse positives plus deliberate zero runs. Label expectations are fixture
  # facts, separate from the classifier output being tested.
  kind <- rep(8L,nrow(rows)); probes <- seq(1L,nrow(rows),by=17L)
  kind[probes] <- (seq_along(probes)-1L)%%7L+1L
  filler <- paste(rep("Ovo je izmišljeni dodatak za provjeru duljine teksta.",5L),collapse=" ")
  bodies <- paste(sentences,filler)
  definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
  predictions <- lapply(bodies,function(body)barometar_classify("Izmišljeni naslov",body,definition))
  for(i in seq_along(expected)) {
    if(!setequal(predictions[[i]]$routes,expected[[i]]))stop("Synthetic fixture route mismatch: ",i)
  }
  rows$case_id <- kind
  rows$SOURCE_TYPE <- "web"
  rows$SOURCE_BATCH <- ifelse(rows$day<"2024-04-01","luka_opce","mediaspace_full")
  rows$DATE <- rows$day; rows$DATETIME <- paste(rows$day,"12:00:00")
  rows$ITEM_ID <- seq_len(nrow(rows))
  rows$FROM <- paste0(rows$outlet_id,".example.invalid")
  rows$URL <- paste0("https://",rows$FROM,"/clanak/",rows$ITEM_ID)
  rows$TITLE <- "Izmišljeni naslov"
  rows$FULL_TEXT <- paste(rows$TITLE,bodies[rows$case_id])
  outage <- rows$day>="2024-01-09" & rows$day<="2024-03-31"
  rows$FULL_TEXT[outage] <- NA_character_
  # Exact January double-load, removed by canonical article identity.
  duplicates <- rows[rows$day>="2021-01-01" & rows$day<="2021-01-20",]
  # Rejected rows exercise real body/URL eligibility, including a title-only
  # item whose full field is long enough until its prefix is removed.
  rejected <- rows[head(which(rows$day>="2021-01-01"),3L),];rejected$ITEM_ID <- max(rows$ITEM_ID)+seq_len(3L)
  rejected$URL <- paste0("https://",rejected$FROM,"/rejected/",rejected$ITEM_ID)
  rejected$FULL_TEXT[1L] <- "Kratko izmišljeno tijelo."
  rejected$TITLE[2L] <- strrep("Izmišljeni naslov ",20L);rejected$FULL_TEXT[2L] <- rejected$TITLE[2L]
  rejected$URL[3L] <- paste0("https://",rejected$FROM[3L],"/")
  raw <- rbind(rows,duplicates,rejected)
  schema <- barometar_expected_schema()
  for(name in setdiff(names(schema),names(raw)))raw[[name]] <- switch(schema[[name]],
    BOOLEAN=NA,DOUBLE=NA_real_,BIGINT=NA_real_,TIMESTAMP=as.POSIXct(NA),NA_character_)
  raw$DATETIME <- as.POSIXct(raw$DATETIME,tz="UTC");raw <- raw[names(schema)]
  data.table::fwrite(raw,file.path(root,"barometar_sample.csv.gz"),bom=FALSE,eol="\n",compress="gzip")
  database <- file.path(root,"synthetic.duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(),dbdir=database)
  DBI::dbExecute(con,paste0("CREATE TABLE media_data_all (",paste(paste(DBI::dbQuoteIdentifier(con,names(schema)),schema),collapse=","),")"))
  DBI::dbAppendTable(con,"media_data_all",raw)
  old_columns <- setdiff(names(schema),c("ITEM_ID","SOURCE_BATCH","I_FILTERED"))
  DBI::dbExecute(con,paste0("CREATE TABLE media_data AS SELECT ",paste(DBI::dbQuoteIdentifier(con,old_columns),collapse=","),
    " FROM media_data_all WHERE SOURCE_BATCH='luka_opce'"))
  actual_schema <- DBI::dbGetQuery(con,"DESCRIBE media_data_all")
  stopifnot(identical(setNames(actual_schema$column_type,actual_schema$column_name),schema))
  counts <- DBI::dbGetQuery(con,'SELECT "DATE" AS day, COUNT(*) AS N, COUNT(FULL_TEXT) AS text_n FROM media_data_all GROUP BY 1 ORDER BY 1')
  DBI::dbDisconnect(con,shutdown=TRUE)
  # Only the invented fixture's timestamp is adjusted; the production quiet-
  # writer safeguard remains active on every real database.
  Sys.setFileTime(database,Sys.time()-600)
  days_frame <- data.frame(day=counts$day,observed=counts$text_n/counts$N>=.9)
  days_frame <- days_frame[days_frame$day>="2021-01-01",]
  registry <- data.frame(outlet_id=panel,from_values=paste0(panel,".example.invalid"),url_hosts=paste0(panel,".example.invalid"))
  old_fingerprint <- barometar_bridge_fingerprint(database,"main.media_data","old",end="2024-03-31")
  old <- barometar_bridge_population(database,"main.media_data","old",registry,data.frame(outlet_id=panel),definition,
    file.path(root,"old"),old_fingerprint,start="2021-01-01",end="2024-03-31")
  new_fingerprint <- barometar_bridge_fingerprint(database,"main.media_data_all","new",end="2026-09-10")
  new <- barometar_bridge_population(database,"main.media_data_all","new",registry,data.frame(outlet_id=panel),definition,
    file.path(root,"new"),new_fingerprint,start="2024-04-01",end="2026-09-10")
  eligible <- rbind(old$rows,new$rows)
  expected_rows <- rows[rows$day>="2021-01-01" & !outage,]
  expected_rows$article_hash <- vapply(paste(expected_rows$outlet_id,barometar_canonicalize_url(expected_rows$URL),sep="|"),digest::digest,character(1L),algo="md5",serialize=FALSE)
  stopifnot(nrow(eligible)==nrow(expected_rows),setequal(eligible$article_hash,expected_rows$article_hash))
  expected_cases <- expected_rows$case_id[match(eligible$article_hash,expected_rows$article_hash)]
  for(i in seq_len(nrow(eligible)))stopifnot(setequal(stringi::stri_split_fixed(eligible$route_set[i],";",omit_empty=TRUE)[[1L]],expected[[expected_cases[i]]]))
  facts <- lapply(c("siri","uze"),function(scope) {
    matched <- vapply(stringi::stri_split_fixed(eligible$route_set,";"),function(routes)any((if(scope=="uze")"A1" else c("A1","B","C")) %in% routes),logical(1L))
    data.frame(day=eligible$day,outlet_id=eligible$outlet_id,scope=scope,N=1L,D=as.integer(matched))
  })
  daily <- do.call(rbind,facts)
  versions <- list(panel_version="synthetic_panel",definition_version=definition$definition_version,release_version="synthetic")
  denominator <- aggregate(N~day+outlet_id,daily[daily$scope=="siri",],sum)
  panel_frame <- data.frame(outlet_id=panel,display_name=paste("Izmišljeni medij",seq_along(panel)),
    outlet_domain=paste0(panel,".example.invalid"),segment=rep(c("national","regional","confessional","political_portal"),length.out=length(panel)))
  series <- barometar_build_tables(denominator,eligible,days_frame,panel_frame,versions,c("A1","B","C"),
    theme_labels=definition$documents[["domain_themes.yaml"]]$labels)
  monthly <- series$monthly
  weekly <- series$weekly
  stopifnot(all(monthly$visibility_status[monthly$period_id %in% c("2024-02","2024-03")]=="unavailable"),
    all(weekly$visibility_status[weekly$period_id=="2020-W53"]!="published"),
    max(monthly$period_id[monthly$visibility_status=="published" & monthly$breadth_status=="published"])=="2026-08",
    max(weekly$period_id[weekly$visibility_status=="published" & weekly$breadth_status=="published"])=="2026-W36",
    sum(daily$D[daily$scope=="uze"])==sum(expected_cases %in% c(1L,2L)))
  validation <- list(release_scope="siri",accepted_routes=c("A1","B","C"),human_validation_complete=FALSE,
    validation=data.frame(route=character(),stratum=character(),n=integer(),k=integer(),precision=numeric(),lo=numeric(),hi=numeric(),
      kappa=numeric(),definition_version=character(),coder_type=character()))
  summary <- barometar_release_summary(series,versions,days_frame,panel_frame,validation,synthetic=TRUE)
  summary$notice <- "SINTETIČKI PODACI";summary$rows <- nrow(raw);summary$deduplicated_eligible_rows <- nrow(eligible)
  summary$source_columns <- length(schema)
  release_dir <- file.path(root,"release")
  barometar_write_release(series,summary,definition,validation,
    data.frame(scope=character(),ratio=numeric(),lo=numeric(),hi=numeric(),break_policy=character()),release_dir)
  cat("Synthetic source-to-series checks passed: ",nrow(raw)," invented rows / ",length(schema)," source columns; actual eligibility, canonical deduplication, monthly masking, classification and aggregation; tempdir only.\n",sep="")
  invisible(list(directory=release_dir,summary=summary,series=series,definition=definition))
}
