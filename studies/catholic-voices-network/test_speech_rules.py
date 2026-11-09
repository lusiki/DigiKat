import unittest
from speech_rules import attributed,first_person,quotes

def token(text,surface,wid,head,dep,lemma=None,upos='VERB',feats=''):
    start=text.index(surface)
    return dict(start=start,end=start+len(surface),sentence=0,
      words=[dict(id=wid,head=head,deprel=dep,lemma=lemma or surface.casefold(),upos=upos,feats=feats)])

class Speech(unittest.TestCase):
    def test_attendance_near_quote_is_not_attribution(self):
        text='Ivan je došao. "Vjera je važna."'
        tokens=[token(text,'Ivan',1,2,'nsubj',upos='PROPN'),token(text,'došao',2,0,'root','doći')]
        mentions=[dict(start=0,end=4,entity_id='E1',**{'class':'contemporary'})]
        self.assertEqual(attributed(text,tokens,mentions),[])
    def test_dependency_subject_gets_quote(self):
        text='Ivan kaže: "Vjera je važna."'
        tokens=[token(text,'Ivan',1,2,'nsubj',upos='PROPN'),token(text,'kaže',2,0,'root','kazati'),
                token(text,'važna',3,2,'ccomp','važan'),token(text,'.',4,3,'punct',upos='PUNCT')]
        mentions=[dict(start=0,end=4,entity_id='E1',**{'class':'contemporary'})]
        rows=attributed(text,tokens,mentions);self.assertEqual(rows[0]['mode'],'direct')
        self.assertEqual(text[rows[0]['content_start']:rows[0]['content_end']],'Vjera je važna.')
        mentions[0]['class']='historical';self.assertEqual(attributed(text,tokens,mentions),[])
    def test_quoted_first_person_does_not_belong_to_author(self):
        text='Ivan kaže: "Molim svakoga jutra."'
        t=token(text,'Molim',1,0,'root','moliti',feats='Person=1|VerbForm=Fin')
        self.assertIsNone(first_person(text,[t],'AUTHOR'))
        text='Molim svakoga jutra.';t=token(text,'Molim',1,0,'root','moliti',feats='Person=1|VerbForm=Fin')
        self.assertEqual(first_person(text,[t],'AUTHOR')['entity_id'],'AUTHOR')
        self.assertIsNone(first_person(text,[t],None))
    def test_person_in_relative_clause_does_not_become_speaker(self):
        text='Ivan kojeg Marko poznaje kaže da je vjera važna.'
        ts=[token(text,'Ivan',1,5,'nsubj',upos='PROPN'),token(text,'Marko',2,3,'nsubj',upos='PROPN'),
            token(text,'poznaje',3,1,'acl:relcl','poznavati'),token(text,'kaže',5,0,'root','kazati'),
            token(text,'važna',6,5,'ccomp','važan'),token(text,'.',7,6,'punct',upos='PUNCT')]
        mentions=[dict(start=text.index(n),end=text.index(n)+len(n),entity_id=n,**{'class':'contemporary'}) for n in ['Ivan','Marko']]
        self.assertEqual([r['entity_id'] for r in attributed(text,ts,mentions)],['Ivan'])
    def test_multiline_quote_cannot_become_author_first_person(self):
        text='Ivan je napisao: "Vjera je važna.\nMolim svakoga dana."'
        t=token(text,'Molim',1,0,'root','moliti',feats='Person=1|VerbForm=Fin')
        self.assertIsNone(first_person(text,[t],'AUTHOR'))

if __name__=='__main__':unittest.main()
