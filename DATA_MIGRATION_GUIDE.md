# Data Migration Guide for DigiKat Repository

This document explains how to set up this repository on a new computer so that all analysis scripts work correctly.

## Prerequisites

Make sure you have the following folder structure in your repository:

```
DigiKat/
├── data/
│   ├── nlp/                  # NLP batch files go here
│   ├── raw/                  # Raw Excel files go here
│   ├── processed/            # Already contains processed data
│   └── merged_comprehensive.rds
├── resources/
│   ├── lexicons/             # Already contains sentiment lexicons
│   ├── dictionaries/         # Already contains lilaHR dictionary
│   └── models/               # UDPipe models go here
```

## Step 1: Copy NLP Batch Files

The NLP analysis scripts require pre-processed UDPipe tokenized data.

**Source location** (on original machine):
```
C:/Users/lsikic/Luka C/HKS/Projekti/Digitalni Kat/SHKM/Podatci/Language model/
```

**Target location** (in repository):
```
data/nlp/
```

**Files to copy** (27 files total):
- `batched_processed_udpipe_1.rds`
- `batched_processed_udpipe_2.rds`
- ... through ...
- `batched_processed_udpipe_27.rds`

**PowerShell command** (from repo root):
```powershell
Copy-Item "C:/Users/lsikic/Luka C/HKS/Projekti/Digitalni Kat/SHKM/Podatci/Language model/batched_processed_udpipe_*.rds" "data/nlp/"
```

## Step 2: Copy Raw Excel Files (Optional)

Only needed if you want to re-run the data loading/merging scripts.

**Source location** (on original machine):
```
C:/Users/lsikic/Dropbox/DigiKat/2024&25 Dta/
```

**Target location** (in repository):
```
data/raw/
```

**PowerShell command** (from repo root):
```powershell
Copy-Item "C:/Users/lsikic/Dropbox/DigiKat/2024&25 Dta/*.xlsx" "data/raw/"
```

## Step 3: Verify Required Files

The following files should already be in the repository:

### Lexicons (`resources/lexicons/`)
- [x] `crosentilex-negatives.txt`
- [x] `crosentilex-positives.txt`
- [x] `gs-sentiment-annotations.txt`

### Dictionaries (`resources/dictionaries/`)
- [x] `lilaHR_clean.xlsx`

### Processed Data (`data/` and `data/processed/`)
- [x] `merged_comprehensive.rds` - Main dataset for all analyses
- [x] Various summary `.rds` files in `data/processed/`

## Step 4: Verify .gitignore

Make sure large data files are not tracked in git. The `.gitignore` should include:

```
# Large data files
data/nlp/*.rds
data/raw/*.xlsx
*.xlsx
```

## Summary of Path Changes

All scripts have been updated to use relative paths:

| File | Old Path | New Path |
|------|----------|----------|
| `pages/mapa/događaji.qmd` | `C:/Users/lsikic/Dropbox/...` | `../../resources/lexicons/`, `../../resources/dictionaries/`, `../../data/nlp/` |
| `pages/mapa/diskurs.qmd` | `C:/Users/lsikic/Luka C/.../Language model` | `../../data/nlp/` |
| `pages/mapa/mapa_stats.qmd` | `C:/Users/lsikic/Luka C/.../Language model` | `../../data/nlp/` |
| `load_and_merge_xlsx.R` | `C:/Users/lsikic/Dropbox/DigiKat/2024&25 Dta` | `data/raw/` |
| `R/load_merge_filter_religious.R` | `C:/Users/lsikic/Dropbox/DigiKat/2024&25 Dta` | `data/raw/` |

## Troubleshooting

If you encounter "file not found" errors:

1. Check that you're running scripts from the repository root directory
2. Verify the data files are in the correct folders
3. For Quarto pages in `pages/mapa/`, the relative paths go up two levels (`../../`)

## Contact

If you have questions about setting up this repository, refer to this document or check the README.md file.
