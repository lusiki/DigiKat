stop=c('biti','jesam','budem','sam','jesi','budeš','si','jesmo','budemo','smo','jeste','budete','ste','jesu','budu','su','bih','bijah','bjeh','bijaše','bi','bje','bješe','bijasmo','bismo','bjesmo','bijaste','biste','bjeste','bijahu','biste','bjeste','bijahu','bi','biše','bjehu','bješe','bio','bili','budimo','budite','bila','bilo','bile','ću','ćeš','će','ćemo','ćete','želim','želiš','želi','želimo','želite','žele','moram','moraš','mora','moramo','morate','moraju','trebam','trebaš','treba','trebamo','trebate','trebaju','mogu','možeš','može','možemo','možete')



istakniSlogotvornoR <- function(niz) {
  stringr::str_replace_all(niz, "(^|[^aeiou])r($|[^aeiou])", "\\1R\\2")
}

imaSamoglasnik <- function(niz) {
  !is.na(stringr::str_detect(istakniSlogotvornoR(niz), "[aeiouR]"))
}

transformiraj <- function(pojavnica) {
  for(i in 1:nrow(transformacije)) {
    trazi <- transformacije[i, 1]
    zamijeni <- transformacije[i, 2]
    if (endsWith(pojavnica, trazi)) {
      return(sub(paste0(trazi, "$"), zamijeni, pojavnica))
    }
  }
  return(pojavnica)
}

korjenuj <- function(pojavnica) {
  for(pravilo in pravila) {
    dioba <- stringr::str_match(pojavnica, pravilo)
    if (!is.na(dioba[2])) {
      if (imaSamoglasnik(dioba[2]) && nchar(dioba[2]) > 1) {
        return(dioba[2])
      }
    }
  }
  return(pojavnica)
}



pravila <- lapply(strsplit(trimws(readLines('C:/Users/Lukas/Dropbox/HKS/Projekti/Dezinformacije/CatholiqDezinfo/rules.txt')), ' '), function(x) paste0('^(', x[1], ')(', x[2], ')$'))
transformacije <- as.data.frame(do.call(rbind, strsplit(trimws(readLines('C:/Users/Lukas/Dropbox/HKS/Projekti/Dezinformacije/CatholiqDezinfo/transformations.txt')), '\t')))


#text <- n_tokenTidy$word %>% head(1000)
#text <- tolower(readLines(input_file))


#tokens <- unlist(stringi::stri_extract_all_words(text))

write_tokens <- function(token) {
  if (token %in% stop) {
    return(paste0(token, '\t', token))
  } else {
    return(paste0(token, '\t', korjenuj(transformiraj(token))))
  }
}
