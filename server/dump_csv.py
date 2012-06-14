import csv
import json
from pprint import pprint

def flatten(x):
    if type(x)==dict:
        ret = {}
        for k,v in x.iteritems():
            fv = flatten(v)
            if type(fv)==dict:
                for k1,v1 in fv.iteritems():
                    ret[k+"."+k1]=v1
            elif fv!=None:
                ret[k]=fv
        return ret
    elif type(x)==list:
        return None
    elif type(x)==unicode:
        return x.encode('utf-8')
    else:
        return x
        

if __name__=="__main__":
    data = json.load(file("data.json"))
    data = [ flatten(x) for x in data ]
    fields = [u'slug',
              u'base.book',
              u'base.chapter',
              u'base.chapter_part',
              u'base.subchapter',
              u'base.subject'
              u'base.result_metric',
              u'base.recommendation',
              u'base.budget.description',
              u'base.budget.millions',
              u'base.budget.year_span',
              u'base.responsible_authority.main',
              u'base.responsible_authority.secondary',
              ]
    data = [ dict([(k,x.get(k,'')) for k in fields]) for x in data ]
    writer = csv.DictWriter(file('dump.csv','wb'),fields)
    data.insert(0,dict(zip(fields,fields)))
    for x in data:
        writer.writerow(x)
    
