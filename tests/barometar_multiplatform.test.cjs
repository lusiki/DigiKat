const assert=require('node:assert/strict');
const {days,value,segments}=require('../assets/js/barometar-multiplatform.js');
assert.equal(days('2024-02'),29);
assert.equal(days('2025-02'),28);
const sample=(month,n,d=100)=>({month,eligible_records:d,matching_records:n,narrow_records:n/2});
assert.equal(value(sample('2026-01',0),'broad','rate'),0);
assert.equal(value(sample('2026-01',0,0),'broad','rate'),null);
assert.equal(value(sample('2026-01',4),'narrow','rate'),2000);
assert.equal(value({...sample('2026-01',4),full_text_records:0},'broad','rate','full'),null);
assert.equal(value({...sample('2026-01',4),full_text_records:50,full_text_narrow_records:1},'narrow','rate','full'),2000);
assert.equal(value(sample('2026-01',4)),4000,'broad scope and rate per 100.000 are the defaults');
const rows=[sample('2024-02',2),sample('2024-03',4),sample('2024-04',6),sample('2024-05',0,0),sample('2024-06',8)];
// The series is continuous across the April 2024 collection change and breaks only
// where a month has no searchable posts.
assert.deepEqual(segments(rows,'broad','count').map(s=>s.map(p=>p.i)),[[0,1,2],[4]]);
assert.deepEqual(segments(rows).map(s=>s.map(p=>p.i)),[[0,1,2],[4]]);
console.log('Platform rates per 100.000, zero-versus-missing and continuous-series rendering passed.');
