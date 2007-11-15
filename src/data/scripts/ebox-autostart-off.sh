#!/bin/sh

# Delete the ebox start line
sed -i 's/^EB:.*$//' /etc/inittab
