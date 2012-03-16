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
    return Response(response=r.get("jsondata"), content_type="application/json")

@app.route("/api/<slug>", methods=['GET'])
def getitem(slug):
    return Response(response=r.get(slug), content_type="application/json")

@app.route("/api/<slug>", methods=['POST'])
def setitem(slug):
    newitem = request.form["data"]
    r.set(slug,newitem)
    newitem = json.loads(newitem)
    jsondata = r.get("jsondata")
    data = json.loads(jsondata)
    data = [ d for d in data if d["slug"] != slug ]
    data.append(newitem)
    jsondata = json.dumps(data,indent=0)
    r.set("jsondata",jsondata)
    file('data.json','wb').write(jsondata)
    return redirect('/list')

if __name__=="__main__":
    r = Redis()
    jsondata = file('data.json').read()
    r.set("jsondata",jsondata)
    data = json.loads(jsondata)
    for x in data:
        r.set(x["slug"],json.dumps(x))
    app.run()
