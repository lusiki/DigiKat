"""Keep documentary profile proposals separate from the unverified base register."""
from urllib.parse import urlsplit
from common import PRIVATE, TABLES, read_csv, write_csv, dump_json

def main():
    register=read_csv(PRIVATE/'register.csv'); by_id={r['association_id']:r for r in register}
    proposals=[
      ('8013','breza','not_documented','social_support;children_youth;education;culture;volunteering','legal_entity','name_city_address','not_yet_verified',''),
      ('4553','skac_palma','Christian_Catholic','religious_formation;education;volunteering;youth','legal_entity','name_city_address','founded_2001_self_report','2001'),
      ('58492','skac_split_attempt','Christian_Catholic','religious_formation;education;volunteering;youth','legal_entity','name_city_address_differs','founded_2010_self_report','2010'),
      ('42673','korablja','God_centred_no_denomination_assigned','disability_support;community;inclusion','legal_entity_in_international_network','pdf_domain_and_address','not_yet_verified',''),
      ('14821','padmasana','Buddhist','meditation;study;retreats;culture','legal_entity','pdf_domain_and_name_activity_location_differs','not_yet_verified',''),
      ('233887','zdenac','Christian_network_description','humanitarian;volunteering;religious_formation','network_entity_mapping_unresolved','shared_pdf_domain','network_founded_2003_entity_history_unresolved',''),
      ('32442','zdenac','Christian_network_description','humanitarian;volunteering;religious_formation','network_entity_mapping_unresolved','shared_pdf_domain','network_founded_2003_entity_history_unresolved',''),
      ('32947','krakr','Christian','intellectual_dialogue;publishing;social_reflection','legal_entity','name_city_address','founded_2002_self_report','2002'),
      ('14665','matica_hvar','not_documented','culture;heritage;publishing','branch','umbrella_branch_page_name_city','dated_activity_2025_06_03',''),
    ]
    for row in register:
        if 'joga u svakodnevnom zivotu' in row['name_normalized']:
            proposals.append((row['association_id'],'yoga','yoga_spiritual_tradition_network_description',
                'yoga;wellbeing;spiritual_practice','network_branch_mapping_pending','name_city_network_directory',
                'not_yet_verified',''))
    log={r['source_key']:r for r in read_csv(PRIVATE/'web_collection_log.csv')}
    profiles=[]
    for aid,key,orientation,activities,scope,identity,history,year in proposals:
        assert aid in by_id and log[key]['status']=='downloaded'
        profiles.append({'association_id':aid,'name':by_id[aid]['name'],'source_key':key,'source_url':log[key]['url'],
           'access_date':log[key]['retrieved_utc'][:10],'orientation_proposal':orientation,'activity_proposals':activities,
           'organisational_scope':scope,'identity_evidence':identity,'historical_evidence':history,'foundation_year_self_report':year,
           'coding_status':'AI_assisted_documentary_proposal_not_human_validated'})
    write_csv(PRIVATE/'profile_evidence.csv',profiles)
    domains={}
    for row in register:
        value=row['website_raw']
        if value:
            domain=(urlsplit(value if '://' in value else 'https://'+value).hostname or '').lower().removeprefix('www.')
            domains.setdefault(domain,[]).append(row['association_id'])
    write_csv(PRIVATE/'shared_register_domains.csv',[{'domain':d,'association_ids':';'.join(ids),'associations':len(ids)} for d,ids in domains.items() if len(ids)>1])
    dump_json(TABLES/'profile_audit.json',{'register_entries_with_profile_proposals':len(profiles),
      'distinct_profile_source_groups':len({r['source_key'] for r in profiles}),'populated_register_website_fields':sum(bool(r['website_raw']) for r in register),
      'distinct_parsed_register_domains':len(domains),'shared_register_domains':sum(len(v)>1 for v in domains.values()),
      'human_validated_profiles':0})
    print('Profile evidence rows',len(profiles),'source groups',len({r['source_key'] for r in profiles}))

if __name__=='__main__': main()
