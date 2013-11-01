#!/bin/bash

WORKDIR=`dirname $0`
. $WORKDIR/common.sh
. $WORKDIR/config_common.sh

function print_usage {
	echo "Executes commands on specific instance reading some configuration values from instances configuration file (e.g. template name)"
	echo ""
	echo "Usage: `basename $0` <instance_name> <args...>"
	echo "       instance_name - the name of Tomcat instance"
	echo "       args - arguments forwarded to Tomcat catalina.sh, e.g. start, stop, ..."
}

if [ ${#@} -lt 2 ] ; then
	print_usage
	exit 1
fi

setup_env "" "$1" "${@:2}"
conf_grep_value "tmpl" "TMPL_VALUE"

$WORKDIR/tomcat.sh $TMPL_VALUE $INST_NAME $EXEC_ARGS

