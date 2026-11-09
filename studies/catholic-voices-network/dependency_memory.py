"""Same CLASSLA decoder operations; discard unused dense contraction history.

The installed reference saves scores/subscores/cycles on its stack, but none
are consumed by expansion. Retain exactly the five inputs expansion reads.
This is a memory-lifetime change, not a different decoding algorithm.
"""
import hashlib
from pathlib import Path

import numpy as np
from classla.models.common import chuliu_edmonds as decoder

REFERENCE_SHA256 = 'c2eb9c2d9d20bb8121474f6c6e57f2e2003901b148b3fff169d7d819bc8b403a'
REFERENCE_DECODE = decoder.chuliu_edmonds


def verify_reference():
    actual = hashlib.sha256(Path(decoder.__file__).read_bytes()).hexdigest()
    if actual != REFERENCE_SHA256:
        raise RuntimeError('CLASSLA decoder source changed; qualification required')
    return actual


def compact_chuliu_edmonds(scores):
    subtree_stack = []
    decoder.prepare_scores(scores)
    tree = np.argmax(scores, axis=1)
    cycles = decoder.tarjan(tree)
    while cycles:
        subscores, cycle_locs, noncycle_locs, metanode_heads, metanode_deps = (
            decoder.process_cycle(tree, cycles.pop(), scores))
        subtree_stack.append((tree, cycle_locs, noncycle_locs,
                              metanode_heads, metanode_deps))
        scores = subscores
        decoder.prepare_scores(scores)
        tree = np.argmax(scores, axis=1)
        cycles = decoder.tarjan(tree)
    while subtree_stack:
        contracted_tree = tree
        tree, cycle_locs, noncycle_locs, metanode_heads, metanode_deps = subtree_stack.pop()
        tree = decoder.expand_contracted_tree(tree, contracted_tree, cycle_locs,
                                              noncycle_locs, metanode_heads, metanode_deps)
    return tree


def install():
    verify_reference()
    from classla.models.depparse import trainer
    decoder.chuliu_edmonds = compact_chuliu_edmonds
    trainer.chuliu_edmonds = compact_chuliu_edmonds
    # The unchanged one-root function resolves chuliu_edmonds in decoder's
    # globals, so its candidates, scores and tie-breaking are unchanged too.


def restore():
    from classla.models.depparse import trainer
    decoder.chuliu_edmonds = REFERENCE_DECODE
    trainer.chuliu_edmonds = REFERENCE_DECODE
