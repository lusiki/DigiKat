# Moj medij `TIME` reliability audit

**Corpus:** `data/digikat_corpus.rds` named by `data/digikat_corpus_manifest.json`
**Corpus SHA-256:** `15473a615bf301c02b5d4149d662a4db282927d3b3e98308c5ff54cbe1de520a`
**Audit date:** 2026-08-17

## Result

The vendor `TIME` field is suitable for the day-of-week by time-band profile when interpreted as
`Europe/Zagreb` local time.

- 413,985 of 413,985 values match `HH:MM:SS` and fall inside the valid clock range.
- Missing values: 0.
- Distinct clock times: 72,034.
- Values with non-zero seconds: 84.51%. The field therefore has genuine second-level granularity rather than
  rounded hour bands.
- All 3,860 Twitter rows carry a status Snowflake. The UTC creation time decoded from those identifiers differs
  from the vendor date-time by exactly the seasonal `Europe/Zagreb` offset within five minutes in 100% of rows.
  Of these, 1,877 use UTC+1 and 1,983 use UTC+2, matching winter and daylight-saving time.

No URL, status identifier, post text, or row-level value is stored in this report. The reproducible audit lives
in `digikat_audit_vendor_time()` in `R/lib/moj_medij_metrics.R`; `R/06_moj_medij.R` fails closed if validity,
missingness, or the timezone check falls below its threshold.

## Display decision

The public heatmap uses six local-time bands. They are 00–05, 06–09, 10–13, 14–17, 18–21, and 22–23.
Cells with fewer than 20 posts are omitted from the public aggregate and displayed only as suppressed.
