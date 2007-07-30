#!/bin/sh

# TODO: Check arguments

MOUNT=$1 

IP='192.168.45.111'

cp bin/ansted $MOUNT/usr/local/bin/
cp bin/anste-slave $MOUNT/usr/local/bin/
mkdir -p $MOUNT/usr/local/lib/site_perl/ANSTE/Comm/
cp -r lib/ANSTE/Comm/*.pm $MOUNT/usr/local/lib/site_perl/ANSTE/Comm/
cp data/conf/ansted $MOUNT/etc/init.d/
cp data/conf/sources.list $MOUNT/etc/apt/
# TODO: Generate it dynamically with hostname variable
cp data/conf/hosts $MOUNT/etc/
echo $IP > $MOUNT/var/local/anste.master
