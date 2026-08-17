#!/usr/bin/env node

import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { extname, resolve, sep } from "node:path";

const chrome = process.env.CHROME_PATH ||
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const siteRoot = resolve(process.argv[2] || "docs");
const pages = process.argv.slice(3).length ? process.argv.slice(3) : ["index.html"];

const mime = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml; charset=utf-8",
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

await new Promise((resolveListen) => server.listen(0, "127.0.0.1", resolveListen));
const port = server.address().port;
const profile = await mkdtemp(resolve(tmpdir(), "digikat-browser-check-"));
const debugPort = 9322;
const browser = spawn(chrome, [
  "--headless=new",
  "--disable-gpu",
  "--no-first-run",
  "--no-default-browser-check",
  `--remote-debugging-port=${debugPort}`,
  `--user-data-dir=${profile}`,
  "about:blank"
], { stdio: "ignore" });

const pause = (milliseconds) => new Promise((resolvePause) => setTimeout(resolvePause, milliseconds));
async function browserVersion() {
  for (let attempt = 0; attempt < 50; attempt += 1) {
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
await new Promise((resolveOpen, rejectOpen) => {
  socket.addEventListener("open", resolveOpen, { once: true });
  socket.addEventListener("error", rejectOpen, { once: true });
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
    findings.push(`${page}: exception: ${message.params.exceptionDetails.text}`);
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
  return new Promise((resolveMessage, rejectMessage) => {
    pending.set(id, { resolveMessage, rejectMessage });
  });
}

try {
  for (const page of pages) {
    const url = `http://127.0.0.1:${port}/${page.replace(/^\/+/, "")}`;
    const { targetId } = await command("Target.createTarget", { url: "about:blank" });
    const { sessionId } = await command("Target.attachToTarget", { targetId, flatten: true });
    sessions.set(sessionId, page);
    await command("Runtime.enable", {}, sessionId);
    await command("Network.enable", {}, sessionId);
    await command("Page.enable", {}, sessionId);
    await command("Page.navigate", { url }, sessionId);
    await pause(2500);
    await command("Target.closeTarget", { targetId });
  }
} finally {
  socket.close();
  browser.kill();
  await Promise.race([
    new Promise((resolveClose) => browser.once("close", resolveClose)),
    pause(2000)
  ]);
  server.close();
  for (let attempt = 0; attempt < 5; attempt += 1) {
    try {
      await rm(profile, { recursive: true, force: true });
      break;
    } catch (error) {
      if (attempt === 4) throw error;
      await pause(200);
    }
  }
}

if (findings.length) {
  console.error(findings.join("\n"));
  process.exitCode = 1;
} else {
  console.log(`Browser console clean for ${pages.length} page(s).`);
}
