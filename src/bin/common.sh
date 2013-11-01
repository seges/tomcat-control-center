#!/bin/bash

os=`uname`
if [ $os == "Linux" ] ; then
	id_cmd="id"
elif [ $os == "SunOS" ] ; then
	id_cmd="/usr/xpg4/bin/id"
fi

# Sets up necessary variables from command line arguments.
function setup_env {
	TMPL_NAME="$1"
	INST_NAME="$2"
	EXEC_ARGS=${@:3}

	workdir=`dirname $0`
        if [ ${workdir:0:1} == "/" ] ; then
		TCC_DIR="$workdir/.."
	else
		TCC_DIR=`pwd`"/$workdir/.."
	fi
	TCC_DIR=`echo $TCC_DIR | sed "s/\(.*\)\/bin\/\.$/\1/"`
	TMPLS_DIR="$TCC_DIR/templates"
	INSTS_DIR="$TCC_DIR/instances"
	LOGS_DIR="$TCC_DIR/logs"
	VAR_DIR="$TCC_DIR/var"

	INSTS_CONF="$INSTS_DIR/config.properties"

	TMPL_DIR="$TMPLS_DIR/$TMPL_NAME"
	INST_DIR="$INSTS_DIR/$INST_NAME"
	INST_PID_FILE="$VAR_DIR/$INST_NAME.pid"
}

function print_info {
	echo "Tomcat Control Center (TCC)"
	echo ""
	echo "Tomcat template = $TMPL_NAME"
	echo "Tomcat instance = $INST_NAME"
	echo "Exec args       = >$EXEC_ARGS<"
	echo ""
	echo "TCC dir       = $TCC_DIR"
	echo "Template dir  = $TMPL_DIR"
	echo "Instance dir  = $INST_DIR"
	echo "Logs dir      = $LOGS_DIR"
	echo ""
}

# Logging facility
function log {
	echo "[$1] $2"

	LOG="$LOGS_DIR/tcc.log"
	if [ -f $LOG ] ; then
		echo "[$1] $2" >> $LOG
	else
		echo "[$1] $2" > $LOG
	fi
}

function check_user
{
	conf_grep_value "user" "USER_GREP"

	curuser=`$id_cmd -u -n`

	if [  "$USER_GREP" ] ; then
		log "check" "User configuration required user: $USER_GREP, current user = $curuser"
		if [ "$USER_GREP" != $curuser ] ; then
			echo "Please execute this script with correct user."
			exit 42
		fi
	else
		echo "No user assigned, current user = $curuser"
		exit 42
	fi

}

