#!/bin/bash
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# If AdminServer.log does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer
# Otherwise, only start NM (container restarted)
########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down the agent!"
   ${DOMAIN_HOME}/bin/agentstop.sh -NAME=OracleDIAgent1
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the agent!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

#Check and start Oracle database 
if [ -f /u01/app/oracle/runOracle.sh ]; then
    sed -i -e "s|tail\ -f\ \$ORACLE_BASE|tail\ \$ORACLE_BASE|g" /u01/app/oracle/runOracle.sh
    /u01/app/oracle/runOracle.sh
fi

#Check if a repository already exists in Oracle database
export ORACLE_SID=ORCLCDB
export ORAENV_ASK=NO
source oraenv
#Set sys password
~/setPassword.sh welcome1
ODIREPOCNT=`$ORACLE_HOME/bin/sqlplus -S "sys/welcome1@localhost:1521/ORCLPDB1 as sysdba" <<EOF
set timing off heading off feedback off pages 0 serverout on feed off
select count(*) from schema_version_registry where comp_id='ODI';
EOF`

#Create an ODI repository if it doesn't exists in the database.
if [ $ODIREPOCNT -gt  0 ]; then
	/bin/echo "The ODI repo exists"
	NEWREPO=0
else
	cd /u01/app/oracle/Middleware/oracle_common/bin
	./rcu -silent -responseFile  /u01/app/oracle/rcuResponseFile.properties  -f </u01/app/oracle/passwords.txt
	NEWREPO=1
fi

#Add a parameter to sqlnet.ora file for inbound connection timeout

OLDIBPAR1=`grep -i INBOUND_CONNECT_TIMEOUT $ORACLE_HOME/network/admin/sqlnet.ora`
if [ "$OLDIBPAR1" == "" ]; then 
	echo "SQLNET.INBOUND_CONNECT_TIMEOUT=0" >>$ORACLE_HOME/network/admin/sqlnet.ora
else 
	cp $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora.orig
	sed -i "/$OLDIBPAR1/d" $ORACLE_HOME/network/admin/sqlnet.ora
        echo "SQLNET.INBOUND_CONNECT_TIMEOUT=0" >>$ORACLE_HOME/network/admin/sqlnet.ora
fi

#Configure standard standalone physical ODI agent in the repository
MIDDLEWARE_HOME=/u01/app/oracle/Middleware
CLPATH=$MIDDLEWARE_HOME/oracle_common/modules/oracle.jdbc/ojdbc7.jar:$MIDDLEWARE_HOME/odi/common/fmwprov/odi_config.jar
AGENTNAME="OracleDIAgent1"
APPCONT="oraclediagent"
AGENTPROTOCOL="http"
AGENTPORT=20910
JDBCURL="jdbc:oracle:thin:@"$HOSTNAME":1521/orclpdb1"
ODIREPOOWNER="DEV_ODI_REPO"
ODIREPOPWD="welcome1" 

ODIAGENTHOST=`$ORACLE_HOME/bin/sqlplus -S "sys/welcome1@localhost:1521/ORCLPDB1 as sysdba" <<EOF
set timing off heading off feedback off pages 0 serverout on feed off
select HOST_NAME from DEV_ODI_REPO.SNP_AGENT where AGENT_NAME='OracleDIAgent1';
EOF`

if [ "$ODIAGENTHOST" == "$HOSTNAME" ]; then
	echo "ODI Agent "$ODIAGENT" has been already configured"
else
	java -cp $CLPATH oracle.odi.util.odiConfigAgent $ODIREPOOWNER $ODIREPOPWD $JDBCURL $AGENTNAME $HOSTNAME $AGENTPORT $APPCONT $AGENTPROTOCOL $AGENTNAME
fi

ADD_DOMAIN=1
if [ ! -f ${DOMAIN_HOME}/bin/agent.sh ]; then
    ADD_DOMAIN=0
fi

# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ]; then
# Auto generate Oracle WebLogic Server admin password
ADMIN_PASSWORD=$(date| md5sum | fold -w 8 | head -n 1)

echo ""
echo "    Oracle WebLogic Standalone ODI agent Domain:"
echo ""
echo "      ----> 'weblogic' admin password: $ADMIN_PASSWORD"
echo ""

sed -i -e "s|ADMIN_PASSWORD|$ADMIN_PASSWORD|g" /u01/app/oracle/createOdiDomainForStandaloneAgent.py

# Create an ODI standalone agent  domain
cd /u01/app/oracle
wlst.sh createOdiDomainForStandaloneAgent.py
fi


# Start the Agent
AGENTPROC=`ps -ef | grep OracleDIAgent1 | grep -v grep | wc -l`

if [ $AGENTPROC -eq 2 ]; then
	echo "Agent is already running"
	tail -f ${DOMAIN_HOME}/system_components/ODI/OracleDIAgent1/logs/oracledi/odiagent.log
elif [ $NEWREPO -eq 1 ]; then 
	echo "New repository! Please verify the physical agent in ODI studio and try to restart the container if has not be created"
	nohup ${DOMAIN_HOME}/bin/agent.sh -NAME=OracleDIAgent1 &
	tail -f ${DOMAIN_HOME}/system_components/ODI/OracleDIAgent1/logs/oracledi/odiagent.log
else
	nohup ${DOMAIN_HOME}/bin/agent.sh -NAME=OracleDIAgent1 &
	tail -f ${DOMAIN_HOME}/system_components/ODI/OracleDIAgent1/logs/oracledi/odiagent.log
fi

childPID=$!
wait $childPID


