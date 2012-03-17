#!/bin/bash

cd bootstrap
make bootstrap
cd ..
iced -I inline -c -o static/js/ .

