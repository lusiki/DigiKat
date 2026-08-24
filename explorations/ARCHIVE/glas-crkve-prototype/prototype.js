"use strict";

if (!window.ANALYSIS_RESULTS || window.ANALYSIS_RESULTS.meta?.status !== "real_companion_analysis") {
  throw new Error("Nedostaju rezultati nastavka analize. Pokrenite analysis.R iz korijena repozitorija.");
}

const DATA = window.ANALYSIS_RESULTS;
const fmt0 = new Intl.NumberFormat("hr-HR", { maximumFractionDigits: 0 });
const fmt1 = new Intl.NumberFormat("hr-HR", { minimumFractionDigits: 1, maximumFractionDigits: 1 });
const actorMap = Object.fromEntries(DATA.actors.map(actor => [actor.key, actor]));
const actorTotals = Object.fromEntries(DATA.actorTotals.map(actor => [actor.key, actor]));
const actorOrder = DATA.actors.map(actor => actor.key);

const escapeHtml = value => String(value).replace(/[&<>"']/g, character => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
})[character]);
const pct = value => Number.isFinite(value) ? `${fmt1.format(value)} %` : "nema procjene";
const signedPct = value => Number.isFinite(value)
  ? `${value > 0 ? "+" : value < 0 ? "−" : ""}${fmt1.format(Math.abs(value))} %`
  : "nema procjene";
const signedPoints = value => Number.isFinite(value)
  ? `${value > 0 ? "+" : value < 0 ? "−" : ""}${fmt1.format(Math.abs(value))} postotnih bodova`
  : "nema procjene";

function svg(content, width, height, label) {
  return `<svg viewBox="0 0 ${width} ${height}" role="img" aria-label="${escapeHtml(label)}">${content}</svg>`;
}

function setAccessibleData(id, title, rows) {
  const target = document.querySelector(`#${id}`);
  if (!target) return;
  target.innerHTML = `<h4>${escapeHtml(title)}</h4><ul>${rows.map(row => `<li>${escapeHtml(row)}</li>`).join("")}</ul>`;
}

function eventCompositionChart() {
  const target = document.querySelector("#event-composition-chart");
  const rows = DATA.eventComposition;
  const width = 940;
  const left = 235;
  const top = 64;
  const rowHeight = 58;
  const barWidth = 640;
  const barHeight = 25;
  const height = top + rows.length * rowHeight + 48;
  let content = "";

  let legendX = left;
  DATA.actors.forEach(actor => {
    content += `<rect x="${legendX}" y="18" width="12" height="12" rx="2" fill="${actor.color}"/>`;
    content += `<text x="${legendX + 18}" y="28" class="legend">${escapeHtml(actor.short)}</text>`;
    legendX += Math.max(135, actor.short.length * 6.2 + 34);
  });

  rows.forEach((row, rowIndex) => {
    const y = top + rowIndex * rowHeight;
    if (row.type === "baseline") {
      content += `<rect x="4" y="${y - 10}" width="920" height="48" rx="4" fill="#eef1ef"/>`;
    }
    content += `<text x="8" y="${y + 7}" class="value-label">${escapeHtml(row.label)}</text>`;
    content += `<text x="8" y="${y + 24}" class="axis">${escapeHtml(row.period)} · ${fmt0.format(row.posts)} objava</text>`;

    let cursor = left;
    actorOrder.forEach(key => {
      const share = Number(row.shares[key]) || 0;
      const segmentWidth = barWidth * share / 100;
      const actor = actorMap[key];
      content += `<rect x="${cursor}" y="${y - 4}" width="${Math.max(segmentWidth, 0.5)}" height="${barHeight}" fill="${actor.color}">`;
      content += `<title>${escapeHtml(actor.label)}: ${pct(share)}</title></rect>`;
      if (share >= 7) {
        content += `<text x="${cursor + segmentWidth / 2}" y="${y + 13}" text-anchor="middle" class="segment-label">${fmt1.format(share)} %</text>`;
      }
      cursor += segmentWidth;
    });
    content += `<line x1="${left}" x2="${left + barWidth}" y1="${y + 31}" y2="${y + 31}" class="row-rule"/>`;
  });

  target.innerHTML = svg(content, width, height, "Udio objava četiriju skupina izvora u cijelom korpusu i tijekom osam najvećih prepoznatih događaja");
  setAccessibleData(
    "event-composition-data",
    "Vrijednosti slike 1",
    rows.map(row => `${row.label}, ${row.period}: ${actorOrder.map(key => `${actorMap[key].label} ${pct(Number(row.shares[key]) || 0)}`).join("; ")}.`)
  );
}

function rhythmChart() {
  const target = document.querySelector("#rhythm-chart");
  const rows = DATA.rhythmEffects;
  const width = 940;
  const height = 360;
  const left = 250;
  const right = 735;
  const top = 62;
  const rowHeight = 58;
  const values = rows.flatMap(row => [row.lower, row.upper]).filter(Number.isFinite);
  const rawMin = Math.min(0, ...values);
  const rawMax = Math.max(0, ...values);
  const padding = Math.max(5, (rawMax - rawMin) * 0.12);
  const min = rawMin - padding;
  const max = rawMax + padding;
  const scale = value => left + (value - min) / (max - min) * (right - left);
  let content = "";

  for (let i = 0; i <= 5; i += 1) {
    const value = min + i / 5 * (max - min);
    const x = scale(value);
    content += `<line x1="${x}" x2="${x}" y1="42" y2="${top + rows.length * rowHeight - 10}" class="grid"/>`;
    content += `<text x="${x}" y="${top + rows.length * rowHeight + 13}" text-anchor="middle" class="axis">${signedPct(value)}</text>`;
  }
  const zeroX = scale(0);
  content += `<line x1="${zeroX}" x2="${zeroX}" y1="35" y2="${top + rows.length * rowHeight - 8}" class="zero-line"/>`;
  content += `<text x="${zeroX}" y="27" text-anchor="middle" class="axis">bez promjene</text>`;

  rows.forEach((row, index) => {
    const y = top + index * rowHeight;
    const actor = actorMap[row.actor];
    content += `<text x="8" y="${y + 5}" class="value-label">${escapeHtml(actor.label)}</text>`;
    content += `<line x1="${scale(row.lower)}" x2="${scale(row.upper)}" y1="${y}" y2="${y}" class="interval-line"/>`;
    content += `<line x1="${scale(row.lower)}" x2="${scale(row.lower)}" y1="${y - 6}" y2="${y + 6}" class="interval-line"/>`;
    content += `<line x1="${scale(row.upper)}" x2="${scale(row.upper)}" y1="${y - 6}" y2="${y + 6}" class="interval-line"/>`;
    content += `<circle cx="${scale(row.estimate)}" cy="${y}" r="7" fill="${actor.color}" stroke="#fff" stroke-width="2"><title>${escapeHtml(actor.label)}: ${signedPct(row.estimate)} [${signedPct(row.lower)}; ${signedPct(row.upper)}]</title></circle>`;
    content += `<text x="915" y="${y + 5}" text-anchor="end" class="value-label">${signedPct(row.estimate)}</text>`;
  });
  content += `<text x="${(left + right) / 2}" y="345" text-anchor="middle" class="axis-label">Procijenjena promjena broja objava oko blagdana</text>`;

  target.innerHTML = svg(content, width, height, "Procijenjena promjena broja objava oko ponavljajućih blagdana prema skupini izvora");
  setAccessibleData(
    "rhythm-data",
    "Vrijednosti slike 2",
    rows.map(row => `${actorMap[row.actor].label}: ${signedPct(row.estimate)}, interval od ${signedPct(row.lower)} do ${signedPct(row.upper)}.`)
  );
}

function populateActorCards() {
  DATA.actorTotals.forEach(actor => {
    const card = document.querySelector(`[data-actor-card="${actor.key}"]`);
    if (card) card.style.setProperty("--actor-color", actor.color);
    const total = document.querySelector(`[data-actor-total="${actor.key}"]`);
    if (total) total.textContent = `${pct(actor.postShare)} svih objava · ${fmt0.format(actor.posts)} objava`;
  });
}

function narrativeFragments() {
  document.querySelectorAll("[data-fragment='scope']").forEach(node => { node.textContent = DATA.scope; });
  document.querySelectorAll("[data-fragment='corpusRows']").forEach(node => { node.textContent = fmt0.format(DATA.meta.corpusRows); });
  document.querySelectorAll("[data-fragment='peakCount']").forEach(node => { node.textContent = fmt0.format(DATA.findings.namedPeakCount); });

  const findings = DATA.findings;
  const responsiveActor = actorMap[findings.mostResponsiveActor];
  const shiftActor = actorMap[findings.largestCompositionShift.actor];
  const shift = findings.largestCompositionShift.percentagePoints;
  const rhythm = DATA.rhythmEffects.find(row => row.actor === findings.mostResponsiveActor);
  const rhythmCertain = rhythm && (rhythm.lower > 0 || rhythm.upper < 0);

  document.querySelector("#hero-finding").textContent = `${findings.largestPeak.label} bio je najveći prepoznati vrhunac, ali događaji nisu svaki put okupljali iste skupine u istom omjeru.`;
  document.querySelector("#hero-readout").textContent = `Među ponavljajućim blagdanima najveću procijenjenu promjenu ritma bilježi skupina „${responsiveActor.label}”.`;

  document.querySelector("#event-readout").textContent = shift >= 0
    ? `Najveći odmak od uobičajene raspodjele vidi se uz događaj „${findings.largestCompositionShift.event}”: skupina „${shiftActor.label}” tada je bila zastupljenija za ${fmt1.format(Math.abs(shift))} postotnih bodova.`
    : `Najveći odmak od uobičajene raspodjele vidi se uz događaj „${findings.largestCompositionShift.event}”: skupina „${shiftActor.label}” tada je bila zastupljena za ${fmt1.format(Math.abs(shift))} postotnih bodova manje.`;

  document.querySelector("#rhythm-readout").textContent = rhythmCertain
    ? `Najveću jasnu promjenu bilježi skupina „${responsiveActor.label}”: procijenjeni broj objava raste za ${pct(findings.mostResponsiveEstimate)}, uz raspon od ${signedPct(findings.mostResponsiveLow)} do ${signedPct(findings.mostResponsiveHigh)}.`
    : `Najveću točkastu procjenu ima skupina „${responsiveActor.label}” (${signedPct(findings.mostResponsiveEstimate)}), ali raspon nesigurnosti treba čitati zajedno s procjenom.`;

  document.querySelector("#conclusion-peak").textContent = `${findings.largestPeak.label}, ${findings.largestPeak.period}`;
  document.querySelector("#conclusion-shift").textContent = `${shiftActor.short}: ${signedPoints(shift)} uz događaj „${findings.largestCompositionShift.event}”`;
  document.querySelector("#conclusion-rhythm").textContent = `${responsiveActor.short}: ${signedPct(findings.mostResponsiveEstimate)}`;
  document.querySelector("#caveat-list").innerHTML = DATA.caveats.map(item => `<li>${escapeHtml(item)}</li>`).join("");
}

function initialise() {
  populateActorCards();
  narrativeFragments();
  eventCompositionChart();
  rhythmChart();
  document.documentElement.dataset.analysisReady = "true";
}

initialise();
