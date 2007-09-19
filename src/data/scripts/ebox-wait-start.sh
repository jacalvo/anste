#!/bin/bash

# Wait a maximum of 30 seconds for apache start
for i in `seq 1 30`
do
    rm index.html
    wget http://localhost
    if [ -f index.html ]
    then
        rm index.html
        exit 0
    else
        sleep 1 
    fi
done
exit 1
