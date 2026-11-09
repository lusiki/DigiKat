"""Apply print styles to Pandoc editions without changing manuscript text."""
import argparse
import re
from pathlib import Path
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files', nargs='+', type=Path)
    args = parser.parse_args()
    for path in args.files:
        doc = Document(path)
        doc.core_properties.author = 'Luka Šikić, Andreja Sršen'
        doc.core_properties.title = doc.paragraphs[0].text
        for sec in doc.sections:
            sec.page_width, sec.page_height = Cm(21), Cm(29.7)
            sec.top_margin = sec.bottom_margin = Cm(2)
            sec.left_margin = sec.right_margin = Cm(2)
        for style in doc.styles:
            if style.type == 1:
                style.font.name = 'Cambria'
                style.font.color.rgb = RGBColor(0, 0, 0)
                style.paragraph_format.widow_control = True
        for name in ['Normal', 'Body Text', 'First Paragraph', 'Compact']:
            if name in doc.styles:
                s = doc.styles[name]
                s.font.size = Pt(11)
                s.paragraph_format.space_after = Pt(6)
                s.paragraph_format.line_spacing = 1.08
        for name, size in [('Title',22),('Subtitle',12),('Heading 1',16),('Heading 2',13),('Heading 3',11)]:
            s = doc.styles[name]
            s.font.size = Pt(size)
            s.paragraph_format.space_before = Pt(12)
            s.paragraph_format.space_after = Pt(6)
            s.paragraph_format.keep_with_next = True
        for p in doc.paragraphs:
            is_table_caption = bool(re.match(r'^(?:Tablica|Table)\s*\d+',p.text))
            is_image_caption = bool(re.match(r'^(?:Slika|Figure)\s*\d+',p.text))
            if p.style.name in ['Caption','Image Caption','Table Caption'] or is_table_caption or is_image_caption:
                p.paragraph_format.space_before = Pt(6)
                p.paragraph_format.space_after = Pt(6)
                p.paragraph_format.keep_with_next = is_table_caption
                for run in p.runs:
                    run.font.size = Pt(9)
            if p._p.xpath('.//w:drawing'):
                p.paragraph_format.keep_with_next = True
        for table in doc.tables:
            table.autofit = False
            widths = [col.width for col in table.columns]
            total = sum(widths)
            widths = [int(Cm(17)*width/total) for width in widths]
            for col,width in zip(table.columns,widths): col.width = width
            props = table._tbl.tblPr
            borders = OxmlElement('w:tblBorders')
            for edge in ['top','left','bottom','right','insideH','insideV']:
                e = OxmlElement('w:'+edge)
                for k,v in {'val':'single','sz':'4','color':'D9D9D9'}.items(): e.set(qn('w:'+k),v)
                borders.append(e)
            props.append(borders)
            margins = OxmlElement('w:tblCellMar')
            for edge in ['top','bottom','left','right']:
                e=OxmlElement('w:'+edge);e.set(qn('w:w'),'70');e.set(qn('w:type'),'dxa');margins.append(e)
            props.append(margins)
            for i,row in enumerate(table.rows):
                rp=row._tr.get_or_add_trPr()
                rp.append(OxmlElement('w:cantSplit'))
                if i == 0: rp.append(OxmlElement('w:tblHeader'))
                for cell,width in zip(row.cells,widths):
                    cell.width=width
                    if i == 0:
                        shade=OxmlElement('w:shd');shade.set(qn('w:fill'),'E7EBEF');cell._tc.get_or_add_tcPr().append(shade)
                    for p in cell.paragraphs:
                        p.paragraph_format.space_after=Pt(3)
                        p.paragraph_format.space_before=Pt(0)
                        p.paragraph_format.line_spacing=1.0
                        p.paragraph_format.keep_with_next = len(table.rows) <= 15 and i < len(table.rows)-1
                        for run in p.runs:
                            run.font.size=Pt(9)
                            if i == 0: run.bold=True
        for shape in doc.inline_shapes:
            if shape.width > Cm(16.5):
                ratio=Cm(16.5)/shape.width
                shape.height=int(shape.height*ratio);shape.width=Cm(16.5)
        doc.save(path)
        print(f'{path.name}: {len(doc.tables)} tables, {len(doc.inline_shapes)} figures')


if __name__ == '__main__': main()
