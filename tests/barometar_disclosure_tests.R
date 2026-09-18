source("R/lib/barometar_disclosure.R",encoding="UTF-8")
stopifnot(length(barometar_public_inspect(list(outer=list(text="invented")))$issues)>0L,
  length(barometar_public_inspect(list(label_hr="https://example.invalid/article"))$issues)>0L,
  length(barometar_public_inspect(list(label_hr="C:/Users/example/private"))$issues)>0L,
  !length(barometar_public_inspect(list(label_hr="Izmišljeni primjer",total_articles=100))$issues))
invented <- "Ovo je potpuno izmišljena rečenica namijenjena provjeri javnoga sadržaja."
stopifnot(length(barometar_text_overlap(invented,paste("Uvod",invented,"Zaključak")))>0L,
  !length(barometar_text_overlap(invented,"Ovo je potpuno druga izmišljena rečenica.")))
cat("Barometer nested disclosure and eight-token overlap checks passed.\n")

# Independent scalar reference protects token order, short strings, Unicode
# normalization, punctuation and cached public grams in the vectorized scan.
scalar_overlap <- function(public,private,n) {
  grams <- barometar_public_ngrams(public,n)
  found <- character()
  for(text in private[!is.na(private)]) {
    tokens <- stringi::stri_extract_all_regex(stringi::stri_trans_tolower(stringi::stri_trans_nfc(text),"hr"),"[\\p{L}\\p{M}\\p{N}]+",omit_no_match=TRUE)[[1L]]
    if(length(tokens)<n)next
    possible <- vapply(seq_len(length(tokens)-n+1L),function(i)paste(tokens[i:(i+n-1L)],collapse=" "),character(1L))
    found <- union(found,intersect(grams,possible))
  }
  found
}
set.seed(192026)
vocabulary <- c("riječ","misao","oblik","čovjek","život","7","A","načelo","test")
private <- c(NA_character_,"", "kratko",replicate(50,paste(sample(vocabulary,80,replace=TRUE),collapse=" · ")),
  stringi::stri_trans_nfd(invented),toupper(invented))
public <- c(invented,private[c(8,19,29)])
for(n in c(1L,2L,8L,12L)) {
  expected <- scalar_overlap(public,private,n)
  stopifnot(setequal(barometar_text_overlap(public,private,n),expected),
    setequal(barometar_text_overlap(public,private,n,barometar_public_ngrams(public,n)),expected))
}
cat("PASS: vectorized and cached overlap scan matches scalar reference on invented cases.\n")
