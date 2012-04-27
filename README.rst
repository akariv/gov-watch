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

    ### Linux:
    $ sudo apt-get install redis-server
    
    ### Mac:
    $ brew install redis

    $ easy_install redis    

    $ git submodule init

    $ git submodule update

    # Build 
    $ cd ~/gov-watch/src/

    $ ./build.sh

Then, at will, just run:
    
    # Run server
    $ cd ~/gov-watch/server/

    $ python dbserver.py

And then pointing your browser to http://127.0.0.1:5000

