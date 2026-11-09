// Render existing formulas into self-contained HTML; no formula content changes.
// Usage: node scripts/render_linked_paper_math.cjs <KaTeX package directory> [cache]
const fs = require('fs');
const path = require('path');
const katexRoot = path.resolve(process.argv[2]);
const katex = require(katexRoot);
const cache = path.resolve(process.argv[3] || 'tmp/church-papers-publication');
let css = fs.readFileSync(path.join(katexRoot, 'dist/katex.min.css'), 'utf8');
css = css.replace(/url\(([^)]+)\)/g, (_, relative) => {
  const filename = path.join(katexRoot, 'dist', relative.replace(/["']/g, ''));
  const ext = path.extname(filename).slice(1);
  return `url(data:font/${ext};base64,${fs.readFileSync(filename).toString('base64')})`;
});
for (const stem of ['crkva-i-dezinformacije', 'sadrzaj-ili-identitet']) {
  const filename = path.join(cache, stem + '.browser.html');
  let html = fs.readFileSync(filename, 'utf8');
  let count = 0;
  html = html.replace(/<span class="math (inline|display)">([\s\S]*?)<\/span>/g, (_, mode, raw) => {
    const tex = raw.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim().slice(2, -2).trim();
    count++;
    return `<span class="math ${mode}">${katex.renderToString(tex, {displayMode:mode === 'display',throwOnError:true,output:'htmlAndMathml'})}</span>`;
  });
  if (count !== 10) throw new Error(`${stem}: expected 10 formulas, got ${count}`);
  html = html.replace('</head>', `<style id="digikat-frozen-math">${css}</style>\n</head>`);
  fs.writeFileSync(filename, html, 'utf8');
  console.log(`${stem}: rendered ${count} formulas (KaTeX ${katex.version})`);
}
