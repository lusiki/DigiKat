"""Qualified execution adapter; scientific rule engine preserved in v1."""
from rules_memory_safe import main
from rules_parallel_standard import reference

# Preserve the existing reusable rule API for tests and constructed checks.
tokens_from_doc = reference.tokens_from_doc
execute_sentence = reference.execute_sentence
materialize_windows = reference.materialize_windows

if __name__ == '__main__':
    main()
