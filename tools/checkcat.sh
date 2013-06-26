#!/bin/bash

# Check what Slackware packages are installed from the given category.

DISTPATH=/mnt/cdrom/slackware/
if [ "$1" != "" ]; then
	CATEGORY=$1 
else
	echo "usage: $0 {a|ap|d|e|f|k|kde|kdei|l|n|t|tcl|x|xap|y}"
	exit 1
fi

cd ${DISTPATH}${CATEGORY} || exit 1

for package in *.tgz; do
	base=$(echo $package | rev | cut -d. -f2- | rev)
	if [ -e /var/log/packages/$base ]; then
		echo $base;
	fi
done

