"""Private inputs for mention networks; disclosure never changes the null model."""
import bisect,csv,hashlib,re
from urllib.parse import urlsplit
from voices_common import ROOT,CORPUS_HASH,CONFIG_HASH,utc,transaction

DOMAIN=re.compile(r'(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}',re.I)

def source_policy(source,platform,labels):
    """An account URL is not made public merely by stripping its path."""
    source=(source or '').strip();key=source.casefold()
    row=labels.get(key,{})
    bare=source.rstrip('/')
    if bare.startswith(('https://','http://')):
        parts=urlsplit(bare)
        bare=parts.netloc if not parts.path and not parts.query and not parts.fragment else ''
    domain=bool(DOMAIN.fullmatch(bare))
    public=bool(source and (row.get('publish','').casefold()=='yes' or domain))
    return dict(source_id='S'+hashlib.sha256((platform+'\0'+source).encode()).hexdigest()[:24],
      public_label=source if public else platform+' — ostali izvori',public=public,
      label=row.get('label') if row.get('label') in {'confessional','secular'} else 'unlabelled',
      nonempty=bool(source))

def read_labels():
    with (ROOT/'resources/dictionaries/source_labels.csv').open(encoding='utf-8-sig',newline='') as f:
        return {r['from'].strip().casefold():r for r in csv.DictReader(f)}

def paragraph_numbers(text,positions):
    ends=[m.end() for m in re.finditer(r'\n\s*\n',text)]
    return [bisect.bisect_right(ends,p) for p in positions]

def materialize(con,labels):
    con.execute('''CREATE TABLE IF NOT EXISTS network_mention_paragraphs (
      doc_id VARCHAR,entity_id VARCHAR,paragraph_id INTEGER,spans INTEGER,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
      PRIMARY KEY(doc_id,entity_id,paragraph_id))''')
    con.execute('''CREATE TABLE IF NOT EXISTS network_mention_docs (
      doc_id VARCHAR PRIMARY KEY,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    while True:
        docs=con.execute('''SELECT d.doc_id,d.text_clean FROM docs d
          ANTI JOIN network_mention_docs n USING(doc_id) ORDER BY d.doc_id LIMIT 500''').fetchall()
        if not docs:break
        by_doc={did:[] for did,_ in docs}
        for did,eid,at in con.execute('''SELECT doc_id,entity_id,start_char FROM resolved_mentions
          WHERE life_class='contemporary' AND qid IS NOT NULL
          AND doc_id IN (SELECT unnest(?)) ORDER BY doc_id,start_char''',[list(by_doc)]).fetchall():
            by_doc[did].append((eid,at))
        import collections
        rows=[]
        for did,text in docs:
            mentions=by_doc[did]
            groups=collections.Counter(zip([r[0] for r in mentions],paragraph_numbers(text,[r[1] for r in mentions])))
            rows.extend((did,eid,p,n,CORPUS_HASH,CONFIG_HASH,utc()) for (eid,p),n in groups.items())
        with transaction(con):
            if rows:con.executemany('INSERT INTO network_mention_paragraphs VALUES (?,?,?,?,?,?,?)',rows)
            con.executemany('INSERT INTO network_mention_docs VALUES (?,?,?,?)',[(d,CORPUS_HASH,CONFIG_HASH,utc()) for d,_ in docs])
        con.execute('CHECKPOINT')
    if con.execute("SELECT count(*) FROM information_schema.tables WHERE table_name='network_input_snapshot'").fetchone()[0]:
        return
    # Source identities stay separate internally. Publishing their aggregate label
    # must never create artificial co-occurrence links among private accounts.
    with transaction(con):
        con.execute('''CREATE OR REPLACE TABLE network_sources (
          source VARCHAR,platform VARCHAR,source_id VARCHAR,public_label VARCHAR,
          publish BOOLEAN,label VARCHAR,nonempty BOOLEAN,
          corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
        sources=[]
        for source,platform in con.execute('SELECT DISTINCT source,platform FROM docs').fetchall():
            s=source_policy(source,platform,labels)
            sources.append((source,platform,s['source_id'],s['public_label'],s['public'],s['label'],s['nonempty'],CORPUS_HASH,CONFIG_HASH,utc()))
        con.executemany('INSERT INTO network_sources VALUES (?,?,?,?,?,?,?,?,?,?)',sources)
        con.execute('''CREATE OR REPLACE TABLE network_people AS
          SELECT p.entity_id,count(DISTINCT p.doc_id) AS documents,
            count(DISTINCT nullif(trim(d.source),'')) AS outlets,
            count(DISTINCT d.platform) AS platforms,sum(p.spans) AS mention_spans,
            count(DISTINCT p.doc_id)>=20 AND count(DISTINCT nullif(trim(d.source),''))>=3 AS d6,
            ? AS corpus_sha256,? AS config_hash,? AS created_utc
          FROM network_mention_paragraphs p JOIN docs d USING(doc_id) GROUP BY p.entity_id''',[CORPUS_HASH,CONFIG_HASH,utc()])
        con.execute('''CREATE OR REPLACE TABLE network_doc_entities AS
          SELECT p.doc_id,p.entity_id,sum(p.spans) AS mention_spans,
            ? AS corpus_sha256,? AS config_hash,? AS created_utc
          FROM network_mention_paragraphs p JOIN network_people n USING(entity_id)
          WHERE n.d6 GROUP BY p.doc_id,p.entity_id''',[CORPUS_HASH,CONFIG_HASH,utc()])
        con.execute('CREATE TABLE network_input_snapshot AS SELECT ? AS created_utc,? AS corpus_sha256,? AS config_hash',
          [utc(),CORPUS_HASH,CONFIG_HASH])
