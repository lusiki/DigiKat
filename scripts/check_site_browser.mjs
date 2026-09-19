#!/usr/bin/env node

import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { extname, resolve, sep } from "node:path";

const siteRoot = resolve(process.argv[2] || "docs");
const viewports = [320, 375, 390, 768, 1024, 1366, 1440, 2048];
const pages = [
  "index.html",
  "pages/baza.html",
  "pages/metodologija.html",
  "pages/moj-medij.html",
  "pages/mapa/index.html",
  "pages/mapa/mapa.html",
  "pages/mapa/evolucija.html",
  "pages/mapa/mapa_stats.html",
  "pages/mapa/diskurs.html",
  "pages/mapa/događaji.html",
  "pages/studije/index.html",
  "pages/izvori/index.html",
  "pages/izvori/web-24sata-hr.html",
  "pages/izvori/youtube-laudatotv.html",
  "pages/izvori/facebook-laudato.html",
  "pages/izvori/instagram-laudatotv.html",
  "pages/izvori/tiktok-index-hr.html",
  "pages/izvori/twitter-24sata.html",
  "assets/izvjestaji/godisnji-pregled-2025.html",
  "assets/izvjestaji/kako-se-govori-o-crkvi/index.html"
];
// Audit either barometer edition whenever its rendered artifact is present.
const barometarPage = "pages/demokrscanstvo/index.html";
if (existsSync(resolve(siteRoot, barometarPage))) pages.push(barometarPage);
const requestedPages = process.argv.slice(3);
if (requestedPages.some(page => !pages.includes(page))) throw new Error("Unknown browser-check page.");
const selectedPages = requestedPages.length ? requestedPages : pages;

const chromeCandidates = [
  process.env.CHROME_PATH,
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
  "/usr/bin/google-chrome",
  "/usr/bin/google-chrome-stable",
  "/usr/bin/chromium",
  "/usr/bin/chromium-browser"
].filter(Boolean);
const chrome = chromeCandidates.find(existsSync);
if (!chrome) throw new Error("Chrome was not found. Set CHROME_PATH to run the browser release check.");

const axeSource = await readFile(resolve("node_modules", "axe-core", "axe.min.js"), "utf8");
const mime = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml; charset=utf-8",
  ".webp": "image/webp",
  ".woff": "font/woff",
  ".woff2": "font/woff2"
};

const server = createServer(async (request, response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
    let target = resolve(siteRoot, `.${pathname}`);
    if (target !== siteRoot && !target.startsWith(`${siteRoot}${sep}`)) {
      response.writeHead(403).end("Forbidden");
      return;
    }
    if ((await stat(target)).isDirectory()) target = resolve(target, "index.html");
    const body = await readFile(target);
    response.writeHead(200, { "content-type": mime[extname(target)] || "application/octet-stream" });
    response.end(body);
  } catch {
    response.writeHead(404).end("Not found");
  }
});

await new Promise((ready) => server.listen(0, "127.0.0.1", ready));
const port = server.address().port;
const profile = await mkdtemp(resolve(tmpdir(), "digikat-quality-browser-"));
const debugPort = 9323;
const browser = spawn(chrome, [
  "--headless=new",
  "--disable-gpu",
  "--no-first-run",
  "--no-default-browser-check",
  "--disable-background-networking",
  `--remote-debugging-port=${debugPort}`,
  `--user-data-dir=${profile}`,
  "about:blank"
], { stdio: "ignore" });

const pause = (milliseconds) => new Promise((done) => setTimeout(done, milliseconds));
async function browserVersion() {
  for (let attempt = 0; attempt < 80; attempt += 1) {
    try {
      const response = await fetch(`http://127.0.0.1:${debugPort}/json/version`);
      if (response.ok) return response.json();
    } catch {}
    await pause(100);
  }
  throw new Error("Chrome DevTools endpoint did not become available.");
}

const version = await browserVersion();
const socket = new WebSocket(version.webSocketDebuggerUrl);
await new Promise((open, reject) => {
  socket.addEventListener("open", open, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

let sequence = 0;
const pending = new Map();
const sessions = new Map();
const findings = [];
socket.addEventListener("message", ({ data }) => {
  const message = JSON.parse(data);
  if (message.id && pending.has(message.id)) {
    const { resolveMessage, rejectMessage } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) rejectMessage(new Error(message.error.message));
    else resolveMessage(message.result);
    return;
  }
  const page = sessions.get(message.sessionId) || "browser";
  if (message.method === "Runtime.exceptionThrown") {
    const details = message.params.exceptionDetails;
    const description = details.exception?.description || details.exception?.value || details.text;
    const location = details.url ? ` (${details.url}:${(details.lineNumber ?? 0) + 1})` : "";
    findings.push(`${page}: exception: ${description}${location}`);
  }
  if (message.method === "Runtime.consoleAPICalled" && ["error", "assert"].includes(message.params.type)) {
    const args = message.params.args.map((arg) => arg.value ?? arg.description ?? "").join(" ");
    findings.push(`${page}: console.${message.params.type}: ${args}`);
  }
  if (message.method === "Network.responseReceived" && message.params.response.status >= 400) {
    findings.push(`${page}: HTTP ${message.params.response.status}: ${message.params.response.url}`);
  }
  if (message.method === "Network.loadingFailed" && !message.params.canceled) {
    findings.push(`${page}: network failure: ${message.params.errorText}`);
  }
});

function command(method, params = {}, sessionId) {
  const id = ++sequence;
  socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
  return new Promise((resolveMessage, rejectMessage) => pending.set(id, { resolveMessage, rejectMessage }));
}

async function evaluate(expression, sessionId, awaitPromise = false) {
  const result = await command("Runtime.evaluate", {
    expression,
    awaitPromise,
    returnByValue: true,
    userGesture: true
  }, sessionId);
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text || "browser evaluation failed");
  return result.result.value;
}

async function waitForReady(sessionId) {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    if (await evaluate("document.readyState === 'complete'", sessionId)) return;
    await pause(100);
  }
  throw new Error("Page did not reach document.readyState=complete.");
}

const auditExpression = `(async () => {
  const results = await axe.run(document, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] },
    resultTypes: ['violations']
  });
  return results.violations
    .filter((item) => item.impact === 'serious' || item.impact === 'critical')
    .map((item) => ({
      id: item.id,
      impact: item.impact,
      help: item.help,
      targets: item.nodes.slice(0, 4).map((node) => node.target.join(' '))
    }));
})()`;

const layoutExpression = `(() => {
  const root = document.documentElement;
  const overflow = root.scrollWidth > window.innerWidth + 1;
  const offenders = overflow ? [...document.querySelectorAll('body *')]
    .filter((element) => {
      const rect = element.getBoundingClientRect();
      if (!rect.width || getComputedStyle(element).position === 'fixed') return false;
      return rect.right > window.innerWidth + 1 || rect.left < -1;
    })
    .slice(0, 8)
    .map((element) => element.tagName.toLowerCase() + (element.id ? '#' + element.id : '') +
      (element.classList.length ? '.' + [...element.classList].slice(0, 2).join('.') : '')) : [];
  const focusable = document.querySelector('main a[href], main button:not([disabled]), main input:not([disabled]), main summary, footer a[href]');
  let focusVisible = true;
  if (focusable) {
    focusable.focus();
    const style = getComputedStyle(focusable);
    focusVisible = (style.outlineStyle !== 'none' && parseFloat(style.outlineWidth) > 0) || style.boxShadow !== 'none';
  }
  return { overflow, scrollWidth: root.scrollWidth, viewport: window.innerWidth, offenders, focusVisible };
})()`;

const motionExpression = `(() => {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const html = getComputedStyle(document.documentElement);
  const animated = [...document.querySelectorAll('body *')].filter((element) => {
    const style = getComputedStyle(element);
    const durations = (style.animationDuration + ',' + style.transitionDuration)
      .split(',').map((value) => parseFloat(value) || 0);
    return Math.max(...durations) > 0.02;
  }).slice(0, 5).map((element) => element.tagName.toLowerCase() + (element.className ? '.' + String(element.className).split(' ').slice(0, 2).join('.') : ''));
  return { reduced, scrollBehavior: html.scrollBehavior, animated };
})()`;

const mapFigureExpression = `(() => {
  const cells = [...document.querySelectorAll('main .cell.page-full')];
  const figures = cells.map((cell) => cell.querySelector('figure.figure')).filter(Boolean);
  const images = figures.map((figure) => figure.querySelector('img.figure-img')).filter(Boolean);
  const scrollers = figures.map((figure) => figure.querySelector(':scope > p')).filter(Boolean);
  const prose = [...document.querySelectorAll('main p')].find((paragraph) =>
    !paragraph.closest('figure') && !paragraph.classList.contains('page-full') &&
    paragraph.getBoundingClientRect().width > 250
  );
  const proseCenter = prose ? prose.getBoundingClientRect().left + prose.getBoundingClientRect().width / 2 : null;
  const centers = cells.map((cell) => {
    const box = cell.getBoundingClientRect();
    return box.left + box.width / 2;
  });
  const paper = figures.every((figure) => getComputedStyle(figure).backgroundColor === 'rgb(245, 244, 240)');
  const mobile = window.innerWidth < 768;
  return {
    count: figures.length,
    internalOverflow: scrollers.some((scroller) => scroller.scrollWidth > scroller.clientWidth + 1),
    maxWidth: Math.max(0, ...cells.map((cell) => cell.getBoundingClientRect().width)),
    centerDelta: proseCenter === null ? null : Math.max(0, ...centers.map((center) => Math.abs(center - proseCenter))),
    paper,
    intrinsicDimensions: images.every((image) => Number(image.getAttribute('width')) > 0 && Number(image.getAttribute('height')) > 0),
    correctSource: images.every((image) => mobile
      ? image.getAttribute('src').includes('/assets/images/maps/mobile/') || image.getAttribute('src').startsWith('../../assets/images/maps/mobile/')
      : !image.getAttribute('src').includes('/assets/images/maps/mobile/') && !image.getAttribute('src').startsWith('../../assets/images/maps/mobile/'))
  };
})()`;

const homepageExpression = `(() => {
  window.scrollTo(0, 0);
  const navbar = document.querySelector('.navbar');
  const hero = document.querySelector('.home-hero');
  const inner = hero?.querySelector('.home-section__inner');
  const credit = hero?.querySelector('.home-credits');
  const titleBlock = document.querySelector('#title-block-header');
  const author = credit?.querySelector('a[rel="author"]');
  const institution = credit?.querySelector('a[href="https://www.unicath.hr/"]');
  if (!navbar || !hero || !inner || !credit) return { ok: false, reason: 'missing homepage structure' };
  const navbarBox = navbar.getBoundingClientRect();
  const creditBox = credit.getBoundingClientRect();
  const innerBox = inner.getBoundingClientRect();
  const titleBlockHeight = titleBlock?.getBoundingClientRect().height || 0;
  const sideDifference = Math.abs(innerBox.left - (document.documentElement.clientWidth - innerBox.right));
  return {
    ok: titleBlockHeight <= 1 && !titleBlock?.textContent.trim() &&
      creditBox.top - navbarBox.bottom >= 40 && creditBox.top - navbarBox.bottom <= 140 &&
      sideDifference <= 2 &&
      author?.textContent.trim() === 'Luka Šikić' &&
      author?.href === 'https://www.lukasikic.info/' &&
      institution?.textContent.trim() === 'Hrvatsko katoličko sveučilište',
    titleBlockHeight: Math.round(titleBlockHeight),
    titleBlockText: titleBlock?.textContent.trim() || '',
    heroGap: Math.round(creditBox.top - navbarBox.bottom),
    sideDifference: Math.round(sideDifference),
    authorText: author?.textContent.trim() || '',
    authorHref: author?.href || '',
    institutionText: institution?.textContent.trim() || ''
  };
})()`;

const mojMedijExpression = `(async () => {
  const input = document.querySelector('#mm-q');
  const results = document.querySelector('#mm-results');
  const status = document.querySelector('#mm-status');
  const detail = document.querySelector('#mm-detail');
  if (!input || !results || !status || !detail) return { ok: false, reason: 'missing application controls' };
  input.focus();
  input.value = 'la';
  input.dispatchEvent(new Event('input', { bubbles: true }));
  await new Promise((done) => setTimeout(done, 30));
  const optionCount = results.querySelectorAll('[role="option"]').length;
  input.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }));
  const active = input.getAttribute('aria-activedescendant');
  input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
  await new Promise((done) => setTimeout(done, 30));
  return {
    ok: optionCount > 0 && Boolean(active) && detail.children.length > 0 && status.textContent.trim().length > 0,
    optionCount,
    active,
    detailChildren: detail.children.length,
    announcement: status.textContent.trim()
  };
})()`;

const barometarExpression = `(async () => {
  const overview = document.querySelector('section#pregled');
  const live = document.querySelector('#dkb-state');
  const params = new URL(location.href).searchParams;
  const matrix = document.querySelector('#dkb-matrix');
  const columns = matrix?.tHead?.rows[0]?.cells.length - 1;
  const keyboardState = overview?.dataset.frequency === 'weekly' &&
    overview?.dataset.scope === 'uze' &&
    document.querySelector('input[name=frequency][value=weekly]')?.checked &&
    document.querySelector('input[name=scope][value=uze]')?.checked &&
    params.get('ucestalost') === 'tjedno' && params.get('obuhvat') === 'uze' &&
    live?.getAttribute('aria-live') === 'polite' &&
    live.textContent.includes('tjedno') && live.textContent.includes('uže');
  const announcement = live?.textContent.trim();
  const payload = JSON.parse(document.querySelector('#dkb-payload').textContent);
  const core = window.BarometarCore;
  const rows = core.unpack(payload.tables.monthly).filter(row => row.scope === 'uze');

  // Use the real range controls to expose the historical collection boundary.
  document.querySelector('input[name=frequency][value=monthly]').click();
  const range = document.querySelector('#dkb-range');
  range.value = 'all';
  range.dispatchEvent(new Event('change', { bubbles: true }));
  await new Promise(done => requestAnimationFrame(() => requestAnimationFrame(done)));
  const boundary = '2024-04-01';
  const sourceSpansBoundary = rows.some(row => row.period_end < boundary) &&
    rows.some(row => row.period_end >= boundary);
  const seam = ['visibility_per_10000', 'breadth_pct'].map((metric, i) => {
    const svg = document.querySelector(i ? '#dkb-breadth-chart svg' : '#dkb-vis-chart svg');
    const marker = svg?.querySelector('line[stroke-dasharray="4 4"]');
    const seamX = Number(marker?.getAttribute('x1'));
    const paths = [...(svg?.querySelectorAll('path.series') || [])];
    const crossings = paths.filter(path => {
      const points = path.getAttribute('d').trim().split(/(?=[ML])/).map(command => ({
        move: command[0] === 'M', x: Number(command.slice(1).split(',')[0])
      }));
      return points.some((point, n) => n > 0 && !point.move &&
        points[n - 1].x < seamX && point.x >= seamX);
    }).length;
    const coreCrossings = core.segments(rows, metric).filter(segment =>
      segment.some(row => row.period_end < boundary) &&
      segment.some(row => row.period_end >= boundary)
    ).length;
    return { metric, marker: Boolean(marker), paths: paths.length, crossings, coreCrossings };
  });

  // The latest twelve periods need not contain an outage. Select the most recent
  // unavailable month so the em-dash assertion cannot pass on an empty cell list.
  const missingIndex = rows.findLastIndex(row => row.visibility_status === 'unavailable');
  if (missingIndex >= 0) {
    document.querySelector('#dkb-from').value = rows[Math.max(0, missingIndex - 11)].period_id;
    const to = document.querySelector('#dkb-to');
    to.value = rows[missingIndex].period_id;
    to.dispatchEvent(new Event('change', { bubbles: true }));
  }
  const unavailable = [...matrix.querySelectorAll('td.dkb-missing-cell')];
  const unavailableCells = unavailable.length;
  const unavailableText = unavailable.every(cell => cell.textContent.trim() === '—');
  return {
    ok: Boolean(keyboardState) && columns === 12 && sourceSpansBoundary &&
      seam.every(item => item.marker && item.paths > 0 && !item.crossings && !item.coreCrossings) &&
      missingIndex >= 0 && unavailableCells > 0 && unavailableText,
    keyboardState: Boolean(keyboardState), columns, announcement,
    sourceSpansBoundary, seam, unavailableCells, unavailableText
  };
})()`;

const multiplatformExpression = `(async () => {
  const data = JSON.parse(document.querySelector('#mp-data').textContent);
  const platform = document.querySelector('#mp-platform');
  const scope = document.querySelector('#mp-scope');
  const measure = document.querySelector('#mp-measure');
  const basis = document.querySelector('#mp-text');
  const status = document.querySelector('#mp-status');
  const keyboardState = platform.selectedIndex === platform.options.length - 1 &&
    scope.value === 'narrow' && measure.value === 'count' && basis.value === 'full';
  const announcement = status.textContent.trim();
  const live = status.getAttribute('aria-live') === 'polite' &&
    announcement.includes(platform.selectedOptions[0].textContent) &&
    announcement.includes(scope.selectedOptions[0].textContent) &&
    announcement.includes(measure.selectedOptions[0].textContent) &&
    announcement.includes(basis.selectedOptions[0].textContent);
  const change = (control, value) => {
    control.value = value;
    control.dispatchEvent(new Event('change', { bubbles: true }));
  };
  change(platform, 'web'); change(scope, 'broad'); change(measure, 'rate'); change(basis, 'all');
  const svg = document.querySelector('#mp-chart svg');
  const marker = svg?.querySelector('line[stroke-dasharray]');
  const seamX = Number(marker?.getAttribute('x1'));
  const paths = [...svg.querySelectorAll('polyline.series')];
  const crossings = paths.filter(path => {
    const xs = path.getAttribute('points').trim().split(/\\s+/).map(point => Number(point.split(',')[0]));
    return xs.some(x => x < seamX) && xs.some(x => x >= seamX);
  }).length;
  const sourceSpansBoundary = data.monthly.some(row => row.platform === 'web' && row.month < '2024-04' && row.eligible_records > 0) &&
    data.monthly.some(row => row.platform === 'web' && row.month >= '2024-04' && row.eligible_records > 0);
  const webRows = data.monthly.filter(row => row.platform === 'web');
  const table = document.querySelector('#mp-monthly table');
  const latest = webRows[webRows.length - 1];
  const first = table.tBodies[0].rows[0];
  const fmt = (n, digits = 0) => Number(n).toLocaleString('hr-HR', { minimumFractionDigits: digits, maximumFractionDigits: digits });
  const tableMatches = table.tBodies[0].rows.length === webRows.length &&
    first.cells[0].textContent === latest.month && first.cells[1].textContent === fmt(latest.matching_records) &&
    first.cells[2].textContent === fmt(latest.eligible_records) &&
    first.cells[3].textContent === fmt(10000 * latest.matching_records / latest.eligible_records, 2);
  const missing = data.monthly.find(row => !row.eligible_records);
  if (missing) change(platform, missing.platform);
  const missingRow = [...document.querySelectorAll('#mp-monthly tbody tr')].find(row => row.cells[0].textContent === missing?.month);
  const unavailableText = missingRow?.cells[1].textContent === '—' && missingRow?.cells[3].textContent === '—';
  const fallback = document.querySelector('#mp-static').hidden && !document.querySelector('#mp-interactive').hidden;
  change(platform, 'web');
  return {
    ok: keyboardState && live && platform.options.length === Object.keys(data.summary.platform_labels).length &&
      Boolean(marker) && paths.length >= 2 && !crossings && sourceSpansBoundary && tableMatches && unavailableText && fallback,
    keyboardState, live, announcement, platforms: platform.options.length,
    marker: Boolean(marker), paths: paths.length, crossings, sourceSpansBoundary, tableMatches, unavailableText, fallback
  };
})()`;

async function checkMultiplatformBarometar(sessionId) {
  for (const selector of ['#mp-platform', '#mp-scope', '#mp-measure', '#mp-text']) {
    await evaluate(`document.querySelector(${JSON.stringify(selector)}).focus()`, sessionId);
    for (const type of ['keyDown', 'keyUp']) {
      await command('Input.dispatchKeyEvent', {
        type, key: 'End', code: 'End', windowsVirtualKeyCode: 35, nativeVirtualKeyCode: 35
      }, sessionId);
    }
    await pause(40);
  }
  const existing = await evaluate(multiplatformExpression, sessionId, true);
  const themes = await evaluate(`(() => {
    const data=JSON.parse(document.querySelector('#mt-data').textContent);
    const platform=document.querySelector('#mt-platform'),year=document.querySelector('#mt-year');
    const change=(node,value)=>{node.value=value;node.dispatchEvent(new Event('change',{bubbles:true}));};
    const initial=document.querySelectorAll('#mt-topics button').length===data.topics.length;
    change(platform,'web');change(year,'2025');
    const n=data.monthly.filter(r=>r.platform==='web'&&r.month.startsWith('2025-')).reduce((a,r)=>a+r.records,0);
    const filtered=document.querySelector('#mt-status').textContent.includes(n.toLocaleString('hr-HR')+' objava');
    const buttons=[...document.querySelectorAll('#mt-topics button')];
    const picked=buttons[buttons.length-1];picked.focus();picked.click();
    const selected=picked.getAttribute('aria-pressed')==='true'&&document.activeElement===picked&&
      document.querySelector('#mt-detail h3').textContent===data.topics.find(t=>t.id===picked.dataset.topic).label;
    change(platform,'bluesky');
    const empty=!document.querySelector('#mt-topics button')&&document.querySelector('#mt-detail').textContent.includes('Nema objava');
    document.querySelector('#mt-reset').click();
    const reset=platform.value==='all'&&year.value==='all'&&document.querySelectorAll('#mt-topics button').length===data.topics.length;
    const fallback=document.querySelector('#mt-static').hidden&&!document.querySelector('#mt-interactive').hidden;
    return {ok:initial&&filtered&&selected&&empty&&reset&&fallback,initial,filtered,selected,empty,reset,fallback};
  })()`,sessionId);
  // Native keyboard activation also updates the topic detail without losing focus.
  await evaluate("document.querySelectorAll('#mt-topics button')[1].focus()",sessionId);
  for (const type of ['keyDown','keyUp']) await command('Input.dispatchKeyEvent',{
    type,key:'Enter',code:'Enter',windowsVirtualKeyCode:13,nativeVirtualKeyCode:13,
    ...(type==='keyDown'?{text:'\r',unmodifiedText:'\r'}:{})
  },sessionId);
  const topicKeyboard=await evaluate("document.activeElement.getAttribute('aria-pressed')==='true'",sessionId);
  await evaluate("document.querySelector('#mt-reset').click()",sessionId);
  return {...existing,themes,topicKeyboard,ok:existing.ok&&themes.ok&&topicKeyboard};
}

async function checkBarometar(sessionId) {
  if (await evaluate("Boolean(document.querySelector('#mp-data'))", sessionId)) {
    return checkMultiplatformBarometar(sessionId);
  }
  const controls = await evaluate(`(() => {
    const weekly = document.querySelector('input[name=frequency][value=weekly]');
    const broad = document.querySelector('input[name=scope][value=siri]');
    const narrow = document.querySelector('input[name=scope][value=uze]');
    return { ready: Boolean(weekly && !weekly.disabled && narrow && !narrow.disabled &&
      window.BarometarCore && document.querySelector('#dkb-payload') &&
      document.querySelector('#dkb-matrix')), broad: Boolean(broad && !broad.disabled) };
  })()`, sessionId);
  if (!controls.ready) return { ok: false, reason: 'missing or disabled barometer controls' };
  // CDP keyboard input invokes the browser's native radio behavior; synthetic
  // KeyboardEvents would not prove that these controls are keyboard operable.
  const selectors = [
    ...(controls.broad ? ['input[name=scope][value=siri]'] : []),
    'input[name=frequency][value=weekly]',
    'input[name=scope][value=uze]'
  ];
  for (const selector of selectors) {
    await evaluate(`document.querySelector(${JSON.stringify(selector)}).focus()`, sessionId);
    for (const type of ['keyDown', 'keyUp']) {
      await command('Input.dispatchKeyEvent', {
        type, key: ' ', code: 'Space', windowsVirtualKeyCode: 32, nativeVirtualKeyCode: 32
      }, sessionId);
    }
    await pause(40);
  }
  return evaluate(barometarExpression, sessionId, true);
}

try {
  for (const page of selectedPages) {
    const url = `http://127.0.0.1:${port}/${page}`;
    const { targetId } = await command("Target.createTarget", { url: "about:blank" });
    const { sessionId } = await command("Target.attachToTarget", { targetId, flatten: true });
    sessions.set(sessionId, page);
    await command("Runtime.enable", {}, sessionId);
    await command("Network.enable", {}, sessionId);
    await command("Page.enable", {}, sessionId);
    await command("Emulation.setDeviceMetricsOverride", {
      width: 1024, height: 900, deviceScaleFactor: 1, mobile: false
    }, sessionId);
    await command("Page.navigate", { url }, sessionId);
    await waitForReady(sessionId);
    await pause(250);
    await evaluate(axeSource, sessionId);

    for (const width of viewports) {
      await command("Emulation.setDeviceMetricsOverride", {
        width, height: 900, deviceScaleFactor: 1, mobile: width < 768
      }, sessionId);
      await pause(80);
      const layout = await evaluate(layoutExpression, sessionId);
      if (layout.overflow) {
        findings.push(`${page} @ ${width}px: page width ${layout.scrollWidth}px; offenders: ${layout.offenders.join(", ") || "unknown"}`);
      }
      if (!layout.focusVisible) findings.push(`${page} @ ${width}px: first interactive element has no visible keyboard focus`);
      if (page.startsWith("pages/mapa/") && page !== "pages/mapa/index.html") {
        const mapFigures = await evaluate(mapFigureExpression, sessionId);
        if (!mapFigures.count || mapFigures.internalOverflow || !mapFigures.paper ||
            !mapFigures.intrinsicDimensions || !mapFigures.correctSource ||
            (width >= 1024 && mapFigures.maxWidth > 961) ||
            (width >= 1024 && mapFigures.centerDelta !== null && mapFigures.centerDelta > 2)) {
          findings.push(`${page} @ ${width}px: map figure contract failed (${JSON.stringify(mapFigures)})`);
        }
      }
      if (page === "index.html") {
        const homepage = await evaluate(homepageExpression, sessionId);
        if (!homepage.ok) findings.push(`${page} @ ${width}px: homepage layout/credit contract failed (${JSON.stringify(homepage)})`);
      }
      const violations = await evaluate(auditExpression, sessionId, true);
      for (const violation of violations) {
        findings.push(`${page} @ ${width}px: ${violation.impact} ${violation.id} — ${violation.help} (${violation.targets.join(", ")})`);
      }
    }

    await command("Emulation.setEmulatedMedia", {
      media: "screen",
      features: [{ name: "prefers-reduced-motion", value: "reduce" }]
    }, sessionId);
    const motion = await evaluate(motionExpression, sessionId);
    if (!motion.reduced || motion.scrollBehavior !== "auto" || motion.animated.length) {
      findings.push(`${page}: reduced-motion contract failed (${JSON.stringify(motion)})`);
    }
    await command("Emulation.setEmulatedMedia", { media: "screen", features: [] }, sessionId);

    if (page === "pages/moj-medij.html") {
      const interaction = await evaluate(mojMedijExpression, sessionId, true);
      if (!interaction.ok) findings.push(`${page}: keyboard combobox/announcement check failed (${JSON.stringify(interaction)})`);
    }
    if (page === barometarPage) {
      const interaction = await checkBarometar(sessionId);
      if (!interaction.ok) findings.push(`${page}: barometer keyboard/data/live-region/collection-boundary contract failed (${JSON.stringify(interaction)})`);
      if (process.env.DIGIKAT_SCREENSHOT_DIR) {
        const output=resolve(process.env.DIGIKAT_SCREENSHOT_DIR);
        await mkdir(output,{recursive:true});
        for (const width of [1440,390]) {
          await command('Emulation.setDeviceMetricsOverride',{width,height:1000,deviceScaleFactor:1,mobile:false},sessionId);
          await pause(250);
          await evaluate("document.querySelector('#teme').scrollIntoView()",sessionId);
          await pause(200);
          const shot=await command('Page.captureScreenshot',{format:'png'},sessionId);
          await writeFile(resolve(output,`barometar-themes-${width}.png`),Buffer.from(shot.data,'base64'));
        }
      }
      await command('Emulation.setScriptExecutionDisabled',{value:true},sessionId);
      await command('Page.reload',{},sessionId);
      await pause(1000);
      const staticVisible=await evaluate("!document.querySelector('#mt-static').hidden && document.querySelector('#mt-static table tbody').rows.length > 0 && !document.querySelector('#mp-static').hidden",sessionId);
      if (!staticVisible) findings.push(`${page}: no-JavaScript static fallback is missing`);
    }
    await command("Target.closeTarget", { targetId });
  }
} finally {
  socket.close();
  browser.kill();
  await Promise.race([new Promise((closed) => browser.once("close", closed)), pause(2000)]);
  server.close();
  for (let attempt = 0; attempt < 5; attempt += 1) {
    try { await rm(profile, { recursive: true, force: true }); break; }
    catch (error) {
      if (attempt === 4) throw error;
      await pause(200);
    }
  }
}

if (findings.length) {
  console.error(`Browser quality check found ${findings.length} issue(s):`);
  console.error(findings.map((finding) => `- ${finding}`).join("\n"));
  process.exitCode = 1;
} else {
  console.log(`Browser quality checks passed for ${selectedPages.length} pages at ${viewports.join(", ")} px.`);
}
