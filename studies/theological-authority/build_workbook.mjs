import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
// Resolve only the supplied runtime, never repo-local node_modules.
const deps = process.env.CODEX_WORKBOOK_NODE_MODULES || path.join(os.homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules');
const requireRuntime = createRequire(path.join(deps,'runtime-entry.cjs'));
const { Workbook, SpreadsheetFile } = await import(pathToFileURL(requireRuntime.resolve('@oai/artifact-tool')).href);
const dir='studies/theological-authority/output/private/extended';
const data=JSON.parse(await fs.readFile(`${dir}/workbook_data.json`,'utf8'));
const coding=JSON.parse(await fs.readFile(`${dir}/coding_data.json`,'utf8'));
const labels={scope:'Obuhvat',source_id:'ID izvora',source:'Izvor',platform:'Platforma',year:'Godina',period:'Razdoblje',
 actor_group:'Skupina aktera (nacrt)',classification_rule:'Pravilo razvrstavanja',classification_confidence:'Pouzdanost oznake',
 posts:'Zabilježene objave',interaction_n:'Objave s interakcijama',interaction_coverage:'Pokrivenost interakcijama',
 total_interactions:'Zabilježene interakcije',mean_interactions:'Prosjek interakcija',median_interactions:'Medijan interakcija',
 platform_year_rank:'Rang: platforma i godina',platform_year_share:'Udio: platforma i godina',
 platform_rank:'Rang na platformi',platform_share:'Udio na platformi',first_observed:'Prvi opaženi datum',
 last_observed:'Posljednji opaženi datum',months_observed:'Broj opaženih mjeseci',selection_rank:'Mjesto na popisu',
 capture_status:'Status obuhvata',stage:'Korak uključivanja',cohort:'Usporedna skupina',section:'Vrsta retka',
 topic:'Polje / tema',description:'Definicija / napomena'};
const groups={church_media:'Crkveni mediji',church_org:'Crkvene ustanove i računi',independent:'Neovisni katolički mediji',
 clergy:'Svećenički profili',community:'Zajednice i udruge',devotional:'Pobožni i autorski kanali',
 public:'Ostali i nerazvrstani izvori',other_christian:'Ostali kršćanski izvori'};
const notes=[
 ['Naslov','Katoličke teme i komunikacijski akteri, 2021.–2025. — raniji lokalni presjek DigiKat podataka'],
 ['Podaci','Raniji lokalni presjek. Nisu korišteni agregati novijeg službenog korpusa s 413.985 zapisa.'],
 ['Ulazni SHA-256',data.input.sha256],['Ulazna datoteka',data.input.path],
 ['Stvarni raspon ulaza',data.input.date_range.join(' – ')],
 ['Odabrani prozor','2021-01-01 – 2025-12-31. Kalendarski prozor ne dokazuje potpunost prikupljanja. Siječanj 2026. je isključen.'],
 ['Obuhvat','Svi zabilježeni izvori uključuju i odabrane katoličke komunikatore. Obuhvati se preklapaju i ne smiju se zbrajati.'],
 ['Duplikati','Za istu platformu i točan URL zadržan je zapis s najvećim raspoloživim brojem interakcija. Zapisi bez URL-a ostaju zasebni.'],
 ['Identitet','Platforma i normalizirana oznaka izvora čine source_id. Računi na različitim platformama ostaju odvojeni.'],
 ['Interakcije','Interakcije zabilježene uz publikacije datirane u određenoj godini. Nisu nužno nastale tijekom te godine.'],
 ['Rangiranje','Silazno po zabilježenim interakcijama, zatim uzlazno po stabilnom ID-u (data.table poredak). Rangovi su zasebni za obuhvat i platformu, te godinu u godišnjim tablicama.'],
 ['Top50_ukupno','Popis odabranih komunikatora za pregled prema sirovim interakcijama preko platformi. Nije platformski neutralna ljestvica utjecaja.'],
 ['Top50_godisnje','Do 50 izvora za svaku platformu, godinu i obuhvat. Top50_kroz_godine prati istih 50 odabranih izvora, i kad nisu godišnji vodeći izvori.'],
 ['Nedostajuće vrijednosti','Prazno u metričkim stupcima znači nedostupno. Opažena nula ostaje broj 0. Bez ijedne opažene vrijednosti ukupan broj i rang su prazni. Udio je prazan ako je nazivnik nula ili nedostaje.'],
 ['Prazna godina','Nema zabilježenih objava znači da ih nema u ovom skupu. Ne dokazuje odsutnost objavljivanja ili pažnje izvan skupa.'],
 ['Prikupljanje','Postoje praznine u obuhvatu. Metoda prikupljanja promijenila se tijekom 2024. Prve/posljednje datume i broj mjeseci provjerite u Obuhvat.'],
 ['Usporedivi prozori','Dodatak u Obuhvat: srpanj–prosinac 2024. i 2025., svi izvori u prozoru te isti izvori s ≥5 objava u oba prozora. Ne izjednačuje dob objava ni uvjete opažanja.'],
 ['Klasifikacija','Postojeće oznake su nacrt iz registara i obrazaca naziva, a ne neovisno potvrđen status. Kodovi pravila i pouzdanosti zadržani su iz skripte.'],
 ['Teološko kodiranje','Nepoznato ostaje prazno. Svećenički profil nije automatski službeni glas ustanove. Pobožni kanal nije automatski laički. Teme i ton zahtijevaju čitanje objava.'],
 ['Čuvanje kodiranja','Uredite Kodiranje ili zasebni output/private/manual-coding/kodiranje.csv. Izvoz spaja izmjene po source_id, čuva sigurnosne kopije CSV-a i prekida se kod sukoba. Ne brišite ID-eve.'],
 ['Promjene statusa','U status_valid_from i status_valid_to upišite primjenjive datume. Za više razdoblja opišite svaki interval i dokaz u notes/evidence_reference.'],
 ['Ponovni izvoz','Pokrenite analyze_extended.R za analizu pa export_workbook.R za radnu knjigu. Ručno kodiranje ne mijenja automatske rezultate bez nove odluke o pravilima.']
 ];
for(const [key,label] of Object.entries(labels)) notes.push([key,label]);
notes.push(['interaction_coverage','interaction_n / posts. Prosjek i medijan koriste samo opažene interakcije, iz pojedinačnih objava.']);
notes.push(['platform_year_share / platform_share','Broj interakcija izvora / zabilježene interakcije svih izvora u istom obuhvatu, platformi i razdoblju.']);
const codingGloss={proposed_actor_group:'Predložena skupina (automatski nacrt)',reviewed_actor_group:'Pregledana skupina',
 institutional_mandate:'Institucionalna povezanost ili mandat',individual_clergy_status:'Pojedinac: svećenički status',
 individual_lay_status:'Pojedinac: laički status',organisation_community_channel:'Organizacija, zajednica ili neidentificirani kanal',
 theological_education:'Teološko obrazovanje',authority_invoked:'Izvori autoriteta na koje se poziva',
 interprets_faith_or_doctrine:'Tumači li vjeru ili doktrinu',status_valid_from:'Status vrijedi od',status_valid_to:'Status vrijedi do',
 evidence_reference:'Referenca dokaza',reviewer:'Osoba koja kodira',review_date:'Datum pregleda',notes:'Bilješke'};
for(const entry of Object.entries(codingGloss)) notes.push(entry);
for(const entry of Object.entries(groups)) notes.push(entry);
const coverage=[...data.flow.map(r=>({...r,section:'Uključivanje'})),
 ...data.coverage.map(r=>({...r,section:'Godišnji obuhvat'})),...data.seasonal.map(r=>({...r,section:'Usporedivi prozori'}))];
const spec=[];
function add(name,rows,fields=null,raw=false){
 fields ||= [...new Set(rows.flatMap(Object.keys))];
 spec.push({name,fields,labels:fields.map(f=>raw?f:(labels[f]||f)),rows:rows.map(r=>fields.map(f=>{
  const v=r[f]??null;
  if(raw)return v;
  if(f==='scope')return {all:'Svi zabilježeni izvori',selected:'Odabrani katolički komunikatori'}[v]||v;
  if(f==='actor_group')return groups[v]||v;
  return v;
 }))});
}
add('Procitaj',notes.map(([topic,description])=>({scope:'all / selected',topic,description})));
add('Obuhvat',coverage,['scope','section','stage','platform','year','period','cohort','posts','interaction_n',
 'interaction_coverage','total_interactions','mean_interactions','median_interactions','first_observed','last_observed','months_observed']);
add('Ukupno',data.overall);add('Po_godinama',data.annual);add('Top50_ukupno',data.shortlist);
add('Top50_godisnje',data.leaders);add('Top50_kroz_godine',data.history,
 ['scope','selection_rank','source_id','source','platform','year','capture_status','actor_group','classification_rule',
 'classification_confidence','posts','interaction_n','interaction_coverage','total_interactions','mean_interactions',
 'median_interactions','platform_year_rank','platform_year_share','first_observed','last_observed','months_observed']);
add('Vrste_aktera',data.actors,['scope','platform','year','actor_group','posts','interaction_n','interaction_coverage',
 'total_interactions','mean_interactions','median_interactions','first_observed','last_observed','months_observed']);
add('Kodiranje',coding,null,true);
const serializedSpec=JSON.stringify(spec);
const previousSpec=await fs.readFile(`${dir}/workbook_spec.json`,'utf8').catch(()=>null);
await fs.writeFile(`${dir}/workbook_spec.json`,serializedSpec);
const wb=Workbook.create();
for(const [i,t] of spec.entries()){
 const sh=wb.worksheets.add(t.name),n=t.rows.length+1,m=t.fields.length;
 console.log(`Building ${t.name}: ${n-1} rows`);
 sh.showGridLines=false;
 const rows=t.rows.map(r=>r.map((v,j)=> ['first_observed','last_observed'].includes(t.fields[j])&&v?new Date(v+'T00:00:00Z'):typeof v==='string'&&v.startsWith('=')?"'"+v:v));
 sh.getRangeByIndexes(0,0,n,m).values=[t.labels,...rows];
 const used=sh.getRangeByIndexes(0,0,n,m);
 used.format.font={name:'Arial',size:10,color:'#243247'};
 used.format.rowHeight=28;
 const table=sh.tables.add(used,true,`Data${i+1}`);table.showFilterButton=true;
 sh.getRangeByIndexes(0,0,1,m).format={fill:'#263D55',font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:44};
 for(let j=0;j<m;j++){
  const f=t.fields[j],col=sh.getRangeByIndexes(0,j,n,1);
  col.format.columnWidth=f==='source_id'?46:f==='source'?38:f==='description'?115:f==='scope'?34:28;
  if(['topic','classification_rule','classification_confidence','actor_group'].includes(f))col.format.columnWidth=34;
  if(['first_observed','last_observed'].includes(f))col.setNumberFormat('yyyy-mm-dd');
  else if(/coverage|share/.test(f))col.setNumberFormat('0.0%');
  else if(/mean|median/.test(f))col.setNumberFormat('#,##0.0');
  else if(['year','posts','interaction_n','total_interactions','months_observed','selection_rank','platform_rank','platform_year_rank'].includes(f))col.setNumberFormat(f==='year'?'0':'#,##0');
 }
 if(t.name==='Procitaj'){
  sh.getRangeByIndexes(1,2,n-1,1).format.wrapText=true;
  sh.getRangeByIndexes(1,0,n-1,m).format.rowHeight=52;
 }
 if(t.name==='Kodiranje')sh.getRangeByIndexes(1,5,n-1,m-5).format.fill='#FFF4D6';
 sh.freezePanes.freezeRows(1);
}
wb.recalculate();
console.log((await wb.inspect({kind:'region',sheetId:'Top50_ukupno',range:'I1:N4',maxChars:1200,tableMaxCols:6})).ndjson);
await fs.mkdir(`${dir}/workbook-previews`,{recursive:true});
for(const t of spec){
 if(previousSpec===serializedSpec && await fs.access(`${dir}/workbook-previews/${t.name}.png`).then(()=>true,()=>false))continue;
 const preview=await wb.render({sheetName:t.name,range:t.name==='Procitaj'?'A1:C8':'A1:F6',scale:1,format:'png'});
 await fs.writeFile(`${dir}/workbook-previews/${t.name}.png`,new Uint8Array(await preview.arrayBuffer()));
}
const xlsx=await SpreadsheetFile.exportXlsx(wb);
// Keep the existing workbook available if building or rendering fails.
const target=`${dir}/katolicke-teme-i-komunikacijski-akteri-2021-2025.xlsx`;
await xlsx.save(target+'.tmp');
await fs.rename(target+'.tmp',target);
console.log('Workbook exported');
