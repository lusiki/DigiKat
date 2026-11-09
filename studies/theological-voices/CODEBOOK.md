# Codebook — model coding of the reviewed sample (pregledani uzorak)

One JSON object per post, one line per object (JSONL). Code ONLY what the title and text show.
Do not use outside knowledge about a person except what the text itself states (role words such
as "biskup", "teolog", "vjeroučiteljica" count; your own memory of who someone is does not).
Values are lowercase ASCII keys exactly as listed.

```json
{"sid": "U001",
 "tumacenje": true,
 "glasovi": [{"ime": "Dražen Kutleša", "uloga": "biskup", "govori": true, "tumaci": true}],
 "glavni_tumac": "biskup",
 "mandat": "uciteljski",
 "autoritet": ["pismo", "uciteljstvo"],
 "tema": "liturgija_duhovnost",
 "ton": "afirmativan",
 "vjernici_opisani": true,
 "vjernici_govore": false,
 "kanal_tumaci": false}
```

## Fields

**tumacenje** — true when the post explains or applies what the faith teaches: doctrine, morals,
Scripture, the meaning of a feast or sacrament, a moral judgment framed by faith. False for plain
event reporting (who attended, when a Mass took place), announcements, or texts that only mention
the Church.

**glasovi** — every person or collective that is GIVEN VOICE (quoted directly or indirectly,
or the post is their own homily/text/video). Max 6, most prominent first. Not people only mentioned.
- `ime`: name as in the text, or a short description if unnamed ("župnik", "vjernica iz Splita").
- `uloga`: `papa`, `biskup` (incl. kardinal, nadbiskup, nuncij), `svecenik_redovnik`,
  `redovnica`, `akademski_teolog` (text says theology professor / theologian / faculty of theology),
  `vjeroucitelj_katehet`, `laik_aktivist` (Catholic association, initiative, activist, publicist),
  `vjernik` (ordinary believer, pilgrim, parishioner, testimony), `influencer` (the post's own lay
  channel author or an online creator), `novinar` (journalist/editor speaking as such),
  `politicar`, `strucnjak` (scientist, doctor, lawyer, non-theology academic), `vidjelac`
  (Međugorje or other seer), `institucija` (statement of HBK, diocese, Caritas without a person),
  `drugo`.
- `govori`: true if this voice is quoted/speaks in the post.
- `tumaci`: true if this voice itself interprets doctrine/morals/Scripture in the post.

**glavni_tumac** — the role (same keys as `uloga`) of whoever does most of the interpreting.
Use `autor_objave` when the interpretation is in the post's own unattributed voice (an editorial,
an anonymous devotional text, a channel's caption). Use `nema` when `tumacenje` is false.

**mandat** — the formal standing of `glavni_tumac` as visible in the text: `uciteljski` (pope,
bishop), `pastoralni` (ordained priest or religious), `akademski` (theology faculty), `bez_mandata`
(lay person without a stated church teaching role), `nepoznato`, `nema` (no interpretation).

**autoritet** — what the interpretation appeals to (list, may be empty): `pismo` (Bible),
`uciteljstvo` (pope, councils, catechism, encyclicals, church documents), `predaja_sveci`
(saints, Church Fathers, tradition), `privatna_objava` (apparitions, messages of Our Lady, seers),
`osobno_iskustvo` (testimony, conversion, own experience), `znanost_razum` (science, statistics,
philosophy, common sense), `pravo_ljudska_prava` (law, constitution, human rights), `nacija_povijest`
(national history, homeland, Croatian martyrs as national memory).

**tema** — one: `liturgija_duhovnost`, `dogma_vjera`, `moral_bioetika` (abortion, euthanasia,
sexuality, family ethics), `obitelj_mladi`, `drustvo_politika`, `socijalna_pravda` (poverty, migrants,
work, Caritas), `crkva_institucija` (appointments, finances, abuses, church-state), `povijest_identitet`,
`kultura_mediji`, `drugo`.

**ton** — one: `afirmativan`, `neutralan`, `kritican_prema_drustvu`, `kritican_prema_crkvi`,
`polemican` (sharp attack on a named opponent, either side).

**vjernici_opisani** — ordinary lay believers (parishioners, pilgrims, families, young people,
"vjernici") are written ABOUT in the post. **vjernici_govore** — at least one ordinary lay believer
speaks (`uloga` = `vjernik`).

**kanal_tumaci** — true when the interpreter is the publishing channel itself (its own priest,
author or editorial voice) rather than someone the channel quotes.
