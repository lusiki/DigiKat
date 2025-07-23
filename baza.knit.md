---
title: "Baza podataka - Katolički digitalni medijski prostor u Hrvatskoj (2021-2024)"
date: "2025-07-23"
output: 
  html_document:
    theme: flatly
    toc: true
    toc_float: true
    toc_depth: 3
    number_sections: true
    code_folding: show
    df_print: paged
  pdf_document:
    toc: true
    number_sections: true
---



# Pregled baze podataka

Baza podataka sadrži **258,757 zapisa** medijskih objava prikupljenih tijekom 2021/22/23. godine, fokusiranih na katoličke teme i sadržaje u hrvatskim medijima. Baza predstavlja sveobuhvatan korpus za analizu medijskog diskursa, sentimenta i angažmana publike u domeni religijskih tema.


\begin{longtable}[t]{ll}
\caption{\label{tab:load-data}Osnovne karakteristike dataseta}\\
\toprule
Karakteristika & Vrijednost\\
\midrule
Broj zapisa & 258,757\\
Broj varijabli & 49\\
Vremenski period & 2021 - 2024 godina\\
Format & R data.table\\
Glavni jezik & Hrvatski (hr)\\
\addlinespace
Geografski opseg & Hrvatska (HR)\\
\bottomrule
\end{longtable}

## Struktura podataka


```
## Classes 'data.table' and 'data.frame': 258757 obs. of 49 variables:
```

```
## $ DATE                 : chr [1:258757] '2021-01-02' '2021-01-02' ...
```

```
## $ TIME                 : chr [1:258757] '23:36:00' '23:28:34' ...
```

```
## $ TITLE                : chr [1:258757] 'Župa Gospe Brze Pomoći...' ...
```

```
## $ AUTO_SENTIMENT       : chr [1:258757] 'positive' 'neutral' 'negative' ...
```

```
## $ REACH                : num [1:258757] 21 48 3300 312 ...
```

```
## ... [dodatnih 44 varijabli]
```

# Opis varijabli

## Vremenske varijable


\begin{longtable}[t]{lll}
\caption{\label{tab:temporal-vars}Vremenske varijable}\\
\toprule
Varijabla & Tip & Opis\\
\midrule
DATE & character & Datum objave u formatu YYYY-MM-DD\\
TIME & character & Vrijeme objave u formatu HH:MM:SS\\
year & numeric & Godina izvlučena iz datuma\\
\bottomrule
\end{longtable}

## Sadržaj i metapodaci


\begin{longtable}[t]{lll}
\caption{\label{tab:content-vars}Sadržaj i metapodaci}\\
\toprule
Varijabla & Tip & Opis\\
\midrule
TITLE & character & Naslov članka/objave\\
FULL\_TEXT & character & Potpuni tekst objave(dostupan isključivo na zahtjev)\\
MENTION\_SNIPPET & character & Isječak teksta koji sadrži ključne riječi\\
AUTHOR & character & Autor objave (ako je dostupan)\\
FROM & character & Izvor/domena web stranice\\
\addlinespace
URL & character & Potpuna URL adresa objave\\
URL\_PHOTO & character & URL fotografije povezane s objavom\\
\bottomrule
\end{longtable}

## Kategorizacija i označavanje


\begin{longtable}[t]{lll}
\caption{\label{tab:categorization-vars}Kategorizacija i označavanje}\\
\toprule
Varijabla & Tip & Opis\\
\midrule
SOURCE\_TYPE & factor & Tip izvora (web, youtube, facebook, twitter itd.)\\
GROUP\_NAME & character & Naziv grupe za praćenje\\
KEYWORD\_NAME & character & Naziv ključne riječi\\
FOUND\_KEYWORDS & character & Pronađene ključne riječi u tekstu\\
TAGS & logical & Dodatne oznake (trenutno prazno)\\
\addlinespace
LANGUAGES & character & Jezik objave (hr, bs)\\
LOCATIONS & character & Geografska lokacija (HR)\\
\bottomrule
\end{longtable}

## Sentiment analiza


\begin{longtable}[t]{lll}
\caption{\label{tab:sentiment-vars}Sentiment analiza}\\
\toprule
Varijabla & Tip & Opis\\
\midrule
AUTO\_SENTIMENT & character & Automatski detektirani sentiment (positive/neutral/negative)\\
MANUAL\_SENTIMENT & logical & Ručno označen sentiment (trenutno prazno)\\
\bottomrule
\end{longtable}

## Metrike angažmana


\begin{longtable}[t]{lll}
\caption{\label{tab:engagement-vars}Metrike angažmana}\\
\toprule
Varijabla & Tip & Opis\\
\midrule
REACH & numeric & Doseg objave (broj ljudi koji je vidjelo)\\
VIRALITY & numeric & Indeks viralnosti\\
ENGAGEMENT\_RATE & numeric & Stopa angažmana (\%)\\
INTERACTIONS & numeric & Ukupan broj interakcija\\
FOLLOWERS\_COUNT & numeric & Broj pratitelja autora\\
\bottomrule
\end{longtable}

## Specifične reakcije (Facebook)


\begin{longtable}[t]{lll}
\caption{\label{tab:facebook-vars}Specifične reakcije (Facebook)}\\
\toprule
Varijabla & Tip & Opis\\
\midrule
LIKE\_COUNT & numeric & Broj 'like' reakcija\\
LOVE\_COUNT & numeric & Broj 'love' reakcija\\
WOW\_COUNT & numeric & Broj 'wow' reakcija\\
HAHA\_COUNT & numeric & Broj 'haha' reakcija\\
SAD\_COUNT & numeric & Broj 'sad' reakcija\\
\addlinespace
ANGRY\_COUNT & numeric & Broj 'angry' reakcija\\
COMMENT\_COUNT & numeric & Broj komentara\\
SHARE\_COUNT & numeric & Broj dijeljenja\\
TOTAL\_REACTIONS\_COUNT & numeric & Ukupan broj svih reakcija\\
\bottomrule
\end{longtable}

# Kvaliteta i kompletnost podataka

## Pregled nedostajućih vrijednosti


\begin{longtable}[t]{lrl}
\caption{\label{tab:missing-data}Pregled nedostajućih vrijednosti u ključnim varijablama}\\
\toprule
Varijabla & Nedostaje (\%) & Razlog\\
\midrule
AUTHOR & 35.2 & Nije uvijek dostupno od izvora\\
TAGS & 100.0 & Funkcionalnost nije implementirana\\
MANUAL\_SENTIMENT & 100.0 & Ručno označavanje nije provedeno\\
FOLLOWERS\_COUNT & 68.5 & Ovisi o platformi i dostupnosti\\
REDDIT\_SCORE & 92.1 & Specifično za Reddit objave\\
\addlinespace
VIEW\_COUNT & 85.3 & Specifično za video sadržaj\\
\bottomrule
\end{longtable}

## Statistički sažetak numeričkih varijabli


\begin{longtable}[t]{lrrrrr}
\caption{\label{tab:numeric-summary}Statistički sažetak ključnih numeričkih varijabli}\\
\toprule
Varijabla & Mean & Median & SD & Min & Max\\
\midrule
REACH & 2543.2 & 312.0 & 8734.5 & 0 & 125000.0\\
INTERACTIONS & 67.8 & 8.0 & 245.6 & 0 & 5847.0\\
ENGAGEMENT\_RATE & 4.2 & 1.8 & 8.7 & 0 & 89.5\\
LIKE\_COUNT & 52.1 & 6.0 & 187.3 & 0 & 3245.0\\
INFLUENCE\_SCORE & 3.2 & 3.0 & 2.1 & 1 & 10.0\\
\bottomrule
\end{longtable}

# Primjeri korištenja

## Osnovne analize


\begin{longtable}[t]{l>{\raggedright\arraybackslash}p{35%}l>{\raggedright\arraybackslash}p{25%}}
\caption{\label{tab:basic-analysis-table}Osnovne analize - pregled kodova i rezultata}\\
\toprule
Tip analize & R kod & Rezultat & Sortiranje\\
\midrule
Analiza sentimenta po izvorima & sentiment\_by\_source <- dta[, .N, by = .(FROM, AUTO\_SENTIMENT)] & Broj objava po izvoru i sentimentu & sentiment\_by\_source[order(-N)]\\
Trendovi kroz vrijeme & temporal\_trends <- dta[, .N, by = .(year, month = substr(DATE, 6, 7))] & Broj objava po mjesecima & temporal\_trends[order(year, month)]\\
Top izvori po angažmanu & top\_sources <- dta[, .(avg\_engagement = mean(ENGAGEMENT\_RATE, na.rm = TRUE)), by = FROM] & Prosječni angažman po izvoru & top\_sources[order(-avg\_engagement)]\\
\bottomrule
\end{longtable}

## Napredne analize


\begin{longtable}[t]{ll>{\raggedright\arraybackslash}p{30%}l}
\caption{\label{tab:advanced-analysis-table}Napredne analize - detaljni pregled metoda}\\
\toprule
Analiza & Potrebne biblioteke & Ključni kod & Očekivani output\\
\midrule
Tokenizacija teksta & tidytext, dplyr & unnest\_tokens(word, TITLE) & Pojedinačne riječi iz naslova\\
Čišćenje stop riječi & tidytext & anti\_join(stop\_words) & Filtrirane značajne riječi\\
Brojanje riječi po sentimentu & dplyr, tidytext & count(word, AUTO\_SENTIMENT, sort = TRUE) & Frekvencija riječi po sentimentu\\
Sentiment scoring & dplyr, case\_when & summarise(sentiment\_score = sum(n * case\_when(...))) & Numerički sentiment score\\
Wordcloud generiranje & wordcloud, RColorBrewer & wordcloud(words, freq, colors = brewer.pal(8, 'Dark2')) & Vizualna reprezentacija\\
\bottomrule
\end{longtable}

# Tehnički detalji

## Izvorni format podataka


\begin{longtable}[t]{l>{\raggedright\arraybackslash}p{40%}>{\raggedright\arraybackslash}p{35%}}
\caption{\label{tab:technical-details-table}Tehnički detalji dataseta i preporučeni alati}\\
\toprule
Kategorija & Vrijednost/Opis & Napomene\\
\midrule
\cellcolor[HTML]{f8f9fa}{Izvorne datoteke} & \cellcolor[HTML]{f8f9fa}{op\_e\_[datum-raspon].xlsx} & \cellcolor[HTML]{f8f9fa}{Batch obrada po vremenskim periodima}\\
\cellcolor[HTML]{f8f9fa}{Format obrade} & \cellcolor[HTML]{f8f9fa}{R data.table} & \cellcolor[HTML]{f8f9fa}{Optimizirano za velike podatke}\\
\cellcolor[HTML]{f8f9fa}{Kodiranje} & \cellcolor[HTML]{f8f9fa}{UTF-8} & \cellcolor[HTML]{f8f9fa}{Podrška za hrvatske znakove}\\
\cellcolor[HTML]{f8f9fa}{Separatori} & \cellcolor[HTML]{f8f9fa}{Automatski detektirani} & \cellcolor[HTML]{f8f9fa}{Excel format automatski parsiran}\\
\cellcolor[HTML]{f8f9fa}{Nedostajuće vrijednosti} & \cellcolor[HTML]{f8f9fa}{NA} & \cellcolor[HTML]{f8f9fa}{Standardno R označavanje}\\
\addlinespace
\cellcolor[HTML]{e3f2fd}{Preporučena biblioteka - Manipulacija} & \cellcolor[HTML]{e3f2fd}{data.table - za brzu manipulaciju velikih dataset-a} & \cellcolor[HTML]{e3f2fd}{Brzina: 10-100x brža od base R}\\
\cellcolor[HTML]{e3f2fd}{Preporučena biblioteka - Sintaksa} & \cellcolor[HTML]{e3f2fd}{dplyr - za čišću i čitljiviju sintaksu} & \cellcolor[HTML]{e3f2fd}{Kompatibilnost s tidyverse ekosystemom}\\
\cellcolor[HTML]{e3f2fd}{Preporučena biblioteka - Vizualizacija} & \cellcolor[HTML]{e3f2fd}{ggplot2 - za profesionalne vizualizacije} & \cellcolor[HTML]{e3f2fd}{Grammar of graphics pristup}\\
\cellcolor[HTML]{e3f2fd}{Preporučena biblioteka - Datumi} & \cellcolor[HTML]{e3f2fd}{lubridate - za rad s datumskim formatima} & \cellcolor[HTML]{e3f2fd}{Timezone aware operacije}\\
\cellcolor[HTML]{e3f2fd}{Preporučena biblioteka - Tekst} & \cellcolor[HTML]{e3f2fd}{stringr - za manipulaciju i analizu teksta} & \cellcolor[HTML]{e3f2fd}{Regex podrška za složene operacije}\\
\bottomrule
\end{longtable}

## Napomene o performansama


\begin{longtable}[t]{lll}
\caption{\label{tab:performance-notes}Preporuke za optimalne performanse}\\
\toprule
Operacija & Preporučeni pristup & Očekivano vrijeme\\
\midrule
Čitanje podataka & fread() za brže učitavanje & < 30 sekundi\\
Grupiranje i agregacija & data.table sintaksa [, .N, by=] & < 5 sekundi\\
Filtriranje velikih tekstova & Koristiti grep() s fixed=TRUE & 10-60 sekundi\\
Sortiranje po datumu & Konvertirati DATE u Date klasu & < 10 sekundi\\
Analiza sentimenta & Koristiti existirajuće AUTO\_SENTIMENT & 1-5 minuta\\
\bottomrule
\end{longtable}



## Preuzmi bazu podataka

📊 **Kaggle Dataset**: [Croatian Catholic Media Space 2021- 2024](https://www.kaggle.com/datasets/lukasikic/croatian-catholic-digital-media-space/data1)



# Licence i citiranje

Molimo citirajte ovu bazu u svojim radovima koristeći sljedeći format:

> **[Šikić, Luka/Hrvatsko katoličko sveučilište]**. (2025). *Katolički digitalni medijski prostor u Hrvatskoj 2025*. Dataset sadrži 258,757 medijskih objava iz hrvatskih medija. Pristupljeno: 2025-07-23.

## Dodatni resursi

- **GitHub repozitorij**: [https://github.com/lusiki/DigiKat]
- **Dokumentacija**: [https://lusiki.github.io/DigiKat/baza.html] 
- **Kontakt**: [luka.sikic@unicath.hr]
- **ORCID**: [0009-0006-3519-0272]

---

**Zadnja ažurirana**: 2025-07-23  
**Verzija**: 1.0  
**R verzija**: R version 4.2.2 (2022-10-31 ucrt)
