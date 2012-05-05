#!/bin/bash

cd bootstrap
make bootstrap -B
cd ..
lessc less/style.less > static/css/style.css
iced -I inline -c -o static/js/ *.iced

#watchr -e "watch('less/.*\.less') { system 'make' }"
