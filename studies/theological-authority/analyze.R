# Standalone descriptive reanalysis. Run from the repository root with Rscript --vanilla.
# The input and shared repository outputs are read-only.
invisible(Sys.setlocale('LC_CTYPE','English_United States.utf8'))
suppressPackageStartupMessages({library(data.table);library(jsonlite);library(digest)})
setDTthreads(4L)
source('R/lib/digikat_paths.R',encoding='UTF-8')
source('studies/catholic-influencers/actor_classification.R',encoding='UTF-8')
source('R/lib/thematic_dictionaries.R',encoding='UTF-8')
out <- 'studies/theological-authority/output'
priv <- file.path(out,'private')
dir.create(priv,recursive=TRUE,showWarnings=FALSE)
say <- function(x) {cat(format(Sys.time(),'%H:%M:%S'),x,'\n');flush.console()}
input <- digikat_legacy_master_path()
input_hash <- digest(file=input,algo='sha256',serialize=FALSE)
say('Reading the available local snapshot')
d <- as.data.table(readRDS(input))
raw_rows <- nrow(d)
d[, date := as.IDate(DATE)]
stopifnot(!anyNA(d$date))
date_range <- as.character(range(d$date))
stored_year_disagreements <- sum(d$year != as.integer(format(d$date,'%Y')),na.rm=TRUE)
d <- d[date >= '2021-01-01' & date <= '2025-12-31']
pre_dedup <- nrow(d)
# Collapse repeated captures with the same platform and exact URL, keeping the
# maximum recorded interaction snapshot. Missing URLs do not form a duplicate group.
d[, input_order := .I]
d[, observed := is.finite(INTERACTIONS) & INTERACTIONS >= 0]
d[, duplicate_key := fifelse(!is.na(URL) & nzchar(trimws(URL)),
 paste(SOURCE_TYPE,trimws(URL),sep='|'),paste0('missing-url-',input_order))]
setorderv(d,c('duplicate_key','observed','INTERACTIONS','input_order'),c(1,-1,-1,1),na.last=TRUE)
d <- d[!duplicated(duplicate_key)]
setorder(d,input_order)
duplicates_removed <- pre_dedup-nrow(d)

# Reuse selected pure definitions from the shared engine; do not execute its pipeline.
engine_path <- 'explorations/_okvir_engine/okvir_lib.R'
needed <- c('normalise_key','official_pattern','independent_pattern','creator_pattern')
found <- character()
for (expr in parse(engine_path,encoding='UTF-8')) {
 if (is.call(expr) && identical(expr[[1]],as.name('<-')) && is.symbol(expr[[2]]) &&
     as.character(expr[[2]]) %in% needed) {
   eval(expr);found <- c(found,as.character(expr[[2]]))
 }
}
stopifnot(setequal(needed,found))
registry <- fread('explorations/okvir-katolicanstva-prototype/source-groups.csv',encoding='UTF-8')
registry[,key:=normalise_key(from)]
labels <- fread('resources/dictionaries/source_labels.csv',encoding='UTF-8')
labels[,key:=normalise_key(from)]
labels <- unique(labels,by='key')
stopifnot(!anyDuplicated(registry$key))
d[,key:=normalise_key(FROM)]
d[is.na(key)|key=='',key:='[unknown]']
# Only the already documented within-platform duplicate alias is combined.
alias <- labels[kind=='duplicate' & !is.na(entity) & nzchar(entity),.(key,target=normalise_key(entity))]
if(nrow(alias)) d[alias,on='key',key:=i.target]
d[,source_id:=paste(SOURCE_TYPE,key,sep='::')]
s <- unique(d[,.(source_id,SOURCE_TYPE,key)])
s[,source:=d$FROM[match(source_id,d$source_id)]]
s[,catalogue:=labels$label[match(key,labels$key)]]
s[,catalogue_kind:=labels$kind[match(key,labels$key)]]
s[,actor:='public']
s[,rule:='unclassified']
s[catalogue=='confessional',`:=`(actor='creator',rule='catalogue_confessional')]
s[catalogue=='secular',rule:='catalogue_secular']
s[grepl(creator_pattern,key,perl=TRUE),`:=`(actor='creator',rule='creator_pattern')]
s[grepl(independent_pattern,key,perl=TRUE),`:=`(actor='independent',rule='independent_pattern')]
s[grepl(official_pattern,key,perl=TRUE),`:=`(actor='official',rule='institution_pattern')]
legacy <- rbindlist(lapply(s$key,function(k)as.data.table(classify_actor_source(k,has_social=TRUE))))
s[,legacy_type:=legacy$actor_type]
s[,legacy_confidence:=legacy$confidence]
s[actor=='public' & legacy_type=='Independent Media',`:=`(actor='independent',rule='inherited_media_list')]
s[actor=='public' & legacy_type %in% c('Institutional Official','Diocesan','Religious Orders','Academic'),
 `:=`(actor='official',rule='inherited_institution_list')]
s[actor=='public' & legacy_type %in% c('Individual Priests','Charismatic Communities','Youth Organizations','Lay Influencers'),
 `:=`(actor='creator',rule='inherited_creator_list')]
s[catalogue_kind %in% c('noise','offtopic'),`:=`(actor='public',rule='catalogue_exclusion')]
s[registry,on='key',`:=`(actor=i.actor_group,rule='existing_registry')]
s[,group:=fcase(actor=='official','church_org',actor=='independent','independent',actor=='creator','devotional',default='public')]
media_pattern <- 'hkm|(^|[.])ika[.]|informativna katoli|hkr|katolički radio|glas.?koncila|kršćanska.?sadašnjost|krscanska.?sadasnjost|^ks[.]hr$|svjetlo.?rije|svjetlo.?riječ|tjednik|nedjelja.?ba|veritas[.]hr|ktabkbih|živo.?vrelo'
s[actor=='official' & grepl(media_pattern,key,perl=TRUE),group:='church_media']
s[actor=='creator' & legacy_type %in% c('Charismatic Communities','Youth Organizations'),group:='community']
s[actor=='creator' & (legacy_type=='Individual Priests'|key=='pulherissimus'),group:='clergy']
# An explicit note in the reused registry identifies this as inter-Christian,
# not a Catholic publisher. Keep it visible as a boundary case, outside the core.
s[key=='novizivot.net',group:='other_christian']
s[,confidence:=fcase(rule=='existing_registry','registry',rule=='catalogue_confessional','catalogue',
 grepl('inherited',rule)&legacy_confidence=='high','inherited_list',default='pattern')]
s[,core:=!group %in% c('public','other_christian')]
group_labels <- c(church_media='Crkveni mediji',church_org='Crkvene ustanove i računi',
 independent='Neovisni katolički mediji',clergy='Svećenički profili',
 community='Zajednice i udruge',devotional='Pobožni i autorski kanali',
 other_christian='Ostali kršćanski izvori',public='Ostali i nerazvrstani izvori')
s[,group_label:=unname(group_labels[group])]
stopifnot(!anyDuplicated(s$source_id))
d[s,on='source_id',`:=`(group=i.group,core=i.core,rule=i.rule)]
stopifnot(!anyNA(d$group),nrow(d)==pre_dedup-duplicates_removed)
d[,sentiment:=fifelse(AUTO_SENTIMENT %in% c('negative','neutral','positive'),AUTO_SENTIMENT,'unknown')]
d[,year_calc:=as.integer(format(date,'%Y'))]
d[,interactions:=fifelse(observed,INTERACTIONS,NA_real_)]
summarize <- function(z) z[,.(posts=.N,sources=uniqueN(source_id),observed=sum(observed),
 interactions=sum(interactions,na.rm=TRUE),mean=if(any(observed))mean(interactions,na.rm=TRUE) else NA_real_,
 median=if(any(observed))median(interactions,na.rm=TRUE) else NA_real_)]
by_group <- d[,summarize(.SD),by=group]
by_group[,label:=unname(group_labels[group])]
by_platform <- d[,summarize(.SD),by=SOURCE_TYPE]
group_platform <- d[core==TRUE,summarize(.SD),by=.(group,SOURCE_TYPE)]
by_source <- d[,.(posts=.N,observed=sum(observed),interactions=sum(interactions,na.rm=TRUE),
 mean=if(any(observed))mean(interactions,na.rm=TRUE) else NA_real_,
 median=if(any(observed))median(interactions,na.rm=TRUE) else NA_real_,
 largest_post=if(any(observed))max(interactions,na.rm=TRUE) else NA_real_,
 date_first=as.character(min(date)),date_last=as.character(max(date)),
 active_months=uniqueN(format(date,'%Y-%m')),posts_2025=sum(year_calc==2025),
 interactions_2025=sum(interactions[year_calc==2025],na.rm=TRUE)),by=source_id]
by_source <- merge(by_source,s,by='source_id',sort=FALSE)
by_source[,coverage:=observed/posts]
setorder(by_source,-interactions,source_id)
core_sources <- copy(by_source[core==TRUE & observed>0])
core_sources[,rank:=seq_len(.N)]
core_sources[,platform_rank:=seq_len(.N),by=SOURCE_TYPE]
core_sources[,share:=interactions/sum(interactions)]
core_sources[,cumulative_share:=cumsum(share)]
core_sources[,largest_post_share:=largest_post/pmax(interactions,1)]
social <- copy(core_sources[SOURCE_TYPE %in% c('facebook','youtube','instagram','twitter','tiktok')])
social[,social_rank:=seq_len(.N)]
fwrite(by_source,file.path(priv,'all_sources.csv'),bom=TRUE)
fwrite(head(core_sources,50),file.path(priv,'top50_all_platforms.csv'),bom=TRUE)
fwrite(head(social,50),file.path(priv,'top50_social.csv'),bom=TRUE)
fwrite(core_sources[platform_rank<=50],file.path(priv,'top50_by_platform.csv'),bom=TRUE)

conc <- function(x) {
 x <- sort(x,decreasing=TRUE);n<-length(x);tot<-sum(x)
 data.table(sources=n,interactions=tot,top1=if(tot>0)sum(head(x,1))/tot else NA_real_,
 top5=if(tot>0)sum(head(x,5))/tot else NA_real_,top10=if(tot>0)sum(head(x,10))/tot else NA_real_,
 top50=if(tot>0)sum(head(x,50))/tot else NA_real_,
 gini=if(tot>0)(2*sum(seq_len(n)*sort(x))/(n*tot)-(n+1)/n) else NA_real_)
}
concentration <- core_sources[,conc(interactions),by=SOURCE_TYPE]
lorenz <- core_sources[,.(rank=seq_len(.N),cum=cumsum(interactions)/sum(interactions)),by=SOURCE_TYPE]
all_concentration <- conc(core_sources$interactions)
social_concentration <- conc(social$interactions)
sent <- d[core==TRUE & SOURCE_TYPE %in% c('facebook','youtube','web'),summarize(.SD),by=.(SOURCE_TYPE,group,sentiment)]
sent_2025 <- d[core==TRUE & year_calc==2025 & SOURCE_TYPE %in% c('facebook','youtube','web'),summarize(.SD),by=.(SOURCE_TYPE,group,sentiment)]
# Same-source comparisons reduce the obvious source-composition problem without a model.
within <- d[core==TRUE & observed & sentiment %in% c('negative','neutral') & SOURCE_TYPE %in% c('facebook','youtube','web'),
 .(n=.N,avg=mean(interactions),med=median(interactions)),by=.(source_id,SOURCE_TYPE,group,sentiment)]
w <- dcast(within,source_id+SOURCE_TYPE+group~sentiment,value.var=c('n','avg','med'))
w <- w[!is.na(n_negative)&!is.na(n_neutral)&n_negative>=5 & n_neutral>=5]
within_summary <- w[,.(sources=.N,median_mean_difference=median(avg_negative-avg_neutral),
 share_negative_higher=mean(avg_negative>avg_neutral)),by=.(SOURCE_TYPE,group)]

# Lightweight thematic signals from the existing 16-category dictionary.
# A word-initial stem match in the first 3,000 characters is a retrieval proxy,
# not a judgment of theological interpretation. Denominator: posts with text.
say('Computing dictionary signals on the selected communicator set')
thematic <- d[core==TRUE & !is.na(FULL_TEXT)&nzchar(trimws(FULL_TEXT)),
 .(source_id,group,text=tolower(substr(FULL_TEXT,1,3000)))]
theme_keys <- c('DUHOVNOST_I_LITURGIJA','TEOLOGIJA_I_DOKTRINA','POLITIKA_I_ODNOS_S_DRZAVOM','UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE')
themes <- rbindlist(lapply(theme_keys,function(k){
 stems <- digikat_thematic_dictionaries[[k]]
 pattern <- paste0('(?<![[:alpha:]])(?:',paste(stems,collapse='|'),')')
 hit <- grepl(pattern,thematic$text,perl=TRUE)
 thematic[,.(posts=.N,hits=sum(hit[.I])),by=group][,theme:=k]
}))
themes[,share:=hits/posts]

# Available metric components: these are checked, not silently equated across platforms.
metric_audit <- d[,.(posts=.N,interaction_available=sum(observed),
 views_available=sum(!is.na(VIEW_COUNT)),likes_available=sum(!is.na(LIKE_COUNT)),
 comments_available=sum(!is.na(COMMENT_COUNT)),shares_available=sum(!is.na(SHARE_COUNT)),
 equal_likes_comments=sum(observed & !is.na(LIKE_COUNT)&!is.na(COMMENT_COUNT)&INTERACTIONS==LIKE_COUNT+COMMENT_COUNT,na.rm=TRUE),
 comparable_likes_comments=sum(observed&!is.na(LIKE_COUNT)&!is.na(COMMENT_COUNT)),
 equal_likes_comments_shares=sum(observed & !is.na(LIKE_COUNT)&!is.na(COMMENT_COUNT)&!is.na(SHARE_COUNT)&INTERACTIONS==LIKE_COUNT+COMMENT_COUNT+SHARE_COUNT,na.rm=TRUE),
 comparable_likes_comments_shares=sum(observed&!is.na(LIKE_COUNT)&!is.na(COMMENT_COUNT)&!is.na(SHARE_COUNT))),by=SOURCE_TYPE]
classification_coverage <- d[core==TRUE,.(posts=.N,interactions=sum(interactions,na.rm=TRUE),sources=uniqueN(source_id)),by=rule]
monthly <- d[,.(posts=.N),by=.(month=format(date,'%Y-%m'),data_source)]
excluded_2026 <- raw_rows-pre_dedup
core_summary <- summarize(d[core==TRUE])
main_summary <- summarize(d)
stopifnot(sum(by_group$posts)==nrow(d),sum(by_source$posts)==nrow(d),
 abs(sum(by_source$interactions)-sum(d$interactions,na.rm=TRUE))<.01,
 abs(sum(core_sources$interactions)-core_summary$interactions)<.01,
 nrow(head(social,50))==50,all(themes$share>=0&themes$share<=1))
results <- list(input=list(path=input,sha256=input_hash,raw_rows=raw_rows,date_range=date_range,
 main_period=c('2021-01-01','2025-12-31'),excluded_outside_period=excluded_2026,
 duplicate_captures_removed=duplicates_removed,stored_year_disagreements=stored_year_disagreements,
 source_unit='platform plus normalized source label; one inherited duplicate alias merged'),
 main=main_summary,core=core_summary,group_labels=as.list(group_labels),
 actor_groups=by_group,platforms=by_platform,group_platform=group_platform,
 all_concentration=all_concentration,social_concentration=social_concentration,
 concentration=concentration,lorenz=lorenz,sentiment=sent,sentiment_2025=sent_2025,
 within_source=within_summary,themes=themes,metric_audit=metric_audit,
 classification_coverage=classification_coverage,monthly=monthly,
 top_sources=head(core_sources,50),top_social=head(social,50),
 noncatholic_boundary=by_source[group=='other_christian'],
 versions=list(R=as.character(getRversion()),data_table=as.character(packageVersion('data.table')),
 jsonlite=as.character(packageVersion('jsonlite')),digest=as.character(packageVersion('digest'))),
 resource_hashes=lapply(c('studies/catholic-influencers/actor_classification.R',engine_path,
 'explorations/okvir-katolicanstva-prototype/source-groups.csv','resources/dictionaries/source_labels.csv',
 'R/lib/thematic_dictionaries.R'),function(p)list(path=p,sha256=digest(file=p,algo='sha256',serialize=FALSE))))
write_json(results,file.path(priv,'results.json'),pretty=TRUE,auto_unbox=TRUE,na='null',digits=12)
for(n in c('actor_groups','platforms','group_platform','concentration','sentiment','sentiment_2025','within_source','themes','metric_audit','classification_coverage','monthly'))
 fwrite(results[[n]],file.path(out,paste0(n,'.csv')),bom=TRUE)
write_json(results[c('input','main','core','versions','resource_hashes')],file.path(out,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,digits=12)
say('Finished. All identities remain in output/private.')
print(by_group)
print(all_concentration)
print(metric_audit)
