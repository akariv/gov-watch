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
    nnn = {}

    nnn['tags'] = [ t.strip() for t in sep.split(x.get('tags').decode('utf8')) if t.strip() != '' ]

    nnn['book'] = x['book'].decode('utf8').strip()
    nnn['chapter'] = x['chapter'].decode('utf8').strip()
    nnn['tags'].append(nnn['chapter'])

    nnn['subchapter'] = x['title'].decode('utf8').strip()
    if nnn['subchapter']:
       nnn['tags'].append(nnn['subchapter'])
    nnn['tags'] = set(nnn['tags'])
    nnn['tags'] = list(nnn['tags'])

    nnn['subject'] = x['subject'].decode('utf8').strip()
    nnn['recommendation'] = x['recommendation'].decode('utf8').strip()
    nnn['responsible_authority'] = x['responsible_authority'].decode('utf8').strip()
    nnn['result_metric'] = x['result_metric'].decode('utf8').strip()
    nnn['budget'] = { 'description' : x.get('budget_cost').decode('utf8').strip(),
                      'millions' : x.get('budget_cost_millions',0),
                      'year_span' : 0  }
    nnn['timeline'] = [ { 'due_date' : convert_date(x.get('schedule','').decode('utf8').strip()),
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
    if x['gov_current_status']:
        for s in x['gov_current_status'].decode('utf8').strip().split(';'):
            date = None
            links = []
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
            if date:
                nnn['timeline'].append( { 'due_date' : date, 'links' : links, 'milestone_name' : s } )
            else:
                nnn['implementation_status_text'] = s       
    nnn['implementation_status'] = {'80':'WORKAROUND','100':'FIXED' }.get(x['gov_current_status_code'],'NEW')

    out.append( {'gov' : nnn, 'slug': x['slug'] } )

print json.dumps(out,indent=4)
