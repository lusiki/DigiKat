(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.BarometarCore=factory();})(typeof globalThis==='object'?globalThis:this,function(){
  'use strict';
  const fmt=new Intl.NumberFormat('hr-HR',{maximumFractionDigits:1,minimumFractionDigits:1});
  const integer=new Intl.NumberFormat('hr-HR',{maximumFractionDigits:0});
  function unpack(table){return table.rows.map(row=>Object.fromEntries(table.columns.map((key,i)=>[key,row[i]])));}
  function rate(value){if(value===null||value===undefined||!Number.isFinite(value))return '—';if(value===0)return '0';if(value>0&&value<0.05)return '< 0,1';return fmt.format(value);}
  function count(n,one,few,many){const a=Math.abs(Math.trunc(n)),last=a%10,last2=a%100;return integer.format(n)+' '+(last===1&&last2!==11?one:last>=2&&last<=4&&(last2<12||last2>14)?few:many);}
  function select(tables,frequency,scope){return tables[frequency].filter(row=>row.scope===scope);}
  function matrixBin(value,bins){return bins.filter(b=>value>b+1e-10).length;}
  function headline(tables,frequency,scope){const rows=select(tables,frequency,scope);const latest=rows.filter(row=>row.visibility_status==='published'&&row.breadth_status==='published').at(-1);if(!latest)return null;if(frequency==='monthly')return {values:latest,period:latest};const rolling=select(tables,'rolling28',scope).find(row=>row.period_end===latest.period_end);return rolling&&rolling.visibility_status==='published'&&rolling.breadth_status==='published'?{values:rolling,period:latest}:null;}
  function segments(rows,metric){const result=[];let current=[];let previous=null;const status=metric==='breadth_pct'?'breadth_status':'visibility_status';for(const row of rows){const seam=previous&&previous.period_end<'2024-04-01'&&row.period_end>='2024-04-01';if(row[status]!=='published'||row[metric]===null||seam){if(current.length)result.push(current);current=[];}if(row[status]==='published'&&row[metric]!==null)current.push(row);previous=row;}if(current.length)result.push(current);return result;}
  const reasons={unavailable:'nije usporedivo',not_comparable_version:'promijenjena definicija ili panel',not_comparable_seam:'promjena prikupljanja',too_few_cases:'premalo slučajeva za usporedbu',within_noise:'promjena unutar slučajne varijacije'};
  function change(row,metric){if(!row)return 'nije dostupno';if(row.comparison_status!=='comparable')return reasons[row.comparison_status]||'nije usporedivo';const value=row[metric];if(!Number.isFinite(value))return 'nije dostupno';return (value<0?'−':'+')+rate(Math.abs(value));}
  return {unpack,rate,count,select,headline,segments,change,matrixBin,integer:n=>integer.format(n)};
});
