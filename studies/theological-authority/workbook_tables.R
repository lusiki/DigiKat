# Complete source exports. Called after analyze_extended.R has prepared d and s.
source_summary <- function(z) z[, .(posts=.N, interaction_n=sum(!is.na(interactions)),
 interaction_coverage=mean(!is.na(interactions)), total_interactions=safe_sum(interactions),
 mean_interactions=safe_mean(interactions), median_interactions=safe_med(interactions),
 first_observed=as.character(min(date)), last_observed=as.character(max(date)),
 months_observed=uniqueN(format(date,'%Y-%m')))]
source_metadata <- s[,.(source_id,source,platform=SOURCE_TYPE,actor_group=group,
 classification_rule=rule,classification_confidence=confidence)]
stopifnot(!anyDuplicated(source_metadata$source_id))
complete_sources <- function(annual=FALSE) {
 by <- c('source_id','SOURCE_TYPE',if(annual)'year_calc')
 ans <- rbindlist(lapply(c('all','selected'),function(sc) {
   z <- if(sc=='all') d else d[core==TRUE]
   z[,source_summary(.SD),by=by][,scope:=sc]
 }))
 setnames(ans,'SOURCE_TYPE','platform')
 if(annual) setnames(ans,'year_calc','year') else ans[,period:='2021–2025']
 n <- nrow(ans)
 ans <- merge(ans,source_metadata,by=c('source_id','platform'),sort=FALSE)
 stopifnot(nrow(ans)==n,!anyDuplicated(ans[,c('scope','source_id',if(annual)'year'),with=FALSE]))
 context <- c('scope','platform',if(annual)'year')
 setorderv(ans,c(context,'total_interactions','source_id'),c(rep(1,length(context)),-1,1),na.last=TRUE)
 rank_col <- if(annual)'platform_year_rank' else 'platform_rank'
 share_col <- if(annual)'platform_year_share' else 'platform_share'
 ans[,(rank_col):=NA_integer_]
 ans[interaction_n>0,(rank_col):=seq_len(.N),by=context]
 ans[,(share_col):={den<-safe_sum(total_interactions);if(is.na(den)||den==0) NA_real_ else total_interactions/den},by=context]
 setcolorder(ans,c('scope','source_id','source','platform',if(annual)'year' else 'period',
   'actor_group','classification_rule','classification_confidence'))
 ans[]
}
source_year_all <- complete_sources(TRUE)
source_overall_all <- complete_sources(FALSE)
shortlist <- copy(source_overall_all[scope=='selected' & interaction_n>0])
setorderv(shortlist,c('total_interactions','source_id'),c(-1,1))
shortlist <- head(shortlist,50)[,selection_rank:=seq_len(.N)]
annual_leaders <- source_year_all[!is.na(platform_year_rank)&platform_year_rank<=50]
history <- merge(CJ(source_id=shortlist$source_id,year=2021:2025),
 source_year_all[scope=='selected'],by=c('source_id','year'),all.x=TRUE,sort=FALSE)
history[is.na(scope),`:=`(scope='selected',posts=0L,interaction_n=0L,months_observed=0L)]
for(col in c('source','platform','actor_group','classification_rule','classification_confidence'))
 history[is.na(get(col)),(col):=source_metadata[[col]][match(source_id,source_metadata$source_id)]]
history[,capture_status:=fifelse(posts==0,'Nema zabilježenih objava','Zabilježene objave')]
history[,selection_rank:=shortlist$selection_rank[match(source_id,shortlist$source_id)]]
setorder(history,selection_rank,year)
flow <- data.table(scope=c('all','all','all','selected'),
 stage=c('Ulazni zapisi','Odabrani prozor 2021.–2025.','Nakon obrade duplikata','Odabrane skupine'),
 posts=c(raw_rows,pre_dedup,nrow(d),sum(d$core)))
coverage <- rbindlist(lapply(c('all','selected'),function(sc) {
 z <- if(sc=='all') d else d[core==TRUE]
 a <- z[,source_summary(.SD),by=.(platform=SOURCE_TYPE,year=year_calc)]
 a <- merge(CJ(platform=unique(d$SOURCE_TYPE),year=2021:2025),a,all.x=TRUE)
 a[is.na(posts),`:=`(posts=0L,interaction_n=0L,months_observed=0L)]
 a[,scope:=sc]
}))
actor_year <- rbindlist(lapply(c('all','selected'),function(sc) {
 z <- if(sc=='all') d else d[core==TRUE]
 z[,source_summary(.SD),by=.(platform=SOURCE_TYPE,year=year_calc,actor_group=group)][,scope:=sc]
}))
seasonal <- rbindlist(lapply(c('all','selected'),function(sc) {
 z <- d[format(date,'%m')>='07' & year_calc %in% 2024:2025]
 if(sc=='selected') z <- z[core==TRUE]
 counts <- z[,.N,by=.(source_id,year_calc)]
 ids <- counts[N>=5, .N,by=source_id][N==2,source_id]
 rbindlist(lapply(c('Svi izvori u prozoru','Isti izvori: ≥5 objava u oba prozora'),function(kind) {
  zz <- if(kind=='Svi izvori u prozoru') z else z[source_id %in% ids]
  zz[,source_summary(.SD),by=.(platform=SOURCE_TYPE,year=year_calc)][,`:=`(scope=sc,cohort=kind,period='srpanj–prosinac')]
 }))
}))
# Reconcile at source level, then against the underlying records in each scope.
check <- source_year_all[,.(posts=sum(posts),interaction_n=sum(interaction_n),
 total_interactions=safe_sum(total_interactions)),by=.(scope,source_id)]
check <- merge(check,source_overall_all,by=c('scope','source_id'),suffixes=c('_annual','_overall'))
stopifnot(nrow(check)==nrow(source_overall_all),all(check$posts_annual==check$posts_overall),
 all(check$interaction_n_annual==check$interaction_n_overall),
 isTRUE(all.equal(check$total_interactions_annual,check$total_interactions_overall)),
 nrow(history)==5*nrow(shortlist),!anyDuplicated(history[,.(source_id,year)]),
 all(source_year_all[interaction_n==0,is.na(total_interactions)&is.na(platform_year_rank)&is.na(mean_interactions)&is.na(median_interactions)]),
 all(history[posts==0,is.na(total_interactions)&is.na(platform_year_rank)]))
for(sc in c('all','selected')) {
 z <- if(sc=='all') d else d[core==TRUE]
 stopifnot(sum(source_overall_all[scope==sc,posts])==nrow(z),
 isTRUE(all.equal(sum(source_overall_all[scope==sc,total_interactions],na.rm=TRUE),sum(z$interactions,na.rm=TRUE))))
}
stopifnot(identical(input_hash,digest(file=input,algo='sha256',serialize=FALSE)))
for(n in c('source_year_all','source_overall_all','shortlist','annual_leaders','history'))
 fwrite(get(n),file.path(ep,paste0(n,'.csv')),bom=TRUE,na='NA')
for(n in c('flow','coverage','actor_year','seasonal'))
 fwrite(get(n),file.path(ext,paste0('workbook_',n,'.csv')),bom=TRUE,na='NA')
write_json(list(input=results$input,overall=source_overall_all,annual=source_year_all,
 shortlist=shortlist,leaders=annual_leaders,history=history,flow=flow,coverage=coverage,
 actors=actor_year,seasonal=seasonal,metadata=source_metadata),
 file.path(ep,'workbook_data.json'),auto_unbox=TRUE,na='null',digits=16)
say(sprintf('Workbook tables validated: %s overall rows; %s annual rows.',nrow(source_overall_all),nrow(source_year_all)))
