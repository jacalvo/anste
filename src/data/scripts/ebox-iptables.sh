#!/bin/sh

# Wait for ebox start
sleep 10

# FIXME: Change this to only add rules that enable anste communication
for i in INPUT OUTPUT FORWARD
do
    iptables -P $i ACCEPT
done

iptables -I INPUT -j ACCEPT
