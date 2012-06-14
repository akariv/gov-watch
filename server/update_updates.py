#!/usr/bin/python
### encoding: utf-8
import urllib2
import csv
import json

update_urls = [ 
    {
        'url': 'https://docs.google.com/spreadsheet/pub?key=0AurnydTPSIgUdGN2T2NHVTZDV1pNMmJZMnhOOGYyVmc&single=true&gid=0&output=csv',
        'name' : u'התאחדות הסטודנטים'
        }, 
    {
        'url': 'https://docs.google.com/spreadsheet/pub?key=0AurnydTPSIgUdFB3V2Z2VlRCd2RNcXVULXdZX3J4Wnc&single=true&gid=0&output=csv',
        'name' : u'צוות ספיבק/יונה (מכון ון-ליר)'
        }
    ]
                

if __name__ == "__main__":
    data = json.load(file('data.json'))
    
    for update_url in update_urls:
        reader = csv.reader(urllib2.urlopen(update_url['url']))
        updates = list(reader)
        titles = updates.pop(0)
        updates = [ dict(zip(titles,x)) for x in updates ]
        name = update_url['name']
        
        for update in updates:
            slug = update['slug']
            for rec in data:
                if rec['slug'] == slug:
                    implementation_status = update.get('implementation_status')
                    implementation_status_text = update.get('implementation_status_text')
                    description = update.get('description')
                    update_time = update.get('update_time')
                    #print implementation_status, implementation_status_text, description, update_time
                    if update_time and ( implementation_status or description ):
                        l = [ { 'update_time' : update_time,
                                'implementation_status' : implementation_status,
                                'implementation_status_text' : implementation_status_text,
                                'description' : description
                                } ]
                        rec['updates'][name] = l
                    break
     
    #print json.dumps(data,indent=0)

    file('data.json','w').write(json.dumps(data,indent=0))
