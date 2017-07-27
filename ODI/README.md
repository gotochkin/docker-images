Oracle Data Integration on Docker
=================================
These  Docker configurations have been used to create the Oracle Data Integration image. It has been created for education purposes only and not designated for any production usage. It is supposed to work with Oracle developed and designed docker images with minor modifications. The Oracle docker project can be found at https://github.com/oracle/docker-images . This ODI fork project includes the installation and the creation of a ODI repository, installation and initial configuration a Weblogic domain for a standalone ODI agent. adding and starting the ODI standalone agent in the container. The Oracle Data Integrator 12.2.1.2.6 image is based on Oracle Database 12.2.0.1 EE built on top of Oracle Linux with Oracle JDK 8 and optional supplemental packages installed.
The basic hiearachy is :
-- oracle/odi:12.2.1.2.6-standalone
	|
	oracle/database:12.2.0.1-ee
		|
		oracle/serverjre:8
			|
			oraclelinux:7-slim

## How to build and run
This project offers sample Dockerfiles for Oracle DI agent, and it provides at least one Dockerfile for the 'standalone' distribution. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.


### Building Oracle WebLogic Server Docker Install Images
**IMPORTANT:** you have to download the binary of Oracle Data Integrator  and put it in place (see `.download` files inside dockerfiles/<version>).

Before you build, choose which version and distribution you want to build an image,then download the required packages (see .download files) and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script.

        $ sh buildDockerImage.sh
       Usage: buildDockerImage.sh -v [version] [-t ] [-s] [-c]
       Builds a Docker Image for Oracle ODI.
  
       Parameters:
          -v: version to build. Required.
             Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
          -t: creates image based on standalone agent  distribution
          -c: enables Docker image layer cache during build
          -s: skips the MD5 check of packages 

       * select one distribution only: -t or -e
        
        LICENSE CDDL 1.0 + GPL 2.0
        
        Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** the resulting images will have a configured agent with default name OracleDIAgent1. 

### Sample Installation and Base Domain for Oracle WebLogic Server 12.2.1.2
The image **oracle/weblogic:12.2.1.2-developer** will configure a **base_domain** with the following settings:

 * Admin Username: `weblogic`
 * Admin Password: `Auto generated` 
 * Oracle Linux Username: `oracle`
 * Oracle Linux Password: `welcome1`
 * WebLogic Server Domain Name: `base_domain`
 * Admin Server on port: `7001`
 * Production Mode: `developer`
  
**IMPORTANT:** If you intend to run these images in production you must change the Production Mode to production. Recommended to change all passwords after installation.
 

###Admin Password

On the first startup of the container a random password will be generated for the Administration of the domain. You can find this password in the output line:

`Oracle WebLogic Server auto generated Admin password:`

If you need to find the password at a later time, grep for "password" in the Docker logs generated during the startup of the container.  To look at the Docker Container logs run:

        $ docker logs --details <Container-id>


## Building the Oracle Data Integrator  Image
To build a sample ODI standalone agent image please execute the steps below:

  1. Build the image oracle/serverjre:8 (Oracle Linux 7 with JRE 8 or JDK 8 )
          
        Download or clone Oracle docker project from https://github.com/oracle/docker-images.
        $ cd docker-images/OracleJava/java-8
        Download oracle JRE server-jre-8u*-linux-x64.tar.gz or JDK jdk-8u*-linux-x64.tar.gz from Oracle site
        In case of using JDK replace "ENV JAVA_PKG=server-jre-8u*-linux-x64.tar.gz" to "ENV JAVA_PKG=jdk-8u*-linux-x64.tar.gz" in the Dockerfile
        $ ./build.sh

  2. Verify you now have this image in place with

        $ docker images

  3. Build the oracle/database:12.2.0.1-ee  (Oracle Database 12.2.0.1 EE based on Linux image with JRE or JDK)

        $ cd docker-images/OracleDatabase/dockerfiles/12.2.0.1
        Download Oracle Database installation archive linuxx64_12201_database.zip from Oracle site http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
        Replace "FROM oraclelinux:7-slim" by "FROM oracle/serverjrevnc:8" in the Dockerfile.ee
        $ cd ..
        $ ./buildDockerImage.sh -v 12.2.0.1 -e

  4. Build the oracle/odi:12.2.1.2.6-standalone  (Oracle Data Integrator 12.2.1.2.6 standalone based on Oracle Database 12.2.0.1 EE image)

        $ cd docker-images/ODI/dockerfiles/12.2.1.2.6
        Download Oracle Data Integrator 12.2.1.2.6  installation archives fmw_12.2.1.2.6_odi_Disk1_1of2.zip and fmw_12.2.1.2.6_odi_Disk1_2of2.zip from Oracle site http://www.oracle.com/technetwork/middleware/data-integrator/downloads/index.html
        $ cd ..
        $ ./buildDockerImage.sh -v 12.2.1.2.6 -t

  5. Start a container from the image created in step 1: 

        $ docker run --name oditest -p 1521:1521 -p 5500:5500 -p 5901:5901 -p 5902:5902 --env ORACLE_BASE=/opt/oracle --env ORACLE_HOME=/opt/oracle/product/12.2.0.1/dbhome_1 oracle/odi:12.2.1.2.6-standalone

        or if you want to use a persistent or previously created database in a directory on an OS FS (as example /home/oracle/oradata) to reuse it later:

        $ docker run --name oditest -p 1521:1521 -p 5500:5500 -p 5901:5901 -p 5902:5902 -p 20910:20910 -v /home/oracle/oradata:/opt/oracle/oradata --env ORACLE_BASE=/opt/oracle --env ORACLE_HOME=/opt/oracle/product/12.2.0.1/dbhome_1 oracle/odi:12.2.1.2.6-standalone
        
       -p is for a port mapping , -v is for your persistent volume for database files and  -env is for environment variables used diring deployment 

  4. Run the ODI studio inside the container (requires to have an X window or a vnc server and x-terminal)

     In your xterminal run:   
     $ /u01/app/oracle/Middleware/odi/studio/odi.sh
     First time it will ask whether you want to use an Oracle wallet. If you want to use preconfigured connection then do not use wallet. The SUPERVISOR and DEV_ODI_REPO users have password "welcome1". You need to change it right after installation. The database connection string is oracle:thin:@//localhost:1521/ORCLPDB1

## License
To download and run Oracle Data Integrator 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/ODI](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Disclaimer
Created in ediucation purposes only based on Oracle docker project scripts located on https://github.com/oracle/docker-images 
