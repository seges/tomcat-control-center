#!/bin/bash

# Greps whole line containing a key in the instances configuration.
#
# Arguments:
#	1st - key to search for
#	2nd - variable the result has to be put into
function key_grep {
	KEY="$INST_NAME.$1"
	if [ -f "$INSTS_CONF" ] ; then
		KEY_GREP=`cat $INSTS_CONF | grep $KEY`
	fi
	eval "$2=\$KEY_GREP"
}

# Greps a value for the key from instances configuration file.
#
# Arguments:
#	1st - key to search for
#	2nd - variable the value has to be put into
function conf_grep_value {
	key_grep "$1" "KEY_GREP"
	KEY_VALUE=`echo $KEY_GREP | sed "s/[^=]*=\(.*\)/\1/"`
	eval "$2=\$KEY_VALUE"
}
