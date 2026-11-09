"""Prepare frozen published HTML for Pandoc, without executing manuscript R code.

Requires lxml. Run before format_linked_church_papers.ps1. The source cache must
contain the files and source-manifest.json downloaded from the pinned commit.
"""
import argparse
import base64
import copy
import hashlib
import json
import re
from pathlib import Path

from lxml import etree, html

PAPERS = {
    '03_framing_paper_2': 'crkva-i-dezinformacije',
    'rsp_paper_revised': 'sadrzaj-ili-identitet',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', type=Path, default=Path('tmp/church-papers-publication'))
    args = parser.parse_args()
    manifest = json.loads((args.cache / 'source-manifest.json').read_text(encoding='utf-8'))
    for source, stem in PAPERS.items():
        raw = (args.cache / f'{source}.html').read_bytes()
        assert hashlib.sha256(raw).hexdigest() == manifest['files'][f'{source}.html']['sha256']
        doc = html.fromstring(raw.decode('utf-8'))
        main = copy.deepcopy(doc.xpath('//main')[0])
        # Only browser controls and folded analysis code are excluded from print.
        for node in main.xpath('.//script|.//style|.//button|.//details|.//div[contains(concat(" ",normalize-space(@class)," ")," sourceCode ")]'):
            if node.getparent() is not None:
                node.drop_tree()
        header = main.xpath('.//header')[0]
        title = header.xpath('.//h1')[0].text_content().strip()
        subtitle = header.xpath('.//*[contains(concat(" ",normalize-space(@class)," ")," subtitle ")]')[0].text_content().strip()
        new_header = html.Element('div')
        for style, text in [('Title', title), ('Subtitle', subtitle), ('Author', 'Luka Šikić, Andreja Sršen'), ('Date', '14. travnja 2026.')]:
            div = etree.SubElement(new_header, 'div', {'custom-style': style})
            etree.SubElement(div, 'p').text = text
        # Preserve the framing paper's keyword metadata.
        keywords = header.xpath('.//*[contains(concat(" ",normalize-space(@class)," ")," keywords ")]')
        for node in keywords:
            if node.text_content().strip():
                etree.SubElement(new_header, 'p').text = node.text_content().strip()
        header.getparent().replace(header, new_header)
        for node in main.xpath('.//a[contains(@class,"anchorjs-link")]'):
            node.drop_tree()
        # Pandoc otherwise wraps every Quarto float (including whole tables) in
        # an unbreakable single-cell Word table. Flatten the float containers
        # while retaining captions, identifiers, images and the actual tables.
        for node in main.xpath('.//figure'):
            node.tag = 'div'
        for node in main.xpath('.//figcaption'):
            node.tag = 'p'
            node.set('custom-style', 'Caption')
        for node in main.xpath('.//*[contains(concat(" ",normalize-space(@class)," ")," math ")]'):
            # The published HTML double-escapes TeX. Correct only its transport
            # escaping; Pandoc converts the original formula into editable OMML.
            node.text = node.text_content().replace('\\\\', '\\')
        images = main.xpath('.//img')
        for index, node in enumerate(images, 1):
            uri = node.get('src', '')
            assert uri.startswith('data:image/png;base64,'), 'Unexpected external figure dependency'
            target = args.cache / f'{stem}-figure-{index}.png'
            target.write_bytes(base64.b64decode(uri.split(',', 1)[1]))
            node.set('src', str(target.resolve()))
            node.set('width', '620')
            node.attrib.pop('height', None)
        # Native HTML table widths often disappear in DOCX conversion. Explicit
        # proportions reserve room for predictor labels and interval estimates.
        for table in main.xpath('.//table'):
            rows = table.xpath('.//tr')
            n = len(rows[0].xpath('./th|./td'))
            for node in table.xpath('./colgroup'):
                table.remove(node)
            first = 0.44 if n >= 6 else 0.40
            fractions = [first] + [(1-first)/(n-1)]*(n-1)
            if n == 6:
                fractions = [0.40, 0.10, 0.10, 0.10, 0.10, 0.20]
                if 'Potkategorija' in rows[0].text_content():
                    fractions = [0.35, 0.21, 0.11, 0.11, 0.11, 0.11]
            group = etree.Element('colgroup')
            for fraction in fractions:
                etree.SubElement(group, 'col', style=f'width: {100*fraction:.3f}%')
            table.insert(0, group)
        text = etree.tostring(main, encoding='unicode', method='html')
        (args.cache / f'{stem}.print.html').write_text('<!doctype html><html><head><meta charset="utf-8"></head><body>'+text+'</body></html>', encoding='utf-8')
        # Keep a standalone browser edition with the complete code folding and
        # scripts, correcting only the same doubled TeX delimiter escaping.
        for node in doc.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," math ")]'):
            node.text = node.text_content().replace('\\\\', '\\')
        (args.cache / f'{stem}.browser.html').write_text('<!doctype html>\n'+etree.tostring(doc, encoding='unicode', method='html'), encoding='utf-8')
        print(json.dumps({'paper':stem,'tables':len(main.xpath('.//table')),'figures':len(images),'title':title},ensure_ascii=True))


if __name__ == '__main__':
    main()
