#!/bin/bash

set -x
set -e

DIR=$1

if [ -z "$DIR" ]
then
    echo "Usage: $0 <suite>"
    exit 1
fi

pushd $DIR

LINKS=$(ls -l | grep "\.\." | sed 's/.*[0-9]:[0-9][0-9] //' | sed 's/\.\.//g' | sed 's/ \/\// /g' | sed 's/ -> /:/g')

for i in $LINKS
do
    SRC=$(echo $i | cut -d':' -f1)
    DST=$(echo $i | cut -d':' -f2 | sed 's/\/$//' | sed 's/^\///')
    if ! echo "$DST" | grep -q ^common
    then
        DST="tests/$DST"
    fi
    DST=$(echo $DST | sed 's/\//\\\//g')
    sed -i "s/dir: $SRC/script: $DST/g" suite.yaml
    git rm $SRC
done

sed -i 's/dir: /script: /g' suite.yaml
git add suite.yaml

for i in `ls|grep -v suite.yaml`; do git mv $i/test tmp; rmdir $i; git mv tmp $i; chmod +x $i; git add $i; done

popd

git commit -m "adapt $DIR suite"
git show

echo "Contents of the suite:"
ls --color $DIR
