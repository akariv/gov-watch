#!/usr/bin/python
### encoding: utf-8
import urllib2
import csv
import json

TAGS_URL = "https://docs.google.com/spreadsheet/pub?key=0AurnydTPSIgUdEFTLW5yMWUxUjByempGajRCQVB0aXc&single=true&gid=0&output=csv"

if __name__=="__main__":
    data = json.load(file('data.json'))
    
    reader = csv.reader(urllib2.urlopen(TAGS_URL))
    for row in reader:
        slug=row[0]
        if slug.strip() == 'slug':
            continue
        tags=[ t.decode('utf8').strip() for t in row[2:] if t.strip() != '' ]

        found = False
        for x in data:
            if x['slug'] == slug:
                print x['base']
                x['base']['tags'] = tags
                found = True
                break
        if not found:
            print 'failed to find slug "%s"' % slug
        print slug, tags

    file('data.json','w').write(json.dumps(data,indent=2))

