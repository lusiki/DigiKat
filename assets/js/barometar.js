(function () {
  'use strict';
  const node = document.getElementById('dkb-payload');
  if (!node) return;
  const C = window.BarometarCore, payload = JSON.parse(node.textContent);
  const tables = Object.fromEntries(Object.entries(payload.tables).map(([key, value]) => [key, C.unpack(value)]));
  const a2 = Object.fromEntries(['monthly','weekly'].map(frequency => [frequency,new Map(C.select(tables,frequency,'uze').map((row,i)=>[row.period_id,{...row,matching_articles:payload.a2?.[frequency]?.[i],visibility_per_10000:row.visibility_status==='unavailable'||!row.total_articles?null:10000*payload.a2?.[frequency]?.[i]/row.total_articles}]))]));
  const root = document.querySelector('.dkb'), url = new URL(location.href);
  const labels = { monthly: 'mjesečno', weekly: 'tjedno', siri: 'šire', uze: 'uže', published: 'dostupno', partial: 'djelomično', unavailable: 'nije dostupno' };
  const requestedScope=url.searchParams.get('obuhvat');
  const state = { frequency: url.searchParams.get('ucestalost') === 'tjedno' ? 'weekly' : 'monthly', scope: ['siri','uze'].includes(requestedScope) ? requestedScope : (payload.meta.default_scope || 'siri'), cursor: null };
  const allowedScopes = payload.meta.available_scopes || ['siri', 'uze'];
  if (!allowedScopes.includes(state.scope)) state.scope = payload.meta.default_scope || allowedScopes[0];
  for (const input of root.querySelectorAll('input[name=scope]')) input.disabled = !allowedScopes.includes(input.value);
  const defaultRange = () => state.frequency === 'weekly' ? (innerWidth >= 1024 ? '52' : '26') : (innerWidth >= 1024 ? 'all' : '24');
  state.range = defaultRange();
  let visible = [];
  const geometries = new Map();
  let matrixPage = 0;
  const facetLabels = {route_set:'Put prepoznavanja',speaker_type:'Govornik',reference_geography:'Prostor',outlet_segment:'Skupina medija',register:'Vrsta argumenta',principles:'Načelo'};
  const valueLabels = {national:'nacionalni',regional:'regionalni',public_service:'javna služba',confessional:'konfesionalni',political_portal:'politički portal',dostojanstvo_osobe:'dostojanstvo osobe',opce_dobro:'opće dobro',opca_namjena_dobara:'opća namjena dobara',supsidijarnost:'supsidijarnost',sudjelovanje:'sudjelovanje',solidarnost:'solidarnost'};
  function matrix() {
    const target = document.getElementById('dkb-matrix'), themes = payload.themes;
    if (!target || !themes?.ids) return;
    document.getElementById('dkb-matrix-detail').textContent='Odaberite ćeliju za broj članaka, razdoblje i status teme.';
    const mode = `${state.frequency}_${state.scope}`, selected = C.select(tables,state.frequency,state.scope), pack = themes.modes[mode];
    if (!pack) return;
    const end = Math.max(1,visible.length-matrixPage*12), periods = visible.slice(Math.max(0,end-12),end);
    const lookup = new Map(selected.map((row,i)=>[row.period_id,i])), bins = payload.meta.matrix_bins?.[mode] || [0,0,0,0];
    document.getElementById('dkb-matrix-bins').textContent=`Granice razreda na 10.000 članaka: ${bins.map(C.rate).join(' · ')}.`;
    const colors = ['#eaf0f2','#c9dce0','#8fb5bd','#5a949f','#2c6f7e'];
    target.setAttribute('role','grid');
    const caption = document.createElement('caption');caption.textContent=`Teme · ${labels[state.frequency]} · ${labels[state.scope]} · na 10.000 članaka`;
    const head = document.createElement('thead'), hr = document.createElement('tr');
    for (const value of ['Tema',...periods.map(row=>row.period_id)]) {const th=document.createElement('th');th.scope='col';th.textContent=value;hr.append(th);}head.append(hr);
    const body=document.createElement('tbody'), cells=[];
    themes.ids.forEach((id,t)=>{
      const tr=document.createElement('tr'), th=document.createElement('th');th.scope='row';th.textContent=themes.labels[t];
      if(id==='unclassified')tr.className='dkb-unclassified';
      const note=document.createElement('small');note.textContent=pack.statuses[t]==='confirmed'?'provjereno':'nepotvrđeno';th.append(note);tr.append(th);
      periods.forEach((row,p)=>{
        const count=pack.counts[lookup.get(row.period_id)][t], missing=row.visibility_status==='unavailable', value=missing?null:10000*count/row.total_articles;
        const td=document.createElement('td');td.setAttribute('role','gridcell');td.tabIndex=cells.length===0?0:-1;
        td.textContent=C.rate(value);td.dataset.row=t;td.dataset.col=p;
        if(missing)td.classList.add('dkb-missing-cell');else if(value>0){const bin=C.matrixBin(value,bins);td.style.backgroundColor=colors[bin];td.style.color=bin===4?'#fff':'#14181d';}
        if(row.visibility_status==='partial')td.classList.add('dkb-partial-cell');
        const detail=`${themes.labels[t]} · ${row.period_id} · ${C.integer(count)} od ${C.count(row.total_articles,'članka','članka','članaka')} · ${C.rate(value)} na 10.000 · ${labels[row.visibility_status]} · ${pack.statuses[t]==='confirmed'?'provjereno':'nepotvrđeno'} · ${labels[state.scope]} · definicija ${payload.meta.definition_version}`;
        td.setAttribute('aria-label',detail);
        td.addEventListener('click',()=>{for(const cell of cells)cell.tabIndex=-1;td.tabIndex=0;document.getElementById('dkb-matrix-detail').textContent=detail;});
        td.addEventListener('keydown',event=>{
          if(['Enter',' '].includes(event.key)){event.preventDefault();td.click();return;}
          if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','Home','End'].includes(event.key))return;
          event.preventDefault();let r=t,c=p;
          if(event.key==='ArrowLeft')c--;if(event.key==='ArrowRight')c++;if(event.key==='ArrowUp')r--;if(event.key==='ArrowDown')r++;
          if(event.key==='Home')c=0;if(event.key==='End')c=periods.length-1;
          r=Math.max(0,Math.min(themes.ids.length-1,r));c=Math.max(0,Math.min(periods.length-1,c));
          const next=target.querySelector(`td[data-row="${r}"][data-col="${c}"]`);for(const cell of cells)cell.tabIndex=-1;next.tabIndex=0;next.focus();
          const scroller=target.parentElement, cellRect=next.getBoundingClientRect(), headerRight=next.parentElement.querySelector('th').getBoundingClientRect().right;
          const viewportRight=scroller.getBoundingClientRect().right;
          if(cellRect.left<headerRight+2)scroller.scrollLeft-=headerRight+2-cellRect.left;
          else if(cellRect.right>viewportRight-2)scroller.scrollLeft+=cellRect.right-viewportRight+2;
        });cells.push(td);tr.append(td);
      });body.append(tr);
    });
    target.replaceChildren(caption,head,body);
    document.getElementById('dkb-matrix-range').textContent=`${periods[0]?.period_id || '—'} – ${periods.at(-1)?.period_id || '—'} · najviše 12 razdoblja`;
    document.getElementById('dkb-matrix-prev').disabled=end<=12;
    document.getElementById('dkb-matrix-next').disabled=matrixPage===0;
    const composition=payload.composition?.[mode], compositionBody=document.getElementById('dkb-composition')?.tBodies[0];
    if(composition && compositionBody) {
      const fragment=document.createDocumentFragment();
      for(const [facet,value,count] of composition.rows){const tr=document.createElement('tr');[facetLabels[facet]||facet,valueLabels[value]||value,C.integer(count)].forEach((value,i)=>{const cell=document.createElement(i?'td':'th');if(!i)cell.scope='row';cell.textContent=value;tr.append(cell);});fragment.append(tr);}
      compositionBody.replaceChildren(fragment);document.getElementById('dkb-composition-period').textContent=`${composition.period} · ${labels[state.frequency]} · ${labels[state.scope]}. Sastav toga razdoblja, bez zbrajanja preklopljenih načela.`;
      const routes=composition.rows.filter(([facet])=>facet==='route_set').map(([,value,count])=>`${value}: ${C.integer(count)}`).join(' · ');
      document.getElementById('dkb-composition-strip').textContent=`Sastav ${composition.period} · ${labels[state.frequency]} · ${labels[state.scope]} · ${routes}. ${state.frequency==='weekly'?'Zasebni tjedan; kartice prikazuju zadnjih 28 dana.':'Točne kombinacije putova.'}`;
    }
    for(const link of root.querySelectorAll('.dkb-selection-download'))link.hidden=link.dataset.frequency!==state.frequency||link.dataset.scope!==state.scope;
  }
  function svgEl(name, attrs = {}, value) {
    const el = document.createElementNS('http://www.w3.org/2000/svg', name);
    for (const [key, val] of Object.entries(attrs)) el.setAttribute(key, val);
    if (value !== undefined) el.textContent = value;
    return el;
  }
  function chart(id, metric) {
    const target = document.getElementById(id), width = Math.max(260, target.clientWidth), height = innerWidth < 640 ? 230 : 310;
    const left = 54, right = 20, top = 35, bottom = 36;
    const status = metric === 'breadth_pct' ? 'breadth_status' : 'visibility_status';
    const rolling = state.frequency === 'weekly' ? C.select(tables, 'rolling28', state.scope).filter(row => visible.some(v => v.period_end === row.period_end)) : [];
    const diagnostic = state.scope==='uze' && metric==='visibility_per_10000' ? visible.map(row=>a2[state.frequency].get(row.period_id)).filter(Boolean) : [];
    const max = metric === 'breadth_pct' ? 100 : Math.max(1, ...[...visible, ...rolling,...diagnostic].map(row => Number.isFinite(row[metric]) ? row[metric] : 0)) * 1.1;
    const step = (width - left - right) / Math.max(1, visible.length - 1), x = i => left + i * step, y = value => height - bottom - value / max * (height - top - bottom);
    const svg = svgEl('svg', { viewBox: `0 0 ${width} ${height}`, role: 'img', 'aria-label': metric === 'breadth_pct' ? 'Širina prisutnosti, postotak medija' : 'Medijska zastupljenost na 10.000 članaka' });
    const defs = svgEl('defs'), pattern = svgEl('pattern', { id: `${id}-missing`, width: 6, height: 6, patternUnits: 'userSpaceOnUse' });
    pattern.append(svgEl('path', { d: 'M-1,1 l2,-2 M0,6 l6,-6 M5,7 l2,-2', stroke: '#d4d1c8', 'stroke-width': 1 })); defs.append(pattern); svg.append(defs);
    visible.forEach((row, i) => { if (!Number.isFinite(row[metric]) || row[status] === 'unavailable') svg.append(svgEl('rect', { x: Math.max(left, x(i) - step / 2), y: top, width: Math.min(step, width - right - Math.max(left, x(i) - step / 2)), height: height - top - bottom, fill: `url(#${id}-missing)`, class: 'missing-band' })); });
    for (let tick = 0; tick <= 4; tick++) {
      const value = max * tick / 4;
      svg.append(svgEl('line', { x1: left, x2: width - right, y1: y(value), y2: y(value), class: 'grid' }));
      svg.append(svgEl('text', { x: left - 7, y: y(value) + 4, 'text-anchor': 'end' }, C.rate(value)));
    }
    const index = new Map(visible.map((row, i) => [row.period_id, i]));
    for(const segment of C.segments(diagnostic,metric))svg.append(svgEl('path',{d:segment.map((row,i)=>`${i?'L':'M'}${x(index.get(row.period_id))},${y(row[metric])}`).join(' '),class:'a2-series'}));
    for(const row of diagnostic.filter(row=>row.visibility_status==='partial'&&Number.isFinite(row[metric])))svg.append(svgEl('circle',{cx:x(index.get(row.period_id)),cy:y(row[metric]),r:2,fill:'#fff',stroke:'#656b70',class:'a2-partial'}));
    if (state.frequency === 'monthly') for (const segment of C.segments(visible, metric)) svg.append(svgEl('path', { d: segment.map((row, i) => `${i ? 'L' : 'M'}${x(index.get(row.period_id))},${y(row[metric])}`).join(' '), class: 'series' }));
    visible.forEach((row, i) => {
      if (!Number.isFinite(row[metric]) || row[status] === 'unavailable') return;
      const partial = row[status] === 'partial', barWidth = Math.max(1.5, step * .6);
      const mark = state.frequency === 'weekly' && row[metric] !== 0
        ? svgEl('rect', { x: x(i) - barWidth / 2, y: y(row[metric]), width: barWidth, height: y(0) - y(row[metric]), fill: partial ? '#fff' : '#5a949f', stroke: '#2c6f7e', class: partial ? 'partial-mark' : 'published-mark' })
        : svgEl('circle', { cx: x(i), cy: y(row[metric]), r: row[metric] === 0 ? 2.5 : 3, stroke: '#0f4c5c', fill: partial ? '#fff' : '#0f4c5c', class: row[metric] === 0 ? 'zero-mark' : partial ? 'partial-mark' : 'published-mark' });
      mark.append(svgEl('title', {}, `${row.period_id}: ${C.rate(row[metric])}; ${labels[row[status]]}`)); svg.append(mark);
    });
    if (rolling.length) {
      const lookup = new Map(visible.map((row, i) => [row.period_end, i]));
      for (const segment of C.segments(rolling, metric)) svg.append(svgEl('path', { d: segment.map((row, i) => `${i ? 'L' : 'M'}${x(lookup.get(row.period_end))},${y(row[metric])}`).join(' '), class: 'series rolling-series' }));
      svg.append(svgEl('text', { x: left, y: 17 }, 'Crta: zadnjih 28 dana'));
    }
    const ticks = Math.min(visible.length, Math.max(2, Math.floor((width - left - right) / 110) + 1), 6);
    for (let i = 0; i < ticks; i++) { const n = Math.round(i * (visible.length - 1) / Math.max(1, ticks - 1)); svg.append(svgEl('text', { x: x(n), y: height - 8, 'text-anchor': i === 0 ? 'start' : i === ticks - 1 ? 'end' : 'middle' }, visible[n].period_id)); }
    for(const annotation of payload.meta.annotations||[]) {
      const seam = visible.findIndex(row => row.period_end >= annotation.day);
      if (seam > 0) { svg.append(svgEl('line', { x1: x(seam), x2: x(seam), y1: top, y2: height - bottom, stroke: '#0f1419', 'stroke-dasharray': '4 4' })); svg.append(svgEl('text', { x: Math.min(width - 195, Math.max(left, x(seam))), y: top - 8 }, `${annotation.label_hr} · ${new Intl.DateTimeFormat('hr-HR',{day:'numeric',month:'numeric',year:'numeric',timeZone:'UTC'}).format(new Date(annotation.day))}`)); }
    }
    // Keep the static fallback until the enhancement is fully constructed.
    target.replaceChildren(svg); geometries.set(id, { svg, x, top, bottom: height - bottom, left, width: width - left - right });
  }
  function readout() {
    for (const g of geometries.values()) { g.svg.querySelectorAll('.crosshair').forEach(el => el.remove()); if (state.cursor !== null) g.svg.append(svgEl('line', { x1: g.x(state.cursor), x2: g.x(state.cursor), y1: g.top, y2: g.bottom, stroke: '#0f1419', 'stroke-dasharray': '2 3', class: 'crosshair' })); }
    const row = visible[state.cursor];
    document.getElementById('dkb-readout').textContent = row ? `${row.period_id} · ${C.rate(row.visibility_per_10000)} na 10.000 (${labels[row.visibility_status]}) · ${C.rate(row.breadth_pct)} % (${labels[row.breadth_status]}) · ${C.integer(row.matching_articles)} od ${C.count(row.total_articles, 'članka', 'članka', 'članaka')}` : '';
    if(row && state.scope==='uze'){const d=a2[state.frequency].get(row.period_id);document.getElementById('dkb-readout').textContent+=` · A2: ${C.count(d.matching_articles,'članak','članka','članaka')}, ${C.rate(d.visibility_per_10000)} na 10.000 (izvan pokazatelja)`;}
  }
  function rangeControls(selected) {
    const select = document.getElementById('dkb-range'), options = state.frequency === 'weekly' ? ['13', '26', '52', '104', 'all'] : ['12', '24', '36', '60', 'all'];
    select.replaceChildren(...options.map(value => new Option(value === 'all' ? 'Sve' : `${value} ${state.frequency === 'weekly' ? 'tjedana' : 'mjeseci'}`, value)));
    if (state.range === 'custom') select.add(new Option('Odabrani raspon', 'custom')); select.value = state.range;
    for (const id of ['dkb-from', 'dkb-to']) { const control = document.getElementById(id); if (!control) continue; control.replaceChildren(...selected.map(row => new Option(row.period_id, row.period_id))); control.value = id === 'dkb-from' ? visible[0]?.period_id : visible.at(-1)?.period_id; }
  }
  function render() {
    const selected = C.select(tables, state.frequency, state.scope);
    visible = state.range === 'custom' ? selected.filter(row => row.period_id >= state.from && row.period_id <= state.to) : state.range === 'all' ? selected : selected.slice(-Number(state.range)); state.cursor = null;
    const head = C.headline(tables, state.frequency, state.scope), values = head?.values, overview = document.getElementById('pregled');
    overview.dataset.frequency = state.frequency; overview.dataset.scope = state.scope;
    document.getElementById('dkb-visibility').textContent = C.rate(values?.visibility_per_10000);
    document.getElementById('dkb-breadth').textContent = C.rate(values?.breadth_pct) + (Number.isFinite(values?.breadth_pct) ? ' %' : '');
    document.getElementById('dkb-count-articles').textContent = values ? `${C.integer(values.matching_articles)} od ${C.count(values.total_articles, 'članka', 'članka', 'članaka')}` : 'nije dostupno';
    document.getElementById('dkb-count-outlets').textContent = values ? `${C.integer(values.matching_outlets)} od ${C.count(values.panel_outlets, 'medija', 'medija', 'medija')}` : 'nije dostupno';
    for (const el of root.querySelectorAll('.dkb-card-period')) el.textContent = `${head?.period.period_id || '—'} · ${labels[state.frequency]} · ${labels[state.scope]}${state.frequency === 'weekly' ? ' · zadnjih 28 dana' : ''}`;
    document.getElementById('dkb-change').textContent = payload.meta.synthetic ? 'Razvojni prikaz, bez tumačenja promjene.' : C.change(head?.period, 'visibility_difference') + (head?.period.comparison_status === 'comparable' ? ' na 10.000' : '');
    document.getElementById('dkb-breadth-change').hidden=state.frequency==='weekly';
    document.getElementById('dkb-breadth-change').textContent=payload.meta.synthetic?'Razvojni prikaz, bez tumačenja promjene.':C.change(head?.period,'breadth_difference_pp')+(head?.period.comparison_status==='comparable'?' postotnih bodova':'');
    document.getElementById('dkb-a2-note').hidden=state.scope!=='uze';
    document.getElementById('dkb-state').textContent = `Prikaz: ${labels[state.frequency]}, ${labels[state.scope]}.${payload.meta.synthetic ? ' Sintetički podaci.' : ''}`;
    for (const input of root.querySelectorAll('input[type=radio]')) input.checked = state[input.name] === input.value;
    const table = document.getElementById('dkb-data-table'); table.querySelector('caption').textContent = `${labels[state.frequency]}, ${labels[state.scope]}.${payload.meta.synthetic ? ' Sintetički podaci.' : ''}`;
    const body = document.createDocumentFragment();
    table.tHead.rows[0].querySelectorAll('.a2-column').forEach(n=>n.remove());
    if(state.scope==='uze')for(const label of ['A2 članci','A2 na 10.000']){const th=document.createElement('th');th.scope='col';th.className='a2-column';th.textContent=label;table.tHead.rows[0].append(th);}
    for (const row of selected) { const tr = document.createElement('tr'); const values=[row.period_id, C.integer(row.matching_articles), C.integer(row.total_articles), C.rate(row.visibility_per_10000), C.integer(row.matching_outlets), C.rate(row.breadth_pct), labels[row.visibility_status], labels[row.breadth_status]];if(state.scope==='uze'){const d=a2[state.frequency].get(row.period_id);values.push(C.integer(d.matching_articles),C.rate(d.visibility_per_10000));}values.forEach((value, i) => { const td = document.createElement(i ? 'td' : 'th'); if (!i) td.scope = 'row'; td.textContent = value; tr.append(td); }); body.append(tr); } table.tBodies[0].replaceChildren(body);
    rangeControls(selected); chart('dkb-vis-chart', 'visibility_per_10000'); chart('dkb-breadth-chart', 'breadth_pct'); readout(); matrix();
    url.searchParams.set('ucestalost', state.frequency === 'weekly' ? 'tjedno' : 'mjesecno'); url.searchParams.set('obuhvat', state.scope); history.replaceState(null, '', url);
  }
  root.addEventListener('change', event => {
    matrixPage=0;
    if (['frequency', 'scope'].includes(event.target.name)) { const changed = event.target.name === 'frequency'; state[event.target.name] = event.target.value; if (changed) state.range = defaultRange(); render(); }
    else if (event.target.id === 'dkb-range') { state.range = event.target.value; render(); }
    else if (['dkb-from', 'dkb-to'].includes(event.target.id)) { [state.from, state.to] = [document.getElementById('dkb-from').value, document.getElementById('dkb-to').value].sort(); state.range = 'custom'; render(); }
  });
  document.getElementById('dkb-matrix-prev')?.addEventListener('click',()=>{matrixPage++;matrix();});
  document.getElementById('dkb-matrix-next')?.addEventListener('click',()=>{matrixPage=Math.max(0,matrixPage-1);matrix();});
  document.getElementById('dkb-latest')?.addEventListener('click', () => { state.range = defaultRange(); matrixPage=0; render(); state.cursor = visible.length - 1; readout(); });
  for (const id of ['dkb-vis-chart', 'dkb-breadth-chart']) {
    const target = document.getElementById(id);
    target.addEventListener('keydown', event => { if (!['ArrowLeft', 'ArrowRight', 'Home', 'End', 'Escape'].includes(event.key) || !visible.length) return; event.preventDefault(); if (event.key === 'Escape') state.cursor = null; else if (event.key === 'Home') state.cursor = 0; else if (event.key === 'End') state.cursor = visible.length - 1; else state.cursor = Math.max(0, Math.min(visible.length - 1, (state.cursor ?? 0) + (event.key === 'ArrowRight' ? 1 : -1))); readout(); });
    target.addEventListener('pointermove', event => { const g = geometries.get(id); if (!g || !visible.length) return; const rect = g.svg.getBoundingClientRect(); state.cursor = Math.max(0, Math.min(visible.length - 1, Math.round((event.clientX - rect.left - g.left) / g.width * (visible.length - 1)))); readout(); });
  }
  let width = 0;
  new ResizeObserver(entries => { const next = Math.round(entries[0].contentRect.width); if (next !== width && visible.length) { width = next; chart('dkb-vis-chart', 'visibility_per_10000'); chart('dkb-breadth-chart', 'breadth_pct'); readout(); } }).observe(root);
  function header() { const n = document.getElementById('quarto-header'); root.style.setProperty('--dkb-subnav-top', n && !n.classList.contains('headroom--unpinned') ? `${n.getBoundingClientRect().height}px` : '0px'); }
  document.addEventListener('quarto-hrChanged', header); header();
  const observer = new IntersectionObserver(entries => { for (const entry of entries) if (entry.isIntersecting) for (const a of root.querySelectorAll('.dkb-subnav a')) { if (a.hash === `#${entry.target.id}`) a.setAttribute('aria-current', 'location'); else a.removeAttribute('aria-current'); } }, { rootMargin: '-15% 0px -60% 0px' });
  root.querySelectorAll('section[id]').forEach(n => observer.observe(n)); render();
  for (const controls of root.querySelectorAll('.dkb-controls')) controls.hidden = false;
})();
