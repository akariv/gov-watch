#!/usr/bin/python
### encoding: utf-8
import urllib2
import csv
import json
from pprint import pprint

update_url = "https://docs.google.com/spreadsheet/pub?key=0AurnydTPSIgUdHY1T3hsYUF3SXRVb3FMQmdQUk9JOWc&single=true&gid=1&output=csv"

if __name__ == "__main__":
    data = json.load(file('data.json'))
    
    reader = csv.reader(urllib2.urlopen(update_url))
    updates = list(reader)
    titles = updates.pop(0)
    updates = [ dict(zip(titles,x)) for x in updates ]
    name = "gov"
    
    for update in updates:
        slug = update['slug']
        for rec in data:
            if rec['slug'] == slug:

                link_to_report = update.get('link_to_report','http://www.hidavrut.org.il')
                if link_to_report:
                    found = False
                    max_due_date = '0'
                    for milestone in rec["base"]["timeline"]:
                        due_date = milestone.get("due_date")
                        if due_date != None:
                            due_date=due_date.strip()
                        if due_date > max_due_date:
                            max_due_date = due_date
                    for milestone in rec["base"]["timeline"]:
                        due_date = milestone.get("due_date")
                        if due_date != None:
                            due_date=due_date.strip()
                        if due_date == u"2011/09/26":
                            found = True
                            milestone["completion"]=False
                            milestone["start"]=True
                            milestone["links"]=[ {'url':link_to_report.strip(), 'description':u'ההמלצה בדו"ח טרכטנברג' } ]
                            milestone["milestone_name"] = u"פרסום הדו\"ח"
                        else:
                            milestone["links"]=[]
                            if due_date == max_due_date:
                                milestone["completion"]=True
                                milestone["start"]=False
                            else:
                                milestone["completion"]=False
                                milestone["start"]=False
                    if not found:
                        rec["base"]["timeline"].append( { "completion": False, 
                                                          "due_date": "2011/09/26", 
                                                          "milestone_name": u"פרסום הדו\"ח", 
                                                          "links": [ {'url':link_to_report, 'description':u'ההמלצה בדו"ח טרכטנברג' } ],
                                                          "start": True} )

                updates = []
                for i in [1,2]:
                    implementation_status = update.get('status%d' % i,'').strip()
                    implementation_status_text = update.get('status_explanation%d' % i,'').strip()
                    description = update.get('description','').strip()
                    update_time = update.get('date%d' % i,'').strip()
                    if update_time:
                        update_time = update_time.split('/')
                        update_time = "%s/%s/%s" % ( update_time[2], update_time[1], update_time[0] )
                    links = []
                    for l in [1,2]:
                        url = update.get("link%d_%d" % (i,l),'').strip()
                        ldescription = update.get("link_des%d_%d" % (i,l),'').strip()
                        if url != '':
                            links.append( {'url':url,'description':ldescription} )            
                    print slug, implementation_status, implementation_status_text, description, update_time
                    if update_time != '' and implementation_status != '':
                        u = { 'update_time' : update_time,
                              'implementation_status' : implementation_status,
                              'implementation_status_text' : implementation_status_text,
                              'description' : description,
                              'links' : links
                              }
                        updates.append(u)
                rec['updates'][name] = updates
                #pprint(("slug %s\n" % slug, updates))
                break
                            
    #print json.dumps(data,indent=0)

    file('data.json','w').write(json.dumps(data,indent=2))
