#### encoding: utf8

import csv
import json
import re

orig = list(csv.DictReader(file('input.csv')))

out = []

link = re.compile('(\[(.+des([0-9]+).htm)\])')
sep = re.compile('[;,]')
dateformat=re.compile("^[0-9/]+$")

def convert_date(date):
    if date == None: return None
    if date == '': return None
    if not dateformat.match(date): return  date
    date = date.split('/')
    date = [ int(z) for z in date ]
    date = "%04d/%02d/%02d" % (date[2],date[1],date[0])
    return date

for x in orig:
    base = {}

    base['tags'] = [ t.strip() for t in sep.split(x.get('tags').decode('utf8')) if t.strip() != '' ]

    base['book'] = x['book'].decode('utf8').strip()
    base['chapter'] = x['chapter'].decode('utf8').strip()
    base['tags'].append(base['chapter'])

    base['subchapter'] = x['title'].decode('utf8').strip()
    if base['subchapter']:
       base['tags'].append(base['subchapter'])
    base['tags'] = set(base['tags'])
    base['tags'] = list(base['tags'])

    base['subject'] = x['subject'].decode('utf8').strip()
    base['recommendation'] = x['recommendation'].decode('utf8').strip()
    base['responsible_authority'] = { 'main' : x['responsible_authority'].decode('utf8').strip(),
                                     'secondary' : '' }
    base['result_metric'] = x['result_metric'].decode('utf8').strip()
    base['budget'] = { 'description' : x.get('budget_cost').decode('utf8').strip(),
                      'millions' : int("0"+x.get('budget_cost_millions',0)),
                      'year_span' : 0  }
    base['timeline'] = [ { 'due_date' : convert_date(x.get('schedule','').decode('utf8').strip()),
                          'links' : [],
                          'milestone_name' : x.get('execution_metric').decode('utf8').strip(),
                          'completion' : True
                        },
                        { 'due_date' : '2011/09/26', 
                          'links' : [ { 'url' : 'http://hidavrut.gov.il/',
                                        'description' : u'דו"ח טרכטנברג' } ], 
                          'milestone_name': u'פרסום הדו"ח',
                          'start' : True }
                      ]
    
    updates = []
    if x['gov_current_status']:
        implementation_status = 'NEW'
        description = ''
        implementation_status_text = ''
        links = []
        for s in x['gov_current_status'].decode('utf8').strip().split(';'):
            date = None
            if '8.1.12' in s:
                date = "8/1/2012"
            if '29.1.12' in s:
                date = "29/1/2012"
            if '18.12.12' in s:
                date = '18/12/2011'
            if '18.12.11' in s:
                date = '18/12/2011'
            if '30.10.2011' in s:
                date = '30/10/2011'
            if '5.12' in s:
                date = '5/12/2011'
            if '4.12.2011' in s:
                date = '4/12/2011'
            if '29.1.2012' in s:
                date = '29/1/2012'
            if '25.12.11' in s:
                date = '25/12/2011'
            if '18.12.2011' in s:
                date = '18/12/2011'
            date=convert_date(date)
            m = link.search(s)
            if m != None:
                s=link.sub('',s)
                match, url, num = m.groups()
                links.append( { 'url' : url, 'description' : u'החלטת ממשלה מספר %s' % num} )
            if not date:
                date = '2012/01/01'
            implementation_status_text = implementation_status_text + "\n" + s
            implementation_status = 'IN_PROGRESS'
            updates.insert( 0, { 'update_date' : date, 
                                 'links' : [l for l in links], 
                                 'implementation_status' : implementation_status,
                                 'implementation_status_text' : implementation_status_text } )
    if len(updates)>0:
        updates[0]['implementation_status'] = {'80':'WORKAROUND','100':'FIXED' }.get(x['gov_current_status_code'],'IN_PROGRESS')

    out.append( { 'base' : base, 
                  'slug' : x['slug'],
                  'updates' : { 'gov' : updates
                                }
                  } )

print json.dumps(out,indent=4)
