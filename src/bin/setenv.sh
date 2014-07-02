#!/bin/bash


WORKDIR=`dirname $0`
config=/tmp/tcc_setenv_source
INST_NAME=`basename $CATALINA_BASE`

echo "inst name = $INST_NAME"
echo "catalina = $CATALINA_BASE"
python $CATALINA_BASE/../ReadInstanceSetEnv.py $CATALINA_BASE/../setenv.csv $INST_NAME > $config

if [ -f $config ]; then
	echo "Loading $config"
	content=`cat $config`
	echo "$content"
	. $config
fi


# **** SNMP export ****
if [ -n "$snmp_port" ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.snmp.port=$snmp_port -Dcom.sun.management.snmp.acl.file=$CATALINA_BASE/conf/snmp.acl -Dcom.sun.management.snmp.interface=$snmp_interface"
fi

# **** Heap setup ****
if [ -n "$java_memory" ]; then
	CATALINA_OPTS="$CATALINA_OPTS $java_memory"
fi

trust_store=$CATALINA_BASE/../trust.jceks
if [ -f $trust_store ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.trustStore=$trust_store -Djavax.net.ssl.trustStorePassword=hesielko -Djavax.net.ssl.trustStoreType=jceks"
fi

# **** Java Agents ****
# e.g. Newrelic = $CATALINA_BASE/newrelic/newrelic.jar
if [ -n "$java_agents" ]; then
	JAVA_OPTS="$JAVA_OPTS -javaagent:$java_agents -Dnewrelic.config.file=$CATALINA_BASE/newrelic/newrelic.yml"
fi

# **** Java Debugging ****
if [ -n "$java_debug_port" ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,address=$java_debug_port,suspend=$java_debug_suspend"
fi

# **** JMX Export ****
if [ -n "$jmx_port" ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=$jmx_port -Dcom.sun.management.jmxremote.password.file=$jmx_pass_file -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=$jmx_host"
fi

# **** Java Monitoring and profiling ****
CATALINA_OPTS="$CATALINA_OPTS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$CATALINA_BASE/monitor"

CATALINA_OPTS="$CATALINA_OPTS -Dfile.encoding=UTF-8 -Djava.awt.headless=true"

# **** Logging ****
CATALINA_OPTS="$CATALINA_OPTS -Dserver.log.dir=$CATALINA_BASE/logs"
if [ -n "$log4j" ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Dlog4j.configuration=$log4j"
fi
	
# **** hr jbpm process deploy
if [ -n "$jbpm_deploy" ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Dhr.jbpm.deploy=$jbpm_deploy"
fi

if [ -n "$java_home" ]; then
	JAVA_HOME=$java_home
fi

if [ -n "$env" ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Denv=$env"
fi

echo "Final CATALINA_OPTS=$CATALINA_OPTS"
