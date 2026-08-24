import { spawn } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";

const root = path.dirname(fileURLToPath(import.meta.url));
const output = path.join(root, "output");
mkdirSync(output, { recursive: true });

const browserPath = [
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
].find(existsSync);
if (!browserPath) throw new Error("Chrome or Edge was not found.");

const port = 9480 + Math.floor(Math.random() * 60);
const profile = mkdtempSync(path.join(output, "qa-profile-"));
const pageUrl = pathToFileURL(path.join(root, "index.html")).href;
const browser = spawn(browserPath, [
  "--headless=new",
  "--disable-gpu",
  "--hide-scrollbars",
  `--remote-debugging-port=${port}`,
  `--user-data-dir=${profile}`,
  "about:blank"
], { stdio: "ignore", windowsHide: true });

const delay = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

async function endpoint() {
  for (let attempt = 0; attempt < 80; attempt += 1) {
    try {
      const pages = await fetch(`http://127.0.0.1:${port}/json`).then(response => response.json());
      const page = pages.find(item => item.type === "page");
      if (page?.webSocketDebuggerUrl) return page.webSocketDebuggerUrl;
    } catch {}
    await delay(100);
  }
  throw new Error("Browser endpoint did not start.");
}

class Cdp {
  constructor(url) {
    this.socket = new WebSocket(url);
    this.pending = new Map();
    this.nextId = 0;
    this.socket.onmessage = event => {
      const message = JSON.parse(event.data);
      if (!message.id || !this.pending.has(message.id)) return;
      const pending = this.pending.get(message.id);
      this.pending.delete(message.id);
      if (message.error) pending.reject(new Error(message.error.message));
      else pending.resolve(message.result);
    };
  }
  open() { return new Promise((resolve, reject) => { this.socket.onopen = resolve; this.socket.onerror = reject; }); }
  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = ++this.nextId;
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }
  close() { this.socket.close(); }
}

let cdp;
const failures = [];

async function inspect(name, width, height, mobile) {
  await cdp.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile });
  await cdp.send("Page.navigate", { url: pageUrl });
  await delay(900);
  const expression = `JSON.stringify({
    ready: document.readyState,
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    svgCount: document.querySelectorAll('.chart svg').length,
    figureCount: document.querySelectorAll('figure').length,
    chartCount: document.querySelectorAll('.chart').length,
    articleWords: (document.querySelector('.article')?.innerText || '').trim().split(/\\s+/).filter(Boolean).length,
    hero: document.querySelector('#hero-finding-title')?.textContent.trim(),
    missingCharts: Array.from(document.querySelectorAll('.chart')).filter(item => !item.querySelector('svg')).map(item => item.id),
    mojibake: /Ã|Ä|Å|Â/.test(document.body.innerText),
    legacyTerms: /nekonfesional|relativni indeks konflikta|\\bRIK\\b|tonalitet/i.test(document.querySelector('.article')?.innerText || ''),
    overflow: Array.from(document.querySelectorAll('body *')).filter(item => {
      const style = getComputedStyle(item);
      return item.scrollWidth > item.clientWidth + 2 && !['auto', 'scroll'].includes(style.overflowX);
    }).slice(0, 10).map(item => ({ tag: item.tagName, id: item.id, cls: item.className, client: item.clientWidth, scroll: item.scrollWidth }))
  })`;
  const evaluated = await cdp.send("Runtime.evaluate", { expression, returnByValue: true });
  const metrics = JSON.parse(evaluated.result.value);
  const screenshot = await cdp.send("Page.captureScreenshot", { format: "png", fromSurface: true, captureBeyondViewport: false });
  writeFileSync(path.join(output, `${name}.png`), Buffer.from(screenshot.data, "base64"));
  const layout = await cdp.send("Page.getLayoutMetrics");
  const contentHeight = Math.min(Math.ceil(layout.cssContentSize.height), 30000);
  const full = await cdp.send("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: true,
    clip: { x: 0, y: 0, width, height: contentHeight, scale: 1 }
  });
  writeFileSync(path.join(output, `${name}-full.png`), Buffer.from(full.data, "base64"));
  return metrics;
}

try {
  cdp = new Cdp(await endpoint());
  await cdp.open();
  await cdp.send("Page.enable");
  await cdp.send("Runtime.enable");
  const desktop = await inspect("qa-desktop", 1440, 1200, false);
  const mobile = await inspect("qa-mobile", 390, 1200, true);

  for (const [name, metrics] of Object.entries({ desktop, mobile })) {
    if (metrics.ready !== "complete") failures.push(`${name}: document not complete`);
    if (metrics.svgCount !== 3) failures.push(`${name}: expected 3 chart SVGs and found ${metrics.svgCount}`);
    if (metrics.figureCount !== 3) failures.push(`${name}: expected 3 figures and found ${metrics.figureCount}`);
    if (metrics.chartCount !== 3) failures.push(`${name}: expected 3 chart containers and found ${metrics.chartCount}`);
    if (metrics.clientWidth !== metrics.scrollWidth) failures.push(`${name}: body horizontal overflow ${metrics.clientWidth}/${metrics.scrollWidth}`);
    if (metrics.missingCharts.length) failures.push(`${name}: missing charts ${metrics.missingCharts.join(", ")}`);
    if (metrics.mojibake) failures.push(`${name}: possible mojibake`);
    if (metrics.legacyTerms) failures.push(`${name}: legacy report terminology remains`);
    if (metrics.articleWords < 700 || metrics.articleWords > 1500) failures.push(`${name}: article length is outside the intended range (${metrics.articleWords} words)`);
    if (!metrics.hero || metrics.hero.includes("učitava")) failures.push(`${name}: calculated hero finding did not render`);
  }

  process.stdout.write(`${JSON.stringify({ desktop, mobile, failures }, null, 2)}\n`);
  if (failures.length) throw new Error(`QA failed:\n- ${failures.join("\n- ")}`);
  await cdp.send("Browser.close");
} finally {
  cdp?.close();
  if (!browser.killed) browser.kill();
  await delay(600);
  const resolvedProfile = path.resolve(profile);
  const resolvedOutput = path.resolve(output);
  if (path.dirname(resolvedProfile) !== resolvedOutput || !path.basename(resolvedProfile).startsWith("qa-profile-")) {
    throw new Error(`Refusing to remove unexpected QA profile: ${resolvedProfile}`);
  }
  try { rmSync(resolvedProfile, { recursive: true, force: true }); } catch {}
}

