# Public artifact checks, including nested JSON values. No database dependency.
barometar_public_inspect <- function(object, origin="artifact") {
  blocked <- c("url","urls","title","description","text","full_text","raw_text",
    "body","content","excerpt","context","window","quote","caption","doc_key",
    "article_hash","item_id","author_id","username","email","phone")
  issues <- character(); strings <- character()
  walk <- function(value,path) {
    keys <- names(value)
    risky <- intersect(tolower(keys),blocked)
    if(length(risky))issues <<- c(issues,paste0(path,": blocked fields: ",paste(risky,collapse=", ")))
    if(is.list(value)) {
      for(i in seq_along(value))walk(value[[i]],paste0(path,"/",if(length(keys)&&nzchar(keys[i]))keys[i] else i))
    } else if(is.character(value)) {
      good <- value[!is.na(value)]
      strings <<- c(strings,good)
      if(any(stringi::stri_detect_regex(good,"(?i)https?://|www\\.")))issues <<- c(issues,paste0(path,": external URL value"))
      if(any(stringi::stri_detect_regex(good,"(?i)(?:[A-Z]:[\\\\/]|/Users/|/home/|\\\\\\\\[^\\\\]+\\\\)")))issues <<- c(issues,paste0(path,": private filesystem path"))
    }
  }
  walk(object,origin)
  list(issues=unique(issues),strings=unique(strings))
}

barometar_public_ngrams <- function(strings,n=8L) {
  grams <- unlist(lapply(strings,function(value) {
    tokens <- stringi::stri_extract_all_regex(stringi::stri_trans_tolower(stringi::stri_trans_nfc(value),"hr"),"[\\p{L}\\p{M}\\p{N}]+",omit_no_match=TRUE)[[1L]]
    if(length(tokens)<n)return(character())
    vapply(seq_len(length(tokens)-n+1L),function(i)paste(tokens[i:(i+n-1L)],collapse=" "),character(1L))
  }),use.names=FALSE)
  unique(grams)
}

# Return public phrases only; never return or log private article passages.
barometar_text_overlap <- function(public_strings,private_texts,n=8L,public_ngrams=NULL) {
  grams <- if(is.null(public_ngrams))barometar_public_ngrams(public_strings,n) else public_ngrams
  if(!length(grams))return(character())
  first <- unique(stringi::stri_extract_first_regex(grams,"^[^ ]+"))
  found <- character()
  for(value in private_texts[!is.na(private_texts)]) {
    tokens <- stringi::stri_extract_all_regex(stringi::stri_trans_tolower(stringi::stri_trans_nfc(value),"hr"),"[\\p{L}\\p{M}\\p{N}]+",omit_no_match=TRUE)[[1L]]
    at <- which(tokens %in% first & seq_along(tokens)<=length(tokens)-n+1L)
    if(length(at)) {
      # Vectorize the exact same consecutive-token join in ICU; avoid one R
      # closure invocation for each candidate position in a long article.
      shifted <- lapply(seq_len(n)-1L,function(offset)tokens[at+offset])
      possible <- do.call(stringi::stri_join,c(shifted,list(sep=" ")))
      found <- union(found,intersect(grams,possible))
    }
  }
  found
}
