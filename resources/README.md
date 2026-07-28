# Language-resource inventory and provenance

Third-party resources in this directory do **not** inherit the repository-wide project-material badge.
Their upstream licenses and attribution requirements remain in force. `PROVENANCE.csv` records every
resource’s size, SHA-256, active/legacy status, source family, and governing terms.

## Active resources

| Files | Use | Source and terms |
|---|---|---|
| `lexicons/crosentilex-{positives,negatives}.txt`, `lexicons/gs-sentiment-annotations.txt` | polarity and gold evaluation | [CroSentiLex, HR-CLARIN](https://repository.clarin.hr/items/a5624515-6a71-45e4-bc6c-afc21ca2fcea); repository record lists MIT |
| `dictionaries/lilaHR_clean.xlsx` | eight-emotion and polarity dictionary | transformed from [LiLaH](https://www.clarin.si/repository/xmlui/handle/11356/1318); CC BY-NC-SA 4.0 |
| `models/croatian-set-ud-2.5-191206.udpipe` | tokenization, lemmatization, POS, dependency parsing | [UDPipe 1 models](https://ufal.mff.cuni.cz/udpipe/1); models CC BY-NC-SA, underlying [UD Croatian SET](https://universaldependencies.org/treebanks/hr_set/index.html) CC BY-SA 4.0 |
| `dictionaries/source_labels.csv` | PI-controlled catalog labels and publication decisions | DigiKat project-authored configuration; project-declared CC BY 4.0 |

The LiLaH paper should be cited as Ljubešić et al. (2020), and the Croatian SET model as Agić and
Ljubešić (2015) together with Straka et al. (2016). Entries are in the root `references.bib`.

## Retained reference/legacy resources

The remaining Catholic-expression workbooks, alternate LiLaH workbooks/raw exports, and stemming
rule files are not read by the active pipeline. They remain checksum-inventoried so historical analyses
can be interpreted. Do not add a new dependency on them without:

1. documenting their exact origin and transformation;
2. confirming redistribution terms;
3. adding a schema/content validation test; and
4. deciding whether the active canonical source should replace an existing one.

`R/religious_terms.R` and `R/lib/thematic_dictionaries.R` are the active canonical term and theme
definitions. The older Catholic-expression workbooks are not authoritative.

## Integrity

The canonical UDPipe hash is:

```text
b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7
```

Run `Rscript R/00_setup.R` or `Rscript R/capture_environment.R` to verify it. If any inventoried resource
changes intentionally, update `PROVENANCE.csv`, record the upstream version, and rerun affected analyses.

