#!/bin/bash
#
# Data aggrigation test script (ArrayFort)

LANG=C;export LANG
CWD=`dirname $0`
CMDNAME=`basename $0`

export SITEHOME="$(git rev-parse --show-toplevel)"

if [ ! -d "$SITEHOME/lib/Getperf/Command/Site" ]; then
	echo "Invalid site home directory '$SITEHOME'"
	exit -1
fi

sumup -t $SITEHOME/t/test_a1/TTSP/afacs.txt
