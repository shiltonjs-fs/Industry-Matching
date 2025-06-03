select * from 
where 
'SIMON JR PTE. LTD.',
'ONLEWO PTE. LTD.',
'CLICK UCOHOL PTE. LTD.',
'Miredo Asia Private Limited',
'THE MARKETING LADS SG',
'THE ODDLY CREATIVES PTE. LTD.',
'LE FAIRYMEADOW',
'Orangebox Corporate Services LLP',
'Linkflow Capital Pte Ltd',
'1 UNITED SERVICES PTE. LTD.',
'1A CLEANING PTE. LTD.',
'2 TO TANGO PTE. LTD.',
'3 RESOURCES PTE. LTD.',
'3B1G CONFECTIONERY PTE. LTD.',
'8TH DIMENSION PTE. LTD.',
'18 CAPITAL AND DEVELOPMENT PTE. LTD.',
'33 DURIAN PTE. LTD.',
'44 RENT PTE. LTD.',
'88 MOBILE PTE. LTD.',
'A TAX ADVISOR PTE LTD',
'A&S MAINTENANCE SERVICE PTE. LTD.',
'A+ TRANSPORTATION LOGISTICS SERVICES PTE LTD',
'A13 PRIVATE LIMITED',
'AAMIRS MARKET 2.0 PTE. LTD.',
'ACE BUSINESS CENTRE PTE. LTD.',
'ACE INTERNATIONAL PTE. LTD.',
'ACECOM TECHNOLOGIES PTE LTD',
'ACETEK COLLEGE PTE. LTD.',
'ACKTEC TECHNOLOGIES PTE. LTD.',
'EAS MARKETING PTE. LTD.';


select * from DEV.SBOX_ADITHYA.SG_GOV_ACRA T1 join cdm.counterparty.cardup_company_t T2 on T2.CU_COMPANY_UEN=t1.uen 
where lower(entity_name) like '%simon jr%'
or lower(entity_name) like '%onlewo%'
or lower(entity_name) like '%click ucohol%'
or lower(entity_name) like '%miredo asia private limite%'
or lower(entity_name) like '%the marketing lads s%'
or lower(entity_name) like '%the oddly creatives%'
or lower(entity_name) like '%le fairymeado%'
or lower(entity_name) like '%orangebox corporate services ll%'
or lower(entity_name) like '%linkflow capital%'
or lower(entity_name) like '%1 united services%'
or lower(entity_name) like '%1a cleaning%'
or lower(entity_name) like '%2 to tango%'
or lower(entity_name) like '%3 resources%'
or lower(entity_name) like '%3b1g confectionery%'
or lower(entity_name) like '%8th dimension%'
or lower(entity_name) like '%18 capital and development%'
or lower(entity_name) like '%33 durian%'
or lower(entity_name) like '%44 rent%'
or lower(entity_name) like '%88 mobile%'
or lower(entity_name) like '%a tax advisor%'
or lower(entity_name) like '%a&s maintenance service%'
or lower(entity_name) like '%a+ transportation logistics services%'
or lower(entity_name) like '%a13 private limite%'
or lower(entity_name) like '%aamirs market 20%'
or lower(entity_name) like '%ace business centre%'
or lower(entity_name) like '%ace international%'
or lower(entity_name) like '%acecom technologies%'
or lower(entity_name) like '%acetek college%'
or lower(entity_name) like '%acktec technologies%'
or lower(entity_name) like '%eas marketing%';