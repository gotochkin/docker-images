#!/bin/bash
# 
# Since: June, 2017
# Author: gerald.venzl@oracle.com
# Description: Setup and runs Oracle Rest Data Services.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
# 

function setupOrds() {

  # Check whether the Oracle DB password has been specified
  if [ "$ORACLE_PWD" == "" ]; then
    echo "Error: No ORACLE_PWD specified!"
    echo "Please specify Oracle DB password using the ORACLE_PWD environment variable."
    exit 1;
  fi;

  # Defaults
  ORACLE_SERVICE=${ORACLE_SERVICE:-"ORCLPDB1"}
  ORACLE_HOST=${ORACLE_HOST:-"localhost"}
  ORACLE_PORT=${ORACLE_PORT:-"1521"}
  ORDS_PWD=${ORDS_PWD:-"welcome1"}
  APEX_PWD=${APEX_PWD:-"welcome1"}
  APEXL_PWD=${APEXL_PWD:-"welcome1"}
  APEXR_PWD=${APEXR_PWD:-"welcome1"}
  APEXI=${APEXI:-"$ORDS_HOME/doc_root/i"}
  
  # Install APEX
  if [ -f $ORDS_HOME/.apex_installed ]; then 
	  echo "Apex already installed"
  else
	  $ORDS_HOME/apex_ins.sh
  fi

  # Make standalone dir
  mkdir -p $ORDS_HOME/config/ords/standalone
  
  # Copy template files
  cp $ORDS_HOME/$CONFIG_PROPS $ORDS_HOME/params/ords_params.properties
  cp $ORDS_HOME/$STANDALONE_PROPS $ORDS_HOME/config/ords/standalone/standalone.properties

  # Replace DB related variables (ords_params.properties)
  sed -i -e "s|###ORACLE_SERVICE###|$ORACLE_SERVICE|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORACLE_HOST###|$ORACLE_HOST|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORACLE_PORT###|$ORACLE_PORT|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORDS_PWD###|$ORDS_PWD|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###APEX_PWD###|$APEX_PWD|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###APEXL_PWD###|$APEXL_PWD|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###APEXR_PWD###|$APEXR_PWD|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $ORDS_HOME/params/ords_params.properties
  
  # Replace standalone runtime variables (standalone.properties)
  sed -i -e "s|###PORT###|8888|g" $ORDS_HOME/config/ords/standalone/standalone.properties
  sed -i -e "s|###DOC_ROOT###|$ORDS_HOME/doc_root|g" $ORDS_HOME/config/ords/standalone/standalone.properties
  sed -i -e "s|###APEXI###|$APEXI|g" $ORDS_HOME/config/ords/standalone/standalone.properties
   
   # Start ODRDS setup
   java -jar $ORDS_HOME/ords.war install simple
}

############# MAIN ################

# Check whether ords is already setup
if [ ! -f $ORDS_HOME/config/ords/standalone/standalone.properties ]; then
   setupOrds;
fi;

java -jar $ORDS_HOME/ords.war standalone
