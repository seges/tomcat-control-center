#!/bin/bash

WORKDIR=`dirname $0`
. $WORKDIR/common.sh
. $WORKDIR/config_common.sh

function print_usage {
	echo "Executes commands on catalina.sh located in Tomcat template using instance environment."
	echo ""
        echo "Usage: tomcat.sh <template_name> <instance_name> <args...>"
        echo "       template_name - the name of Tomcat template which will be used for command execution"
        echo "       instance_name - the name of Tomcat instance to be used for command execution"
        echo "       args - arguments forwarded to Tomcat catalina.sh, e.g. start, stop, ..."
}

if [ ${#@} -lt 3 ] ; then
        print_usage
        exit 1
fi


setup_env "$1" "$2" "${@:3}"
check_user
print_info

export CATALINA_HOME="$TMPL_DIR"
export CATALINA_BASE="$INST_DIR"
export CATALINA_PID="$INST_PID_FILE"

$TMPL_DIR/bin/catalina.sh $EXEC_ARGS
