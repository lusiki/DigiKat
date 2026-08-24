#!/usr/bin/env node

import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdtemp, readFile, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { extname, resolve, sep } from "node:path";

const siteRoot = resolve(process.argv[2] || "docs");
const viewports = [320, 375, 390, 768, 1024, 1440, 2048];
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

try {
  for (const page of pages) {
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
  console.log(`Browser quality checks passed for ${pages.length} pages at ${viewports.join(", ")} px.`);
}
