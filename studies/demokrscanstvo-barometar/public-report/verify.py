"""Verify the public edition against original releases and inspect PDF structure.

Rendering and actual visual inspection remain separate required steps.
"""
from pathlib import Path
from collections import Counter
import csv
import json
import re
import hashlib
import argparse
import fitz
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / 'output/demokrscanstvo-analysis/v1'
OUT = ROOT / 'output/demokrscanstvo-public/v2'
QA = ROOT / 'tmp/pdfs/demokrscanstvo-public'
PDF = ROOT / 'output/pdf/demokrscanstvo-u-medijskom-prostoru.pdf'

def js(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--visual-reviewed', action='store_true')
    args = parser.parse_args()
    meta = js(OUT / 'build.json')
    original = js(DATA / 'manifest.json')
    for name, value in meta['source_hashes'].items():
        assert value == sha(DATA / name) == original['files'][name], name
    old_pdf = ROOT / 'output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf'
    assert sha(old_pdf) == meta['original_technical_pdf_sha256'] == original['report']['sha256']
    assert sha(ROOT / 'output/pdf/demokrscanstvo-plan-analize.pdf') == original['source_plan_sha256']
    assert sha(PDF) == meta['pdf_sha256']
    assert sha(Path(__file__).with_name('build.py')) == meta['builder_sha256']

    themes_dir = ROOT / 'data/barometar/demokrscanstvo-themes/v1'
    base_dir = ROOT / 'data/barometar/demokrscanstvo-multiplatform/v1'
    for directory in (themes_dir, base_dir):
        manifest = js(directory / 'manifest.json')
        for name, value in manifest['files'].items():
            assert sha(directory / name) == value
    monthly = rows(themes_dir / 'topic_monthly.csv')
    topic_counts, year_counts, platform_counts, months = Counter(), Counter(), Counter(), Counter()
    year_topics, platform_topics = Counter(), Counter()
    for r in monthly:
        count = int(r['records'])
        year = r['month'][:4]
        topic_counts[r['topic']] += count
        year_counts[year] += count
        platform_counts[r['platform']] += count
        months[r['month']] += count
        year_topics[year, r['topic']] += count
        platform_topics[r['platform'], r['topic']] += count
    total = sum(topic_counts.values())
    assert total == meta['records'] == 2306
    for r in rows(DATA / 'topic_sensitivity.csv'):
        if r['scope'] != 'publications':
            continue
        assert int(r['n']) == topic_counts[r['topic']]
        assert int(r['denominator']) == total
        assert abs(float(r['percent']) - 100 * int(r['n']) / total) < 1e-10
    for r in rows(DATA / 'platforms.csv'):
        assert int(r['n']) == platform_counts[r['platform']]
        assert abs(float(r['percent']) - 100 * int(r['n']) / total) < 1e-10
    for r in rows(DATA / 'topic_profiles.csv'):
        if r['scope'] == 'year':
            count = year_topics[r['category'], r['topic']]
            denominator = year_counts[r['category']]
        elif r['scope'] == 'platform':
            count = platform_topics[r['category'], r['topic']]
            denominator = platform_counts[r['category']]
        else:
            continue
        assert int(r['n']) == count and int(r['denominator']) == denominator
        assert abs(float(r['percent']) - 100 * count / denominator) < 1e-10
    chosen = [r for r in rows(DATA / 'episode_selection.csv') if r['selected'] == 'True']
    assert len(chosen) == 3
    for r in chosen:
        assert int(r['publications']) == months[r['month']]

    # Inspect the delivered object, not just source strings.
    doc = fitz.open(PDF)
    assert len(doc) == meta['pages'] == 14
    assert len(doc.get_toc()) == 14
    text = '\n'.join(page.get_text() for page in doc)
    folded = text.casefold()
    forbidden = [r'validacij', r'robust', r'robusnost', r'dokazn', r'zamrzn',
                 r'kontrol', r'revizij', r'arhiv', r'analiz[ae] osjetljivosti',
                 r'točn\w* tekst', r'identičn', r'\ba1\b', r'\bnm[f]\b',
                 r'\bnpmi\b', r'protokol', r'\bai\b', r'codex', r'metode \|']
    for pattern in forbidden:
        assert not re.search(pattern, folded), pattern
    assert '\ufffd' not in text and '\x00' not in text
    assert not re.search(r'[a-f0-9]{64}', text)
    assert '2.306' in text and '50,0%' in text
    for r in chosen:
        assert f'{int(r["publications"])} tekstova i objava u tom mjesecu' in text
    for required in ['solidarnost', 'Supsidijarnost', 'savjest', 'Plenković', 'Hasanbegović', 'Penava', 'Stier']:
        assert required in text, required
    bounds = []
    spans = 0
    for i, page in enumerate(doc):
        if i:
            assert f'{i + 1} / {len(doc)}' in page.get_text()
        assert len(page.get_text()) > 250
        for block in page.get_text('dict')['blocks']:
            for line in block.get('lines', []):
                for span in line['spans']:
                    spans += 1
                    rect = fitz.Rect(span['bbox'])
                    if rect.x0 < 20 or rect.y0 < 15 or rect.x1 > page.rect.width - 15 or rect.y1 > page.rect.height - 15:
                        bounds.append((i + 1, span['text'], span['bbox']))
    assert not bounds, bounds
    assert all(r['bottom_y'] >= 60 for r in js(QA / 'layout.json'))
    links = [link['uri'] for page in doc for link in page.get_links()]
    assert set(links) == {'https://lusiki.github.io/DigiKat/', 'https://www.lukasikic.info/'}
    reader = PdfReader(PDF)
    assert reader.metadata.author == 'Luka Šikić'
    fonts = set()
    for page in reader.pages:
        for reference in page['/Resources']['/Font'].values():
            font = reference.get_object()
            name = str(font['/BaseFont'])
            if 'Calibri' in name or 'Georgia' in name:
                descriptor = font['/FontDescriptor'].get_object()
                assert '/FontFile2' in descriptor or '/FontFile3' in descriptor
                fonts.add(name)
    assert len(fonts) >= 3
    rendered = sorted(QA.glob('page-*.png'))
    assert len(rendered) == len(doc)
    assert all(path.stat().st_mtime >= PDF.stat().st_mtime for path in rendered)
    (QA / 'extracted.txt').write_text(text, encoding='utf-8')
    result = {
        'status': 'PASS', 'pdf_sha256': sha(PDF), 'pages': len(doc),
        'public_release_counts_reconciled': True,
        'original_report_and_plan_unchanged': True,
        'technical_material_absent': True,
        'embedded_fonts': sorted(fonts), 'text_spans_checked': spans,
        'text_outside_page': len(bounds),
        'visual_review': 'All pages inspected; changed pages reinspected' if args.visual_reviewed else 'pending',
        'visual_reviewer': 'Codex AI' if args.visual_reviewed else None,
    }
    (OUT / 'qa.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False))

if __name__ == '__main__':
    main()
