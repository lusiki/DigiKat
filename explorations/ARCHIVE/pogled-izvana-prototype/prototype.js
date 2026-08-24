"use strict";

const D = window.CROSSOVER_RESULTS;
if (!D) throw new Error("Nedostaju izračunati rezultati izvještaja.");

const NS = "http://www.w3.org/2000/svg";
const HR0 = new Intl.NumberFormat("hr-HR", { maximumFractionDigits: 0 });
const HR1 = new Intl.NumberFormat("hr-HR", { minimumFractionDigits: 1, maximumFractionDigits: 1 });

const pct = value => `${HR1.format(Number(value))} %`;
const pp = value => `${value > 0 ? "+" : value < 0 ? "−" : ""}${HR1.format(Math.abs(Number(value)))} p. b.`;
const circle = key => D.circles.find(item => item.key === key);

function svgNode(tag, attrs = {}, text = null) {
  const item = document.createElementNS(NS, tag);
  Object.entries(attrs).forEach(([key, value]) => item.setAttribute(key, value));
  if (text !== null) item.textContent = text;
  return item;
}

function makeSvg(target, width, height, label) {
  target.innerHTML = "";
  const svg = svgNode("svg", {
    viewBox: `0 0 ${width} ${height}`,
    role: "img",
    "aria-label": label,
    preserveAspectRatio: "xMinYMin meet"
  });
  target.append(svg);
  return svg;
}

function line(svg, x1, y1, x2, y2, attrs = {}) {
  svg.append(svgNode("line", { x1, y1, x2, y2, ...attrs }));
}

function text(svg, x, y, value, attrs = {}) {
  svg.append(svgNode("text", { x, y, ...attrs }, value));
}

function drawThemeChart() {
  const target = document.querySelector("#chart-themes");
  const rows = [...D.figures.themeSelection].sort((a, b) => Math.max(b.catholic_share, b.general_share) - Math.max(a.catholic_share, a.general_share));
  const width = 860;
  const top = 88;
  const rowHeight = 72;
  const height = top + rows.length * rowHeight + 42;
  const left = 270;
  const right = 790;
  const maxValue = Math.ceil(Math.max(...rows.flatMap(row => [row.catholic_share, row.general_share])) / 10) * 10;
  const x = value => left + (right - left) * Number(value) / maxValue;
  const svg = makeSvg(target, width, height, "Usporedba udjela šest tema u katoličkim izvorima i općim informativnim medijima");

  const catholic = circle("catholic");
  const general = circle("general");
  svg.append(svgNode("circle", { cx: left, cy: 25, r: 6, fill: catholic.color }));
  text(svg, left + 12, 29, catholic.label, { class: "legend-text" });
  svg.append(svgNode("circle", { cx: left + 180, cy: 25, r: 6, fill: general.color }));
  text(svg, left + 192, 29, general.label, { class: "legend-text" });

  for (let tick = 0; tick <= maxValue; tick += 10) {
    const tx = x(tick);
    line(svg, tx, 58, tx, height - 30, { class: "grid-line" });
    text(svg, tx, 51, `${tick} %`, { class: "axis-text", "text-anchor": "middle" });
  }

  rows.forEach((row, index) => {
    const y = top + index * rowHeight;
    text(svg, left - 20, y + 5, row.label, { class: "row-label", "text-anchor": "end" });
    line(svg, x(row.catholic_share), y, x(row.general_share), y, { class: "comparison-line" });
    svg.append(svgNode("circle", { cx: x(row.catholic_share), cy: y, r: 8, fill: catholic.color, stroke: "white", "stroke-width": 2 }));
    svg.append(svgNode("circle", { cx: x(row.general_share), cy: y, r: 8, fill: general.color, stroke: "white", "stroke-width": 2 }));
    text(svg, x(row.catholic_share), y - 14, pct(row.catholic_share), { class: "value-text", "text-anchor": "middle", fill: catholic.color });
    text(svg, x(row.general_share), y + 25, pct(row.general_share), { class: "value-text", "text-anchor": "middle", fill: general.color });
  });
}

function drawCategoryChart() {
  const target = document.querySelector("#chart-categories");
  const positive = [...D.figures.categoryGap].filter(row => row.gap > 0).sort((a, b) => b.gap - a.gap).slice(0, 4);
  const negative = [...D.figures.categoryGap].filter(row => row.gap < 0).sort((a, b) => a.gap - b.gap).slice(0, 4);
  const rows = [...negative, ...positive].sort((a, b) => a.gap - b.gap);
  const width = 900;
  const top = 82;
  const rowHeight = 56;
  const height = top + rows.length * rowHeight + 54;
  const left = 300;
  const right = 830;
  const centre = (left + right) / 2;
  const maxGap = Math.max(5, Math.ceil(Math.max(...rows.map(row => Math.abs(row.gap))) / 5) * 5);
  const x = value => centre + (right - left) * Number(value) / (2 * maxGap);
  const svg = makeSvg(target, width, height, "Najveće razlike u udjelu šesnaest tematskih kategorija između dvaju medijskih krugova");

  text(svg, left, 28, "Veći udio u katoličkim izvorima", { class: "side-label", fill: circle("catholic").color });
  text(svg, right, 28, "Veći udio u općim medijima", { class: "side-label", fill: circle("general").color, "text-anchor": "end" });
  line(svg, centre, 45, centre, height - 32, { class: "zero-line" });
  text(svg, centre, 58, "0", { class: "axis-text", "text-anchor": "middle" });

  rows.forEach((row, index) => {
    const y = top + index * rowHeight;
    text(svg, left - 18, y + 5, row.label, { class: "row-label", "text-anchor": "end" });
    const end = x(row.gap);
    const x0 = Math.min(centre, end);
    const barWidth = Math.max(1, Math.abs(end - centre));
    svg.append(svgNode("rect", {
      x: x0,
      y: y - 10,
      width: barWidth,
      height: 20,
      rx: 3,
      fill: row.gap < 0 ? circle("catholic").color : circle("general").color
    }));
    text(svg, end + (row.gap < 0 ? -8 : 8), y + 5, pp(row.gap), {
      class: "value-text",
      "text-anchor": row.gap < 0 ? "end" : "start",
      fill: row.gap < 0 ? circle("catholic").color : circle("general").color
    });
  });
}

function drawEventChart() {
  const target = document.querySelector("#chart-events");
  const rows = [...D.figures.eventCrossover].sort((a, b) => String(a.peak_date).localeCompare(String(b.peak_date)));
  const width = 900;
  const top = 86;
  const rowHeight = 46;
  const height = top + rows.length * rowHeight + 48;
  const left = 280;
  const right = 820;
  const maxValue = Math.ceil(Math.max(...rows.flatMap(row => [row.baseline_share, row.general_share])) / 10) * 10;
  const x = value => left + (right - left) * Number(value) / maxValue;
  const svg = makeSvg(target, width, height, "Udio općih informativnih medija tijekom prepoznatih liturgijskih i papinskih događajnih valova");

  svg.append(svgNode("circle", { cx: left, cy: 26, r: 6, fill: "#a8adaf" }));
  text(svg, left + 12, 30, "Uobičajeni udio", { class: "legend-text" });
  svg.append(svgNode("circle", { cx: left + 160, cy: 26, r: 7, fill: circle("general").color }));
  text(svg, left + 173, 30, "Udio tijekom događaja", { class: "legend-text" });

  for (let tick = 0; tick <= maxValue; tick += 10) {
    const tx = x(tick);
    line(svg, tx, 56, tx, height - 28, { class: "grid-line" });
    text(svg, tx, 50, `${tick} %`, { class: "axis-text", "text-anchor": "middle" });
  }

  rows.forEach((row, index) => {
    const y = top + index * rowHeight;
    text(svg, left - 18, y + 5, `${row.label} ${row.year}.`, { class: "row-label", "text-anchor": "end" });
    line(svg, x(row.baseline_share), y, x(row.general_share), y, {
      stroke: row.above_baseline ? circle("general").color : "#9b7a70",
      "stroke-width": 3,
      opacity: 0.65
    });
    svg.append(svgNode("circle", { cx: x(row.baseline_share), cy: y, r: 5, fill: "#a8adaf" }));
    svg.append(svgNode("circle", { cx: x(row.general_share), cy: y, r: 7, fill: circle("general").color, stroke: "white", "stroke-width": 2 }));
    text(svg, x(row.general_share) + 11, y + 5, pct(row.general_share), { class: "value-text", fill: circle("general").color });
  });
}

function renderNarrative() {
  document.querySelectorAll("[data-scope]").forEach(item => { item.textContent = D.scope; });
  document.querySelector("#metric-general-posts").textContent = HR0.format(D.findings.generalPosts);
  document.querySelector("#metric-catholic-posts").textContent = HR0.format(D.findings.catholicPosts);
  document.querySelector("#metric-general-brands").textContent = HR0.format(D.findings.generalBrands);
  document.querySelector("#metric-events").textContent = HR0.format(D.findings.namedEvents);

  const catholicTheme = D.findings.catholicTheme;
  const generalTheme = D.findings.generalTheme;
  document.querySelector("#hero-finding-title").textContent = D.findings.heroTitle;
  document.querySelector("#hero-finding-summary").textContent =
    `Tema „${catholicTheme.label}” zauzima ${pct(catholicTheme.catholic_share)} objava katoličkih izvora i ${pct(catholicTheme.general_share)} objava općih medija. Udio općih medija viši je od uobičajenoga u ${HR0.format(D.findings.eventsAboveBaseline)} od ${HR0.format(D.findings.namedEvents)} prepoznatih liturgijskih i papinskih valova.`;

  document.querySelector("#theme-reading").textContent =
    `Najveći pomak prema općim medijima vidi se u temi „${generalTheme.label}”. Ona ondje čini ${pct(generalTheme.general_share)} prepoznatih tema, a u katoličkim izvorima ${pct(generalTheme.catholic_share)}. Najveći pomak u suprotnome smjeru ima tema „${catholicTheme.label}”.`;

  const generalCoverage = D.themeCoverage.find(row => row.media_circle === "general");
  const catholicCoverage = D.themeCoverage.find(row => row.media_circle === "catholic");
  document.querySelector("#theme-coverage-note").textContent =
    `Projektni je rječnik prepoznao barem jednu temu u ${pct(generalCoverage.recognised_share)} web-objava općih medija s dostupnim tekstom i ${pct(catholicCoverage.recognised_share)} objava katoličkih izvora s dostupnim tekstom.`;

  const generalCategory = D.findings.generalCategory;
  const catholicCategory = D.findings.catholicCategory;
  document.querySelector("#category-reading").textContent =
    `Kategorija „${generalCategory.label}” ima najveći pomak prema općim medijima. Razlika iznosi ${HR1.format(Math.abs(generalCategory.gap))} postotnih bodova. Kategorija „${catholicCategory.label}” ima najveći pomak prema katoličkim izvorima. Ta razlika iznosi ${HR1.format(Math.abs(catholicCategory.gap))} postotnih bodova.`;

  document.querySelector("#event-reading").textContent =
    `Udio općih medija viši je od osnovice pripadajućega razdoblja u ${HR0.format(D.findings.eventsAboveBaseline)} od ${HR0.format(D.findings.namedEvents)} prepoznatih valova. Šira pozornost zato nije ograničena na krizne ili političke teme.`;

  document.querySelector("#conclusion-reading").textContent =
    `Opći mediji najviše mijenjaju ravnotežu prema temi „${generalTheme.label}”, dok tema „${catholicTheme.label}” ostaje snažnije zastupljena u katoličkom krugu. Istodobno, prepoznati blagdani i papinski događaji pokazuju da redovit crkveni kalendar može postati tema šire javnosti.`;

  document.querySelector("#caveat-list").innerHTML = D.method.caveats.map(item => `<li>${item}</li>`).join("");
  const grouped = D.method.themeCollapse.reduce((acc, item) => {
    (acc[item.theme] ||= []).push(item.category);
    return acc;
  }, {});
  document.querySelector("#theme-collapse").innerHTML = Object.entries(grouped).map(([theme, categories]) =>
    `<div><h3>${theme}</h3><p>${categories.join(" · ")}</p></div>`
  ).join("");
}

function improveScrollRegions() {
  document.querySelectorAll(".chart-scroll").forEach(region => {
    if (region.scrollWidth <= region.clientWidth + 1) region.removeAttribute("tabindex");
  });
}

renderNarrative();
drawThemeChart();
drawCategoryChart();
drawEventChart();
improveScrollRegions();
