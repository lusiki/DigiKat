"""Bounded process parallelism; six disjoint year partitions, four SQL threads each."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import subprocess,sys
script=Path(__file__).with_name('01_scan.py')
def run(year):
    p=subprocess.run([sys.executable,'-X','utf8',str(script),'--year',str(year)])
    if p.returncode:raise RuntimeError(f'Year {year} failed: {p.returncode}')
if __name__=='__main__':
    subprocess.run([sys.executable,'-X','utf8',str(script),'--prepare-only'],check=True)
    with ThreadPoolExecutor(max_workers=6) as pool:list(pool.map(run,range(2021,2027)))
    subprocess.run([sys.executable,'-X','utf8',str(script)],check=True)
