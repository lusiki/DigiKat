"""Download official Croatian models; no corpus is read or transmitted."""
import classla
for kind in ('standard', 'nonstandard'):
    classla.download('hr', type=kind)
