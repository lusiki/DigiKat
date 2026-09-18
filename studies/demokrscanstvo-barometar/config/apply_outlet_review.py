"""Apply evidence-backed metadata recommendations under PI's execution authority.

Does not freeze membership or inspect numerator counts. Unknowns remain explicit.
"""
from pathlib import Path
import csv

root = Path(__file__).resolve().parents[3]
registry_path = root / 'studies/demokrscanstvo-barometar/config/outlet_registry.csv'
review_path = root / 'quality_reports/2026-09-18_barometar-outlet-review.csv'
with registry_path.open(encoding='utf-8-sig', newline='') as stream:
    reader = csv.DictReader(stream)
    columns = reader.fieldnames
    registry = list(reader)
with review_path.open(encoding='utf-8-sig', newline='') as stream:
    review = list(csv.DictReader(stream))
for recommendation in review:
    domain = recommendation['domain']
    matching = [row for row in registry if domain in row['from_values'].split(';') or domain in row['url_hosts'].split(';')]
    if len(matching) != 1:
        raise ValueError(f'Expected exactly one registry entry for {domain}, found {len(matching)}')
    row = matching[0]
    for key in ['editorial', 'croatia_link', 'segment']:
        row[key] = recommendation[key]
    row['evidence_note'] = recommendation['note'] + ' Source: ' + recommendation['evidence_url']
    row['status'] = 'metadata_reviewed_2026-09-18'
    row['proposed_eligible'] = str(row['editorial']=='TRUE' and row['croatia_link']=='TRUE').upper()
with registry_path.open('w', encoding='utf-8', newline='') as stream:
    writer = csv.DictWriter(stream, fieldnames=columns, lineterminator='\n')
    writer.writeheader()
    writer.writerows(registry)
print(f'Applied {len(review)} documented outlet metadata recommendations; panel remains unfrozen.')
