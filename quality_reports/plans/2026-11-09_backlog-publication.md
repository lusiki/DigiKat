# Backlog publication and local cleanup

User authorization: commit and push the paper update and all other pending project work to GitHub, and clean the local Git backlog.

Plan:
1. Inventory tracked, staged and untracked files; preserve all local research data.
2. Exclude disposable caches, temporary render files and restricted research artifacts from version control.
3. Run disclosure and forbidden-artifact checks; independently verify the website/paper release and staged files.
4. Commit the manuscript/site update and remaining research work in explicit groups, fetch and push without rewriting history.
5. Confirm remote HEAD and clean working tree; document local-only exclusions.

No corpus rebuild, full website render, raw-data deletion or history rewrite is needed.

## Validation and approval checkpoint

- Reviewed 872 paths; no forbidden artifacts or files over 50 MB.
- R disclosure guard passed for 411 artifacts. Normal renv startup stalled; the read-only guard completed with `Rscript --vanilla`, without changing dependencies or data.
- Seventeen report/public-export/aggregate tests passed. The missing regex dependency was installed only in ignored temporary storage.
- Independent verifier returned PASS for paper hashes, source snapshots, PDF/DOCX contents, site links, UTF-8, data safety and public artifact spot checks.
- Origin main and local HEAD matched before staging.
- Automatic approval review rejected bulk staging, requiring confirmation of this exact inventoried set immediately before staging. No commit or push has occurred. Existing six staged public data files remain unchanged.
- Exact reviewable list: `tmp/backlog-publication/reviewed-files.md` (local only). Temporary and private files are preserved, not deleted.

The user subsequently explicitly confirmed this reviewed batch: "Come on commit and push." Bulk staging succeeded. Publication proceeds in the three documented groups without deleting local files.
