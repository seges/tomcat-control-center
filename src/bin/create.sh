#!/bin/bash

WORKDIR=`dirname $0`
. $WORKDIR/common.sh
. $WORKDIR/config_common.sh

function print_usage {
	echo "Creates an instance from a Tomcat template"
	echo ""
        echo "Usage: `basename $0` <template_name> <instance_name> <user_name> [<tcc_group>]"
        echo "       template_name - Tomcat template name (located in templates dir)"
        echo "       instance_name - the name of Tomcat instance to be created"
	echo "       user_name     - user to be in charge of starting/stopping and managing the instance"
	echo "       tcc_group     - optional TCC group (by default tcc)"
}

# Links configuration files in instance to the template except server.xml and
# directories. In server.xml there are port numbers defined so it has to be a
# copy of the template.
function link_conf_files {
	TMPL_CONF="$TMPL_DIR/conf"
	INST_CONF="$INST_DIR/conf"
	for CONF in `ls $TMPL_CONF` ; do
		TMPL_CONF_FILE="$TMPL_CONF/$CONF";
		if [ ! -d "$TMPL_CONF_FILE" ] && [ "$CONF" != "server.xml" ] ; then
			INST_CONF_FILE="$INST_CONF/$CONF"
			ln -s "$TMPL_CONF_FILE" "$INST_CONF_FILE"
			log "instance" "Link $INST_CONF_FILE created"
		fi
	done
}

# Modifies instance's server.xml by providing parameters via console.
function edit_server_xml_params {
	TMPL_SERVER_XML="$TMPL_DIR/conf/server.xml"
	SERVER_XML="$INST_DIR/conf/server.xml"

	echo "Shutdown port [8005] : "
	read INP
	if [ "$INP" ] && [ "$INP" -ne "8005" ] ; then
		sed -e "s/Server\ port\=\"8005\"/Server\ port\=\"$INP\"/" $TMPL_SERVER_XML > $SERVER_XML.tmp
		log "instance" "Shutdown port set to $INP in $SERVER_XML"
	fi

	echo "HTTP Connector port [8080] : "
	read INP
	if [ "$INP" ] && [ "$INP" -ne "8080" ] ; then
		sed -e "s/Connector\ port=\"8080\"/Connector\ port=\"$INP\"/" $SERVER_XML.tmp > $SERVER_XML
		rm $SERVER_XML.tmp
		log "instance" "Connector port set to $INP in $SERVER_XML"
	else
		mv $SERVER_XML.tmp $SERVER_XML
	fi
}

# Writes configuration of the instance into instances properties file.
# Information about template the instance was created from is because
# some control scripts use it not to bother user to provide it.
function write_configuration {
	#KEY="$INST_NAME.tmpl"
	#if [ -f "$INSTS_CONF" ] ; then
	#	KEY_GREP=`cat $INSTS_CONF | grep $KEY`
	#fi
	key_grep "tmpl" "KEY_GREP"

	if [  "$KEY_GREP" ] ; then
		log "instance" "Configuration already present: $KEY_GREP"
	elif [ -f $INSTS_CONF ] ; then
		echo "$INST_NAME.tmpl=$TMPL_NAME" >> $INSTS_CONF
		log "instance" "Configuration written"
	else
		echo "$INST_NAME.tmpl=$TMPL_NAME" > $INSTS_CONF
		log "instance" "New configuration written"
	fi

	key_grep "user" "KEY_GREP"

	if [  "$KEY_GREP" ] ; then
		log "instance" "User already present: $KEY_GREP"
	elif [ -f $INSTS_CONF ] ; then
		echo "$INST_NAME.user=$USER" >> $INSTS_CONF
		log "instance" "User $USER written"
	else
		echo "$INST_NAME.user=$USER" > $INSTS_CONF
		log "instance" "New user $USER written"
	fi
}

if [ ${#@} -lt 3 ] ; then
        print_usage
        exit 1
fi

USER=$3

if [ "$4" == "" ] ; then
	TCC_GROUP="tcc"
else
	TCC_GROUP="$4"
fi

setup_env "$1" "$2"
print_info

TCC_TMPL="$TMPLS_DIR/tcc_template/*"

if [ ! -d "$INST_DIR" ] ; then
	mkdir $INST_DIR
	log "instance" "Created directory $INST_DIR"
fi
# create required structure
cp -R $TCC_TMPL $INST_DIR
chown -R $USER:$TCC_GROUP $INST_DIR
log "instance" "Created structure based on TCC template in $TCC_TMPL"

link_conf_files
edit_server_xml_params 
write_configuration 
