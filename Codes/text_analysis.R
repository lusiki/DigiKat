# Text analysis


# read in lexicons
CroSentilex_n <- read.delim("./crosentilex-negatives.txt",
                            header = FALSE,
                            sep = " ",
                            stringsAsFactors = FALSE,
                            fileEncoding = "UTF-8")  %>%
  rename(word = "V1", sentiment = "V2" ) %>%
  mutate(brija = "NEG")

CroSentilex_p  <- read.delim("./crosentilex-positives.txt",
                             header = FALSE,
                             sep = " ",
                             stringsAsFactors = FALSE,
                             fileEncoding = "UTF-8") %>%
  rename(word = "V1", sentiment = "V2" ) %>%
  mutate(brija = "POZ")

Crosentilex_sve <- rbind(setDT(CroSentilex_n), setDT(CroSentilex_p))
# check lexicon data
#head(sample_n(Crosentilex_sve,1000),15)


CroSentilex_Gold  <- read.delim2("./gs-sentiment-annotations.txt",
                                 header = FALSE,
                                 sep = " ",
                                 stringsAsFactors = FALSE) %>%
  rename(word = "V1", sentiment = "V2" )
Encoding(CroSentilex_Gold$word) <- "UTF-8"
CroSentilex_Gold[1,1] <- "dati"
CroSentilex_Gold$sentiment <- str_replace(CroSentilex_Gold$sentiment , "-", "1")
CroSentilex_Gold$sentiment <- str_replace(CroSentilex_Gold$sentiment , "\\+", "2")
CroSentilex_Gold$sentiment <- as.numeric(unlist(CroSentilex_Gold$sentiment))
# check lexicon data
#head(sample_n(CroSentilex_Gold,100),15)


LilaHR  <- read_excel("./lilaHR_clean.xlsx", sheet = "Sheet1") %>% select (-"...1")
LilaHR_long <- read_excel("./lilaHR_clean_long.xlsx", sheet = "Sheet1") %>% select (-"...1")



# Print the long format data
#print(data_long)

#proba <- read.csv2("C:/Users/Lukas/Dropbox/Mislav@Luka/lilaHRcsv.csv", encoding = "UTF-8")
#df <- separate_rows(LilaHR, HR, sep = ", ")
#
# zero_rows_count <- sum(apply(df[-1], 1, function(row) all(row == 0)))
# print(zero_rows_count)
#
# filtered_df <- df %>%
#   filter(!apply(.[,-1], 1, function(row) all(row == 0)))
#
# write.xlsx(filtered_df, "C:/Users/Lukas/Dropbox/Mislav@Luka/lilaHR_.xlsx" )


# create stop words
stopwords_cro <- get_stopwords(language = "hr", source = "stopwords-iso")
# check stopwords data
#head(sample_n(stopwords_cro,100),15)
# extend stop words
my_stop_words <- tibble(
  word = c(
    "jedan","mjera", "može", "možete", "mogu", "kad", "sada", "treba", "ima", "osoba",
    "e","prvi", "dva","dvije","drugi",
    "tri","treći","pet","kod",
    "ove","ova",  "ovo","bez", "kod",
    "evo","oko",  "om", "ek",
    "mil","tko","šest", "sedam",
    "osam",   "čim", "zbog",
    "prema", "dok","zato", "koji",
    "im", "čak","među", "tek",
    "koliko", "tko","kod","poput",
    "baš", "dakle", "osim", "svih",
    "svoju", "odnosno", "gdje",
    "kojoj", "ovi", "toga",
    "ubera", "vozača", "hrvatskoj", "usluge", "godine", "više", "taksi", "taxi", "taksija", "taksija", "kaže", "rekao", "19"," aee", "ae","bit.ly", "https", "one", "the"
  ),
  lexicon = "lux"
)

# full set with diacritics
cro_sw_full_d <- tibble(word = c("a","ako","ali","baš","bez","bi","bih","bila","bili","bilo","bio","bismo","bit","biti","bolje","bude","čak","čega","čemu","često","četiri","čime","čini","će","ćemo","ćete","ću","da","dakle","dalje","dan","dana","dana","danas","dio","do","dobro","dok","dosta","dva","dvije","eto","evo","ga","gdje","god","godina","godine","gotovo","grada","i","iako","ići","ih","ili","im","ima","imaju","imali","imam","imao","imati","inače","ipak","isto","iz","iza","između","ja","jako","je","jedan","jedna","jednog","jednom","jednostavno","jednu","jer","joj","još","ju","ka","kad","kada","kaj","kako","kao","kaže","kod","koja","koje","kojeg","kojeg","kojem","koji","kojih","kojim","kojima","kojoj","kojom","koju","koliko","kraju","kroz","li","malo","manje","me","među","međutim","mene","meni","mi","milijuna","mislim","mjesto","mnogo","mogao","mogli","mogu","moj","mora","možda","može","možemo","možete","mu","na","način","nad","naime","nakon","nam","naravno","nas","ne","neće","nego","neka","neke","neki","nekog","nekoliko","neku","nema","nešto","netko","ni","nije","nikad","nisam","nisu","ništa","niti","no","njih","o","od","odmah","odnosno","oko","on","ona","onda","oni","onih","ono","opet","osim","ova","ovaj","ovdje","ove","ovim","ovo","ovog","ovom","ovu","pa","pak","par","po","pod","poput","posto","postoji","pred","preko","prema","pri","prije","protiv","prvi","puno","put","radi","reći","s","sa","sad","sada","sam","samo","sati","se","sebe","si","smo","ste","stoga","strane","su","svaki","sve","svi","svih","svoj","svoje","svoju","što","ta","tada","taj","tako","također","tamo","te","tek","teško","ti","tih","tijekom","time","tko","to","tog","toga","toj","toliko","tom","tome","treba","tu","u","uopće","upravo","uvijek","uz","vam","vas","već","vi","više","vrijeme","vrlo","za","zapravo","zar","zato","zbog","zna","znači"),
                        lexicon = "boras")


stop_corpus <- my_stop_words %>%
  bind_rows(stopwords_cro)


stop_corpus <- stop_corpus %>%
  bind_rows(cro_sw_full_d)

# check stopwords data
#head(sample_n(st