#!/bin/sh

SOURCES="/etc/apt/sources.list"

if ! grep -q juruen $SOURCES
then
    echo "deb http://ppa.launchpad.net/juruen/ubuntu hardy main" >> $SOURCES
fi    
