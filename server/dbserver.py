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
from profiles import profiles
from slugs import slugify, unslugify
try:
    from gevent import Greenlet, sleep
    def _timer(t,f):
        print "Saving data"
        sleep(t)
        f()
    Timer = lambda t,f: Greenlet( _timer, t,f )
except Exception,e:
    print e,"running with native timers"
    from threading import Timer
    

app = Flask(__name__)
app.debug = True

@app.route('/')
def idx():
    orig_hashbang = request.args.get('_escaped_fragment_')

    if not orig_hashbang:
        return Response(file('static/html/index.html').read())
    else:
        if ('googlebot' not in request.user_agent.string.lower()) and ('facebook' not in request.user_agent.string.lower()):
            return redirect('/#!%s' % orig_hashbang )
        orig_hashbang = urllib.unquote(orig_hashbang)
        hashbang = orig_hashbang[2:].split('_')
        hashbang = [ x.split(':') for x in hashbang ]
        hashbang = dict(hashbang)
        slug = hashbang.get('s')
        if slug:
            data = json.loads(r.get('slug:%s' % slug))
            return render_template('single.html', item=data, hashbang=orig_hashbang)
        else:
            data = json.loads(r.get('everything'))
            return render_template('all.html', items=data, hashbang=orig_hashbang)

@app.route('/sitemap')
def sitemap():
    data = json.loads(r.get('everything'))
    return render_template('sitemap.xml',content_type="text/xml",items=data)

@app.route('/edit')
def edit():
    return Response(file('static/html/edit-issue.html').read())

@app.route('/update')
def update():
    return Response(file('static/html/update-issue.html').read())

@app.route('/list')
def list():
    return Response(file('static/html/edit-list.html').read())

@app.route('/api/fb')
def fb():
    resp = make_response(Response(response=r.get("fbcomments"), content_type="application/json"))
    resp.cache_control.no_cache = True
    return resp

@app.route('/api')
def listall():
    resp = make_response(Response(response=r.get("everything"), content_type="application/json"))
    resp.cache_control.no_cache = True
    return resp

@app.route('/profile/<slug>')
def profile_img(slug):
    return Response(response=r.get('profile:%s' % slug), content_type='image/png')

@app.route('/api/version')
def version():
    resp = make_response(Response(response=r.get("version"), content_type="application/json", ))
    resp.cache_control.no_cache = True
    return resp

@app.route('/subscribe/<slug>', methods=['POST'])
def subscribe(slug):
    email = request.form["email"]
    key = "slug:%s" % slug
    if r.exists(key):
        skey = "subscribe:%s" % key
        r.sadd(skey ,[email])
        rec = json.loads(r.get(key))
        rec["subscribers"] = r.scard(skey)
        r.set(key,json.dumps(rec,indent=0))
        update_everything(slug)
        return Response(response=str(r.scard(skey)),content_type="application/json")
    else:
        return Response(response="0",content_type="application/json")

@app.route('/unsubscribe/<slug>', methods=['POST'])
def unsubscribe():
    email = request.form["email"]
    key = "slug:%s" % slug
    if r.exists(key):
        skey = "subscribe:%s" % key
        r.srem(skey ,[email])
        rec = json.loads(r.get(key))
        rec["subscribers"] = r.scard(skey)
        r.set(key,json.dumps(rec,indent=0))
        update_everything(slug)
    return Response(response="1",content_type="application/json")

@app.route("/api/<slug>", methods=['GET'])
def getitem(slug):
    return Response(response=r.get("slug:%s" % slug), content_type="application/json")

def update_everything(slug):
    print "updating data"
    t = Timer(0.1,lambda: _update_everything(slug))
    t.start()
    print "updated everything?"
    
    
def _update_everything(slug):
    print "updating data - for real",slug
    newrec = r.get("slug:%s" % slug)
    newrec = json.loads(newrec)

    everything = r.get("everything")
    everything = json.loads(everything)

    everything = [ d if d["slug"] != slug else newrec for d in everything ]

    everything = json.dumps(everything,indent=2)
    r.set("everything",everything)

    f = file('data.json','wb')
    f.write(everything)
    f.flush()
    f.close()
    r.incr('version')

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

    currentrec = r.get("slug:%s" % slug)
    currentrec = json.loads(currentrec)
    currentrec['base'] = baseinfo
    currentrec = json.dumps(currentrec,indent=0)
    r.set("slug:%s" % slug,currentrec)

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

    currentrec = r.get("slug:%s" % slug)
    currentrec = json.loads(currentrec)
    currentrec.setdefault('updates',{}).setdefault(user,[]).insert(0,update)
    currentrec = json.dumps(currentrec,indent=0)
    r.set("slug:%s" % slug,currentrec)

    update_everything(slug)

    return redirect('/list')

if __name__=="__main__":
    r = Redis()
    everything = file('data.json').read()
    r.set('version',int(os.stat('data.json').st_mtime))
    r.set("everything",everything)
    data = json.loads(everything)
    for x in data:
        key = "slug:%s" % x["slug"]
        if r.exists(key):
            skey = "subscribe:%s" % key
            x["subscribers"] = r.scard(skey)
        else:
            x.setdefault('subscribers',0)
        r.set(key,json.dumps(x,indent=0))
    for profile_name, profile_image in profiles.iteritems():
        r.set("profile:%s" % slugify(profile_name), file('static/img/%s' % profile_image).read())

    try:
        from gevent import monkey ; monkey.patch_all()
        from gevent.wsgi import WSGIServer

        http_server = WSGIServer(('', 5000), app)
        print "note: running with greenlet"
        http_server.serve_forever()

    except:
        print "note: running without greenlet"
        app.run(host="0.0.0.0",debug=True)
