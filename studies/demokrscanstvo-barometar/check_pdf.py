"""Inspect the isolated conference PDF and render every page for visual QA."""
import json
from pathlib import Path
import sys
import fitz

pdf, summary_path, output = map(Path, sys.argv[1:4])
summary = json.loads(summary_path.read_text(encoding="utf-8"))
with fitz.open(pdf) as document:
    if len(document) not in (1, 2):
        raise ValueError("Conference summary must fit one or two pages")
    text = "\n".join(page.get_text() for page in document)
    if "demokr\u0161\u0107anstva" not in text or summary["definition_version"] not in text:
        raise ValueError("PDF text or definition version mismatch")
    output.mkdir(parents=True, exist_ok=True)
    for i, page in enumerate(document, 1):
        page.get_pixmap(matrix=fitz.Matrix(120 / 72, 120 / 72)).save(output / f"review-page-{i}.png")
    print(f"PDF: {len(document)} pages; Croatian text and version verified; every page rendered.")
