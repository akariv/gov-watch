import urllib, urllib2
from redis import Redis
from slugs import slugify, unslugify
import json
import time

if __name__=="__main__":
    r = Redis()
    while True:
        everything = r.get('everything')
        everything = json.loads(everything)
        everything = [ (x['base']['book'], x['slug']) for x in everything ]
        results = {}
        for book,slug in everything:
            url = "http://watch.gov.il/#!z=b:%s_s:%s" % (slugify(book),slug)
            query = urllib.urlencode([("query","SELECT url,commentsbox_count FROM link_stat WHERE url='%s'" % url),
                                      ('format','json')])
            response = urllib2.urlopen('https://api.facebook.com/method/fql.query?%s' % query).read()
            print response
            try:
                response = json.loads(response)
            except:
                break
            commentsbox_count = response[0]['commentsbox_count']
            results[slug] = commentsbox_count
            print slug,commentsbox_count
        r.set('fbcomments',json.dumps(results,indent=0))
        time.sleep(600)
