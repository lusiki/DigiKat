import copy,json,tempfile,unittest
from pathlib import Path
from report_contract import assemble,sha,FOOTER,format_hr

class Contract(unittest.TestCase):
    def test_complementary_counts_hide_both_cells(self):
        from report_narrative import Narrative
        with tempfile.TemporaryDirectory() as folder:
            source=Path(folder)/'counts.json'
            for counts in [(20,51),(3,68),(68,3),(0,71),(5,66)]:
                data=dict(a=counts[0],b=counts[1])
                source.write_text(json.dumps(data),encoding='utf-8')
                narrative=Narrative(data,source,folder,{})
                rendered=narrative.complementary_counts(['/a','/b'])
                if min(counts)<5:
                    self.assertEqual(rendered,['nije prikazano']*2)
                    self.assertEqual(narrative.registry['scalars'],{})
                else:
                    self.assertEqual(len(narrative.registry['scalars']),2)
                    self.assertTrue(all(value.startswith('{{scalar:') for value in rendered))

    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.base=Path(self.temp.name)
        source=self.base/'source.json';source.write_text(json.dumps({'n':611583,'speaks':'withdrawn'}),encoding='utf-8')
        fragment=self.base/'mentions.md';fragment.write_text('Korpus sadrži {{scalar:n}} objava.',encoding='utf-8')
        self.registry=dict(sources={'source':dict(path='source.json',sha256=sha(source))},
          scalars={'n':dict(value=611583,proof=dict(source='source',pointer='/n'))},
          claims={'coverage':dict(level='A',evidence=['n'])},
          fragments={'mentions':dict(path='mentions.md',sha256=sha(fragment),status='complete',claims=['coverage'])})
        self.template='{{fragment:mentions}}\n\n'+FOOTER
    def tearDown(self):self.temp.cleanup()
    def test_literal_numbers_and_tamper(self):
        output,_=assemble(self.template,self.registry,self.base)
        self.assertIn('611\u00a0583',output)
        self.registry['scalars']['n']['value']=611584
        with self.assertRaisesRegex(ValueError,'does not match'):assemble(self.template,self.registry,self.base)
    def test_withdrawn_model_cannot_be_published(self):
        claim=self.registry['claims']['coverage'];claim['level']='B'
        claim['publication_gate']=dict(source='source',pointer='/speaks')
        with self.assertRaisesRegex(ValueError,'publication gate'):assemble(self.template,self.registry,self.base)
    def test_pending_and_altered_fragments_fail(self):
        self.registry['fragments']['mentions']['status']='pending'
        with self.assertRaisesRegex(ValueError,'Unfinished'):assemble(self.template,self.registry,self.base)
        self.registry['fragments']['mentions']['status']='complete'
        (self.base/'mentions.md').write_text('Changed',encoding='utf-8')
        with self.assertRaisesRegex(ValueError,'Fragment changed'):assemble(self.template,self.registry,self.base)
    def test_small_cells_and_fractions(self):
        self.assertEqual(format_hr(3,suppress_small=True),'<5')
        self.assertEqual(format_hr(0,suppress_small=True),'<5')
        self.assertEqual(format_hr(.943333,'percent',1),'94,3\u00a0%')
        with self.assertRaises(ValueError):format_hr(1.2,'integer')
    def test_labels_are_data_not_markdown(self):
        self.assertEqual(format_hr('Ime | <script> @citacija','label'),'Ime \\| &lt;script&gt; \\@citacija')
    def test_unregistered_number_is_rejected(self):
        path=self.base/'mentions.md';path.write_text('Ukupno 999 objava.',encoding='utf-8')
        self.registry['fragments']['mentions']['sha256']=sha(path)
        with self.assertRaisesRegex(ValueError,'Unregistered literal number'):assemble(self.template,self.registry,self.base)

if __name__=='__main__':unittest.main()
