#!/bin/bash
# 
# Since: October, 2018
# Author: gleb.otochkin@gmail.com
# Description: Install and configure Apex in the database.
#
# The script configures the Apex in a dataabse if environment variable APEX_RESET = yes (any case allowed)
# Existing Apex installation will be removed and Apex will be installed to the "APEX" tablespace.
#
export LD_LIBRARY_PATH=/usr/lib/oracle/18.3/client64/lib
APEX_STATUS=`/usr/lib/oracle/18.3/client64/bin/sqlplus -S sys/$ORACLE_PWD@$ORACLE_HOST:1521/$ORACLE_SERVICE as sysdba <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select count(*) from dba_objects where object_name='APEX_RELEASE'; 
exit
EOF`

DB_CREATE_FILE_DEST=`/usr/lib/oracle/18.3/client64/bin/sqlplus -S sys/$ORACLE_PWD@$ORACLE_HOST:1521/$ORACLE_SERVICE as sysdba <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select distinct case when nvl(p.value,'') != '' then p.value else substr(f.file_name,1,instr (f.file_name,'/',-1,1)) end from v\\$system_parameter p, dba_data_files f where p.name='db_create_file_dest';
exit
EOF`

if [[ $APEX_RESET = [Yy][Ee][Ss] ]]; then 
    echo "Apex installation in database is going to be recreated ..."
    cd $ORDS_HOME/apex
    /usr/lib/oracle/18.3/client64/bin/sqlplus sys/$ORACLE_PWD@$ORACLE_HOST:1521/$ORACLE_SERVICE as sysdba <<EOF
    @apxremov.sql
    exit
EOF

    /usr/lib/oracle/18.3/client64/bin/sqlplus sys/$ORACLE_PWD@$ORACLE_HOST:1521/$ORACLE_SERVICE as sysdba <<EOF
    alter session set db_create_file_dest='$DB_CREATE_FILE_DEST';
    create tablespace apex datafile '$DB_CREATE_FILE_DEST/apex01.dbf' size 50m autoextend on;
    @apexins.sql apex apex temp /i/
    @apex_rest_config.sql $APEXL_PWD $APEXR_PWD
    alter user APEX_PUBLIC_USER account unlock;
    alter user APEX_PUBLIC_USER identified by $APEX_PWD;
    exit;
EOF
    echo "Apex has been reset/installed at "`date +%F-%T` > $ORDS_HOME/.apex_installed
elif (( $APEX_STATUS < 1 )); then 
   echo "Apex installation is not found. Apex is going to be installed using an "APEX" tablespace."
    cd $ORDS_HOME/apex
    /usr/lib/oracle/18.3/client64/bin/sqlplus sys/$ORACLE_PWD@$ORACLE_HOST:1521/$ORACLE_SERVICE as sysdba <<EOF
    alter session set db_create_file_dest='$DB_CREATE_FILE_DEST';
    create tablespace apex datafile '$DB_CREATE_FILE_DEST/apex01.dbf' size 50m autoextend on;
    @apexins.sql apex apex temp /i/
    @apex_rest_config.sql $APEXL_PWD $APEXR_PWD
    alter user APEX_PUBLIC_USER account unlock;
    alter user APEX_PUBLIC_USER identified by $APEX_PWD;
    exit;
EOF
    echo "Apex has been reset/installed at "`date +%F-%T` > $ORDS_HOME/.apex_installed
    echo "Run $ORDS_HOME/APEX/apxchpwd.sql to reset password for the Apex ADMIN user"
else
    echo "No Apex re-installation requested."
fi
