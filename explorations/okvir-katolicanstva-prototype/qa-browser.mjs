import { spawn } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";

const root = path.dirname(fileURLToPath(import.meta.url));
const output = path.join(root, "output");
mkdirSync(output, { recursive: true });

const resolvedOutputRoot = path.resolve(output);
for (const entry of readdirSync(output, { withFileTypes: true })) {
  if (!entry.isDirectory() || !/^qa-profile-[a-z0-9_-]+$/i.test(entry.name)) continue;
  const staleProfile = path.resolve(output, entry.name);
  if (path.dirname(staleProfile) !== resolvedOutputRoot) {
    throw new Error(`Refusing to remove stale QA profile outside output: ${staleProfile}`);
  }
  try {
    rmSync(staleProfile, { recursive: true, force: true });
  } catch {
    // A stale browser child process may still hold a cache lock. A later run can retry.
  }
}

const chromeCandidates = [
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
];
const chromePath = chromeCandidates.find(existsSync);
if (!chromePath) throw new Error("Chrome or Edge was not found.");

const port = 9400 + Math.floor(Math.random() * 80);
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

async function waitForPage() {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const pages = await fetch(`http://127.0.0.1:${port}/json`).then(response => response.json());
      const page = pages.find(candidate => candidate.type === "page");
      if (page?.webSocketDebuggerUrl) return page.webSocketDebuggerUrl;
    } catch {
      // Browser startup is asynchronous.
    }
    await delay(100);
  }
  throw new Error("Chrome DevTools endpoint did not start.");
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
        const request = this.pending.get(message.id);
        this.pending.delete(message.id);
        if (message.error) request.reject(new Error(message.error.message));
        else request.resolve(message.result);
        return;
      }
      const listeners = this.listeners.get(message.method) || [];
      listeners.forEach(listener => listener(message.params));
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
    const listeners = this.listeners.get(method) || [];
    listeners.push(listener);
    this.listeners.set(method, listeners);
  }

  close() {
    this.socket.close();
  }
}

const exceptions = [];
let cdp;

async function inspectViewport(name, width, height, mobile) {
  await cdp.send("Emulation.setDeviceMetricsOverride", {
    width,
    height,
    deviceScaleFactor: 1,
    mobile
  });
  await cdp.send("Page.navigate", { url: pageUrl });
  await delay(600);

  const expression = `JSON.stringify({
    ready: document.readyState,
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    bodyWidth: Math.round(document.body.getBoundingClientRect().width),
    svgCount: document.querySelectorAll('svg').length,
    chartCount: document.querySelectorAll('.chart').length,
    figureCount: document.querySelectorAll('figure').length,
    tableCount: document.querySelectorAll('table').length,
    tableRows: document.querySelectorAll('tbody tr').length,
    visibleWords: (document.body.innerText.match(/[\\p{L}\\p{M}]+(?:[-’'][\\p{L}\\p{M}]+)*/gu) || []).length,
    articleWords: (() => {
      const article = document.querySelector('.article')?.cloneNode(true);
      if (!article) return 0;
      article.querySelectorAll('.chart, .sr-only').forEach(node => node.remove());
      return article.innerText.trim().split(/\\s+/).filter(Boolean).length;
    })(),
    analysisReady: document.documentElement.dataset.analysisReady === 'true',
    mojibakeMatches: (document.body.innerText.match(/[ÃÄÅÂ]/g) || []).length,
    missingCharts: Array.from(document.querySelectorAll('.chart')).filter(node => !node.querySelector('svg')).map(node => node.id),
    horizontalOverflow: Array.from(document.querySelectorAll('body *')).filter(node => {
      const style = getComputedStyle(node);
      return node.scrollWidth > node.clientWidth + 2 && !['auto', 'scroll'].includes(style.overflowX);
    }).slice(0, 15).map(node => ({tag: node.tagName, cls: node.className, id: node.id, client: node.clientWidth, scroll: node.scrollWidth}))
  })`;
  const evaluated = await cdp.send("Runtime.evaluate", { expression, returnByValue: true });
  const metrics = JSON.parse(evaluated.result.value);
  const screenshot = await cdp.send("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: false
  });
  writeFileSync(path.join(output, `${name}.png`), Buffer.from(screenshot.data, "base64"));
  const layout = await cdp.send("Page.getLayoutMetrics");
  const contentHeight = Math.min(Math.ceil(layout.cssContentSize.height), 30000);
  const fullScreenshot = await cdp.send("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: true,
    clip: { x: 0, y: 0, width, height: contentHeight, scale: 1 }
  });
  writeFileSync(path.join(output, `${name}-full.png`), Buffer.from(fullScreenshot.data, "base64"));
  if (name === "qa-desktop") {
    const boxesResult = await cdp.send("Runtime.evaluate", {
      expression: `JSON.stringify(Array.from(document.querySelectorAll('figure')).map((node, index) => {
        const box = node.getBoundingClientRect();
        return { index: index + 1, x: box.left + scrollX, y: box.top + scrollY, width: box.width, height: box.height };
      }))`,
      returnByValue: true
    });
    const boxes = JSON.parse(boxesResult.result.value);
    for (const box of boxes) {
      const detail = await cdp.send("Page.captureScreenshot", {
        format: "png",
        fromSurface: true,
        captureBeyondViewport: true,
        clip: { x: box.x, y: box.y, width: box.width, height: box.height, scale: 1 }
      });
      writeFileSync(path.join(output, `qa-figure-${box.index}.png`), Buffer.from(detail.data, "base64"));
    }
    const extraResult = await cdp.send("Runtime.evaluate", {
      expression: `JSON.stringify([
        ...Array.from(document.querySelectorAll('.table-card')).map((node, index) => ({ name: 'table-' + (index + 1), node })),
        { name: 'sources', node: document.querySelector('.source-guide') },
        { name: 'themes', node: document.querySelector('.theme-guide') },
        { name: 'concepts', node: document.querySelector('.concept-guide') },
        { name: 'verdict', node: document.querySelector('.verdict-box') },
        { name: 'method', node: document.querySelector('.method-box') }
      ].filter(item => item.node).map(item => {
        const box = item.node.getBoundingClientRect();
        return { name: item.name, x: box.left + scrollX, y: box.top + scrollY, width: box.width, height: box.height };
      }))`,
      returnByValue: true
    });
    const extras = JSON.parse(extraResult.result.value);
    for (const box of extras) {
      const detail = await cdp.send("Page.captureScreenshot", {
        format: "png",
        fromSurface: true,
        captureBeyondViewport: true,
        clip: { x: box.x, y: box.y, width: box.width, height: box.height, scale: 1 }
      });
      writeFileSync(path.join(output, `qa-${box.name}.png`), Buffer.from(detail.data, "base64"));
    }
  }
  metrics.contentHeight = contentHeight;
  return metrics;
}

try {
  cdp = new Cdp(await waitForPage());
  await cdp.open();
  cdp.on("Runtime.exceptionThrown", params => exceptions.push(params.exceptionDetails?.text || "Runtime exception"));
  cdp.on("Log.entryAdded", params => {
    if (["error", "warning"].includes(params.entry?.level)) exceptions.push(params.entry.text);
  });
  await cdp.send("Page.enable");
  await cdp.send("Runtime.enable");
  await cdp.send("Log.enable");

  const desktop = await inspectViewport("qa-desktop", 1440, 1200, false);
  const mobile = await inspectViewport("qa-mobile", 390, 1200, true);
  const results = { desktop, mobile, exceptions };
  const failures = [];

  for (const [viewport, metrics] of Object.entries({ desktop, mobile })) {
    const expectedCounts = {
      svgCount: 9,
      chartCount: 9,
      figureCount: 9,
      tableCount: 1,
      tableRows: 8
    };
    for (const [metric, expected] of Object.entries(expectedCounts)) {
      if (metrics[metric] !== expected) {
        failures.push(`${viewport}.${metric}: expected ${expected}, received ${metrics[metric]}`);
      }
    }
    if (metrics.missingCharts.length !== 0) {
      failures.push(`${viewport}.missingCharts: ${metrics.missingCharts.join(", ")}`);
    }
    if (metrics.clientWidth !== metrics.scrollWidth) {
      failures.push(`${viewport}.width: client ${metrics.clientWidth}, scroll ${metrics.scrollWidth}`);
    }
    if (!metrics.analysisReady) {
      failures.push(`${viewport}.analysisReady: generated data did not finish rendering`);
    }
    if (metrics.mojibakeMatches !== 0) {
      failures.push(`${viewport}.mojibakeMatches: ${metrics.mojibakeMatches}`);
    }
    // Keep the report readable while leaving detailed qualifications in project methodology.
    if (metrics.articleWords < 900 || metrics.articleWords > 1800) {
      failures.push(`${viewport}.articleWords: expected 900–1,800, received ${metrics.articleWords}`);
    }
  }
  if (exceptions.length !== 0) {
    failures.push(`exceptions: ${exceptions.join(" | ")}`);
  }

  process.stdout.write(`${JSON.stringify(results, null, 2)}\n`);
  if (failures.length !== 0) {
    throw new Error(`QA assertions failed:\n- ${failures.join("\n- ")}`);
  }
  await cdp.send("Browser.close");
} finally {
  cdp?.close();
  if (!browser.killed) browser.kill();
  await delay(750);
  const resolvedProfile = path.resolve(profile);
  if (path.dirname(resolvedProfile) !== resolvedOutputRoot || !path.basename(resolvedProfile).startsWith("qa-profile-")) {
    throw new Error(`Refusing to remove unexpected QA profile: ${resolvedProfile}`);
  }
  try {
    rmSync(resolvedProfile, { recursive: true, force: true });
  } catch {
    // A browser child process can briefly retain a cache lock on Windows. The ignored output can remain.
  }
}
