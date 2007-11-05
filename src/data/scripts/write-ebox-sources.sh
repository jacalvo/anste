#!/bin/sh

SOURCES="/etc/apt/sources.list"

echo "deb http://ebox-platform.com/debian/nightly-builds ./" >> $SOURCES
echo "deb http://ebox-platform.com/debian/stable/ ebox/" >> $SOURCES 
echo "deb http://ebox-platform.com/debian/stable/ extra/" >> $SOURCES
echo "deb http://ebox-platform.com/debian/sarge/stable/ security/" >> $SOURCES
