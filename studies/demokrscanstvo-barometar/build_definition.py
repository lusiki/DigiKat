"""Build inspectable proposed v1 surface forms. No source articles are read.

The execution brief and the frozen CST title list are the only seed sources.
This does not import the excluded co-authored working paper or freeze a definition.
Run from the repository root; generated scalars are always single quoted.
"""
from pathlib import Path
import hashlib
import itertools

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'resources/dictionaries/demokrscanstvo/v1'
BRIEF = 'studies/demokrscanstvo-barometar/BRIEF.md'

def quote(value):
    return "'" + str(value).replace("'", "''") + "'"

def yaml(value, indent=0):
    pad = ' ' * indent
    if isinstance(value, dict):
        rows = []
        for key, val in value.items():
            if isinstance(val, dict) or (isinstance(val, list) and val and isinstance(val[0], dict)):
                rows.append(pad + key + ':\n' + yaml(val, indent + 2))
            else:
                rows.append(pad + key + ': ' + scalar(val))
        return '\n'.join(rows)
    rows = []
    for val in value:
        lines = yaml(val, indent + 2).splitlines()
        rows.append(pad + '- ' + lines[0].lstrip() + '\n' + '\n'.join(lines[1:]))
    return '\n'.join(rows)

def scalar(value):
    if isinstance(value, list):
        return '[' + ', '.join(scalar(v) for v in value) + ']'
    return quote(value)

def forms(stem, endings):
    return [stem + x for x in endings.split('|')]

def adj(stem):
    return forms(stem, 'i|a|o|e|u|og|oga|om|omu|ome|oj|im|ima|ih')

def nf(stem):
    return forms(stem, 'a|e|i|u|om|ama|o')

def nm(stem):
    return forms(stem, '|a|u|om|e|i|ima')

def nn(stem):
    return forms(stem, 'o|a|u|om|ima')

def uniq(seq):
    return sorted(set(seq))

DOCS = {}

def entry(file, ident, family, surface, tier='generic', slots=None, gap=0, principle=None,
          excluded=(), exclusions=(), ascii_forms=(), case=False, source=BRIEF, source_object='section_3_7'):
    surface = uniq(surface)
    kind = 'phrase' if slots or any(' ' in v for v in surface) else 'token'
    item = dict(id=ident, family=family, tier=tier, kind=kind, forms=surface,
                case_sensitive=str(case).lower(), ascii_variants=uniq(ascii_forms),
                exclude_if=list(exclusions), excluded_forms=list(excluded))
    if kind == 'phrase':
        item.update(slots=slots or [], gap_max=str(gap), order='fixed')
    if principle:
        item['principle'] = principle
    source_lines = (ROOT/source).read_text(encoding='utf-8').splitlines()
    if source_object == 'CST_DOCS':
        source_line = str(next(i for i, line in enumerate(source_lines, 1) if '"' + surface[0] + '"' in line))
    else:
        heading = '### 3.9' if file == 'actors' else '### 3.7'
        first = next(i for i, line in enumerate(source_lines, 1) if line.startswith(heading))
        last = next((i - 1 for i, line in enumerate(source_lines, 1) if i > first and line.startswith('### ')), len(source_lines))
        source_line = f'{first}-{last}'
        source_object = 'actor_registry_specification' if file == 'actors' else 'seed_families_specification'
    item['provenance'] = dict(source_file=source, source_object=source_object, source_line=source_line,
        source_sha256=hashlib.sha256((ROOT/source).read_bytes()).hexdigest(), added='2026-09-18',
        reviewed_by='Codex; proposed for empirical development',
        known_defects='Enumerated proposed forms; no human precision estimate yet')
    DOCS.setdefault(file + '.yaml', {'entries': []})['entries'].append(item)

def phrase(file, ident, family, slots, tier='generic', **kwargs):
    entry(file, ident, family, [' '.join(s[0] for s in slots)], tier, slots=slots, **kwargs)

def main():
    entry('direct_terms', 'cd_noun', 'cd_label', nn('demokršćanstv'), 'strong',
          ascii_forms=nn('demokrscanstv'))
    direct = forms('demokršćan', 'in|ina|inu|inom|i|a|ima|e') + adj('demokršćansk')
    direct += forms('demohrišćan', 'in|ina|inu|inom|i|a|ima|e') + adj('demohrišćansk')
    direct += forms('demo-kršćan', 'in|ina|inu|inom|i|a|ima|e')
    entry('direct_terms', 'cd_label', 'cd_label', direct, 'strong',
          ascii_forms=[v.replace('š', 's').replace('ć', 'c') for v in direct])
    first = adj('kršćansk') + adj('hrišćansk')
    second = nm('demokrat') + nf('demokracij') + nf('demokratij') + adj('demokratsk')
    phrase('direct_terms', 'cd_phrase', 'cd_label', [first, second], 'strong')
    closed = [a + b for a in ['kršćansko', 'hrišćansko'] for b in adj('demokratsk')]
    entry('direct_terms', 'cd_closed', 'cd_label', closed, 'strong',
          ascii_forms=[v.replace('š', 's').replace('ć', 'c') for v in closed])
    phrase('direct_terms', 'cd_ascii_phrase', 'cd_label',
           [[v.replace('š', 's').replace('ć', 'c') for v in first], second], 'strong')
    entry('direct_terms', 'cd_foreign', 'cd_label',
          ['christian democrat', 'christian democrats', 'christian democratic', 'christian democracy',
           'christdemokrat', 'christdemokraten', 'christdemokratisch', 'christlich demokratisch',
           'democristiano', 'democristiani', 'democrazia cristiana'], 'strong')
    idea = nn('načel') + ['vrijednost', 'vrijednosti', 'vrijednostima', 'vrijednošću'] + nf('tradicij') + nf('ideologij') + nf('doktrin')
    idea += nm('identitet') + forms('nadahnuć','e|a|u|em') + nf('baštin') + nm('korijen') + nm('svjetonazor')
    idea += nf('orijentacij') + nf('etik') + ['misao', 'misli', 'mišlju'] + nm('koncept') + nf('idej')
    idea += sum([adj(x) for x in ['svjetonazorsk', 'vrijednosn', 'doktrinarn', 'idejn', 'identitetsk', 'tradicijsk']], [])
    idea += ['konzervatizam', 'konzervatizma', 'konzervatizmu', 'konzervatizmom']
    entry('direct_terms', 'idea_cues', 'idea_cue', idea)
    party = nf('strank') + ['stranci', 'stranaka'] + nf('unij') + nm('klub') + nf('koalicij')
    party += nm('kandidat') + nm('čelnik') + ['čelnici', 'čelnicima'] + nf('vođ')
    party += nm('kancelar') + nm('premijer') + nm('zastupnik') + ['zastupnici', 'zastupnicima']
    party += nf('frakcij') + nf('vlad') + nm('izbor') + nm('birač')
    party += sum([adj(x) for x in ['njemačk', 'austrijsk', 'talijansk', 'bavarsk', 'europsk']], [])
    party += sum([adj(x) for x in ['izborn', 'koalicijsk', 'zastupničk', 'biračk', 'kancelarsk', 'čeln']], [])
    party += sum([nf(x) for x in ['ministric', 'premijerk', 'kandidatkinj', 'gradonačelnic', 'zastupnic', 'kancelark', 'čelnic']], [])
    party += nn('čelništv') + ['klubova', 'klubove', 'klubovi', 'klubovima']
    entry('direct_terms', 'party_cues', 'party_cue', party)
    entry('direct_terms', 'party_codes', 'party_cue', ['CDU', 'CSU', 'ÖVP', 'EPP'], case=True)

    phrase('doctrinal_anchors', 'social_teaching', 'doctrine',
           [forms('socijaln', 'i|og|oga|om|omu|ome|im'), forms('nauk', '|a|u|om')], 'strong')
    phrase('doctrinal_anchors', 'social_doctrine', 'doctrine', [adj('socijaln'), nf('doktrin')], 'strong')
    phrase('doctrinal_anchors', 'catholic_teaching', 'doctrine',
           [adj('katoličk'), adj('socijaln'), forms('učenj', 'e|a|u|em|ima')], 'strong')
    phrase('doctrinal_anchors', 'church_teaching', 'doctrine',
           [adj('socijaln'), forms('učenj', 'e|a|u|em|ima'), ['Crkve', 'Crkvi', 'Crkvom', 'Crkava']], 'strong')
    phrase('doctrinal_anchors', 'christian_social_thought', 'doctrine',
           [adj('kršćansk'), adj('socijaln'), ['misao', 'misli', 'mišlju']], 'strong')
    phrase('doctrinal_anchors', 'universal_goods', 'universal_goods',
           [adj('opć') + adj('univerzaln'), nf('namjen'), ['dobara']], 'strong', principle='opca_namjena_dobara')
    phrase('doctrinal_anchors', 'poor_option', 'poor_option',
           [forms('opredjeljenj', 'e|a|u|em') + nf('opcij'), ['za'], adj('siromašn')], 'strong')
    phrase('doctrinal_anchors', 'preferential_poor_love', 'poor_option',
           [adj('povlašten'), ['ljubav', 'ljubavi', 'ljubavlju'], ['prema'], ['siromašnima']], 'strong')
    phrase('doctrinal_anchors', 'integral_ecology', 'integral_ecology',
           [adj('integraln'), nf('ekologij')], 'strong')
    entry('doctrinal_anchors', 'personalism', 'personalism',
          ['personalizam', 'personalizma', 'personalizmu', 'personalizmom'] + nm('personalist') + adj('personalističk'), 'strong')
    titles = ['rerum novarum', 'quadragesimo anno', 'mater et magistra', 'pacem in terris',
      'gaudium et spes', 'populorum progressio', 'octogesima adveniens', 'laborem exercens',
      'sollicitudo rei socialis', 'centesimus annus', 'caritas in veritate', 'evangelii gaudium',
      'laudato si', 'fratelli tutti', 'laudate deum', 'dignitas infinita']
    for title in titles:
        entry('doctrinal_anchors', 'doc_' + title.replace(' ', '_'), 'document', [title], 'strong',
              source='studies/moral-economy/cst_lexicon.R', source_object='CST_DOCS')
    entry('doctrinal_anchors', 'encyclical_genre', 'encyclical', nf('enciklik') + ['enciklici'])

    phrase('christian_grounding', 'christian_basis', 'grounding',
           [adj('kršćansk') + adj('katoličk'),
            nn('načel') + ['vrijednost', 'vrijednosti', 'vrijednostima'] + nf('etik') + nm('nauk') +
            forms('nadahnuć','e|a|u|em') + nm('pogled') + nf('antropologij') + ['savjest', 'savjesti', 'savješću']])
    entry('christian_grounding', 'gospel', 'grounding', forms('evanđelj', 'e|a|u|em') + adj('evanđeosk'))
    entry('christian_grounding', 'according_to_church', 'grounding', ['prema nauku Crkve'])
    entry('christian_grounding', 'church_speaker', 'church_speaker',
          nm('biskup') + nm('nadbiskup') + ['papa', 'pape', 'papi', 'papu', 'papom'] +
          ['Hrvatska biskupska konferencija', 'Hrvatske biskupske konferencije', 'Iustitia et pax',
           'Justitia et pax', 'Sveta Stolica', 'Svete Stolice', 'Caritas', 'Karitas'])

    phrase('concept_families', 'dignity_person', 'dignity',
           [adj('ljudsk'), nn('dostojanstv')], principle='dostojanstvo_osobe')
    phrase('concept_families', 'dignity_of_person', 'dignity',
           [nn('dostojanstv'), ['osobe', 'osoba', 'čovjeka', 'čovjeku']], gap=1, principle='dostojanstvo_osobe')
    phrase('concept_families', 'dignity_work', 'dignity_work',
           [nn('dostojanstv'), ['rada', 'radu', 'radnika', 'radnicima']], 'distinctive', principle='dostojanstvo_osobe')
    phrase('concept_families', 'religious_freedom', 'freedom', [adj('vjersk'), nf('slobod')])
    entry('concept_families', 'conscience', 'freedom', ['sloboda savjesti', 'slobode savjesti', 'prigovor savjesti', 'priziv savjesti'])
    phrase('concept_families', 'human_rights', 'rights', [adj('ljudsk'), ['prava', 'pravima']])
    entry('concept_families', 'solidarity', 'solidarity', ['solidarnost', 'solidarnosti', 'solidarnošću'], principle='solidarnost')
    phrase('concept_families', 'social_justice', 'justice', [adj('socijaln') + adj('društven'), nf('pravd')])
    phrase('concept_families', 'worker_rights', 'work', [adj('radničk'), ['prava', 'pravima', 'pravo']])
    phrase('concept_families', 'rights_of_workers', 'work', [['prava', 'pravo', 'pravima'], ['radnika', 'radnica', 'radnicima', 'zaposlenika', 'zaposlenih']])
    phrase('concept_families', 'fair_wage', 'work', [adj('pravedn'), nf('plać')])
    phrase('concept_families', 'sunday_rest', 'work', [adj('neradn'), nf('nedjelj')])
    entry('concept_families', 'subsidiarity', 'subsidiarity', ['supsidijarnost', 'supsidijarnosti', 'supsidijarnošću'], 'distinctive', principle='supsidijarnost')
    phrase('concept_families', 'subsidiarity_principle', 'subsidiarity', [nn('načel'), adj('supsidijarn')], 'distinctive', principle='supsidijarnost')
    phrase('concept_families', 'participation', 'participation',
           [adj('političk') + adj('građansk') + adj('demokratsk') + adj('društven'), nf('participacij')], principle='sudjelovanje')
    phrase('concept_families', 'social_market', 'social_market',
           [adj('socijaln'), adj('tržišn'), nn('gospodarstv') + nf('ekonomij')], 'distinctive')
    phrase('concept_families', 'common_good', 'common_good',
           [forms('opć', 'e|eg|ega|em|emu|im') + forms('zajedničk', 'o|og|oga|om|omu'), nn('dobr')], 'distinctive',
           excluded=['opća dobra'], principle='opce_dobro')
    phrase('concept_families', 'social_partnership', 'work', [adj('socijaln'), nn('partnerstv')])
    phrase('concept_families', 'family_policy', 'family_life',
           [adj('obiteljsk') + adj('demografsk'), nf('politik') + ['politici']])
    phrase('concept_families', 'parental_rights', 'family_life', [adj('roditeljsk'), nm('dopust') + ['prava', 'pravima', 'pravo']])
    phrase('concept_families', 'child_benefit', 'family_life', [adj('dječj'), ['doplatak', 'doplatka', 'doplatku', 'doplatkom', 'doplatci', 'doplatcima']])
    phrase('concept_families', 'protect_life', 'family_life',
           [nf('zaštit'), ['život', 'života', 'životu', 'životom'] + adj('nerođen')],
           exclusions=['rescue_life'], excluded=['zaštita životinja'])
    entry('concept_families', 'family_life_policy', 'family_life',
          ['sloboda odgoja', 'slobode odgoja', 'medicinski potpomognuta oplodnja', 'palijativna skrb',
           'hod za život', 'vjeronauk u školi', 'pobačajem', 'palijativne skrbi', 'palijativnoj skrbi',
           'palijativnu skrb', 'palijativnom skrbi'] + nm('pobačaj') + nf('eutanazij'))

    public = nm('proračun') + nm('porez') + nf('plać') + nf('mirovin') + nf('strank')
    public += nf('vlad') + nm('parlament') + ['ministar', 'ministra', 'ministru', 'ministrom', 'ministri', 'ministre', 'ministrima'] + nn('ministarstv')
    public += ['Sabor', 'Sabora', 'Saboru', 'Saborom', 'općina', 'općine', 'općini', 'općinama',
               'gradonačelnik', 'gradonačelnika', 'gradonačelnici', 'županija', 'županije', 'županijama']
    public += nm('ustav') + adj('ustavn') + nf('demokracij') + ['pluralizam', 'pluralizma', 'pluralizmu', 'pluralizmom']
    public += ['općinu', 'gradonačelniku', 'gradonačelnikom', 'županiji', 'županiju', 'županijom']
    public += sum([nf(x) for x in ['ministric', 'premijerk', 'gradonačelnic', 'zastupnic', 'kancelark']], [])
    public += adj('zakonodavn')
    entry('public_context', 'public_institutions', 'public', public)
    phrase('public_context', 'public_courts', 'public',
           [adj('ustavn') + adj('vrhovn') + adj('općinsk') + adj('županijsk') + adj('trgovačk') + adj('upravn'), nm('sud') + ['sudovi', 'sudove', 'sudova', 'sudovima']])
    phrase('public_context', 'civil_society', 'public', [adj('civiln'), nn('društv')])
    phrase('public_context', 'party_programme', 'public', [adj('stranačk') + adj('političk'), nm('program')])
    entry('public_context', 'programme_of_party', 'public',
          ['program stranke', 'programa stranke', 'programu stranke', 'programom stranke',
           'program političke stranke', 'programa političke stranke', 'programu političke stranke'])
    entry('public_context', 'public_phrases', 'public',
          ['zakon o', 'Zakona o', 'izmjene zakona', 'izmjena zakona', 'prijedlog zakona', 'prijedloga zakona',
           'donošenje zakona', 'vladavina prava', 'vladavine prava', 'na izborima', 'Europska komisija',
           'Europske komisije', 'Europski parlament', 'Europskog parlamenta', 'lokalna samouprava',
           'lokalne samouprave'], excluded=['zakon o zaštiti osobnih podataka', 'zakon o medijima',
           'zakon o elektroničkim medijima', 'zakon o igrama na sreću'])
    phrase('public_context', 'public_policy', 'public', [adj('javn') + adj('ekonomsk') + adj('gospodarsk') +
        adj('socijaln') + adj('mirovinsk') + adj('porezn') + adj('obrazovn') + adj('zdravstven') +
        adj('demografsk') + adj('obiteljsk') + adj('migracijsk'), nf('politik') + ['politici']])
    phrase('public_context', 'policy_reforms', 'public', [adj('mirovinsk') + adj('porezn') + adj('zdravstven') + adj('obrazovn'), nf('reform')])
    entry('public_context', 'policy_action', 'policy_action', ['izmjene', 'izmjena', 'prijedlog', 'prijedloga',
          'povisiti', 'poveća', 'povećati', 'smanjiti', 'uredi', 'urediti', 'donijeti', 'donošenje', 'odlučuju', 'uređuje',
          'ugraditi', 'ugradio', 'ugradila', 'ugrađuje', 'uvrstiti', 'uvrstio', 'uvrstila', 'isplatiti', 'isplaćivati'])
    phrase('public_context', 'bound_policy_action', 'policy_action',
           [['predložio', 'predložila', 'predložili', 'predložilo', 'predlagao', 'predlagala', 'predlagali',
             'uvesti', 'uveo', 'unijeti', 'unijeli'],
            ['zakon', 'zakona', 'porez', 'poreza', 'reformu', 'reforme', 'proračun', 'proračuna',
             'program', 'programa', 'plaću', 'plaće', 'mirovinu', 'mirovine']], gap=3)
    phrase('public_context', 'election', 'public', [adj('parlamentarn') + adj('lokaln') + adj('predsjedničk') + adj('europsk'), nm('izbor')])

    entry('argument_connectors', 'argument', 'connector',
          ['zahtijeva', 'zahtijevaju', 'zahtijevao', 'zahtijevala', 'protivi se', 'protive se', 'u duhu',
           'polazeći od', 'na temelju', 'nadahnut', 'nadahnuta', 'nadahnuti', 'poziva se na',
           'pozivaju se na', 'se poziva na', 'se pozivaju na', 'pozivajući se na', 'pozvao se na', 'pozvala se na', 'prema nauku Crkve',
           'u skladu sa', 'u skladu s', 'traži', 'traže', 'brani', 'brane', 'zalaže se', 'zalažu se',
           'temelj je', 'temelji se na', 'poziva na', 'pozivaju na', 'pozvao na', 'pozvala na', 'pozvali na',
           'pozvala je na', 'pozvao je na', 'poziva da', 'pozivaju da', 'pozvala je da', 'pozvao je da'])
    entry('argument_connectors', 'argument_reviewed_forms', 'connector',
          ['tražio', 'tražila', 'tražili', 'tražile', 'tražilo', 'tražimo', 'tražite', 'tražiš', 'tražeći',
           'braneći', 'branili', 'branimo', 'branio', 'branila', 'zahtijevalo', 'temeljem',
           'nadahnuto', 'nadahnule', 'nadahnute', 'nadahnutu', 'polazi od', 'polaze od',
           'zalagao se za', 'zalagali se za', 'zalažemo se za', 'temeljilo se na'] +
          [v + complement for v in ['pozivam', 'pozivamo', 'pozivali', 'pozivao', 'pozivala', 'pozvale', 'pozvavši']
           for complement in [' na', ' se na', ' na temelju']] +
          [v + ' na' for v in ['temeljen', 'temeljenom', 'temeljenu', 'temeljena', 'temeljenih',
                             'temeljeno', 'temeljenog', 'temeljene', 'temeljeni']])
    entry('argument_connectors', 'other_speaker', 'other_speaker',
          nm('novinar') + nm('analitičar') + nm('autor') + nm('komentator') + nm('urednik') +
          ['urednici', 'urednicima', 'dužnosnik', 'dužnosnika', 'dužnosnici', 'dužnosnicima'])
    entry('argument_connectors', 'other_speaker_reviewed_forms', 'other_speaker',
          ['analitičarem'] + sum([nf(x) for x in ['autoric', 'novinark', 'političark', 'analitičark', 'urednic', 'komentatoric']], []))
    entry('argument_connectors', 'attribution', 'attribution',
          ['ističe', 'ističu', 'istaknuo', 'istaknula', 'rekao', 'rekla', 'kaže', 'kazao', 'kazala',
           'poručuje', 'poručio', 'poručila', 'navodi', 'smatra', 'smatraju', 'traži', 'zahtijeva'])
    entry('argument_connectors', 'attribution_reviewed_forms', 'attribution',
          ['rekli', 'reklo', 'rekle', 'rekavši', 'kažu', 'kažete', 'kažem', 'kažemo', 'kažeš', 'kazali', 'kazuje', 'kazavši',
           'smatrao', 'smatram', 'smatramo', 'smatrali', 'smatrala', 'smatralo', 'smatrate', 'smatrajući',
           'ističući', 'ističemo', 'ističem', 'ističete', 'istaknuli', 'navode', 'navodeći'])
    entry('identity_register', 'identity_family', 'identity_family',
          ['tradicionalna obitelj', 'tradicionalne obitelji', 'obiteljske vrijednosti', 'obiteljskih vrijednosti',
           'zaštita nerođenih', 'zaštite nerođenih', 'pravo na život', 'prava na život'])
    entry('identity_register', 'identity_other', 'identity_other',
          ['kršćanski identitet', 'kršćanskog identiteta', 'kršćanski korijeni', 'kršćanskih korijena',
           'kršćanska civilizacija', 'kršćanske civilizacije', 'kršćanska Europa', 'kršćanske Europe',
           'rodna ideologija', 'rodne ideologije', 'velika zamjena', 'velike zamjene'] + nf('islamizacij'))

    domains = {
      'family': ('Obitelj, život i odgoj', ['obitelj', 'obitelji', 'obiteljima'] + nm('odgoj') + nm('vjeronauk') + nf('škol') +
                 nm('pobačaj') + nf('eutanazij') + ['djeca', 'djece', 'djeci', 'roditelji', 'roditelja',
                 'roditelj', 'roditelje', 'roditeljima', 'odgojem', 'pobačajem', 'abortus', 'abortusa', 'dječjeg']),
      'work': ('Rad i dostojanstvo rada', ['rad', 'rada', 'radu', 'radom', 'radnik', 'radnika', 'radnici', 'radnicima'] +
               nm('zaposlenik') + ['zaposlenici', 'zaposlenima', 'radnike', 'radniku', 'radnice'] + nf('plać') + ['radne migracije', 'radnih migracija', 'strani radnici', 'stranih radnika']),
      'economy': ('Gospodarski život i socijalna država', nn('gospodarstv') + nf('ekonomij') + nm('porez') +
                 nm('proračun') + nf('mirovin') + nn('siromaštv') + ['socijalna država', 'socijalne države']),
      'politics': ('Politička zajednica, demokracija i vjerska sloboda', nf('demokracij') + nm('ustav') +
                  ['vjerska sloboda', 'vjerske slobode', 'vladavina prava', 'vladavine prava'] + nm('izbor')),
      'europe': ('Europa, međunarodna zajednica i mir', ['Europa', 'Europe', 'Europi', 'Europska unija',
                 'Europske unije', 'Europu', 'Europom', 'Europo', 'mir u svijetu', 'kultura mira', 'kulture mira'] + adj('mirovn') + nm('mirotvorac') + forms('pomirenj','e|a|u|em')),
      'environment': ('Okoliš i briga za zajednički dom', nm('okoliš') + nf('ekologij') +
                     ['briga za zajednički dom', 'brige za zajednički dom', 'brizi za zajednički dom',
                      'brigu za zajednički dom', 'brigom za zajednički dom', 'brigama za zajednički dom'])}
    for ident, (label, vocabulary) in domains.items():
        entry('domain_themes', 'theme_' + ident, 'theme_' + ident, vocabulary)
    DOCS['domain_themes.yaml']['labels'] = {k: v[0] for k,v in domains.items()}
    DOCS['domain_themes.yaml']['labels']['unclassified'] = 'Nerazvrstano'

    entry('exclusions', 'rescue_life', 'exclusion', ['života i imovine', 'života i zdravlja', 'zaštitili živote'])
    phrase('exclusions', 'ecclesial_council', 'ecclesial_council',
           [adj('vatikansk') + adj('crkven') + adj('ekumensk') + adj('biskupsk'), nm('sabor')])
    phrase('exclusions', 'ecclesial_minister', 'ecclesial_council',
           [['generalni', 'generalnog', 'generalnoga', 'generalnom', 'provincijalni', 'provincijalnog', 'provincijalnoga'],
            ['ministar', 'ministra', 'ministru', 'ministrom'] + nf('ministric')])
    phrase('exclusions', 'franciscan_minister', 'ecclesial_council',
           [['ministar', 'ministra', 'ministru', 'ministrom'] + nf('ministric'), adj('franjevačk')], gap=1)
    entry('exclusions', 'cst_organisation_name', 'cst_organisation_name',
          ['Centar za promicanje socijalnog nauka Crkve', 'Centra za promicanje socijalnog nauka Crkve',
           'Centru za promicanje socijalnog nauka Crkve', 'Centrom za promicanje socijalnog nauka Crkve'])
    entry('exclusions', 'publication_notice', 'notice',
          ['predstavljen', 'predstavljena', 'predstavljanje', 'predstavljanja', 'prijevod', 'prijevoda',
           'obljetnica', 'obljetnice', 'promocija', 'promocije', 'objavljena', 'objavljen',
           'objavio', 'objavljeno', 'obljetnicu', 'objava', 'objave', 'objavili', 'objavi', 'objavila', 'objavljenoj',
           'objavu', 'predstavljanju', 'predstavljene', 'objaviti', 'objavljivanja', 'objavljuje', 'obljetnici',
           'objavljene', 'objavljeni', 'objavljenom', 'promociju', 'objavljenih', 'objavljivanje', 'predstavljeni',
           'prijevodu', 'promocijom', 'objavama', 'objavile', 'objavilo', 'objavljenima', 'objavljenu', 'objavljivali',
           'objavljivani', 'objavljivati', 'objavljujemo', 'objavom', 'predstavljenim', 'prijevode', 'promociji'])
    entry('exclusions', 'papal_naming', 'papal_naming',
          ['uzeo ime', 'izabrao ime', 'odabrao ime', 'izbor imena', 'izbora imena', 'papinsko ime'])
    entry('exclusions', 'legal_senses', 'legal_sense',
          ['supsidijarna zaštita', 'supsidijarne zaštite', 'supsidijarnu zaštitu',
           'supsidijarna odgovornost', 'supsidijarne odgovornosti', 'supsidijarna tužba',
           'pomorsko dobro', 'pomorskog dobra', 'od interesa za Republiku'])
    entry('exclusions', 'toponyms', 'toponym',
          ['Općina Biskupija', 'Općine Biskupija', 'Sveti Križ Začretje', 'Vatikanska ulica',
           'Općina Kapela', 'oltar Domovine', 'križni put'])
    entry('actors', 'actor_hdz', 'actor_cd', ['HDZ', 'HDZ-a', 'HDZ-u', 'HDZ-om', 'HDZ-ov', 'HDZ-ova', 'HDZ-ove'], case=True)
    entry('actors', 'actor_hdz_full', 'actor_cd', ['Hrvatska demokratska zajednica', 'Hrvatske demokratske zajednice', 'Hrvatskoj demokratskoj zajednici'], case=True)
    entry('actors', 'actor_hbk', 'actor_church', ['HBK', 'HBK-a', 'HBK-u', 'HBK-om'], case=True)
    entry('actors', 'actor_foreign_codes', 'actor_foreign', ['CDU', 'CSU', 'ÖVP', 'CD&V', 'NSi'], case=True)
    entry('actors', 'actor_hdz_bih', 'actor_foreign', ['HDZ BiH', 'HDZ-a BiH', 'HDZ-u BiH'], case=True)
    entry('actors', 'geography_foreign', 'geography_foreign', ['Francuska', 'Francuskoj', 'Francuske', 'Njemačka',
          'Njemačkoj', 'Njemačke', 'Austrija', 'Austriji', 'Austrije', 'Italija', 'Italiji', 'Italije', 'Bosna i Hercegovina',
          'Bosne i Hercegovine', 'Slovenija', 'Sloveniji', 'Slovenije', 'Poljska', 'Poljskoj', 'Poljske',
          'Francusku', 'Austrijom', 'Slovenijom', 'Poljsku', 'Bosni i Hercegovini', 'Bosnu i Hercegovinu', 'Bosnom i Hercegovinom'])
    entry('actors', 'geography_eu', 'geography_eu', ['Europska komisija', 'Europske komisije', 'Europskoj komisiji',
          'Europski parlament', 'Europskog parlamenta', 'Europskom parlamentu', 'Europska unija', 'Europske unije', 'Europskoj uniji'])
    entry('actors', 'geography_domestic', 'geography_domestic', ['Hrvatska', 'Hrvatske', 'Hrvatskoj', 'Hrvatsku',
          'Hrvatskom', 'Hrvatsko', 'Hrvatskih', 'Hrvatskim', 'Hrvatskoga', 'Zagreb', 'Zagrebu', 'Zagreba', 'Hrvatski sabor', 'Hrvatskog sabora'])
    DOCS['actors.yaml']['registry'] = [
      dict(id='hdz', name_hr='Hrvatska demokratska zajednica', role='cd_self_identified',
           aliases=['HDZ', 'HDZ-a', 'HDZ-u', 'HDZ-om', 'HDZ-ov', 'HDZ-ova', 'HDZ-ove', 'Hrvatska demokratska zajednica', 'Hrvatske demokratske zajednice', 'Hrvatskoj demokratskoj zajednici'],
           valid_from='2024-10-20', valid_to='2026-09-18', country='HR', status='proposed',
           sources=['https://www.hdz.hr/userfiles/My_folder5/dodatno/Statut_2024/STATUT_HDZ_2024.pdf', 'Article 1(1)'],
           note='Earlier validity requires historical statute verification; no back-projection'),
      dict(id='hbk', name_hr='Hrvatska biskupska konferencija', role='church_body',
           aliases=['HBK', 'HBK-a', 'HBK-u', 'HBK-om', 'Hrvatska biskupska konferencija', 'Hrvatske biskupske konferencije'],
           valid_from='2021-01-01', valid_to='2026-09-18', country='HR', status='proposed',
           sources=['https://hbk.hr/'], note='Organisation only; speaker attribution required')]
    # D remains the separately dated domestic self-identification diagnostic.
    # These records license named foreign-party/identity cues, never D.
    for ident, name, aliases, country, start, sources in [
      ('cdu', 'Christlich Demokratische Union Deutschlands', ['CDU'], 'DE', '2021-01-01',
       ['https://archiv.cdu.de/node/27667', '2007 programme and 2024-05-07 successor; official programme history']),
      ('csu', 'Christlich-Soziale Union', ['CSU'], 'DE', '2021-01-01',
       ['https://www.hss.de/fileadmin/user_upload/HSS/Dokumente/ACSP/Grundsatzprogramme/CSU_Grundsatzprogramm_2016.pdf', 'Adopted 2016-11-05; identity cue only']),
      ('ovp', 'Österreichische Volkspartei', ['ÖVP'], 'AT', '2021-01-01',
       ['https://www.dievolkspartei.at/Common/Download/Grundsatzprogramm_dieVolkspartei.pdf', '2015-05-12 edition, printed page 13']),
      ('nsi', 'Nova Slovenija – krščanski demokrati', ['NSi'], 'SI', '2021-01-01',
       ['https://nsi.si/wp-content/uploads/2020/02/Temeljni-program-NSi_sprejetnakongresu.pdf', 'Adopted 2019-11-17']),
      ('cdv', 'Christen-Democratisch & Vlaams', ['CD&V'], 'BE', '2021-01-01',
       ['https://www.cdenv.be/geschiedenis', 'Official history: name adopted 2001-09-28/29; 2020 manifesto']),
      ('hdz_bih', 'Hrvatska demokratska zajednica Bosne i Hercegovine', ['HDZ BiH', 'HDZ-a BiH', 'HDZ-u BiH'], 'BA', '2023-05-06',
       ['https://hdzbih.org/sites/default/files/dokumenti/HDZ%20BiH%20-%20XIV.%20Sabor%20-%20_Statut%20%26%20Program_.pdf', 'Official indexed XIV programme, 2023-05-06; no domestic D inference'])]:
        DOCS['actors.yaml']['registry'].append(dict(id=ident, name_hr=name, aliases=aliases, role='foreign_cd_party',
          valid_from=start, valid_to='2026-09-18', country=country, status='proposed', sources=sources,
          note='Study interval begins after cited identity evidence; organisation identity/foreign cue only; no D or inferred individual ideology'))
    for ident, name, role, country in [
      ('cda', 'Christen Democratisch Appèl', 'foreign_cd_party', 'NL'),
      ('dc_historical', 'Democrazia Cristiana (povijesna talijanska stranka)', 'historical_cd', 'IT'),
      ('hss', 'Hrvatska seljačka stranka', 'epp_affiliated', 'HR'),
      ('hps_1919', 'Hrvatska pučka stranka (1919)', 'historical_cd', 'HR'),
      ('hkp', 'Hrvatski katolički pokret', 'historical_cd', 'HR'),
      ('hkdu', 'Hrvatska kršćanska demokratska unija', 'historical_cd', 'HR'),
      ('hkds', 'Hrvatska kršćanska demokratska stranka', 'historical_cd', 'HR'),
      ('hds', 'Hrvatska demokršćanska stranka', 'historical_cd', 'HR'),
      ('uio', 'U ime obitelji', 'identity_civil_society', 'HR'),
      ('iustitia_hbk', 'Komisija HBK Iustitia et pax', 'church_body', 'HR'),
      ('caritas_hr', 'Hrvatski Caritas', 'church_body', 'HR')]:
        DOCS['actors.yaml']['registry'].append(dict(id=ident, name_hr=name, aliases=[name], role=role,
          valid_from='', valid_to='', country=country, status='excluded_pending_evidence', sources=[],
          note='Candidate listed by the brief; exact dated entity/role evidence incomplete. No active actor entry; ambiguous abbreviations excluded. Generic church-role vocabulary does not identify this named entity.'))
    DOCS['segmenter.yaml'] = dict(abbreviations='sv dr sc mr mons o don vlč preč msgr prof doc izv dipl ing mag univ prim npr tj br st čl sl itd tzv god mil mlrd tis kn str usp v gl min tel ul pok al engl njem lat tal hrv pov'.split(),
        month_genitives='siječnja veljače ožujka travnja svibnja lipnja srpnja kolovoza rujna listopada studenoga prosinca'.split())
    DOCS['rules.yaml'] = dict(status='proposed', max_tokens='80', cue_distance='5', text_cap='32000', min_body_chars='200',
        identity_choice='family_life_one_family', route_d='diagnostic_only',
        christian_social_label='facet_only_not_A', rescue_life='excluded',
        direct_precedence=['A1', 'A2_if_all_mentions_party', 'A?'],
        development_fraction='0.30', evaluation_fraction='0.70', seed='20260918')
    DOCS['rules.yaml']['near_miss_frame'] = 'one_missing_lexical_condition_in_complete_same_sentence_clause_within_80_tokens_no_suffix_slicing'
    OUT.mkdir(parents=True, exist_ok=True)
    for name, doc in DOCS.items():
        (OUT / name).write_text(yaml(doc) + '\n', encoding='utf-8', newline='\n')
    (OUT/'README.md').write_text('''# Definicija barometra v1

Status zamrzavanja i točan sažetak definicije vodi config/gates.json u studiji barometra.
Rječnik sam po sebi ne dokazuje ljudsku validaciju niti predstavlja objavljene rezultate.
Barometar obuhvaća imenovanu demokršćansku tradiciju (A1) te socijalni nauk i kršćanski
utemeljene argumente o političkim pitanjima (B i C). Stranački nazivi (A2) ne ulaze u pokazatelje.
Programski govor aktera (D) zasebna je oznaka već uključenih članaka.

Obiteljski i životni identitetski izrazi mogu dati jednu obitelj načela u C. Migracije, islam
i neprijateljske skupine to ne mogu. Sam kršćanski identitet, crkvene vijesti, pastoralni
pozivi, milosrđe, imenovanje pape i objavljivanje enciklika nisu dovoljni. Negacija i kritika
broje se jednako kao potvrdan govor. Ne zaključuje se o uvjerenju autora ili medija.

Uvjeti moraju stati u najviše 80 riječi unutar susjednih rečenica istoga polja. Naslov je
zasebno polje. Pretražuje se prvih 32.000 znakova tijela nakon uklanjanja ponovljenoga naslova.
Načela se razlikuju od šest tematskih područja. Migracije su u području rada prema
Kompendiju socijalnog nauka Crkve, odlomci 297–298. Nazivi područja prilagođene su skupine.

Oblici su neovisno razrađeni prema odobrenom projektnom briefu. Naslovi dokumenata kopirani
su iz zamrznutoga projektnog CST rječnika uz sažetak izvora u svakoj stavci. Vanjski
koautorski rad i njegovi rječnici nisu korišteni. Izvorni raspon redaka odnosi se na
specifikaciju obitelji; hrvatski oblici neovisno su razrađeni i provjereni razvojnim primjerima.
Ne pripisuje se ljudska provjera oblicima koje je pripremio Codex.

Rječnik se zamrzava tek nakon razvojne provjere segmentacije, isključenja i kandidatskog
nadskupa. Objavljivanje zatim ovisi o zasebnom ljudskom kodiranju novih članaka.

Razvojne dopune izričito ograničavaju primjenu. Novi redak sam po sebi nije granica rečenice.
Pripisivanje govornika koristi blizinu unutar klauze, do 12 tokena, uz blokadu bližim
konkurentskim govornikom; nije sintaktička analiza. Ženski i padežni oblici javnih dužnosti
koriste isti uvjet. Čitanje dokumenta ili poziv na izložbu uz sam naziv dužnosti nisu
primjena nauka na politiku. Pozivi trebaju zaseban politički predmet.

Uzorak gotovo prihvaćenih članaka ograničen je na točno jedan odsutan leksički uvjet u
cijeloj rečenici/klauzi čiji relevantni pogoci stanu u 80 tokena. Taj uvjet mora nedostajati
u cijelom polju; ne stvara se rezanjem potpunoga argumenta. Pogreške udaljenosti ili
pripisivanja nisu iscrpno obuhvaćene tim uzorkom. Odvojeni uzorak mogućih propusta vrijedi
samo za svoj okvir, a odziv za cijeli panel nije procijenjen.

Registar je namjerno ograničen na dokumentirana razdoblja. Zapisi označeni
excluded_pending_evidence nisu aktivni. Opći crkveni nazivi zaseban su rječnik uloga,
a ne dokaz vremenske valjanosti imenovane organizacije. Dijagnostika HDZ-a vrijedi samo
unutar dokumentiranog razdoblja, ne pripisuje uvjerenja pojedincima i isključuje HDZ BiH.
Oznaka hdz_only znači da je HDZ jedini prepoznati registrirani akter/uloga prema ovom
rječniku; nije potpuno prepoznavanje svih imenovanih političara. Analiza osjetljivosti
mora zadržati tu ogradu u nazivu i ne služi dokazivanju odsutnosti drugih aktera.

Ljudska evaluacija koristi jedinstvene članke, poznate vjerojatnosti uključenja i težine
za preklopljene stratume. Wilsonovi intervali s Kishovom efektivnom veličinom uzorka
aproksimacija su uz težine; moraju biti tako označeni. AI razvojne procjene nikada nisu
ljudske evaluacijske oznake.
''', encoding='utf-8', newline='\n')
    print(f'Proposed definition: {sum(len(x.get("entries", [])) for x in DOCS.values())} entries; {len(DOCS)} YAML files.')

if __name__ == '__main__':
    main()
