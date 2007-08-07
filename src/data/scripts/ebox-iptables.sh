#!/bin/sh

for i in INPUT OUTPUT FORWARD
do
    iptables -P $i ACCEPT
done
