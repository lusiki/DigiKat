"""Batch POS/lemma work while tokenizing each original context separately.

Sentence/token objects stay in their original documents. Only the processors'
existing sentence/word batch loaders see a combined list; no contexts are joined
into one sentence or re-tokenized. Production use requires separate GPU parity.
"""
from classla.models.common.doc import Document


def analyze_contexts(pipeline,texts):
    if set(pipeline.processors)!={'tokenize','pos','lemma'}:
        raise ValueError('Only the pinned tokenize,pos,lemma pipeline is supported')
    documents=[pipeline.processors['tokenize'].process(text) for text in texts]
    combined=Document([])
    combined.sentences=[sentence for document in documents for sentence in document.sentences]
    combined.num_tokens=sum(document.num_tokens for document in documents)
    combined.num_words=sum(document.num_words for document in documents)
    pipeline.processors['pos'].process(combined)
    pipeline.processors['lemma'].process(combined)
    return documents


def fingerprint(document):
    return [[(token.text,token.start_char,token.end_char,
              [(word.text,word.lemma,word.upos,word.xpos,word.feats) for word in token.words])
             for token in sentence.tokens] for sentence in document.sentences]
