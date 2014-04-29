#!/bin/bash

DIR=$1

if [ -z "$DIR" ]
then
    echo "Usage: $0 <anste_dir>"
    exit 1
fi

SRC_BIN_DIR=$DIR/data/deploy/bin/
SRC_SRC_DIR=$DIR/src/

TMP_DIR=`mktemp -d`
DST_BIN_DIR=$TMP_DIR/anste/bin
DST_SRC_DIR=$TMP_DIR/anste/src

mkdir -p $TMP_DIR/anste/anste-bin
mkdir -p $TMP_DIR/anste/anste-log
mkdir -p $DST_BIN_DIR

cp $SRC_BIN_DIR/anste-slave $DST_BIN_DIR
cp $SRC_BIN_DIR/ansted $DST_BIN_DIR

mkdir -p $DST_SRC_DIR/ANSTE/Comm

cp $SRC_SRC_DIR/ANSTE/Comm/SlaveServer.pm $DST_SRC_DIR/ANSTE/Comm
cp $SRC_SRC_DIR/ANSTE/Comm/SlaveClient.pm $DST_SRC_DIR/ANSTE/Comm

mkdir -p $DST_SRC_DIR/ANSTE/Exceptions

cp $SRC_SRC_DIR/ANSTE/Exceptions/Base.pm $DST_SRC_DIR/ANSTE/Exceptions
cp $SRC_SRC_DIR/ANSTE/Exceptions/MissingArgument.pm $DST_SRC_DIR/ANSTE/Exceptions

# Default anste.master
echo "10.6.7.1:8001" > $TMP_DIR/anste/bin/anste.master

echo "c: & cd C:\anste\bin" > $TMP_DIR/anste.bat
echo "perl anste-slave ready" >> $TMP_DIR/anste.bat
echo "perl ansted" >> $TMP_DIR/anste.bat

pwd=$PWD
cd $TMP_DIR
zip -qr anste.zip anste anste.bat
cp anste.zip $pwd
rm -rf $TMP_DIR

echo "Bundle available in 'anste.zip'"