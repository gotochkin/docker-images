#!/usr/bin/python

# Copyright (c) 2011, 2014 Oracle and/or its affiliates. All rights reserved.
#Modified: by Gleb Otochkin for ODI standalone agent 12.2.1.2.6

import re, os, sys

# This script creates domain, extends domain with all ODI Standalone templates 
# and configures master repository datasource

###############################################################################
# Set approriate values for following variable as per your environment
###############################################################################

# gets hostname from the OS
host_name = os.getenv('HOSTNAME');  # get hostname from os

# Middleware Home of your environment
mw_home="/u01/app/oracle/Middleware";

# odi install location under middleware home
odi_oracle_home= mw_home + "/odi";

# WLS domain directory. Update as appropriate
wls_domain_dir=mw_home+"/user_projects/domains"; 

# Domain name for the Odi Agent
wls_domain_name="base_domain";

# Weblogic admin user name
wls_user="weblogic";

# Weblogic admin user's password
wls_pass="welcome1";

# ODI supervisor user
odi_supervisor='SUPERVISOR';

# ODI Supervisor user's password
odi_supervisor_pass='welcome1';

# ODI agent name for standalone agent. Default teample contains OracleDIAgent1
odi_instance='OracleDIAgent1'; 

# Listen Address
odi_listen_address = host_name;

# ODI Port
odi_port = "20910";

# ODI Protocol
odi_protocol = "http";

# Agent Machine Name from template
agent_machine="LocalODIMachine";

# The STB schema username created through RCU. Ends with _STB
# ODI Master and Work repository and Opss database connections are fetched from
# this schema
service_db_user="DEV_STB";

# STB users password
service_db_pass="welcome1";

# JDBC URL to the STB database
# Make sure to use the right URL format
service_db_url='jdbc:oracle:thin:@localhost:1521/orclpdb1';

# JDBC driver to be used for the STB Database connection
service_db_driver='oracle.jdbc.OracleDriver';

#Master Repository datasource name. Default is odiMasterRepository
master_db_datasource = "odiMasterRepository"; 

# master db definitions below are not needed here if they are coming from the service_db
#master_db_user='STANDALONE_ODI_REPO';
#master_db_pass="abc123";
#master_db_url='jdbc:oracle:thin:@slc01fqo:1524/orcl2.us.oracle.com';
#master_db_driver='oracle.jdbc.OracleDriver';

# Work repository name
odi_work_repository_name='WORKREP'; # normally WORKREP 

##################################################################################

#This script creates domain, extends domain with all ODI templates 
#and finally configures master and work datasources on managed server

def createDataSource(dsName, user, password, url, driver):
	print 'Setting JDBCSystemResource with name '+dsName
	cd('/');
        existing=true;
        try:
		cd('/JDBCSystemResource/'+dsName+'/JdbcResource/'+dsName)
        except :
                existing=false;
	if ( not(existing) ) :
		create(dsName,'JDBCSystemResource');
	cd('/JDBCSystemResource/'+dsName+'/JdbcResource/'+dsName)
	if ( not(existing) ) :
		create('NO_NAME_0', 'JDBCDriverParams')
	cd('JDBCDriverParams/NO_NAME_0')
	cmo.setPasswordEncrypted(password)
	cmo.setUrl(url)
	cmo.setDriverName(driver)
	if ( not(existing) ) :
		create('NO_NAME_0', 'Properties')
	cd('Properties/NO_NAME_0');
	if ( not(existing) ) :
		create('user', 'Property')
	cd('Property/user')
	cmo.setValue(user)

def createWLSUser(domain_name, user, password): 
        cd('/Security/'+domain_name); ## do not delete this line, it will fail
        #ls('/Security/'+domain_name);
        ls('/Security/'+domain_name+'/User');
        cd('/Security');
        create(user,'User');
	cd(r'/Security/'+domain_name+'/User/'+user)  # no AdminServer for unmanaged  standalone
	cmo.setPassword(password)   # no AdminServer for unmanaged  standalone
	#cd(r'/Server/AdminServer') # no AdminServer for unmanaged  standalone
	#cmo.setName('AdminServer') # no AdminServer for unmanaged  standalone
	cd(r'/SecurityConfiguration/'+domain_name+'/')
	cmo.setNodeManagerUsername(user);
	cmo.setNodeManagerPasswordEncrypted(password);

def createODIInstance(instance, machine, listen_address, port, supervisor, supervisor_pass, datasource):
	cd('/');
        existing=true;
        try:
                cd('/SystemComponent/'+instance);
        except :
                existing=false;
        if( not(existing) ) :
		create(instance,"SystemComponent");
	cd('/SystemComponent/'+instance);
	set('ComponentType','ODI');
	set('Machine',machine);
	cd('/SystemCompConfig/OdiConfig/OdiInstance/'+instance);
	set("ListenAddress",listen_address);
	cmo.setListenPort(port);
	set('SupervisorUsername', supervisor);
	set('PasswordEncrypted', supervisor_pass);
	set('PreferredDataSource', datasource);

def makeOPSSChanges(supervisor, password):
        #OPSS related changes - START
        cd(r'/Credential/TargetStore/oracle.odi.credmap/TargetKey/SUPERVISOR')
        create('c','Credential')
        cd(r'Credential')
        #this user is created in OdiTaskExecute class through ANT
        cmo.setUsername(supervisor)
        cmo.setPassword(password)
        #OPSS related changes - END

#this method updates agent instance.properties with work repository name
def updating(filename,dico):

    RE = '(('+'|'.join(dico.keys())+')\s*=)[^\r\n]*?(\r?\n|\r)'
    pat = re.compile(RE)

    def jojo(mat, dic = dico ):
        return dic[mat.group(2)].join(mat.group(1,3))

    f = open(filename,'rb')
    content = f.read()

    f = open(filename,'wb')
    f.write(pat.sub(jojo, content))
    f.close()

##################################################################################

vars = ['ODI_SECU_WORK_REP'] #comma separated tokens
new_values = [odi_work_repository_name] #comma separated values
what_to_change = dict(zip(vars, new_values))

if not os.path.isdir(mw_home):
      sys.exit("Error: fusion middleware home directory '" + mw_home + "' does not exist.")

odi_domain_dir = wls_domain_dir+"/"+wls_domain_name
odi_domain_name = wls_domain_name;
#odi_standalone_base_template_jar = "/odi/common/templates/wls/odi_cam_unmanagedbase_template_12.1.3.jar"
odi_standalone_base_template_jar = "/wlserver/common/templates/wls/base_standalone.jar"
#odi_standalone_template_jar = "/odi/common/templates/wls/odi_cam_unmanaged_template_12.1.3.jar"
odi_standalone_template_jar = "/odi/common/templates/wls/odi_cam_unmanagedbase_template.jar"

#domain_path - path built dynamically from parameters defined in setting.properties

#readTemplate(mw_home + odi_standalone_base_template_jar)
#addTemplate(mw_home + odi_standalone_template_jar)
selectTemplate('Basic Standalone System Component Domain')
selectTemplate('Oracle Data Integrator - Standalone Agent')
loadTemplates()

#ls('/SecurityConfiguration');
cd('/SecurityConfiguration/'+'base_domain'); # domain is odi_standalone_domain until saved as otherwise
cmo.setUseKSSForDemo(false);

#create(agent_machine, 'Machine'); # exists in the template
cd('/Machine/' + agent_machine);
create(agent_machine, 'NodeManager');
cd('NodeManager/' + agent_machine);
set('ListenAddress', host_name);

# domain creation will fail if there is no user in the Admin group.

createWLSUser('base_domain', wls_user, wls_pass); # domain is odi_standalone_domain until saved as otherwise

createDataSource('LocalSvcTblDataSource', service_db_user, service_db_pass, service_db_url, service_db_driver);

#createDataSource(master_db_datasource, master_db_user, master_db_pass, master_db_url, master_db_driver);

createODIInstance(odi_instance, agent_machine, odi_listen_address, odi_port, odi_supervisor, odi_supervisor_pass, master_db_datasource)

getDatabaseDefaults(); # service_db, master_db, (and opss) definitions from service_db

writeDomain(odi_domain_dir)
closeTemplate()


# there is no API to update the Work Repository name in <domain>/config/fmwconfig/components/ODI/<instance>/instance.properties

print 'Configuring instance.properties'

updating(odi_domain_dir + '/config/fmwconfig/components/ODI/' + odi_instance + '/instance.properties', what_to_change)

print '************************************************************************************'
print 'Done creating Standalone domain, Master repository, Supervisor user and Nodemanager'
print '************************************************************************************'

exit()
