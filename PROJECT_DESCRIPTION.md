# DigiKat Project Description

## Metadata

Project title: Prikaz i analiza katoličke tematike u digitalnom medijskom prostoru (Presentation and Analysis of Catholic Themes in the Croatian Digital Media Space)

Institution: Hrvatsko katoličko sveučilište (Croatian Catholic University), Department of Communication Studies

Principal investigator: doc. dr. sc. Luka Šikić (luka.sikic@unicath.hr)

Duration: 2025 to 2027 (three years, six phases)

License: CC BY 4.0

Repository: https://github.com/lusiki/DigiKat

Project website: https://lusiki.github.io/DigiKat/

Status: Active


## Executive Summary

DigiKat is a three year interdisciplinary research project that applies computational social science methods to systematically map, measure, and analyze the presence of Catholic themes across the Croatian digital media ecosystem. The project covers web portals, YouTube, Facebook, Twitter, Reddit, and online forums. Its empirical foundation is a structured database of over 610,000 media posts collected between 2021 and 2025, written primarily in Croatian and Bosnian. The project produces both a reusable open data infrastructure and a series of thematic studies on specific aspects of Catholic digital media presence.

The project sits at the intersection of communication studies, digital humanities, computational text analysis, and sociology of religion. It is committed to open science principles, with all code, methodological frameworks, and where possible data published openly under FAIR principles.


## Research Questions

The project is organized around five core research questions.

First, how is Catholic subject matter represented and discussed in the Croatian digital media space? This encompasses the volume, frequency, platform distribution, and narrative framing of Catholic content across different digital channels.

Second, what are the connections between Catholic themes and other social and political issues in Croatian public discourse? The project examines co occurrence patterns between religious topics and political, ethical, cultural, and economic debates.

Third, which actors and institutions are most prominent in these discussions? The project identifies and classifies key media sources, organizations, influencers, and institutional voices that shape Catholic discourse online.

Fourth, how do narratives and sentiment shift in response to real world events? The project tracks temporal dynamics of tone, emotion, and thematic emphasis around events such as papal visits, church scandals, political elections, and religious holidays.

Fifth, what is the network dynamic between different platforms and media outlets covering these topics? The project maps cross platform information flows and ecosystem structures.


## Database

The empirical core of the project is a large scale structured database stored as an R data.table object (merged_comprehensive.rds). The database contains over 610,000 records spanning 2021 to 2025, with more than 620 variables per record.

### Data Sources and Coverage

The data was collected from Croatian digital media using automated web scraping and API integrations. The geographic scope is Croatia (country code HR) and the primary languages are Croatian (hr) and Bosnian (bs). Platform coverage includes web news portals (the dominant source by volume), YouTube channels and videos, Facebook pages and posts, Twitter accounts and tweets, Reddit threads, and online discussion forums.

### Variable Categories

Temporal variables capture publication date, year, month, and day of week for each post. Content variables include the full text of articles or posts, titles, descriptions, URLs, and media type indicators. Source variables record the platform, domain name, specific page or channel, and author metadata where available. Categorization variables store topic labels, thematic tags, and the religious term matches that qualified each post for inclusion.

Engagement variables track platform specific interaction metrics. For web content this includes estimated reach. For YouTube this covers views, likes, dislikes, and comments. For Facebook this includes reactions (like, love, haha, wow, sad, angry), shares, and comments. Sentiment variables contain scores from multiple lexicon based approaches as well as emotional category assignments.

### Religious Content Filtering

Inclusion in the database is determined by a dictionary based matching system. The project defines over 70 Catholic religious root terms with complex regular expressions designed to capture Croatian morphological inflections. Key term families include clergy and hierarchy (biskup, papa, svećenik, kardinal, nadbiskup), sacraments and liturgy (misa, sakrament, euharistija, krštenje), theological concepts (evanđelje, teologija, dogma, katekizam), institutions (Vatikan, biskupija, župa, katolička crkva), and cultural practices (hodočašće, blagdan, korizma, advent). Each term pattern accounts for Croatian case endings, plural forms, and derivational morphology.

### Processed Data Outputs

The project generates several aggregated analytical datasets. platform_summary.rds contains platform level statistics by year. proportions_summary.rds holds platform share analysis. source_summary.rds tracks media source productivity and engagement. Separate files store top performing sources on each platform (top_web_sources.rds, top_youtube_sources.rds, top_facebook_sources.rds) and actor mapping data for each platform (web_actors.rds, youtube_actors.rds, facebook_actors.rds).


## Analytical Framework

The project employs a multi layered analytical framework with four distinct but interconnected layers.

### Layer 1: Digital Ecosystem Mapping (Mapa ekosustava)

This layer answers the question of who speaks and how loudly. It quantifies the structural composition of the Catholic digital ecosystem by measuring post volume, interaction counts, and estimated reach across platforms and sources. A key output is an actor typology that classifies media sources into four archetypes. Giants are sources with both high reach and high engagement. Community Builders have lower reach but generate disproportionately high engagement. Megaphones achieve wide reach but low engagement per impression. Specialists are smaller niche outlets serving dedicated audiences.

The mapping reveals that mainstream news portals like vecernji.hr and jutarnji.hr dominate by volume, while specialized Catholic channels like LaudatoTV on YouTube generate outsized engagement relative to their size.

### Layer 2: Thematic Stream Analysis (Tematske struje)

This layer uses natural language processing to decompose the corpus into thematic categories and track their evolution over time. The NLP pipeline begins with UDPipe tokenization (using the Croatian UD model, version 2.5), followed by lemmatization, POS tagging, and stopword removal using an extended Croatian stopword list.

Thematic classification employs a dictionary based scoring approach across 16 categories. These categories are spirituality and liturgy, theology, church governance, popes and the Vatican, church finances, global church and missions, politics, bioethics, charity and social justice, history and identity, science and faith, media and culture, digital evangelization, abuse and crisis, internal disputes, and interfaith relations.

The analysis uses stratified sampling (2 to 5 percent of the total corpus) to manage computational costs while maintaining representativeness. Temporal dynamics track how these 16 themes rise and fall across the 2021 to 2025 period.

### Layer 3: Discourse Atmosphere Analysis (Atmosfera diskursa)

This layer captures the emotional and conflict dimensions of the discourse through a two level emotional analysis framework. The first level (tonality) measures basic positive versus negative sentiment. The second level (psychological processes) identifies specific emotional categories.

Three sentiment lexicons are used in parallel. CroSentilex provides Croatian language positive and negative word lists. CroSentilex Gold offers categorical sentiment annotations (negative, neutral, positive) with higher precision. The lilaHR lexicon (an NRC emotion lexicon translated and adapted for Croatian) enables classification across eight emotional dimensions: anger (ljutnja), anticipation (iščekivanje), disgust (gađenje), fear (strah), joy (radost), sadness (tuga), surprise (iznenađenje), and trust (povjerenje).

Beyond sentiment, this layer computes conflict indices that measure aggression intensity in the discourse. It also constructs narrative atmosphere networks that visualize the co occurrence and clustering of emotional tones across sources and topics.

### Layer 4: Event Driven Dynamics (Fokus na događaje i kampanje)

This layer examines how real world events create perturbations in the digital discourse. It tracks temporal sentiment shifts around specific events, measures the speed and magnitude of discourse responses, and analyzes how emotional and thematic compositions change when major Catholic or political events occur. This creates a dynamic picture of the media ecosystem as a responsive system rather than a static content repository.


## Technical Infrastructure

### Programming Languages and Environment

The primary analytical language is R, with supporting Python scripts for specific NLP tasks. The project uses RStudio as its development environment and is structured as an R Project (DigiKat.Rproj).

### Key R Packages and Tools

Data manipulation relies on data.table for high performance operations on the large dataset. Text analysis uses the udpipe package for tokenization and lemmatization with the Croatian UD model (croatian-set-ud-2.5-191206.udpipe). Sentiment analysis is performed using custom lexicon matching against CroSentilex and lilaHR dictionaries. A custom Croatian stemmer is implemented in R (R/stemmer.R) with transformation rules and vowel checking functions adapted for Croatian morphology.

### Python Components

A Croatian stemmer implementation exists in Python (R/Croatian_stemmer.py) as an alternative to the R based version. This uses rule based transformations specific to Croatian morphological patterns.

### Web Presentation

The project website is built with Quarto and published via GitHub Pages. The site uses the cosmo Bootstrap theme with custom CSS and SCSS styling. Navigation is organized into sections covering project information, the database, the media space map (with four analytical sub pages), thematic studies (five planned studies), news, and resources.

### Data Storage and Formats

Raw data is stored as Excel files (.xlsx) in the data/raw directory. Processed analytical outputs are stored as R RDS files in data/processed. NLP tokenized data is stored in data/nlp. Lexicon resources include TSV, TXT, and XLSX files in the resources/lexicons and resources/dictionaries directories.


## Project Team

The project is led by Luka Šikić from the Communication Studies department at Croatian Catholic University. The interdisciplinary team includes Andreja Sršen (Sociology, Faculty of Humanities and Social Sciences), Irena Palić (Statistics, Faculty of Economics and Business Zagreb), Lana Ciboci Perša (Communication Studies, HKS), Petra Palić (Sociology, HKS), Ivan Uldrijan (Communication Studies, HKS), Suzana Lipar Obrovac (Public Relations, HKS), Hana Kilijan (Communication Studies, HKS), Veronika Novoselec (History, HKS), and Matea Topić Crnoja (Sociology, HKS).

This composition brings together expertise in quantitative media analysis, computational methods, survey research, historical analysis, sociological theory, and public relations.


## Project Timeline

### Year 1 (2025)

Phase 1 covers the analysis of historical data from 2021 to 2024. Phase 2 focuses on building analytical infrastructure, including the database, processing pipelines, and the project website.

### Year 2 (2026)

Phase 3 produces the first annual analytical report covering the period through mid 2026. Phase 4 launches the thematic sub studies.

### Year 3 (2027)

Phase 5 delivers the second annual report with expanded scope. Phase 6 completes the project with a synthesis report, final publications, and public dissemination.


## Planned Thematic Studies

The project plans five focused thematic investigations, each designed as a standalone study drawing on the shared database infrastructure.

The first examines self help content analysis on YouTube, investigating how Catholic self help and spiritual guidance channels operate and what audiences they attract.

The second studies pilgrimage tourism (hodočasnički turizam), analyzing digital advertising, promotion, and discussion of Catholic pilgrimage sites and related travel.

The third investigates Christian democracy (demokršćanstvo), tracking how Christian democratic political ideas, parties, and candidates are discussed in digital media.

The fourth focuses on Catholic education (katoličko obrazovanje), examining the digital presence and public debate around Catholic schools, religious instruction, and educational institutions.

The fifth analyzes the representation of Catholic saints (prikazivanje katoličkih svetaca i svetica), studying how hagiographic content circulates in digital spaces.


## Open Science Commitment

All tools, scripts, and methodological frameworks are published as open source on GitHub. The project follows FAIR data principles (Findable, Accessible, Interoperable, Reusable). A data migration guide (DATA_MIGRATION_GUIDE.md) documents path conversions to ensure reproducibility across different computing environments. The project actively encourages collaboration and invites contributions through GitHub issues.


---


# Research Integration Opportunities

The following section outlines how various research directions from adjacent fields could be productively integrated into or built upon the DigiKat infrastructure.


## 1. Comparative Cross Country Religious Media Analysis

The DigiKat methodology and analytical framework could be extended to other predominantly Catholic countries in Central and Southern Europe. A natural first expansion would cover Slovenia, Poland, Italy, and Ireland, each of which has a distinctive relationship between Catholic institutions and public media. The existing NLP pipeline would need adaptation for each target language, but the overall architecture of dictionary based filtering, thematic classification, and sentiment analysis transfers directly. The comparative dimension would reveal whether patterns observed in Croatia (such as the dominance of mainstream portals in covering religious topics or the high engagement rates of specialized YouTube channels) represent universal dynamics or are specific to the Croatian media ecosystem. This integration could produce a pan European dataset of Catholic digital media presence, enabling cross national studies of secularization, media framing of religion, and the digital transformation of religious communication.


## 2. Automated Narrative and Frame Detection Using Large Language Models

The current thematic classification relies on dictionary based scoring across 16 predefined categories. A natural extension would incorporate transformer based language models fine tuned for Croatian (such as BERTić or CroSloEngual BERT) to perform more nuanced frame detection. Rather than counting term frequencies, these models could identify implicit framing devices, rhetorical strategies, and argumentative structures in the text. This would enable detection of how the same event is framed differently across outlets (for example, whether a church statement on social policy is framed as moral guidance, political interference, or cultural commentary). Integration with the existing pipeline would involve training classifiers on a manually annotated subset of the DigiKat corpus and using those classifiers to extend the analysis to the full 610,000 post dataset. The LLM approach could also improve the emotional analysis layer by capturing sarcasm, irony, and implicit sentiment that lexicon based methods miss.


## 3. Network Analysis of Information Diffusion and Amplification

The project already maps actors and platforms, but a dedicated network science component could trace how specific stories, narratives, and talking points propagate across the digital ecosystem. By constructing temporal citation and sharing networks (tracking when the same story or claim appears across different platforms and outlets), the project could identify information cascades, gatekeeping nodes, and echo chambers in the Catholic digital space. This would draw on methods from computational epidemiology (treating narratives as contagions) and network science (centrality measures, community detection, temporal motif analysis). Integration would require enriching the existing database with URL sharing data, cross referencing timestamps across platforms, and applying cascade reconstruction algorithms. The output would reveal whether Catholic digital media operates as a unified discourse space or fragments into disconnected communities with distinct information diets.


## 4. Audience Reception and Engagement Prediction

The database already contains rich engagement metrics (views, likes, shares, comments, emotional reactions). A machine learning component could model what predicts high engagement with Catholic content. Features could include textual characteristics (topic, sentiment, complexity, title structure), temporal features (day of week, time of day, proximity to religious calendar events), source characteristics (platform, outlet reputation, historical engagement), and contextual features (concurrent news events, seasonal patterns). Regression and classification models could identify the structural drivers of engagement, distinguishing between content that generates broad but shallow attention versus content that provokes deep community interaction. This would connect the project to the broader literature on algorithmic amplification, attention economics, and the platform specific incentive structures that shape religious communication online.


## 5. Hate Speech and Polarization Monitoring

The conflict index component of the discourse atmosphere analysis could be expanded into a dedicated hate speech and polarization monitoring system. This would involve building or adapting hate speech classifiers for Croatian (training data could come from the FRENK or CLASSLA datasets), identifying polarization dynamics around contentious Catholic topics (such as LGBTQ issues, abortion debates, church and state separation), and tracking whether specific actors or platforms systematically amplify hostile discourse. The longitudinal structure of the DigiKat database is particularly valuable here because it enables analysis of polarization trajectories rather than snapshots. Integration would add a new analytical layer that complements the existing sentiment analysis with explicit toxicity detection, stance classification, and polarization measurement.


## 6. Multimodal Content Analysis

The current project focuses on textual data. A multimodal extension would analyze visual content (images and video thumbnails associated with Catholic media posts) and audio or video content (particularly from YouTube). Computer vision methods could classify visual framing (for example, whether articles about the Church are illustrated with images of cathedrals, clergy, protests, or political settings). Video analysis of YouTube content could examine production quality, visual rhetoric, and the relationship between visual presentation and engagement. This would require integrating image and video processing pipelines (using pre trained models like CLIP for image text alignment or Whisper for audio transcription) with the existing text analysis infrastructure. The multimodal dimension would capture aspects of religious media communication that text alone cannot reveal.


## 7. Digital Evangelization Strategy Research

One of the 16 thematic categories already tracks digital evangelization. This could be expanded into a full sub study examining how Catholic institutions and individuals use digital platforms for explicit evangelization purposes. Research questions would include what communication strategies successful Catholic digital evangelizers employ, how evangelization content differs from journalistic or commentary content in structure and tone, whether evangelization content generates different engagement patterns than news coverage of Catholic topics, and how Croatian Catholic digital evangelization compares to established models from the United States and Latin America. This would connect the project to the growing academic literature on mediatized religion and digital religion studies.


## 8. Public Opinion and Survey Integration

The digital media analysis could be triangulated with public opinion data on religiosity, trust in the Church, and attitudes toward Catholic social teaching. By linking temporal patterns in the DigiKat database (such as spikes in negative sentiment around church scandals) with survey data on public attitudes (from the European Values Study, Eurobarometer, or custom surveys), the project could test whether digital media dynamics predict or reflect shifts in public opinion. This would require either accessing existing longitudinal survey data for Croatia or conducting original survey waves timed to coincide with identified media events. The integration would strengthen causal claims about the relationship between media representation and public perception of the Catholic Church.


## 9. Historical Digitization and Long Term Trend Analysis

The current database covers 2021 to 2025, which captures a specific moment in Croatian digital media development. Extending the temporal scope backward by digitizing and coding earlier web content (through the Wayback Machine or national web archives) or by coding print media archives would enable analysis of how the digital transformation changed Catholic media presence. Was the shift to digital platforms accompanied by a secularization of tone? Did new actors emerge who had no presence in traditional media? How did the ratio of institutional to grassroots Catholic content change? This historical extension would position DigiKat within the longer trajectory of media and religion in post independence Croatia.


## 10. Computational Sociology of Religion

The DigiKat database provides an empirical foundation for testing theories from the sociology of religion in a computational framework. Secularization theory could be examined by tracking whether Catholic media presence is declining, stable, or growing over time across platforms. Supply side theories of religion could be tested by examining whether the diversity of Catholic content producers is associated with higher overall engagement. Mediatization theory could be investigated by analyzing whether Catholic communication is increasingly adopting media logic (sensationalism, personalization, conflict framing) at the expense of religious logic. Each of these theoretical directions could produce standalone academic publications grounded in the shared DigiKat dataset.
