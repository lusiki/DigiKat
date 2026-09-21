/* Aggregate-only platform explorer. No source records or external requests. */
(function () {
  "use strict";
  const fmt = (value, digits = 0) => value == null ? "—" : Number(value).toLocaleString("hr-HR", {
    minimumFractionDigits: digits, maximumFractionDigits: digits
  });
  const days = month => {
    const [year, m] = month.split("-").map(Number);
    return new Date(Date.UTC(year, m, 0)).getUTCDate();
  };
  const denominator = (row, basis = "all") => basis === "full" ? row.full_text_records : row.eligible_records;
  const matches = (row, scope = "broad", basis = "all") => basis === "full"
    ? (scope === "narrow" ? row.full_text_narrow_records : row.full_text_matches)
    : (scope === "narrow" ? row.narrow_records : row.matching_records);
  const value = (row, scope = "broad", measure = "rate", basis = "all") => {
    const d = denominator(row,basis);
    if (!d) return null;
    const count = matches(row,scope,basis);
    return measure === "count" ? count : 100000 * count / d;
  };
  /* One continuous series. It breaks only where a month has no searchable posts,
     because there is no point there to connect. */
  const segments = (rows, scope = "broad", measure = "rate", basis = "all") => {
    const output = []; let current = [];
    rows.forEach((row, i) => {
      const y = value(row, scope, measure, basis);
      if (y == null) {
        if (current.length) output.push(current);
        current = [];
      } else current.push({i, y, row});
    });
    if (current.length) output.push(current);
    return output;
  };
  if (typeof module !== "undefined" && module.exports) module.exports = {days, value, segments};
  if (typeof document === "undefined") return;
  const raw = document.getElementById("mp-data");
  if (!raw) return;
  const data = JSON.parse(raw.textContent);
  const platform = document.getElementById("mp-platform");
  const chart = document.getElementById("mp-chart");
  const labels = data.summary.platform_labels;
  const UNIT = "Na 100.000 objava";
  [...new Set(data.monthly.map(r => r.platform))].sort((a,b) => a === "web" ? -1 : b === "web" ? 1 : labels[a].localeCompare(labels[b], "hr")).forEach(id => {
    const option = document.createElement("option"); option.value = id; option.textContent = labels[id]; platform.append(option);
  });
  const svgNode = (name, attrs = {}, text = null) => {
    const el = document.createElementNS("http://www.w3.org/2000/svg", name);
    Object.entries(attrs).forEach(([k,v]) => el.setAttribute(k, v));
    if (text != null) el.textContent = text;
    return el;
  };
  function render() {
    const rows = data.monthly.filter(r => r.platform === platform.value);
    const groups = segments(rows);
    const compact = chart.clientWidth < 550;
    const W = compact ? 480 : 950, H = compact ? 310 : 350;
    const left = 65, right = 20, top = 42, bottom = 40;
    const points = groups.flat();
    const max = Math.max(1, ...points.map(p => p.y)) * 1.1;
    const x = i => left + i * (W-left-right) / Math.max(1,rows.length-1);
    const y = n => H-bottom - n * (H-top-bottom) / max;
    const svg = svgNode("svg", {viewBox:`0 0 ${W} ${H}`, role:"img"});
    const title = `${labels[platform.value]} · ${UNIT}`;
    svg.append(svgNode("title", {}, title), svgNode("desc", {}, "Mjesečna serija od 2021. do 2026."));
    for(let tick=0;tick<=4;tick++) {
      const v = max*tick/4;
      svg.append(svgNode("line", {x1:left,x2:W-right,y1:y(v),y2:y(v),class:"grid"}),
        svgNode("text", {x:left-8,y:y(v)+4,"text-anchor":"end"}, fmt(v, max < 10 ? 1 : 0)));
    }
    rows.forEach((r,i) => {
      if(r.month.endsWith("-01") && (!compact || Number(r.month.slice(0,4))%2===1))
        svg.append(svgNode("text",{x:x(i),y:H-12,"text-anchor":"middle"},r.month.slice(0,4)+"."));
    });
    groups.forEach(group => svg.append(svgNode("polyline",{points:group.map(p=>`${x(p.i)},${y(p.y)}`).join(" "),class:"series"})));
    points.forEach(point => {
      const partial=point.row.observed_days<days(point.row.month);
      const circle=svgNode("circle",{cx:x(point.i),cy:y(point.y),r:partial?3.4:2.5,fill:partial?"white":"#0f4c5c",stroke:"#0f4c5c","stroke-width":1.5});
      circle.append(svgNode("title",{},`${point.row.month}: ${fmt(point.y,2)}; ${fmt(denominator(point.row))} pretraživih; ${point.row.observed_days}/${days(point.row.month)} dana`));
      svg.append(circle);
    });
    chart.replaceChildren(svg);
    chart.setAttribute("aria-label", title);
    document.getElementById("mp-chart-title").textContent=title;
    const available=rows.filter(r=>denominator(r)>0);
    const latest=available[available.length-1];
    document.getElementById("mp-status").textContent=latest
      ? `${title}. Posljednji raspoloživi mjesec ${latest.month}. ${fmt(matches(latest))} od ${fmt(denominator(latest))} objava. ${latest.observed_days} od ${days(latest.month)} kalendarskih dana u arhivi.`
      : "Za ovu platformu nema pretraživih objava.";
  }
  document.getElementById("mp-controls").hidden=false;
  document.getElementById("mp-interactive").hidden=false;
  platform.addEventListener("change",render);
  render();
  document.getElementById("mp-static").hidden=true;
  let timer;
  window.addEventListener("resize",()=>{clearTimeout(timer);timer=setTimeout(render,120);});
})();
