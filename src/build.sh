#!/bin/bash

cd bootstrap
make bootstrap -B
cd ..
echo Running less
lessc less/style.less > static/css/style.css
echo Compressing less
lessc --compress less/style.less > static/css/min.css
echo Running ICED coffeescript
iced -I inline -c -o static/js/ *.iced
echo Concatenating JS files
cat static/js/jquery.min.js static/bootstrap/js/bootstrap.min.js  static/js/jquery.isotope.min.js static/js/jquery.scrollintoview.min.js static/js/jquery.tinysort.min.js  > static/js/_min.js
cat static/js/mustache.js static/js/gov-watch.js > static/js/_max.js
echo Compressing JS
cp static/js/{_,}min.js 
uglifyjs -nc static/js/_max.js >> static/js/min.js
cat static/js/{_min,_max}.js > static/js/max.js

#watchr -e "watch('less/.*\.less') { system 'make' }"
