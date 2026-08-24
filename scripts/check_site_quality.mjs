#!/usr/bin/env node

import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, extname, posix, relative, resolve, sep } from "node:path";

const siteRoot = resolve(process.argv[2] || "docs");
const projectRoot = process.cwd();
const origin = "https://lusiki.github.io/DigiKat/";
const allowedStatuses = [
  "Radni prikaz", "Preliminarno", "Ažurira se", "Stabilno izdanje", "Arhivirano",
  "Working view", "Preliminary", "Updated", "Stable edition", "Archived"
];

function walk(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = resolve(directory, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

function rel(path) {
  return relative(siteRoot, path).split(sep).join("/");
}

function activeHtml(path) {
  const file = rel(path);
  return file === "index.html" || file.startsWith("pages/") || [
    "assets/izvjestaji/godisnji-pregled-2025.html",
    "assets/izvjestaji/annual-review-2025.html",
    "assets/izvjestaji/kako-se-govori-o-crkvi/index.html"
  ].includes(file);
}

const allFiles = walk(siteRoot);
const allRelativeFiles = new Set(allFiles.map(rel));
const htmlFiles = allFiles.filter((path) => extname(path).toLowerCase() === ".html" && activeHtml(path));
const findings = [];
const descriptions = new Map();
const weights = [];

function fail(file, message) {
  findings.push(`${file}: ${message}`);
}

function attr(html, elementPattern, attribute) {
  const match = html.match(elementPattern);
  if (!match) return "";
  const value = match[0].match(new RegExp(`${attribute}=["']([^"']*)["']`, "i"));
  return value ? value[1].trim() : "";
}

function meta(html, key, attribute = "name") {
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return attr(html, new RegExp(`<meta\\s+[^>]*${attribute}=["']${escaped}["'][^>]*>`, "i"), "content");
}

function stripTags(value) {
  return value.replace(/<[^>]+>/g, " ").replace(/&[^;]+;/g, " ").replace(/\s+/g, " ").trim();
}

function pathFromUrl(value, fromFile) {
  if (!value || /^(?:mailto:|tel:|javascript:|data:)/i.test(value)) return null;
  let pathname = value.split("#")[0].split("?")[0];
  if (!pathname) return null;
  if (/^https?:\/\//i.test(pathname)) {
    let url;
    try { url = new URL(pathname); } catch { return null; }
    if (url.origin !== new URL(origin).origin || !url.pathname.startsWith("/DigiKat/")) return null;
    pathname = url.pathname.slice("/DigiKat/".length);
  } else if (pathname.startsWith("/DigiKat/")) {
    pathname = pathname.slice("/DigiKat/".length);
  } else if (pathname.startsWith("/")) {
    return null;
  } else {
    pathname = posix.normalize(posix.join(posix.dirname(fromFile), pathname));
  }
  try { pathname = decodeURIComponent(pathname); } catch {}
  return pathname.replace(/^\.\//, "");
}

function resolveTarget(value, fromFile) {
  if (value.startsWith("#")) return fromFile;
  let target = pathFromUrl(value, fromFile);
  if (target === null) return null;
  if (target === "" || target.endsWith("/")) target += "index.html";
  return target;
}

function jsonTypes(value, output = new Set()) {
  if (!value || typeof value !== "object") return output;
  if (typeof value["@type"] === "string") output.add(value["@type"]);
  if (Array.isArray(value["@type"])) value["@type"].forEach((type) => output.add(type));
  Object.values(value).forEach((child) => jsonTypes(child, output));
  return output;
}

function pngDimensions(path) {
  const buffer = readFileSync(path);
  if (buffer.length < 24 || buffer.toString("ascii", 1, 4) !== "PNG") return null;
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}

function pageClass(file) {
  if (file === "pages/moj-medij.html") return ["Moj medij", 2_000_000];
  if (file === "pages/izvori/mreza.html") return ["mreža izvora", 2_000_000];
  if (file.startsWith("pages/mapa/")) return ["mapa", 8_000_000];
  if (file.startsWith("assets/izvjestaji/")) return ["izvještaj", 5_000_000];
  if (file.startsWith("pages/pregled/")) return ["pregled", 2_000_000];
  return ["standardna", 1_500_000];
}

for (const path of htmlFiles) {
  const file = rel(path);
  const html = readFileSync(path, "utf8");
  const semanticHtml = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "");

  const h1Count = (semanticHtml.match(/<h1(?:\s|>)/gi) || []).length;
  if (h1Count !== 1) fail(file, `expected exactly one H1, found ${h1Count}`);

  const headings = [...semanticHtml.matchAll(/<h([1-6])(?:\s[^>]*)?>([\s\S]*?)<\/h\1>/gi)]
    .map((match) => ({ level: Number(match[1]), text: stripTags(match[2]) }));
  // The annual reviews use H4 as non-sectional figure/table titles by design.
  if (!file.startsWith("assets/izvjestaji/")) {
    for (let index = 1; index < headings.length; index += 1) {
      if (headings[index].level > headings[index - 1].level + 1) {
        fail(file, `heading order skips from H${headings[index - 1].level} to H${headings[index].level} at “${headings[index].text}”`);
        break;
      }
    }
  }

  const description = meta(html, "description");
  if (!description) fail(file, "missing or empty meta description");
  else {
    const used = descriptions.get(description) || [];
    used.push(file);
    descriptions.set(description, used);
  }

  const title = stripTags((html.match(/<title>([\s\S]*?)<\/title>/i) || ["", ""])[1]);
  if (!title) fail(file, "missing title element");
  if ((title.match(/DigiKat/gi) || []).length > 1) fail(file, `site name is duplicated in title “${title}”`);

  const canonical = attr(html, /<link\s+[^>]*rel=["']canonical["'][^>]*>/i, "href");
  if (!canonical) fail(file, "missing canonical URL");
  else if (!canonical.startsWith(origin)) fail(file, `canonical URL is outside the DigiKat origin: ${canonical}`);

  const isProfile = /^pages\/izvori\/(?:web|youtube|facebook|instagram|tiktok|twitter)-.+\.html$/.test(file);
  const ogImage = meta(html, "og:image", "property");
  const twitterImage = meta(html, "twitter:image");
  if (!isProfile && (!ogImage || !twitterImage)) fail(file, "missing Open Graph or Twitter preview image");
  for (const [label, image] of [["Open Graph", ogImage], ["Twitter", twitterImage]]) {
    if (!image) continue;
    const target = resolveTarget(image, file);
    if (target && !allRelativeFiles.has(target)) fail(file, `${label} image does not resolve: ${image}`);
    const alt = label === "Open Graph" ? meta(html, "og:image:alt", "property") : meta(html, "twitter:image:alt");
    if (!alt) fail(file, `${label} image has no alternative text`);
  }

  const schemas = new Set();
  for (const match of html.matchAll(/<script\s+[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)) {
    try { jsonTypes(JSON.parse(match[1]), schemas); }
    catch (error) { fail(file, `invalid JSON-LD: ${error.message}`); }
  }
  if (file === "pages/baza.html" && !schemas.has("Dataset")) fail(file, "official corpus page is missing Dataset JSON-LD");
  if (isProfile && !schemas.has("ProfilePage")) fail(file, "source profile is missing ProfilePage JSON-LD");
  if (/^pages\/izvori\/(?:index|platforma-[^/]+)\.html$/.test(file) && !schemas.has("CollectionPage")) {
    fail(file, "catalogue page is missing CollectionPage JSON-LD");
  }
  if (file.startsWith("assets/izvjestaji/") && !schemas.has("ScholarlyArticle") && !schemas.has("Report")) {
    fail(file, "report is missing ScholarlyArticle or Report JSON-LD");
  }

  const hasFreshness = /class=["'][^"']*(?:freshness-strip|report-status-strip|report-status|status-chip|prototype-banner)[^"']*["']/i.test(html);
  if (!hasFreshness) fail(file, "missing visible freshness/status information");
  if (!allowedStatuses.some((status) => html.includes(status))) fail(file, "missing a ratified current status");
  if (file === "pages/news.html" && /<h[1-6][^>]*>\s*Uskoro\s*</i.test(html)) fail(file, "contains a stale Uskoro section");

  if (/^pages\/mapa\/(?:mapa|mapa_stats|diskurs|doga%C4%91aji|događaji|evolucija)\.html$/.test(file)) {
    const figures = (html.match(/class=["'][^"']*figure-card__takeaway/gi) || []).length;
    const summaries = (html.match(/class=["'][^"']*chart-accessible-summary/gi) || []).length;
    if (figures && summaries < figures) fail(file, `chart summaries (${summaries}) do not cover figure takeaways (${figures})`);
  }

  for (const match of html.matchAll(/<a\s+[^>]*href=["']([^"']*)["'][^>]*>/gi)) {
    const href = match[1];
    if (!href) { fail(file, "contains an empty link target"); continue; }
    const target = resolveTarget(href, file);
    if (target === null) continue;
    if (!allRelativeFiles.has(target)) { fail(file, `broken local link: ${href}`); continue; }
    const hash = href.includes("#") ? href.slice(href.indexOf("#") + 1) : "";
    if (hash && extname(target).toLowerCase() === ".html") {
      const targetHtml = readFileSync(resolve(siteRoot, ...target.split("/")), "utf8");
      let decoded = hash;
      try { decoded = decodeURIComponent(hash); } catch {}
      const escaped = decoded.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      if (!new RegExp(`\\bid=["']${escaped}["']`, "i").test(targetHtml)) fail(file, `broken local anchor: ${href}`);
    }
  }

  for (const match of html.matchAll(/<img\s+[^>]*>/gi)) {
    const tag = match[0];
    const source = attr(tag, /<img\s+[^>]*>/i, "src");
    const altText = attr(tag, /<img\s+[^>]*>/i, "alt");
    if (!altText && !/aria-hidden=["']true["']|role=["']presentation["']/i.test(tag)) fail(file, `image has empty alternative text: ${source}`);
    const target = resolveTarget(source, file);
    if (!target || !allRelativeFiles.has(target)) continue;
    if (extname(target).toLowerCase() === ".png") {
      const imagePath = resolve(siteRoot, ...target.split("/"));
      const dimensions = pngDimensions(imagePath);
      if (!dimensions) { fail(file, `could not read PNG dimensions: ${source}`); continue; }
      const declaredWidth = Number(attr(tag, /<img\s+[^>]*>/i, "width"));
      const declaredHeight = Number(attr(tag, /<img\s+[^>]*>/i, "height"));
      if (!declaredWidth && !declaredHeight) fail(file, `raster image has no declared dimensions: ${source}`);
      if (declaredWidth && dimensions.width > declaredWidth * 2.5 && statSync(imagePath).size > 250_000) {
        fail(file, `raster image is ${dimensions.width}px wide but declared at ${declaredWidth}px: ${source}`);
      }
    }
  }

  const resources = new Set([file]);
  for (const match of html.matchAll(/<(?:script|img|source|link)\s+[^>]*(?:src|href)=["']([^"']+)["'][^>]*>/gi)) {
    const target = resolveTarget(match[1], file);
    if (target && allRelativeFiles.has(target)) resources.add(target);
  }
  const total = [...resources].reduce((sum, item) => sum + statSync(resolve(siteRoot, ...item.split("/"))).size, 0);
  const [kind, budget] = pageClass(file);
  weights.push({ file, kind, total, budget });
  if (total > budget) fail(file, `${kind} page weight ${Math.ceil(total / 1024)} KiB exceeds ${Math.ceil(budget / 1024)} KiB budget`);
}

for (const [description, files] of descriptions) {
  if (files.length > 1) files.forEach((file) => fail(file, `description is duplicated across ${files.length} pages`));
}

const activeImageDirectory = resolve(projectRoot, "assets", "images");
if (existsSync(activeImageDirectory)) {
  for (const path of walk(activeImageDirectory)) {
    if (/\.(?:png|jpe?g|webp)$/i.test(path) && statSync(path).size > 1_000_000) {
      fail(relative(projectRoot, path), `active raster asset is ${Math.ceil(statSync(path).size / 1024)} KiB; archive or optimize it`);
    }
  }
}

const classSummary = new Map();
for (const item of weights) {
  const current = classSummary.get(item.kind);
  if (!current || item.total > current.total) classSummary.set(item.kind, item);
}
for (const [kind, item] of [...classSummary].sort()) {
  console.log(`${kind}: max ${Math.ceil(item.total / 1024)} KiB / ${Math.ceil(item.budget / 1024)} KiB — ${item.file}`);
}

if (findings.length) {
  console.error(`Site quality check found ${findings.length} issue(s):`);
  console.error(findings.map((finding) => `- ${finding}`).join("\n"));
  process.exitCode = 1;
} else {
  console.log(`Site quality checks passed for ${htmlFiles.length} active HTML pages.`);
}
