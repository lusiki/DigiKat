Sys.setlocale('LC_CTYPE', 'English_United States.utf8')
source('R/lib/digikat_paths.R', encoding='UTF-8')
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(jsonlite))
Sys.setlocale('LC_CTYPE', 'English_United States.utf8')
p <- digikat_legacy_master_path()
d <- as.data.table(readRDS(p))
out <- 'studies/theological-authority/output'
dir.create(file.path(out,'private'), recursive=TRUE, showWarnings=FALSE)
audit <- list(rows=nrow(d),columns=names(d),classes=lapply(d,class),
 date_range=as.character(range(as.Date(d$DATE),na.rm=TRUE)),
 platform=d[,.N,by=SOURCE_TYPE],
 sentiment=lapply(grep('SENT|EMOT',names(d),value=TRUE), function(n) list(field=n,counts=as.data.frame(table(d[[n]],useNA='always')))),
 metrics=lapply(grep('INTERACT|REACH|LIKE|SHARE|COMMENT|VIEW|ENGAGE|FACEBOOK|YOUTUBE',names(d),value=TRUE),function(n) list(field=n,missing=sum(is.na(d[[n]])),class=class(d[[n]]),summary=capture.output(summary(d[[n]])))))
write_json(audit,file.path(out,'audit.json'),pretty=TRUE,auto_unbox=TRUE)
cat(toJSON(audit,pretty=TRUE,auto_unbox=TRUE))
