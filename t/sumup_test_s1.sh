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

sumup -t $SITEHOME/t/test_s1/TTSP/sc01/tsuacs.txt
sumup -t $SITEHOME/t/test_s1/TTSP/sc02/tsuacs.txt
sumup -t $SITEHOME/t/test_s1/TTSP/sc03/tsuacs__INSCDB1.txt
sumup -t $SITEHOME/t/test_s1/TTSP/sc03/tsuacs__INSCDB2.txt
