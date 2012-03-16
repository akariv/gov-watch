#!/bin/bash

cd bootstrap
make bootstrap
cd ..
lessc less/style.less > static/css/style.css
iced -I inline -c -o static/js/ *.iced

