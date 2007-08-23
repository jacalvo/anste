#!/bin/bash

# Wait a maximum of 20 seconds for apache start
for i in `seq 1 20`
do
    # TODO: Do this with wget, with time options so we
    # don't need a loop
    netstat -a | grep www | grep LISTEN
    if [ $? ]
    then
        exit 0
    else
        sleep 1 
    fi
done
exit 1
