#!/bin/bash
#
# Graph creation test script (ArrayFort)

LANG=C;export LANG
CWD=`dirname $0`
CMDNAME=`basename $0`

export SITEHOME="$(git rev-parse --show-toplevel)"
if [ ! -f "$SITEHOME/node/ArrayFort/KB2800/wbc.json" ]; then
	echo "Graph definition file is not found. Please run the data aggregation test in the beginning."
	exit -1
fi

cacti-cli -f $SITEHOME/node/ArrayFort/KB3950
cacti-cli -f $SITEHOME/node/ArrayFort/KB2801
cacti-cli -f $SITEHOME/node/ArrayFort/KB3266
cacti-cli -f $SITEHOME/node/ArrayFort/KB2800
cacti-cli -f $SITEHOME/node/ArrayFort/KB3024
cacti-cli -f $SITEHOME/node/ArrayFort/KB2802
cacti-cli -f $SITEHOME/node/ArrayFort/KB4382

