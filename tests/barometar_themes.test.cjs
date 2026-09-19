const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {summarize,distribution} = require('../assets/js/barometar-themes.js');
const topics=[{id:'a',label:'A'},{id:'b',label:'B'}];
const rows=[{platform:'web',month:'2025-01',topic:'a',records:3},
  {platform:'web',month:'2026-01',topic:'b',records:2},
  {platform:'tv',month:'2026-02',topic:'a',records:5}];
assert.equal(summarize(rows,topics).total,10);
assert.equal(summarize(rows,topics,'web','2026').topics[0].share,100);
assert.equal(summarize(rows,topics,'tv','2025').total,0);
assert.equal(summarize(rows,topics,'tv','2025').topics[0].share,null);
assert.deepEqual(distribution(rows,'a','platform'),[{key:'tv',records:5},{key:'web',records:3}]);
// Exercise every live platform/year slice and verify shares against independent totals.
const root='data/barometar/demokrscanstvo-themes/v1/';
const summary=JSON.parse(readFileSync(root+'summary.json','utf8'));
const [header,...lines]=readFileSync(root+'topic_monthly.csv','utf8').trim().split('\n');
const records=lines.map(line=>{const [platform,month,topic,n]=line.split(',');return {platform,month,topic,records:Number(n)};});
const platforms=['all',...new Set(records.map(r=>r.platform)),'bluesky'];
const years=['all',...new Set(records.map(r=>r.month.slice(0,4)))];
for(const platform of platforms)for(const year of years){
  const part=summarize(records,summary.topics,platform,year);
  const n=records.filter(r=>(platform==='all'||r.platform===platform)&&(year==='all'||r.month.slice(0,4)===year)).reduce((s,r)=>s+r.records,0);
  assert.equal(part.total,n);
  assert.equal(part.topics.reduce((s,r)=>s+r.records,0),n);
  if(n)assert.ok(Math.abs(part.topics.reduce((s,r)=>s+r.share,0)-100)<1e-8);
  else assert.ok(part.topics.every(r=>r.share===null));
}
assert.equal(summarize(records,summary.topics).total,2306);
console.log('Thematic filter intersections, empty selections and all live shares pass.');
