import { spawn } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";

const root = path.dirname(fileURLToPath(import.meta.url));
const output = path.join(root, "output");
mkdirSync(output, { recursive: true });

const chromeCandidates = [
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
];
const chromePath = chromeCandidates.find(existsSync);
if (!chromePath) throw new Error("Chrome or Edge was not found.");

const port = 9500 + Math.floor(Math.random() * 80);
const profile = mkdtempSync(path.join(output, "qa-profile-"));
const pageUrl = pathToFileURL(path.join(root, "index.html")).href;
const browser = spawn(chromePath, [
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
      const page = pages.find(candidate => candidate.type === "page");
      if (page?.webSocketDebuggerUrl) return page.webSocketDebuggerUrl;
    } catch {}
    await delay(100);
  }
  throw new Error("Browser debugging endpoint did not start.");
}

class Cdp {
  constructor(url) {
    this.socket = new WebSocket(url);
    this.pending = new Map();
    this.listeners = new Map();
    this.nextId = 0;
    this.socket.onmessage = event => {
      const message = JSON.parse(event.data);
      if (message.id && this.pending.has(message.id)) {
        const pending = this.pending.get(message.id);
        this.pending.delete(message.id);
        if (message.error) pending.reject(new Error(message.error.message));
        else pending.resolve(message.result);
      } else {
        (this.listeners.get(message.method) || []).forEach(listener => listener(message.params));
      }
    };
  }
  async open() {
    await new Promise((resolve, reject) => {
      this.socket.onopen = resolve;
      this.socket.onerror = reject;
    });
  }
  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = ++this.nextId;
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }
  on(method, listener) {
    this.listeners.set(method, [...(this.listeners.get(method) || []), listener]);
  }
  close() { this.socket.close(); }
}

const exceptions = [];
let cdp;

async function inspect(name, width, height, mobile) {
  await cdp.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile });
  await cdp.send("Page.navigate", { url: pageUrl });
  for (let attempt = 0; attempt < 60; attempt += 1) {
    const ready = await cdp.send("Runtime.evaluate", { expression: "document.documentElement.dataset.analysisReady === 'true'", returnByValue: true });
    if (ready.result.value) break;
    await delay(100);
  }
  const expression = `JSON.stringify({
    analysisReady: document.documentElement.dataset.analysisReady,
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    svgCount: document.querySelectorAll('.chart svg').length,
    figureCount: document.querySelectorAll('figure').length,
    tableCount: document.querySelectorAll('table').length,
    tableRows: document.querySelectorAll('tbody tr').length,
    actorCardCount: document.querySelectorAll('[data-actor-card]').length,
    forbiddenTerms: ['SPS', 'V1', 'V2', 'V3', 'V4', 'Politički portali'].filter(term => (document.querySelector('main')?.innerText || '').includes(term)),
    articleWords: (document.querySelector('.article')?.innerText || '').trim().split(/\\s+/).filter(Boolean).length,
    emptyCharts: Array.from(document.querySelectorAll('.chart')).filter(node => !node.querySelector('svg')).map(node => node.id),
    horizontalOverflow: Array.from(document.querySelectorAll('body *')).filter(node => {
      if (node.closest('.sr-only')) return false;
      const style = getComputedStyle(node);
      return node.scrollWidth > node.clientWidth + 3 && !['auto', 'scroll'].includes(style.overflowX);
    }).slice(0, 12).map(node => ({ tag: node.tagName, id: node.id, cls: node.className, client: node.clientWidth, scroll: node.scrollWidth }))
  })`;
  const evaluated = await cdp.send("Runtime.evaluate", { expression, returnByValue: true });
  const metrics = JSON.parse(evaluated.result.value);
  const layout = await cdp.send("Page.getLayoutMetrics");
  const contentHeight = Math.min(Math.ceil(layout.cssContentSize.height), 30000);
  const shot = await cdp.send("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: true,
    clip: { x: 0, y: 0, width, height: contentHeight, scale: 1 }
  });
  writeFileSync(path.join(output, `${name}-full.png`), Buffer.from(shot.data, "base64"));
  metrics.contentHeight = contentHeight;
  return metrics;
}

try {
  cdp = new Cdp(await endpoint());
  await cdp.open();
  cdp.on("Runtime.exceptionThrown", params => exceptions.push(params.exceptionDetails?.text || "Runtime exception"));
  cdp.on("Log.entryAdded", params => {
    if (["error", "warning"].includes(params.entry?.level)) exceptions.push(params.entry.text);
  });
  await cdp.send("Page.enable");
  await cdp.send("Runtime.enable");
  await cdp.send("Log.enable");

  const desktop = await inspect("qa-desktop", 1440, 1100, false);
  const mobile = await inspect("qa-mobile", 390, 1000, true);
  const failures = [];
  for (const [viewport, metrics] of Object.entries({ desktop, mobile })) {
    for (const [key, expected] of Object.entries({ svgCount: 2, figureCount: 2, tableCount: 0, tableRows: 0, actorCardCount: 4 })) {
      if (metrics[key] !== expected) failures.push(`${viewport}.${key}: expected ${expected}, received ${metrics[key]}`);
    }
    if (metrics.analysisReady !== "true") failures.push(`${viewport}.analysisReady: ${metrics.analysisReady}`);
    if (metrics.clientWidth !== metrics.scrollWidth) failures.push(`${viewport}.pageWidth: ${metrics.clientWidth}/${metrics.scrollWidth}`);
    if (metrics.emptyCharts.length) failures.push(`${viewport}.emptyCharts: ${metrics.emptyCharts.join(", ")}`);
    if (metrics.forbiddenTerms.length) failures.push(`${viewport}.forbiddenTerms: ${metrics.forbiddenTerms.join(", ")}`);
    if (metrics.horizontalOverflow.length) failures.push(`${viewport}.overflow: ${JSON.stringify(metrics.horizontalOverflow)}`);
    if (metrics.articleWords < 650 || metrics.articleWords > 1500) failures.push(`${viewport}.articleWords: ${metrics.articleWords}`);
  }
  if (exceptions.length) failures.push(`browser exceptions: ${exceptions.join(" | ")}`);
  process.stdout.write(`${JSON.stringify({ desktop, mobile, exceptions }, null, 2)}\n`);
  if (failures.length) throw new Error(`QA assertions failed:\n- ${failures.join("\n- ")}`);
  await cdp.send("Browser.close");
} finally {
  cdp?.close();
  if (!browser.killed) browser.kill();
  await delay(600);
  const resolved = path.resolve(profile);
  if (path.dirname(resolved) === path.resolve(output) && path.basename(resolved).startsWith("qa-profile-")) {
    try { rmSync(resolved, { recursive: true, force: true }); } catch {}
  }
}
