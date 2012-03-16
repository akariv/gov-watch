import os

from gevent import monkey; monkey.patch_all()
from gevent.pywsgi import WSGIServer
from dbserver import app

http_server = WSGIServer(('', 5555), app)
http_server.serve_forever()
