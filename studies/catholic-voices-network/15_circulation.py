"""Compatible entry point: frozen circulation algorithm with verified bulk inserts."""
from circulation_bulk import main, reference
shingles, jaccard, components = reference.shingles, reference.jaccard, reference.components

if __name__ == '__main__':
    main()
