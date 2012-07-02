Gov-Watch
=========
A project that helps us track our government.

Usage
-----
Currently working with the tracthenberg committee report, the code includes most of what you need to get going. We do assume you have node.js installed. Just::
   
    # Installations

    $ npm install -g iced-coffee-script

    $ npm install -g less
    
    $ npm install -g uglify-js

    ### Linux
    $ sudo apt-get install redis-server libevent-dev
    
    ### Mac
    $ brew install redis

    $ easy_install redis flask gevent

    $ cd gov-watch # root folder of project

    $ git submodule init

    $ git submodule update

    $ ./get_latest.sh
 
    # Build 
    
    $ cd src/

    $ ./build.sh

Then, at will, just run::
    
    # Run server
    
    $ cd gov-watch/server/

    $ python dbserver.py

And then point your browser to http://127.0.0.1:5000

