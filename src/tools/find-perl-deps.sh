#!/bin/sh

find . -name '*' -exec grep -H ^use {} \; | 
grep -v ".svn" |
grep -v "use ANSTE" | 
grep -v "use strict" | 
grep -v "use warnings" | 
grep -v "use base" |
grep -v "use constant"|
grep -v "use lib" |
grep -v "use threads" |
grep -v "FindBin" | 
cut -d: -f2- |
cut -d' ' -f2- |
cut -d';' -f1 |
cut -d' ' -f1 |
sort |
uniq
