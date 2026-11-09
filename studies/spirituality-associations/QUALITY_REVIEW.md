# Exploratory release verification

Checked 19 September 2026. This records technical and presentational verification, not substantive human validation of organisation visibility.

- `08_verify.py` passes all sixteen verification groups. It independently checks PDF/JSON identity agreement, source hashes, all county totals and densities, Python/SQL normalization on every name, matching boundaries, URL canonicalization, pilot reproduction, complete monthly candidate caches, count reconciliation, blank human labels, filter bounds and private-path exclusion.
- `R/check_disclosure.R` passes against all trackable study and public-barometer artifacts. Normal project startup reports existing renv synchronization and locale warnings; the guard exits successfully. No R library or lockfile was changed.
- The final PDF has seven pages and eleven clickable source links. Poppler rendered every page; all seven final images were inspected after the final content changes. Tables repeat their headers, Croatian characters render correctly, and no clipping or overlap was observed.
- The local directory was checked in headless Chromium: all 1,325 rows, name search, county selection, retrieval-state filters, pagination and searches without Croatian diacritics work. Unknown search states display “Not searched” rather than an observed zero. No browser script errors occurred. The rendered directory was also visually inspected.
- The source database was read-only and its file fingerprint remained unchanged. All twelve 2025 monthly candidate files reconcile to the final retrieval totals. The optional AI development audit is separate from human coding.
- `git diff --check` passes. Trackable files contain scripts, study documentation, aggregate diagnostics and figures, and the research report. The register, source copies, official HTML snapshots, media records, addresses, URLs, coding sheets and local directory remain ignored.

Verification output is in `output/tables/verification.json`. PDF and browser QA evidence is under `output/private/qa/`. No final publication, source-affiliation validation, national orientation coding, or independent human media validation is claimed.
