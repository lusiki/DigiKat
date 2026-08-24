# 00_make_synthetic.R — a SYNTHETIC vendor-shaped export to test the pipeline end to end
# before the real Omiš export lands. Nothing produced from it is a finding.
#
# Output: output/synthetic/SYNTHETIC_mentions.csv (49 vendor columns + nothing else)
# Run:    Rscript 00_make_synthetic.R
#
# The generator encodes a PLAUSIBLE diffusion story (locals first, socials next, nationals
# an hour later, officials and foreign media much later; frames drifting from operations to
# casualties to politics to cause to solidarity) purely so that every figure has structure to
# render. Any resemblance to the real event's numbers is coincidence.

setwd(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))))
source("lib.R")
set.seed(20260813)

SYN_DIR <- file.path(OUT_DIR, "synthetic")
dir.create(SYN_DIR, showWarnings = FALSE, recursive = TRUE)

# --- synthetic source registry ---------------------------------------------------------------
src <- rbindlist(list(
  data.table(FROM = c("slobodnadalmacija.hr","dalmacijadanas.hr","dalmatinskiportal.hr","dalmacijanews.hr","morski.hr",
                      "omis-info.hr","makarska-danas.com","radio-split.hr","ferata.hr","sibenik.in","057info.hr","dubrovackidnevnik.hr"),
             SOURCE_TYPE = "web", kind = "lokalni",   w = c(9,8,5,4,4,6,3,3,2,1.5,1.5,1.5), start_h = c(0.4,0.5,0.7,0.9,1.5,0.6,1.2,0.8,1.0,3,4,5)),
  data.table(FROM = c("index.hr","jutarnji.hr","vecernji.hr","24sata.hr","net.hr","tportal.hr","dnevnik.hr","hrt.hr","rtl.hr","telegram.hr","n1info.hr","hina.hr","direktno.hr","dnevno.hr","narod.hr"),
             SOURCE_TYPE = "web", kind = "nacionalni", w = c(12,7,7,9,8,6,6,7,5,3,5,4,3,3,2), start_h = c(1.2,1.6,1.5,1.3,1.4,1.7,1.9,2.2,2.0,3.5,2.6,2.4,4,5,6)),
  data.table(FROM = c("poslovni.hr","novilist.hr","glas-slavonije.hr","zagreb.info","srednja.hr","story.hr","gloria.hr","regionalni.com","032portal.hr","varazdinske-vijesti.hr","istra24.hr","lokalni.hr","kamenjar.com","hkm.hr","laudato.hr"),
             SOURCE_TYPE = "web", kind = "ostali_web", w = c(1,3,2,2,1,1.5,1,1,1,1,1.5,1,1,2,1.5), start_h = c(9,4,8,6,20,14,16,7,10,11,9,12,15,13,14)),
  data.table(FROM = c("vatrogastvo.hr","civilna-zastita.gov.hr","mup.hr","omis.hr","hck.hr"),
             SOURCE_TYPE = "web", kind = "sluzbeni", w = c(3,2,2,2,1.5), start_h = c(2.0,2.5,3.0,1.8,12)),
  data.table(FROM = c("sputnikportal.rs","klix.ba","avaz.ba","blic.rs","24ur.com","index.hu","telex.hu","orf.at","bild.de","bbc.com"),
             SOURCE_TYPE = "web", kind = "strani", w = c(2,3,2,2,2,2,1.5,1,1,0.7), start_h = c(9,8,10,12,11,14,15,20,26,30)),
  data.table(FROM = c("Index.hr","24sata","Slobodna Dalmacija","Dalmacija Danas","Radio Split","Vatrogasci Hrvatske","Omiš Info","Dnevnik.hr","HRT Vijesti","Net.hr"),
             SOURCE_TYPE = "facebook", kind = "drustveni", w = c(8,7,6,6,3,4,4,4,3,3), start_h = c(1.3,1.4,0.7,0.6,0.9,2.2,0.5,2.0,2.5,1.6)),
  data.table(FROM = c("@index_hr","@24sata_HR","@SlobodnaDalmac","@HRTvijesti","@vatrogasci_hr","@N1info","@Bura_Dalmacija"),
             SOURCE_TYPE = "twitter", kind = "drustveni", w = c(3,2,2,2,2,2,3), start_h = c(1.5,1.6,0.9,2.6,2.3,2.8,0.6)),
  data.table(FROM = c("Index Vijesti","HRT","Dalmacija Danas TV","24sata Video"), SOURCE_TYPE = "youtube", kind = "drustveni", w = c(2,2,2,2), start_h = c(6,8,5,7)),
  data.table(FROM = c("forum.hr","reddit.com/r/croatia"), SOURCE_TYPE = c("forum","reddit"), kind = "drustveni", w = c(3,3), start_h = c(1.0,1.2)),
  data.table(FROM = c("index.hr","24sata.hr","jutarnji.hr"), SOURCE_TYPE = "comment", kind = "drustveni", w = c(4,3,2), start_h = c(1.5,1.6,1.9))
))

# --- time intensity: story hours 0..115 -----------------------------------------------------
H_MAX <- 115
lambda <- function(h) {
  # ramp overnight, peak morning of day 1 (h≈12–16), decay half-life ~26 h, bumps on day 2 (politics/DORH) and day 3
  base <- ifelse(h < 0, 0, pmin(1, h / 6) * exp(-pmax(0, h - 14) / 37))
  bump1 <- 0.55 * exp(-((h - 44) / 5)^2)   # day 2 afternoon
  bump2 <- 0.28 * exp(-((h - 68) / 6)^2)   # day 3
  pmax(0, base + bump1 + bump2)
}
N_TOTAL <- 2600
hgrid <- seq(0, H_MAX, by = 0.05)
p_time <- lambda(hgrid); p_time <- p_time / sum(p_time)

# per-source draw: weight × availability after its start hour
draw_items <- function(n) {
  out <- vector("list", n)
  hs <- sample(hgrid, n, replace = TRUE, prob = p_time) + runif(n, 0, 0.05)
  for (i in seq_len(n)) {
    h <- hs[i]
    elig <- src[start_h <= h]
    if (!nrow(elig)) { elig <- src[which.min(start_h)]; h <- elig$start_h + runif(1, 0, 0.3) }
    # foreign & other web relatively more likely later; socials relatively more likely early
    wt <- elig$w * fifelse(elig$kind == "strani", pmin(1, h / 30), 1) *
                   fifelse(elig$kind == "drustveni", 1.35 * exp(-h / 90), 1) *
                   fifelse(elig$kind == "ostali_web", pmin(1, h / 24), 1)
    j <- sample.int(nrow(elig), 1, prob = wt)
    out[[i]] <- data.table(h = h, FROM = elig$FROM[j], SOURCE_TYPE = elig$SOURCE_TYPE[j], kind = elig$kind[j])
  }
  rbindlist(out)
}
it <- draw_items(N_TOTAL)

# --- which fire ---------------------------------------------------------------------------
it[, fire := sample(c("omis","peljesac","dugi_otok","brac"), .N, replace = TRUE, prob = c(0.86, 0.08, 0.04, 0.02))]

# --- frames by story hour -------------------------------------------------------------------
frame_probs <- function(h) {
  c(operativno  = 0.75 * exp(-h / 40) + 0.08,
    evakuacija  = 0.55 * exp(-h / 14) + 0.03,
    zrtve       = ifelse(h < 6, 0.15, 0.55 * exp(-(h - 12) / 40)) ,
    steta       = 0.10 + 0.45 * (1 - exp(-h / 10)) * exp(-h / 90),
    politika    = 0.02 + 0.45 * plogis((h - 18) / 4) * exp(-h / 120),
    uzrok       = 0.01 + 0.40 * plogis((h - 34) / 5),
    solidarnost = 0.01 + 0.45 * plogis((h - 40) / 6),
    turizam     = 0.12 + 0.10 * exp(-((h - 20) / 10)^2))
}
frame_names <- names(FRAMES)
fm <- t(sapply(it$h, function(h) { p <- frame_probs(h); as.integer(runif(length(p)) < p) }))
colnames(fm) <- frame_names
# ensure at least one frame
none <- rowSums(fm) == 0
fm[none, "operativno"] <- 1L
it <- cbind(it, as.data.table(fm))

# --- titles ---------------------------------------------------------------------------------
place <- function(f) switch(f, omis = sample(c("kod Omiša","u Lokvi Rogoznici","iznad Omiša","na omiškom području","kod Stanića","na Jadranskoj magistrali"), 1),
                            peljesac = "na Pelješcu", dugi_otok = "na Dugom otoku", brac = "na Braču")
tpl <- list(
  operativno  = c("Vatrogasci se cijelu noć bore s požarom %s", "Kanaderi od jutra gase požar %s", "Bura raspiruje vatru %s, na terenu %d vatrogasaca", "Požar %s još nije pod kontrolom", "Vatra %s lokalizirana, dežurstvo se nastavlja"),
  evakuacija  = c("Evakuirano %d ljudi %s, magistrala zatvorena", "Turisti i mještani evakuirani brodovima %s", "Prihvatni centar otvoren, autobusi voze evakuirane %s", "HAK: promet %s u prekidu zbog požara"),
  zrtve       = c("U požaru %s ozlijeđeno %d osoba, %d životno ugroženo", "Policija: pronađena mrtva osoba %s", "KBC Split: primljeno %d ozlijeđenih iz požara %s", "Ministrica: %d pacijenata na respiratoru nakon požara %s"),
  steta       = c("Izgorjelo %d hektara %s, uništene kuće i automobili", "Prve fotografije razmjera štete %s", "Deseci vozila izgorjeli %s", "Šteta od požara %s bit će golema"),
  politika    = c("Milanović %s: Ovo je neviđeno", "Plenković stigao %s, obećao pomoć", "Ministar %s: država će pomoći stradalima", "Župan i gradonačelnik %s traže hitnu pomoć"),
  uzrok       = c("Istraga požara %s: vještaci uzeli uzorke", "DORH: požar %s izbio uz cestu, traže se snimke kamera", "Je li požar %s podmetnut? Policija istražuje", "Uhićen osumnjičeni za požar %s"),
  solidarnost = c("Pula donira %d tisuća eura za obnovu %s", "Crveni križ prikuplja pomoć za stradale %s", "Val solidarnosti: građani pomažu %s", "Vatrogasci heroji: kako su obranili kuće %s"),
  turizam     = c("Turisti bježali od vatre %s, sezona pod upitnikom", "Mađarski turisti ozlijeđeni u požaru %s", "Što požar %s znači za ostatak sezone")
)
sens <- c("Apokalipsa %s", "Pakao %s", "Katastrofa %s", "Dramatične scene %s", "Neviđene scene %s", "Horor %s")
mk_title <- function(row) {
  fs <- frame_names[unlist(row[, ..frame_names]) == 1L]
  f <- sample(fs, 1)
  t <- sample(tpl[[f]], 1)
  t <- gsub("%d", as.character(sample(c(3,7,12,36,40,42,200,253,286,321,1000,2400), 1)), t, fixed = TRUE)
  t <- sprintf(t, place(row$fire))
  p_sens <- switch(row$kind, nacionalni = 0.16, drustveni = 0.10, lokalni = 0.06, strani = 0.14, 0.05)
  if (runif(1) < p_sens) t <- paste0(sprintf(sample(sens, 1), place(row$fire)), ": ", stri_trans_tolower(substr(t, 1, 1)), substr(t, 2, nchar(t)))
  t
}
it[, TITLE := vapply(seq_len(.N), function(i) mk_title(it[i]), character(1))]

# syndicated (agency) copies: a pool of 25 titles reused by many web outlets
pool <- it[kind %in% c("nacionalni","ostali_web") & fire == "omis", TITLE][1:25]
synd <- it[, kind %in% c("nacionalni","ostali_web","lokalni") & runif(.N) < 0.22]
it[synd, TITLE := sample(pool, sum(synd), replace = TRUE)]
it[synd, syndicated := TRUE][is.na(syndicated), syndicated := FALSE]

# --- text, ids, urls, engagement ------------------------------------------------------------
it[, id := sprintf("%06d", seq_len(.N))]
slug <- function(x) gsub("-+", "-", gsub("[^a-z0-9]+", "-", fold(x)))
it[, URL := fifelse(SOURCE_TYPE == "web", sprintf("https://www.%s/vijesti/%s-%s", FROM, substr(slug(TITLE), 1, 60), id),
             fifelse(SOURCE_TYPE == "facebook", sprintf("https://www.facebook.com/%s/posts/%s", slug(FROM), id),
             fifelse(SOURCE_TYPE == "twitter", sprintf("https://x.com/%s/status/17%s", sub("@","",FROM), id),
             fifelse(SOURCE_TYPE == "youtube", sprintf("https://www.youtube.com/watch?v=%s", id),
             fifelse(SOURCE_TYPE == "comment", sprintf("https://www.%s/vijesti/clanak-%s#comment-%s", FROM, sample(pool_id <- 1:40, .N, TRUE), id),
                     sprintf("https://%s/t/%s", FROM, id))))))]
# a few exact duplicate URLs to exercise dedupe
dup <- sample(which(it$SOURCE_TYPE == "web"), 40)
it <- rbind(it, it[dup])

it[, FULL_TEXT := paste0(TITLE, ". ", fifelse(syndicated, "(Hina) ", ""),
                          fifelse(fire == "omis", "Požar koji je izbio u četvrtak navečer u Lokvi Rogoznici proširio se prema Omišu. ",
                          fifelse(fire == "peljesac", "Požar na Pelješcu kod Kune izbio je jutros, situaciju otežava jak vjetar. ",
                          fifelse(fire == "dugi_otok", "Na Dugom otoku kod Savra vatrogasci su se cijelu noć borili s vatrom. ",
                                  "Požar na Braču gase kanaderi i air tractor. "))),
                          fifelse(operativno == 1, "Na terenu su vatrogasci iz više županija, gašenje otežava jak vjetar. ", ""),
                          fifelse(evakuacija == 1, "Evakuirani su smješteni u prihvatne centre, Jadranska magistrala je zatvorena. ", ""),
                          fifelse(zrtve == 1, "Ozlijeđeni su zbrinuti u KBC-u Split, dio ih je životno ugrožen. ", ""),
                          fifelse(steta == 1, "Izgorjele su kuće, vikendice i deseci automobila na oko tisuću hektara. ", ""),
                          fifelse(politika == 1, "Predsjednik i premijer posjetili su požarište i obećali pomoć. ", ""),
                          fifelse(uzrok == 1, "DORH je proveo očevid, uzeti su uzorci radi utvrđivanja uzroka. ", ""),
                          fifelse(solidarnost == 1, "Crveni križ i gradovi prikupljaju pomoć za stradale. ", ""),
                          fifelse(turizam == 1, "Među evakuiranima je velik broj stranih turista. ", ""))]
it[, MENTION_SNIPPET := substr(FULL_TEXT, 1, 200)]

it[, DATETIME := T0 + h * 3600]
it[, DATE := format(DATETIME, "%Y-%m-%d", tz = TZ)]
it[, TIME := format(DATETIME, "%H:%M:%S", tz = TZ)]

# engagement — platform-specific fields, heavy tails, many zeros on web
it[, zero_web := runif(.N) < 0.62]
it[, early_bonus := exp(-h / 40) * 1.6 + 0.4]
it[, INTERACTIONS := NA_real_][, REACH := NA_real_][, VIRALITY := NA_real_]
it[SOURCE_TYPE == "web", INTERACTIONS := fifelse(zero_web, 0, round(rlnorm(.N, 3.2, 1.3) * early_bonus))]
it[SOURCE_TYPE == "web", REACH := round(rlnorm(.N, 9.5, 1.1))]
it[SOURCE_TYPE == "facebook", `:=`(LIKE_COUNT = round(rlnorm(.N, 4.2, 1.2) * early_bonus),
                                   COMMENT_COUNT = round(rlnorm(.N, 2.8, 1.2)), SHARE_COUNT = round(rlnorm(.N, 2.5, 1.4)))]
it[SOURCE_TYPE == "facebook", `:=`(TOTAL_REACTIONS_COUNT = LIKE_COUNT, INTERACTIONS = LIKE_COUNT + COMMENT_COUNT + SHARE_COUNT, REACH = round(rlnorm(.N, 10, 1)))]
it[SOURCE_TYPE == "twitter", `:=`(RETWEET_COUNT = round(rlnorm(.N, 1.5, 1.2)), FAVORITE_COUNT = round(rlnorm(.N, 2.5, 1.3)))]
it[SOURCE_TYPE == "twitter", INTERACTIONS := RETWEET_COUNT + FAVORITE_COUNT]
it[SOURCE_TYPE == "youtube", `:=`(VIEW_COUNT = round(rlnorm(.N, 8, 1.4)), LIKE_COUNT = round(rlnorm(.N, 3.5, 1.2)), COMMENT_COUNT = round(rlnorm(.N, 2, 1.2)))]
it[SOURCE_TYPE == "youtube", INTERACTIONS := LIKE_COUNT + COMMENT_COUNT]
it[SOURCE_TYPE == "reddit", `:=`(REDDIT_SCORE = round(rlnorm(.N, 3, 1.3)), COMMENT_COUNT = round(rlnorm(.N, 2.5, 1.2)))]
it[SOURCE_TYPE == "reddit", INTERACTIONS := REDDIT_SCORE + COMMENT_COUNT]
it[SOURCE_TYPE %in% c("forum","comment"), INTERACTIONS := round(rlnorm(.N, 0.8, 1.0)) * (runif(.N) < 0.4)]
# a handful of genuinely viral items
viral <- sample(which(it$SOURCE_TYPE %in% c("facebook","web") & it$h < 30), 8)
it[viral, INTERACTIONS := INTERACTIONS + round(rlnorm(8, 8.5, 0.6))]

# languages / locations
it[, LANGUAGES := fifelse(kind == "strani",
                          fifelse(grepl("\\.rs$", FROM), "sr", fifelse(grepl("\\.ba$", FROM), "bs, hr", fifelse(grepl("\\.si$|24ur", FROM), "sl",
                          fifelse(grepl("\\.hu$", FROM), "hu", fifelse(grepl("\\.at$|\\.de$", FROM), "de", "en"))))), "hr")]
it[, LOCATIONS := fifelse(kind == "strani",
                          fifelse(grepl("\\.rs$", FROM), "RS", fifelse(grepl("\\.ba$", FROM), "BA", fifelse(grepl("\\.si$|24ur", FROM), "SI",
                          fifelse(grepl("\\.hu$", FROM), "HU", fifelse(grepl("\\.at$", FROM), "AT", fifelse(grepl("\\.de$", FROM), "DE", "GB")))))), "HR")]
it[, AUTHOR := fifelse(SOURCE_TYPE %in% c("twitter","facebook","youtube","reddit","forum","comment"), FROM, NA_character_)]
it[, AUTO_SENTIMENT := sample(c("negative","neutral","positive"), .N, TRUE, prob = c(0.55, 0.38, 0.07))]

# --- assemble the 49 vendor columns in vendor order ------------------------------------------
VENDOR_COLS <- c("DATE","TIME","TITLE","FROM","AUTHOR","URL","URL_PHOTO","SOURCE_TYPE","GROUP_NAME","KEYWORD_NAME",
  "FOUND_KEYWORDS","LANGUAGES","LOCATIONS","TAGS","MANUAL_SENTIMENT","AUTO_SENTIMENT","MENTION_SNIPPET","REACH",
  "VIRALITY","ENGAGEMENT_RATE","INTERACTIONS","FOLLOWERS_COUNT","LIKE_COUNT","COMMENT_COUNT","SHARE_COUNT",
  "TWEET_COUNT","LOVE_COUNT","WOW_COUNT","HAHA_COUNT","SAD_COUNT","ANGRY_COUNT","TOTAL_REACTIONS_COUNT",
  "FAVORITE_COUNT","RETWEET_COUNT","VIEW_COUNT","DISLIKE_COUNT","COUNT","REPOST_COUNT","REDDIT_TYPE","REDDIT_SCORE",
  "INFLUENCE_SCORE","TWEET_TYPE","TWEET_SOURCE_NAME","TWEET_SOURCE_URL","DIGG_COUNT","AUTHOR_FOLLOWER_COUNT",
  "DURATION","PAGE_AREA","FULL_TEXT")
it[, GROUP_NAME := "SYNTHETIC"][, KEYWORD_NAME := "požar Omiš (SYNTHETIC)"]
it[, FOUND_KEYWORDS := fifelse(fire == "omis", "požar, Omiš", "požar")]
for (cc in setdiff(VENDOR_COLS, names(it))) it[, (cc) := NA_character_]
out <- it[order(DATETIME), ..VENDOR_COLS]

f <- file.path(SYN_DIR, "SYNTHETIC_mentions.csv")
fwrite(out, f, bom = TRUE)
cat(sprintf("Wrote %s rows x %s cols -> %s\n", fmt_hr(nrow(out)), ncol(out), f))
cat("First item at", format(min(it$DATETIME), "%Y-%m-%d %H:%M", tz = TZ), "| last at", format(max(it$DATETIME), "%Y-%m-%d %H:%M", tz = TZ), "\n")
