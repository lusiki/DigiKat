"""Parallel execution entry point; the original method is byte-preserved in v1."""
from gazetteer_parallel import main, reference

# Preserve the public pattern API used by existing regression checks.
NB, NE, CUES = reference.NB, reference.NE, reference.CUES
inflect, patterns = reference.inflect, reference.patterns

if __name__ == '__main__':
    main()