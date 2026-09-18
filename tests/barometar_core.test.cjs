const test=require('node:test');const assert=require('node:assert/strict');const C=require('../assets/js/barometar-core.js');
test('Croatian counts and zero versus missing',()=>{assert.equal(C.rate(null),'—');assert.equal(C.rate(0),'0');assert.equal(C.rate(.01),'< 0,1');assert.equal(C.count(21,'članak','članka','članaka'),'21 članak');assert.equal(C.count(12,'članak','članka','članaka'),'12 članaka');assert.equal(C.count(24,'članak','članka','članaka'),'24 članka');});
test('lines break at missing periods and collection seam',()=>{const rows=[['2023-12-31',1,'published'],['2024-01-31',null,'unavailable'],['2024-03-31',2,'published'],['2024-04-30',3,'published'],['2024-05-31',4,'partial'],['2024-06-30',0,'published']].map(([end,value,status])=>({period_end:end,visibility_per_10000:value,visibility_status:status}));assert.deepEqual(C.segments(rows,'visibility_per_10000').map(x=>x.map(y=>y.visibility_per_10000)),[[1],[2],[3],[0]]);});
test('weekly headline uses its endpoint rolling28 counts',()=>{const week={scope:'siri',period_id:'2026-W36',period_end:'2026-09-06',visibility_status:'published',breadth_status:'published',matching_articles:3};const rolling={...week,period_id:'2026-09-06',matching_articles:17};const result=C.headline({monthly:[],weekly:[week],rolling28:[rolling]},'weekly','siri');assert.equal(result.values.matching_articles,17);assert.equal(result.period.matching_articles,3);assert.equal(C.headline({monthly:[],weekly:[week],rolling28:[]},'weekly','siri'),null);});
test('columnar payload and scope selection',()=>{const rows=C.unpack({columns:['scope','period_id'],rows:[['siri','2026-08'],['uze','2026-08']]});assert.deepEqual(C.select({monthly:rows},'monthly','uze'),[{scope:'uze',period_id:'2026-08'}]);});
test('both indicator lines split exactly at the collection boundary',()=>{
  for(const metric of ['visibility_per_10000','breadth_pct']) {
    const status=metric==='breadth_pct'?'breadth_status':'visibility_status';
    const rows=['2024-03-30','2024-03-31','2024-04-01','2024-04-02']
      .map((period_end,i)=>({period_end,[metric]:i,[status]:'published'}));
    assert.deepEqual(C.segments(rows,metric).map(segment=>segment.map(row=>row.period_end)),
      [['2024-03-30','2024-03-31'],['2024-04-01','2024-04-02']]);
  }
});
test('matrix boundary colors survive CSV and JSON decimal round trips',()=>{
  const bins=[10000/31,10000/31,10000/30,10000/30];
  const csvRates=[322.58064516129,333.333333333333];
  const expected=[0,2];
  // These representations caused different static/enhanced colors in the preview.
  for(const cutoffs of [bins,bins.map(x=>Number(x.toFixed(12))),JSON.parse(JSON.stringify(bins))]) {
    assert.deepEqual(csvRates.map(value=>C.matrixBin(value,cutoffs)),expected);
    assert.deepEqual([10000/31,10000/30].map(value=>C.matrixBin(value,cutoffs)),expected);
  }
  // The tolerance must not swallow a real change beyond a cutoff.
  assert.deepEqual([bins[0]-1e-6,bins[0]+1e-6,bins[2]+1e-6].map(value=>C.matrixBin(value,bins)),[0,2,4]);
});
