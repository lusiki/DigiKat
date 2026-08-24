"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const findings = require("../assets/js/moj-medij-findings.js");

function dataFixture() {
  return {
    policy: {
      min_posts: 100,
      rhythm_min_cell_posts: 20,
      topic_min_classified_posts: 100
    },
    totals: { sources_listed: 356 },
    behaviour: {
      rhythm: { min_cell_posts: 20, bands: ["00–05", "06–09", "10–13"] },
      topics: {
        min_classified_posts: 100,
        labels: ["Duhovnost i liturgija", "Politika i odnos s državom"]
      }
    }
  };
}

function richSource() {
  return {
    n: "Primjer.hr",
    p: 1200,
    rp: 12,
    pl: "web",
    bh: [{
      pl: "web",
      p: 1200,
      a: { t: 48, mt: 25, nt: 80, z: 10, mz: 12, nz: 80 },
      r: [{ d: 1, b: 2, p: 70 }, { d: 5, b: 3, p: 110 }],
      tm: { n: 900, pn: 80, s: [55, 10], f: [35, 15] }
    }]
  };
}

test("three findings follow the locked evidence priority", () => {
  const result = findings.createFindings(richSource(), dataFixture());
  assert.equal(result.length, 3);
  assert.deepEqual(result.map((item) => item.kind), ["scale", "attention", "topic"]);
  assert.match(result[1].text, /platformi web/);
  assert.equal(result[1].support.peer_count, 80);
  assert.equal(result[2].support.classified_posts, 900);
});

test("sparse profiles return fewer honest findings without throwing", () => {
  const source = { n: "Mali profil", p: 140, rp: 200, bh: [{ pl: "web", p: 140 }] };
  const result = findings.createFindings(source, dataFixture());
  assert.deepEqual(result.map((item) => item.kind), ["scale"]);
});

test("attention and topic claims respect peer and gap thresholds", () => {
  const source = richSource();
  source.bh[0].a = { t: 29, mt: 25, nt: 200, z: 40, mz: 10, nz: 8 };
  source.bh[0].tm = { n: 99, pn: 200, s: [80, 20], f: [20, 80] };
  const result = findings.createFindings(source, dataFixture());
  assert.deepEqual(result.map((item) => item.kind), ["scale", "rhythm"]);
});

test("incomplete platform data never creates unsupported comparisons", () => {
  const source = { n: "Nepotpuni", p: 300, rp: 100, bh: [null, { pl: "youtube", p: 300, a: {} }] };
  assert.doesNotThrow(() => findings.createFindings(source, dataFixture()));
  assert.deepEqual(findings.createFindings(source, dataFixture()).map((item) => item.kind), ["scale"]);
});

test("duplicate names are resolved by exact case and optional platform", () => {
  const sources = [
    { n: "index.hr", pl: "web", bh: [{ pl: "web", p: 1000 }] },
    { n: "Index.hr", pl: "facebook", bh: [{ pl: "facebook", p: 200 }] }
  ];
  assert.equal(findings.findRequestedSource(sources, "Index.hr").pl, "facebook");
  assert.equal(findings.findRequestedSource(sources, "INDEX.HR", "web").pl, "web");
  assert.equal(findings.findRequestedSource(sources, "INDEX.HR", "facebook").pl, "facebook");
  assert.equal(findings.findRequestedSource(sources, "nema.hr", "web"), null);
});

test("share parameters retain the legacy media name and add the main platform", () => {
  const source = richSource();
  source.bh.push({ pl: "facebook", p: 100 });
  assert.deepEqual(findings.shareParameters(source), { medij: "Primjer.hr", platforma: "web" });
});

test("the rendered interface keeps the keyboard, sharing, and narrow-screen contract", () => {
  const source = fs.readFileSync("pages/moj-medij.qmd", "utf8");
  const rendered = fs.readFileSync("docs/pages/moj-medij.html", "utf8");

  assert.match(source, /role="combobox"[^>]+aria-autocomplete="list"[^>]+aria-expanded="false"/);
  assert.match(source, /aria-activedescendant/);
  for (const key of ["ArrowDown", "ArrowUp", "Enter", "Escape"]) {
    assert.match(source, new RegExp(`event\\.key === '${key}'`));
  }
  assert.match(source, /Kopirajte poveznicu/);
  assert.match(source, /navigator\.clipboard/);
  assert.match(source, /role="region" tabindex="0"/);
  assert.match(source, /@media \(max-width:640px\)/);
  assert.match(source, /\.mm-heat-wrap \{[^}]*overflow-x:auto/s);
  assert.match(source, /Tablični prikaz tema/);
  assert.match(source, /Podaci iz grafikona/);
  assert.doesNotMatch(source, /class="mm-aside"/);
  assert.match(rendered, /src="\.\.\/assets\/js\/moj-medij-findings\.js"/);
  assert.match(rendered, /id="mm-status"[^>]+role="status"/);
});
