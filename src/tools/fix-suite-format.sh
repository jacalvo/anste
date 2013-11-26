#!/bin/bash

DIR=$1

if [ -z "$DIR" ]
then
    echo "Usage: $0 <suite>"
    exit 1
fi

pushd $DIR

LINKS=$(ls -l|cut -d' ' -f11-13 |grep ".."|sed 's/\.\.//g'|sed 's/ \/\// /g'|sed 's/ -> \//:/g')

for i in $LINKS
do
    SRC=$(echo $i | cut -d':' -f1)
    DST=$(echo $i | cut -d':' -f2 | sed 's/\//\\\//g')
    sed -i "s/dir: $SRC/script: $DST/g" suite.yaml
    git rm $SRC
done

sed -i 's/dir: /script: /g' suite.yaml
git add suite.yaml

for i in `ls|grep -v suite.yaml`; do git mv $i/test tmp; rmdir $i; git mv tmp $i; chmod +x $i; git add $i; done

popd
