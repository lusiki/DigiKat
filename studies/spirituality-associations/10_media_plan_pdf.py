"""Render the prospective media study plan; never reads restricted media rows.

Run from the repository root with: python -X utf8 studies/spirituality-associations/10_media_plan_pdf.py
After changing the plan, render the final PDF with Poppler and inspect every page.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import matplotlib
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, HRFlowable, PageTemplate, Paragraph, Spacer,
    Table, TableStyle,
)

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]
SOURCE = ROOT / "MEDIA_ANALYSIS_PLAN.md"
TARGET = REPO / "output/pdf/spirituality-associations-media-research-plan.pdf"
FONT_PATH = Path(matplotlib.get_data_path()) / "fonts/ttf"
INK = colors.HexColor("#203844")
TEAL = colors.HexColor("#216775")
COPPER = colors.HexColor("#9b5c3b")
MUTED = colors.HexColor("#63747b")
WIDTH, HEIGHT = A4
MARGIN = 49
CONTENT_WIDTH = WIDTH - 2 * MARGIN


def register_fonts():
    for name, file in [
        ("Plan", "DejaVuSans.ttf"),
        ("PlanBold", "DejaVuSans-Bold.ttf"),
        ("PlanItalic", "DejaVuSans-Oblique.ttf"),
    ]:
        pdfmetrics.registerFont(TTFont(name, str(FONT_PATH / file)))
    pdfmetrics.registerFontFamily(
        "Plan", normal="Plan", bold="PlanBold", italic="PlanItalic", boldItalic="PlanBold"
    )


def markup(raw):
    escaped = html.escape(raw)

    def link(match):
        label, target = match.groups()
        if target.startswith("https://"):
            return f'<link href="{target}" color="#216775"><u>{label}</u></link>'
        return label

    escaped = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link, escaped)
    escaped = re.sub(r"`([^`]+)`", r'<font color="#475a63">\1</font>', escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", escaped)
    escaped = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", escaped)
    return escaped


class PlanDocument(BaseDocTemplate):
    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph) and flowable.style.name == "section":
            title = flowable.getPlainText()
            key = "section-" + title.split(".")[0]
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(title, key, level=0, closed=False)


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#d5e0e3"))
    canvas.setLineWidth(.5)
    canvas.line(MARGIN, HEIGHT - 34, WIDTH - MARGIN, HEIGHT - 34)
    canvas.setFont("PlanBold", 8)
    canvas.setFillColor(TEAL)
    canvas.drawString(MARGIN, HEIGHT - 25, "DIGIKAT  /  RESEARCH DESIGN")
    canvas.setFillColor(MUTED)
    canvas.setFont("Plan", 7.5)
    canvas.drawRightString(WIDTH - MARGIN, HEIGHT - 25, "Spirituality-related associations")
    canvas.line(MARGIN, 36, WIDTH - MARGIN, 36)
    canvas.drawString(MARGIN, 23, "19 September 2026  |  Prospective media analysis plan")
    canvas.drawRightString(WIDTH - MARGIN, 23, str(doc.page))
    canvas.restoreState()


def styles():
    common = dict(fontName="Plan", textColor=INK, allowWidows=0, allowOrphans=0)
    return {
        "title": ParagraphStyle("title", fontName="PlanBold", fontSize=23, leading=29,
                                spaceAfter=15, textColor=INK, keepWithNext=True),
        "section": ParagraphStyle("section", fontName="PlanBold", fontSize=13.5, leading=18,
                                  textColor=TEAL, spaceBefore=16, spaceAfter=9, keepWithNext=True),
        "subsection": ParagraphStyle("subsection", fontName="PlanBold", fontSize=11,
                                     leading=15, textColor=INK, spaceBefore=11,
                                     spaceAfter=7, keepWithNext=True),
        "body": ParagraphStyle("body", fontSize=9.8, leading=14.1, spaceAfter=9, **common),
        "meta": ParagraphStyle("meta", fontName="Plan", fontSize=8.3, leading=12,
                               textColor=MUTED, spaceAfter=12),
        "bullet": ParagraphStyle("bullet", fontSize=9.8, leading=14.1, leftIndent=13,
                                 firstLineIndent=-10, spaceAfter=6, **common),
        "cell": ParagraphStyle("cell", fontSize=8.5, leading=11.8, spaceAfter=0, **common),
        "head": ParagraphStyle("head", fontName="PlanBold", fontSize=8.5, leading=11.8,
                               textColor=colors.white),
    }


def build_table(rows, st):
    columns = len(rows[0])
    if any(len(row) != columns for row in rows):
        raise ValueError("Table has inconsistent column counts")
    ratios = {2: [.29, .71], 3: [.24, .42, .34]}[columns]
    parsed = [[Paragraph(markup(cell), st["head"] if i == 0 else st["cell"])
               for cell in row] for i, row in enumerate(rows)]
    table = Table(parsed, colWidths=[CONTENT_WIDTH * ratio for ratio in ratios],
                  repeatRows=1, hAlign="LEFT", spaceAfter=11)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), TEAL),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#eef4f5"), colors.white]),
        ("LINEBELOW", (0, 0), (-1, 0), .6, TEAL),
        ("LINEBELOW", (0, 1), (-1, -1), .35, colors.HexColor("#d9e2e4")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("NOSPLIT", (0, 0), (-1, min(2, len(rows) - 1))),
        ("NOSPLIT", (0, max(1, len(rows) - 2)), (-1, -1)),
    ]))
    return table


def parse_markdown(st):
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    story = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith("### "):
            story.append(Paragraph(markup(line[4:]), st["subsection"]))
        elif line.startswith("## "):
            story.append(Paragraph(markup(line[3:]), st["section"]))
        elif line.startswith("# "):
            story.append(Paragraph(markup(line[2:]), st["title"]))
            story.append(HRFlowable(width=55, thickness=3, color=COPPER, hAlign="LEFT", spaceAfter=12))
        elif line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [cell.strip() for cell in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r"[:\-]+", cell or "-") for cell in cells):
                    rows.append(cells)
                i += 1
            story.append(build_table(rows, st))
            continue
        elif line.startswith("- "):
            story.append(Paragraph("&#8226; " + markup(line[2:]), st["bullet"]))
        elif re.match(r"\d+\. ", line):
            story.append(Paragraph(markup(line), st["bullet"]))
        else:
            paragraph = [line]
            while i + 1 < len(lines):
                nxt = lines[i + 1].strip()
                if not nxt or nxt.startswith(("#", "|", "- ")) or re.match(r"\d+\. ", nxt):
                    break
                i += 1
                paragraph.append(nxt)
            key = "meta" if line.startswith("Detailed research and collection plan") else "body"
            story.append(Paragraph(markup(" ".join(paragraph)), st[key]))
        i += 1
    return story


def main():
    register_fonts()
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    doc = PlanDocument(str(TARGET), pagesize=A4, title="Spirituality-related associations in Croatia's media space: research plan",
                       author="DigiKat research project", subject="Prospective collection, linking and media representation protocol")
    frame = Frame(MARGIN, 47, CONTENT_WIDTH, HEIGHT - 99,
                  leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    doc.addPageTemplates([PageTemplate(id="plan", frames=frame, onPage=footer)])
    doc.build(parse_markdown(styles()))
    print(TARGET)


if __name__ == "__main__":
    main()
