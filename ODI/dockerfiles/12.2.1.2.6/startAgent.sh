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
   ${DOMAIN_HOME}/bin/agentstop.sh
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

sed -i -e "s|ADMIN_PASSWORD|$ADMIN_PASSWORD|g" /u01/oracle/createOdiDomainForStandaloneAgent.py

# Create an ODI standalone agent  domain
cd /u01/app/oracle
wlst.sh createOdiDomainForStandaloneAgent.py
fi


# Start the Agent
AGENTPROC=`ps -ef | grep OracleDIAgent1 | grep -v grep | wc -l`

if [ $AGENTPROC -eq 2 ]; then
	echo "Agent is already running"
elif [ $NEWREPO -eq 1 ]; then 
	echo "New repository! Please configure agent in ODI studio ans start it manually after that."
else
	nohup ${DOMAIN_HOME}/bin/agent.sh -NAME=OracleDIAgent1 &
	tail ${DOMAIN_HOME}/system_components/ODI/OracleDIAgent1/logs/oracledi/odiagent.log
fi

childPID=$!
wait $childPID


