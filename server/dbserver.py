#!/usr/bin/env python

from flask import Flask, g, request, Response, redirect, render_template, session
from flask.helpers import url_for
import urllib
import json
from redis import Redis

app = Flask(__name__)
app.debug = True

@app.route('/')
def idx():
    return Response(file('static/html/index.html').read())

@app.route('/edit')
def edit():
    return Response(file('static/html/edit-issue.html').read())

@app.route('/list')
def list():
    return Response(file('static/html/edit-list.html').read())

@app.route('/api')
def listall():
    return Response(response=r.get("all_recs"), content_type="application/json")

@app.route("/api/<slug>", methods=['GET'])
def getitem(slug):
    return Response(response=r.get(slug), content_type="application/json")

@app.route("/api/<slug>", methods=['POST'])
def setitem(slug):
    user = request.form["user"]
    auth = request.form["auth"]
    assert( user == auth )

    newitem = request.form["data"]
    newitem = json.loads(newitem) 

    currentrec = r.get(slug)
    currentrec = json.loads(currentrec)
    currentrec[user] = newitem

    currentrec = json.dumps(currentrec,indent=0)
    r.set(slug,currentrec)

    all_recs = r.get("all_recs")
    all_recs = json.loads(all_recs)
    all_recs = [ d for d in all_recs if d["slug"] != slug ]
    all_recs.append(currentrec)
    all_recs = json.dumps(data,indent=0)
    r.set("all_recs",all_recs)
    file('data.json','wb').write(all_recs)
    return redirect('/list')

if __name__=="__main__":
    r = Redis()
    all_recs = file('data.json').read()
    r.set("all_recs",all_recs)
    data = json.loads(all_recs)
    for x in data:
        r.set(x["slug"],json.dumps(x))
    app.run()
