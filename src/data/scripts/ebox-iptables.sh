#!/bin/sh

# FIXME: Change this to only add rules that enable anste communication
for i in INPUT OUTPUT FORWARD
do
    iptables -P $i ACCEPT
done
