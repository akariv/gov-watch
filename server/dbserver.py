#!/usr/bin/env python
# encoding: utf8

from flask import Flask, g, request, Response, redirect, render_template, session, make_response
from flask.helpers import url_for
import urllib
import json
import os
import datetime
from redis import Redis
from secret import calc_secret

app = Flask(__name__)
app.debug = True

@app.route('/')
def idx():
    return Response(file('static/html/index.html').read())

@app.route('/edit')
def edit():
    return Response(file('static/html/edit-issue.html').read())

@app.route('/update')
def update():
    return Response(file('static/html/update-issue.html').read())

@app.route('/list')
def list():
    return Response(file('static/html/edit-list.html').read())

@app.route('/api')
def listall():
    return Response(response=r.get("everything"), content_type="application/json")

@app.route('/api/version')
def version():
    resp = make_response(Response(response=r.get("version"), content_type="application/json", ))
    resp.cache_control.no_cache = True
    return resp

@app.route("/api/<slug>", methods=['GET'])
def getitem(slug):
    return Response(response=r.get(slug), content_type="application/json")

def update_everything(slug):
    newrec = r.get(slug)
    newrec = json.loads(newrec)

    everything = r.get("everything")
    everything = json.loads(everything)

    everything = [ d if d["slug"] != slug else newrec for d in everything ]

    everything = json.dumps(everything,indent=0)
    r.set("everything",everything)

    f = file('data.json','wb')
    f.write(everything)
    f.flush()
    f.close()
    r.set('version',int(os.stat('data.json').st_mtime))

    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    f = file('data.%s.json' % timestamp,'wb')
    f.write(everything)
    f.flush()
    f.close()

@app.route("/base/<slug>", methods=['POST'])
def setbaseinfo(slug):
    user = request.form["user"]
    auth = request.form["auth"]
    assert( auth == calc_secret(user) )
    assert( user == 'gov' )

    baseinfo = request.form["data"]
    baseinfo = json.loads(baseinfo) 

    currentrec = r.get(slug)
    currentrec = json.loads(currentrec)
    currentrec['base'] = baseinfo
    currentrec = json.dumps(currentrec,indent=0)
    r.set(slug,currentrec)

    update_everything(slug)

    return redirect('/list')

@app.route("/update/<slug>", methods=['POST'])
def doupdate(slug):
    user = request.form["user"]
    auth = request.form["auth"]
    if ( auth != calc_secret(user) ):
        print "Expected %s for user %s" % calc_secret(user),user

    update = request.form["data"]
    update = json.loads(update)
    update['update_time'] = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S")

    currentrec = r.get(slug)
    currentrec = json.loads(currentrec)
    currentrec.setdefault('updates',{}).setdefault(user,[]).insert(0,update)
    currentrec = json.dumps(currentrec,indent=0)
    r.set(slug,currentrec)

    update_everything(slug)

    return redirect('/list')

if __name__=="__main__":
    r = Redis()
    everything = file('data.json').read()
    r.set('version',int(os.stat('data.json').st_mtime))
    r.set("everything",everything)
    data = json.loads(everything)
    for x in data:
        r.set(x["slug"],json.dumps(x,indent=0))
    app.run()
