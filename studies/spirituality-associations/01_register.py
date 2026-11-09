"""Preserve source files, extract PDF cells, reconcile and profile the register."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import importlib.metadata
import json
import re
import shutil
import fitz
from common import PRIVATE, TABLES, norm, sha, dump_json, write_csv

CUES = {
    'christian': r'katolic|krscan|bratov|isus|marijin|franjev|hagioter|evandel|biblij|salezij|dominik|karmel|ignacij|stepinc|bogorod|apostol',
    'other_named_traditions': r'budis|budd|padmasana|shechen|zidov|hebrej|islams|dervis|hare kris|vaisnav|bahai|baha i|hindu|vedsk',
    'yoga_meditation_development': r'joga|yoga|medit|holist|osobn.{0,8}razvoj|duhovn|reiki|svjesnost|svijesnost|psihofiz|transformacij',
    'humanitarian_social_support': r'humanitar|socijal|inkluz|volonter|dobrotvor|pomoc|potpor|solidarn|invalid|djeci|djece|obitelj',
    'culture_heritage_community': r'matic[ae] hrvatsk|kultur|bastin|zbor|izvidac|branitelj|veteran|folklor|tradic|umjet|zena|turist',
}

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--json', required=True)
    p.add_argument('--pdf', required=True)
    p.add_argument('--brief', required=True)
    args = p.parse_args()
    src = PRIVATE / 'source'
    src.mkdir(exist_ok=True)
    sources = []
    for label, input_path, filename in [('register_json', args.json, 'associations_parsed.json'), ('register_pdf', args.pdf, 'associations_register.pdf'), ('research_brief', args.brief, 'research_brief.txt')]:
        dest = src / filename
        if not dest.exists():
            shutil.copy2(input_path, dest)
        if sha(dest) != sha(input_path):
            raise ValueError(f'Preserved source differs: {label}')
        sources.append({'source': label, 'stored_file': filename, 'bytes': dest.stat().st_size, 'sha256': sha(dest)})
    original = json.loads((src / 'associations_parsed.json').read_text(encoding='utf-8'))
    by_id = {r['id']: r for r in original}
    assert len(by_id) == len(original), 'Duplicate supplied IDs'
    doc = fitz.open(src / 'associations_register.pdf')
    cover = doc[0].get_text()
    cover_total = int(re.search(r'RH:\s*(\d+)', cover).group(1))
    rows, failures, county_totals, dates = [], [], {}, set()
    for i, page in enumerate(doc):
        txt = page.get_text()
        dates.update(re.findall(r'\d{1,2}\.\d{1,2}\.2026\.', txt))
        for table in page.find_tables().tables:
            for cells in table.extract():
                if len(cells) != 6:
                    continue
                raw_id = re.sub(r'\s+', '', cells[0] or '')
                if not raw_id.isdigit():
                    continue
                county, name, seat = [' '.join((c or '').split()) for c in cells[1:4]]
                email = re.sub(r'\s+', '', cells[4] or '')
                website = re.sub(r'\s+', '', cells[5] or '')
                supplied = by_id.get(raw_id)
                record = {'association_id': raw_id, 'county': county, 'name': name, 'registered_seat': seat,
                          'locality_candidate': seat.rsplit(',', 1)[-1].strip() if ',' in seat else '',
                          'email_present': bool(email), 'website_raw': website, 'pdf_page': i+1,
                          'name_normalized': norm(name), 'declared_orientation': 'not_yet_verified',
                          'existence_in_2025': 'not_yet_verified', 'recent_activity': 'not_yet_verified'}
                # No personal email addresses retained outside the preserved PDF.
                if supplied is None or norm(name) != norm(supplied['name']) or county != supplied['county'] or i+1 != supplied['page']:
                    failures.append({'pdf': record, 'json': supplied})
                for cue, pattern in CUES.items():
                    record['cue_' + cue] = bool(re.search(pattern, norm(name)))
                record['cue_count'] = sum(record['cue_' + c] for c in CUES)
                record['sampling_stratum'] = next((c for c in CUES if record['cue_' + c]), 'no_lexical_cue')
                rows.append(record)
        if 'BROJ UDRUGA:' in txt:
            # Footer extraction places the total immediately before BROJ UDRUGA.
            m = re.search(r'(\d+)\s+BROJ UDRUGA:\s+ŽUPANIJA:\s+([^\n]+)', txt)
            if m:
                county_totals[m.group(2).strip()] = int(m.group(1))
    dump_json(PRIVATE / 'reconciliation_discrepancies.json', failures)
    write_csv(PRIVATE / 'register.csv', rows)
    counts = Counter(r['county'] for r in rows)
    actual_ids = [r['association_id'] for r in rows]
    audit = {'source_files': sources, 'pdf_pages': len(doc), 'pdf_metadata': doc.metadata,
             'pdf_report_dates': sorted(dates), 'cover_total': cover_total, 'json_rows': len(original),
             'pdf_rows': len(rows), 'unique_ids': len(set(actual_ids)), 'county_count': len(counts),
             'missing_from_pdf': sorted(set(by_id)-set(actual_ids)), 'extra_in_pdf': sorted(set(actual_ids)-set(by_id)),
             'row_discrepancies': len(failures), 'footer_counties': len(county_totals),
             'county_totals_reconcile': dict(counts) == county_totals,
             'website_populated': sum(bool(r['website_raw']) for r in rows),
             'email_populated': sum(r['email_present'] for r in rows),
             'locality_candidate_populated': sum(bool(r['locality_candidate']) for r in rows),
             'duplicate_normalized_name_groups': sum(v>1 for v in Counter(r['name_normalized'] for r in rows).values()),
             'pymupdf_version': importlib.metadata.version('pymupdf'),
             'run_utc': datetime.now(timezone.utc).isoformat()}
    dump_json(TABLES / 'register_audit.json', audit)
    write_csv(TABLES / 'county_inventory.csv', [{'county': c, 'associations': n, 'share_pct': round(n/len(rows)*100,4),
          'pdf_footer_total': county_totals.get(c), 'website_field_present': sum(bool(r['website_raw']) for r in rows if r['county']==c)}
          for c,n in counts.most_common()])
    write_csv(TABLES / 'lexical_cues.csv', [{'lexical_cue': k, 'associations': sum(r['cue_'+k] for r in rows), 'regex_normalized_name': v}
          for k,v in CUES.items()] + [{'lexical_cue': 'no_lexical_cue','associations':sum(r['cue_count']==0 for r in rows),'regex_normalized_name':''},
          {'lexical_cue':'multiple_cues','associations':sum(r['cue_count']>1 for r in rows),'regex_normalized_name':''}])
    assert len(rows) == len(set(actual_ids)) == len(original) == cover_total
    assert set(by_id) == set(actual_ids)
    assert audit['county_totals_reconcile'], 'County footer mismatch'
    print(json.dumps(audit, ensure_ascii=False, indent=2))
    if failures:
        print('Inspect discrepancies: line wrap hyphenation may explain differences.')

if __name__ == '__main__':
    main()
