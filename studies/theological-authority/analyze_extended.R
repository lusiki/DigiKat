# Twenty-page extension. Source the established analysis; never rewrite input data.
invisible(Sys.setlocale('LC_CTYPE','English_United States.utf8'))
source('studies/theological-authority/analyze.R',encoding='UTF-8')
ext <- file.path(out,'extended')
ep <- file.path(priv,'extended')
dir.create(ext,recursive=TRUE,showWarnings=FALSE)
dir.create(ep,recursive=TRUE,showWarnings=FALSE)
supported <- c('web','facebook','youtube','instagram','tiktok','twitter')
d[,metric_supported:=SOURCE_TYPE %in% supported]
d[,reach:=fifelse(metric_supported & is.finite(REACH)&REACH>=0,REACH,NA_real_)]
d[,views:=fifelse(SOURCE_TYPE %in% c('youtube','tiktok','instagram') & is.finite(VIEW_COUNT)&VIEW_COUNT>=0,VIEW_COUNT,NA_real_)]
d[metric_supported==FALSE,interactions:=NA_real_]
d[,has_text:=!is.na(FULL_TEXT)&nzchar(trimws(FULL_TEXT))]
d[,month:=format(date,'%Y-%m')]
safe_sum <- function(x) if(all(is.na(x))) NA_real_ else sum(x,na.rm=TRUE)
safe_mean <- function(x) if(all(is.na(x))) NA_real_ else mean(x,na.rm=TRUE)
safe_med <- function(x) if(all(is.na(x))) NA_real_ else median(x,na.rm=TRUE)
ms <- function(z) z[,.(posts=.N,sources=if('source_id' %in% names(z))uniqueN(source_id) else 1L,
 interaction_n=sum(!is.na(interactions)),interactions=safe_sum(interactions),
 interaction_mean=safe_mean(interactions),interaction_median=safe_med(interactions),
 reach_n=sum(!is.na(reach)),reach_total=safe_sum(reach),reach_mean=safe_mean(reach),reach_median=safe_med(reach),
 reach_zero_n=sum(reach==0,na.rm=TRUE),views_n=sum(!is.na(views)),views_total=safe_sum(views),
 text_n=sum(has_text),months=uniqueN(format(date,'%Y-%m')),first=as.character(min(date)),last=as.character(max(date)))]
scope_metrics <- function(z,by_cols) rbindlist(list(
 z[,ms(.SD),by=by_cols][,scope:='all'],
 z[core==TRUE,ms(.SD),by=by_cols][,scope:='selected']))
platform_ext <- scope_metrics(d,'SOURCE_TYPE')
group_ext <- d[core==TRUE,ms(.SD),by=group]
gp_ext <- d[core==TRUE,ms(.SD),by=.(SOURCE_TYPE,group)]
annual_ext <- scope_metrics(d,c('SOURCE_TYPE','year_calc'))
annual_groups <- d[core==TRUE,ms(.SD),by=.(SOURCE_TYPE,year_calc,group)]
monthly_ext <- scope_metrics(d,c('SOURCE_TYPE','month'))
monthly_origin <- d[,.(posts=.N,selected_posts=sum(core),text_n=sum(has_text)),by=.(month,data_source)]
setorder(monthly_origin,month,data_source)
annual_all <- scope_metrics(d,'year_calc')
reach_raw_audit <- d[,.(posts=.N,raw_reach_n=sum(!is.na(REACH)),raw_reach_nonzero=sum(REACH>0,na.rm=TRUE),
 raw_interaction_n=sum(!is.na(INTERACTIONS)),raw_interaction_nonzero=sum(INTERACTIONS>0,na.rm=TRUE),
 raw_view_n=sum(!is.na(VIEW_COUNT)),raw_view_nonzero=sum(VIEW_COUNT>0,na.rm=TRUE)),by=SOURCE_TYPE]
source_ext <- d[core==TRUE,ms(.SD),by=source_id]
source_ext <- merge(source_ext,s[,.(source_id,source,SOURCE_TYPE,group,group_label,rule,confidence)],by='source_id',sort=FALSE)
source_ext[,reach_coverage:=reach_n/posts]
source_ext[,interaction_coverage:=interaction_n/posts]
setorderv(source_ext,c('interactions','source_id'),c(-1,1),na.last=TRUE)
source_ext[,`:=`(rank=NA_integer_,platform_rank=NA_integer_)]
source_ext[interaction_n>0,rank:=seq_len(.N)]
source_ext[interaction_n>0,platform_rank:=seq_len(.N),by=SOURCE_TYPE]
source_ext[,reach_rank:=frank(-reach_total,ties.method='min',na.last='keep'),by=SOURCE_TYPE]
sy <- d[core==TRUE,ms(.SD),by=.(source_id,SOURCE_TYPE,year_calc)]
setorderv(sy,c('year_calc','interactions','source_id'),c(1,-1,1),na.last=TRUE)
sy[,`:=`(year_rank=NA_integer_,platform_year_rank=NA_integer_)]
sy[interaction_n>0,year_rank:=seq_len(.N),by=year_calc]
sy[interaction_n>0,platform_year_rank:=seq_len(.N),by=.(year_calc,SOURCE_TYPE)]
source_ext[sy[year_calc==2025],on='source_id',`:=`(rank_2025=i.year_rank,platform_rank_2025=i.platform_year_rank,
 posts_2025=i.posts,interactions_2025=i.interactions,reach_2025=i.reach_total)]
rank_overlap <- data.table(full_top50=50,year2025_top50=50,overlap=length(intersect(head(source_ext$source_id,50),sy[year_calc==2025 & year_rank<=50,source_id])))
# Matched seasonal comparison after collection changed. No inferential tests.
co <- d[core==TRUE & ((date>='2024-07-01'&date<='2024-12-31')|(date>='2025-07-01'&date<='2025-12-31'))]
co[,period:=paste0(year_calc,'H2')]
cm <- co[,ms(.SD),by=.(source_id,SOURCE_TYPE,group,period)]
eligible <- cm[posts>=5,.(periods=uniqueN(period)),by=source_id][periods==2,source_id]
matched <- co[source_id %in% eligible]
matched_summary <- matched[,ms(.SD),by=.(SOURCE_TYPE,period)]
unmatched_summary <- co[,ms(.SD),by=.(SOURCE_TYPE,period)]
sw <- dcast(cm[source_id %in% eligible],source_id+SOURCE_TYPE+group~period,value.var=c('posts','interaction_mean','reach_mean'))
source_changes <- sw[,.(sources=.N,
 mean_interaction_change_median=median(interaction_mean_2025H2-interaction_mean_2024H2,na.rm=TRUE),
 interaction_increase_share=mean(interaction_mean_2025H2>interaction_mean_2024H2,na.rm=TRUE),
 mean_reach_change_median=median(reach_mean_2025H2-reach_mean_2024H2,na.rm=TRUE),
 reach_increase_share=mean(reach_mean_2025H2>reach_mean_2024H2,na.rm=TRUE)),by=SOURCE_TYPE]
cohort_origin <- matched[,.(posts=.N),by=.(period,data_source)]
# Single-label groups can be dominated by one publishing channel.
group_concentration <- source_ext[interaction_n>0,.(sources=.N,total=sum(interactions),
 top1_share=max(interactions)/sum(interactions),top5_share=sum(head(sort(interactions,decreasing=TRUE),5))/sum(interactions)),by=group]
classification_ext <- source_ext[,.(sources=.N,posts=sum(posts),interactions=sum(interactions,na.rm=TRUE),reach=safe_sum(reach_total)),by=.(rule,confidence)]
allmonths <- format(seq(as.Date('2021-01-01'),as.Date('2025-12-01'),by='month'),'%Y-%m')
missing_months <- setdiff(allmonths,unique(d$month))
period_origin <- d[,.(posts=.N,first=as.character(min(date)),last=as.character(max(date))),by=data_source]
metric_flags <- d[,.(negative_reach=sum(REACH<0,na.rm=TRUE),infinite_reach=sum(!is.na(REACH)&!is.finite(REACH)),
 reach_equals_views=sum(!is.na(reach)&!is.na(views)&reach==views),reach_and_views=sum(!is.na(reach)&!is.na(views))),by=SOURCE_TYPE]
# Existing public artifacts: inspect schema and provenance, not reuse their totals.
pm <- fromJSON('data/processed/manifest.json')
public_schema <- rbindlist(lapply(names(pm$outputs),function(n){
 p<-file.path('data/processed',pm$outputs[[n]]$file);a<-readRDS(p)
 data.table(file=basename(p),rows=nrow(a),columns=paste(names(a),collapse=' | '),
 hash_matches=identical(digest(file=p,algo='sha256',serialize=FALSE),pm$outputs[[n]]$sha256))
}))
res_ext <- list(platform=platform_ext,groups=group_ext,group_platform=gp_ext,annual=annual_ext,
 annual_groups=annual_groups,annual_all=annual_all,monthly=monthly_ext,monthly_origin=monthly_origin,
 raw_metrics=reach_raw_audit,source_ranking=source_ext,source_year=sy[year_rank<=50],
 rank_overlap=rank_overlap,cohort_matched=matched_summary,cohort_all=unmatched_summary,
 cohort_source_changes=source_changes,cohort_origin=cohort_origin,group_concentration=group_concentration,
 classification=classification_ext,missing_months=missing_months,period_origin=period_origin,
 metric_flags=metric_flags,public_schema=public_schema)
stopifnot(sum(platform_ext[scope=='all',posts])==nrow(d),
 sum(platform_ext[scope=='selected',posts])==core_summary$posts,
 abs(sum(platform_ext[scope=='selected',interactions],na.rm=TRUE)-core_summary$interactions)<.01,
 abs(sum(source_ext$reach_total,na.rm=TRUE)-sum(d[core==TRUE,reach],na.rm=TRUE))<.01,
 all(source_ext$reach_coverage>=0&source_ext$reach_coverage<=1),
 all(platform_ext[!SOURCE_TYPE %in% supported,is.na(interactions)&is.na(reach_total)]),
 all(source_ext[interaction_n>0,interactions]==sort(source_ext[interaction_n>0,interactions],decreasing=TRUE)),
 identical(head(source_ext[interaction_n>0,source_id],50),head(core_sources$source_id,50)),
 identical(source_ext[interaction_n>0,rank],seq_len(nrow(core_sources))),
 all(source_ext[interaction_n==0,is.na(rank)&is.na(platform_rank)]))
public_names <- setdiff(names(res_ext),c('source_ranking','source_year','missing_months'))
for(n in public_names) fwrite(res_ext[[n]],file.path(ext,paste0(n,'.csv')),bom=TRUE,na='NA')
for(n in c('source_ranking','source_year')) fwrite(res_ext[[n]],file.path(ep,paste0(n,'.csv')),bom=TRUE,na='NA')
top_ext <- head(source_ext[interaction_n>0],50)
top_ext[,`:=`(institutional_mandate=NA_character_,theological_education=NA_character_,authority_invoked=NA_character_,research_notes=NA_character_)]
fwrite(top_ext,file.path(ep,'top-50-izvora.csv'),sep=';',bom=TRUE,na='')
fwrite(source_ext[interaction_n>0 & platform_rank<=50],file.path(ep,'top-50-po-platformama.csv'),sep=';',bom=TRUE,na='')
fwrite(head(source_ext[interaction_n>0 & SOURCE_TYPE!='web'],50),file.path(ep,'top-50-drustvene-mreze.csv'),sep=';',bom=TRUE,na='')
write_json(res_ext,file.path(ep,'results.json'),pretty=TRUE,auto_unbox=TRUE,na='null',digits=12)
write_json(list(input=results$input,versions=results$versions,resource_hashes=results$resource_hashes,
 generated=as.character(Sys.time()),missing_months=missing_months,period_origin=period_origin,
 metric_notes=c('REACH is recorded estimated reach, not unique audience. Sums are not deduplicated people.',
 'Unsupported forum/reddit/comment metrics are NA, never zero. Views are separate.',
 'Within-platform source ranks; combined engagement ranking is only a retrieval list.',
 'Matched cohort: >=5 captured posts per source in both July-December 2024 and 2025.'),
 public_reference_corpus=pm$corpus),file.path(ext,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,na='null',digits=12)
say('Extension complete')
source('studies/theological-authority/workbook_tables.R', encoding='UTF-8')
print(platform_ext[scope=='selected'])
print(matched_summary)
print(source_changes)
print(rank_overlap)
