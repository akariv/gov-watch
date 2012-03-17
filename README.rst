Gov-Watch
=========
A project that helps us track our government.

Usage
-----
Currently working with the tracthenberg committee report, the code includes everything you need to get going. Just:
   
    # Installations
    $ npm install -g iced-coffee-script
    $ npm install -g less
    $ npm install -g uglify-js

    $ git submodule init
    $ git submoodule update

    # Build styles
    $ cd src/bootstrap
    $ make bootstrap
    $ cd ../..

Then, at will, just run:
    
    $ cd server/
    $ python -m SimpleHTTPServer

And then pointing your browser to http://127.0.0.1:5000

