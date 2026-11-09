"""Pin the actual local tools and fonts; never download or substitute."""
import importlib.metadata
import platform
import shutil
import subprocess
import sys
from evidence_io import *

TYPST = Path("C:/Program Files/Quarto/bin/tools/x86_64/typst.exe")
QUARTO = Path("C:/Program Files/Quarto/bin/quarto.exe")
FONTS = Path("C:/Windows/Fonts")


def capture_environment():
    from fontTools.ttLib import TTFont
    configure_environment()
    packages = {p: importlib.metadata.version(p) for p in
                ["pandas", "numpy", "pyarrow", "PyMuPDF", "fonttools"]}
    expected = {"python": "3.14.4", "quarto": "1.9.38", "typst": "typst 0.14.2 (b33de9de)",
                "pandas": "3.0.3", "numpy": "2.4.6", "pyarrow": "25.0.1", "PyMuPDF": "1.27.2.3"}
    observed = {
        "python": platform.python_version(),
        "quarto": subprocess.check_output([str(QUARTO), "--version"], text=True).strip(),
        "typst": subprocess.check_output([str(TYPST), "--version"], text=True).strip(), **packages}
    differences = [{"component": k, "expected": v, "observed": observed[k]}
                   for k, v in expected.items() if observed[k] != v]
    env = {"schema_version": "1.0", "observed": observed, "brief_baseline": expected,
           "version_differences": differences,
           "executables": {"python": sys.executable, "quarto": str(QUARTO), "typst": str(TYPST)},
           "executable_sha256": {"python": sha256(sys.executable), "quarto": sha256(QUARTO),
                                 "typst": sha256(TYPST)},
           "platform": platform.platform(), "packages_used": packages,
           "rendering": "PyMuPDF rasterization; Poppler was not available on PATH",
           "unused_baseline_packages": ["matplotlib", "pypdf"],
           "quarto_use": "version inspected only; compilation uses its bundled Typst directly",
           "network": "none", "cache_root": relative(OUT / "cache")}
    if (OUT / "environment.lock.json").exists():
        old = json.loads((OUT / "environment.lock.json").read_text(encoding="utf-8"))
        if old["observed"] != env["observed"] or old["executable_sha256"] != env["executable_sha256"]:
            raise RuntimeError("Environment differs from recorded lock; review changes explicitly.")
    write_json(OUT / "environment.lock.json", env)
    write_text(OUT / "requirements.lock.txt", "# Python " + platform.python_version() + "\n" +
               "\n".join(f"{p}=={v}" for p,v in packages.items()) + "\n")
    font_files = ["pala.ttf", "palab.ttf", "palai.ttf", "palabi.ttf",
                  "segoeui.ttf", "segoeuib.ttf", "segoeuii.ttf", "segoeuiz.ttf"]
    fonts = []
    for filename in font_files:
        path=FONTS/filename
        if not path.is_file():
            raise RuntimeError(f"Required recorded font is missing: {path}; no fallback is authorised.")
        with TTFont(path, lazy=True) as font:
            names=font["name"]
            fonts.append({"path":str(path), "filename":filename, "sha256":sha256(path),
                          "family":names.getDebugName(1), "style":names.getDebugName(2),
                          "version":names.getDebugName(5)})
    manifest={"schema_version":"1.0","profile":"primary-local","fonts":fonts,
              "redistributed":False,"fallback_allowed":False,
              "open_alternatives":{"families":["Libertinus Serif","Noto Sans"],
                "status":"documented only; not installed, rendered or claimed equivalent by this task",
                "requirements":"Record exact files, hashes and licences, then rebuild and repeat all page inspection."}}
    if (OUT/"font_manifest.json").exists():
        old=json.loads((OUT/"font_manifest.json").read_text(encoding="utf-8"))
        if old["fonts"] != fonts: raise RuntimeError("Recorded font files changed.")
    write_json(OUT/"font_manifest.json",manifest)
    return env


def verify_fonts():
    manifest=json.loads((OUT/"font_manifest.json").read_text(encoding="utf-8"))
    for item in manifest["fonts"]:
        if not Path(item["path"]).is_file() or sha256(item["path"]) != item["sha256"]:
            raise RuntimeError("Missing or changed recorded font: "+item["path"])
    return {"status":"passed","files_checked":len(manifest["fonts"])}
