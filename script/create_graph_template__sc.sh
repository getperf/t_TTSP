#!/bin/bash
#
# Cacti graph template creation (SC3000)

LANG=C;export LANG
CWD=`dirname $0`
CMDNAME=`basename $0`

export SITEHOME="$(git rev-parse --show-toplevel)"

if [ ! -d "$SITEHOME/lib/Getperf/Command/Site" ]; then
	echo "Invalid site home directory '$SITEHOME'"
	exit -1
fi
export GRAPH_CONFIG="$SITEHOME/lib/graph"
export COLOR_CONFIG="$GRAPH_CONFIG/color"
export GRADATION_10="--color-scheme $COLOR_CONFIG/gradation3.json --color-style gradation"
export GRADATION_16="--color-scheme $COLOR_CONFIG/gradation2.json --color-style gradation"
export GRADATION_30="--color-scheme $COLOR_CONFIG/gradation.json  --color-style gradation"

cacti-cli -f -g $GRAPH_CONFIG/SC3000/wbc.json              $GRADATION_10
cacti-cli -f -g $GRAPH_CONFIG/SC3000/summary.json
cacti-cli -f -g $GRAPH_CONFIG/SC3000/read_elapse.json      $GRADATION_30
cacti-cli -f -g $GRAPH_CONFIG/SC3000/write_elapse.json     $GRADATION_30
cacti-cli -f -g $GRAPH_CONFIG/SC3000/read_size.json        $GRADATION_16
cacti-cli -f -g $GRAPH_CONFIG/SC3000/write_size.json       $GRADATION_16

cacti-cli -f -g $GRAPH_CONFIG/SC3000/lun_summary.json
cacti-cli -f -g $GRAPH_CONFIG/SC3000/lun_read_elapse.json  $GRADATION_30
cacti-cli -f -g $GRAPH_CONFIG/SC3000/lun_write_elapse.json $GRADATION_30
cacti-cli -f -g $GRAPH_CONFIG/SC3000/lun_read_size.json    $GRADATION_16
cacti-cli -f -g $GRAPH_CONFIG/SC3000/lun_write_size.json   $GRADATION_16

cacti-cli -f -g $GRAPH_CONFIG/SC3000/raid_summary.json
cacti-cli -f -g $GRAPH_CONFIG/SC3000/raid_read_size.json   $GRADATION_16
cacti-cli -f -g $GRAPH_CONFIG/SC3000/raid_write_size.json  $GRADATION_16
