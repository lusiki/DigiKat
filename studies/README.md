# Study workspace policy

Each study is a self-contained analysis workspace. Keep scripts, codebooks,
proposals, disclosure-reviewed aggregate tables, and figures under version
control. Do not commit corpus rows.

## Output classes

- `output/`: publishable aggregate tables, figures, calendars, code lists, and
  de-identified validation summaries only.
- `output/private/`: URLs, source/account identities at row level, titles,
  excerpts, coding sheets, annotator copies, and joined labels. This directory
  is gitignored.
- `output/intermediate/`: replaceable computation checkpoints. This directory
  is gitignored.
- Large `.rds` study slices are also gitignored, even outside these two
  subdirectories.

Before committing a study output, run:

```powershell
Rscript R/check_disclosure.R
```

The automated guard catches direct text and identifier fields. A human must
still review small cells, rare categories, free-text labels, and combinations
that could indirectly identify a person or account.

The full master corpus is restricted and is never a study deliverable. The
repository's synthetic sample is the public fixture for testing and examples.

