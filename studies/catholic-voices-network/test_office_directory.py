import importlib,unittest
module=importlib.import_module('22_office_directory')

class Directory(unittest.TestCase):
    def test_title_link_scope(self):
        rows=module.directory_entries('<a href="/profile">Mons. dr. Ana Primjer, primjerna biskupica</a><a href="https://elsewhere.test">Mons. Ivan Primjer, biskup</a>','https://hbk.hr/biskupi/')
        self.assertEqual(len(rows),1);self.assertEqual(rows[0]['name'],'Ana Primjer')
    def test_dates_do_not_become_tenures(self):
        events=module.dated_events('Imenovan je 1. siječnja 2024. Zaređen je 3. ožujka 2024.')
        self.assertEqual(len(events),2)
        self.assertTrue(all(not x['tenure_boundary_accepted'] for x in events))
        self.assertTrue(all('ordination' in x['nearby_event_types'] for x in events))
    def test_only_unique_specific_dated_office_gets_alias(self):
        from test_offices import row
        aliases=importlib.import_module('22_office_aliases')
        r=row('Qperson','2024-01-01');r['office_label_hr']='Roman Catholic Bishop of Example'
        person=dict(name='Ana Primjer',role='primjerna biskupica',qid_matches=['Qperson'],retired=False,
          unique_holder_matches_at_corpus_end=False,url='https://hbk.hr/example',directory='https://hbk.hr/biskupi/',profile_retrieved_utc='fixture')
        result,_=aliases.derive({'entries':[person]},{'offices':[r]})
        self.assertEqual(len(result),1);self.assertEqual(result[0]['office_qid'],'Q1')
        other={**r,'office_qid':'Q2','office_label_hr':'Roman Catholic Bishop of Elsewhere'}
        result,_=aliases.derive({'entries':[person]},{'offices':[r,other]})
        self.assertEqual(result,[])
        self.assertFalse(aliases.specific_bishop_office('naslovni biskup Stagnuma'))

if __name__=='__main__':unittest.main()
