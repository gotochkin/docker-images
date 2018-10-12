#Copyright and sources
The current Docker is prepared using Oracle sample Docker configuration from [Oracle Docker Repository] (https://github.com/oracle/docker-images/tree/master/OracleRestDataServices) and inherits Oracle Copyrights (Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.)
This Docker implementation has been created pursuing explicitely educational goals and not for production. 

# Oracle Apex configuration and REST Data Services on Docker
Sample Docker build files for setup a dev environment  with Apex and ORDS. During configuration it uses Oracle instant client.
For more information about Oracle Apex please see the [Apex Documentation] (https://docs.oracle.com/database/apex-18.2)
For more information about Oracle REST Data Services (ORDS) please see the [ORDS Documentation](http://www.oracle.com/technetwork/developer-tools/rest-data-services/documentation/index.html).
For more information about Oracle Instant Client please see [Oracle Instant Client] (https://www.oracle.com/technetwork/database/database-technologies/instant-client/overview/index.html)

## How to build and run
This project offers sample Dockerfiles for Oracle Apex and REST Data Services
 
To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle REST Data Services Install Images
**IMPORTANT:** You will have to provide Oracle instant client, Oracle Apex and the installation binaries of ORDS and put them into the `dockerfiles` folder. You only need to provide the binaries for the version you are going to install. The Apex and ORDS  binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/developer-tools).The instant client binaries rpm could be downloaded from [Oracle Instant Client Downloads] (https://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html)  Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!  

The image builds on top of the `oracle/serverjre:8` image which can be buld using [Oracle Github] (https://github.com/oracle/docker-images/tree/master/OracleJava) , see [OracleJava](../OracleJava). You will first have to build the `oracle/serverjre:8` image before you can build this image!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have done that go into the **dockerfiles** folder and run the **buildDockerImage.sh** script:

    [oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h
    
    Usage: buildDockerImage.sh [-i] [-o] [Docker build option]
    Builds a Docker Image for Oracle Rest Data Services
    
    Parameters:
       -i: ignores the MD5 checksums
       -o: passes on Docker build option
    
    LICENSE UPL 1.0
    
    Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will be an image with the ORDS binaries installed and configured for Apex. On first startup of the container ORDS will be setup, Apex will be installed if the environment APEX_RESET was passed with "Yes" .

### Running Oracle REST Data Services in a Docker container

Before you run your ORDS Docker container you will have to specify a network in wich ORDS will communicate with the database you would like it to expose via REST.
In order to do so you need to create a [user-defined network](https://docs.docker.com/engine/userguide/networking/#user-defined-networks) first.
This can be done via following command:

    docker network create <your network name> 

Once you have created the network you can double check by running:

    docker network ls

You should see your network, amongst others, in the output.

As a next step you will have to start your database container with the specified network. This can be done via the `docker run` `--network` option, for example:

    docker run --name oracledb --network=<your network name> oracle/database:18.3.0-ee

The database container will be visible within the network by its name passed on with the `--name` option, in the example above **oracledb**.
Once your database container is up and running and the database available, you can run a new ORDS container.

To run your ORDS Docker image use the **docker run** command as follows:

    docker run --name <container name> \
    --network=<name of your created network> \
    -p <host port>:8888 \
    -e ORACLE_HOST=<Your Oracle DB host (default: localhost)> \
    -e ORACLE_PORT=<Your Oracle DB port (default: 1521)> \
    -e ORACLE_SERVICE=<your Oracle DB Service name (default: ORCLPDB1)> \
    -e ORACLE_PWD=<your database SYS password> \
    -e ORDS_PWD=<your ORDS password> \
    -e APEX_PWD=<your APEX_PUBLIC_USER password> \
    -e APEXL_PWD=<your APEX_LISTENER password> \
    -e APEXR_PWD=<your APEX_REST_PUBLIC_USER password> \
    -e APEX_RESET=<Yes if you want to create/recreate Apex in the database>
    -v [<host mount point>:]/opt/oracle/ords/config/ords \
    oracle/apexords:18.2.0
    
    Parameters:
       --name:            The name of the container (default: auto generated)
       --network:         The network to use to communicate with databases.
       -p:                The port mapping of the host port to the container port. 
                          One port is exposed: 8888
       -e ORACLE_HOST:    The Oracle Database hostname that ORDS should use (default: localhost)
                          This should be the name that you gave your Oracle database Docker container, e.g. "oracledb"
       -e ORACLE_PORT:    The Oracle Database port that ORSD should use (default: 1521)
       -e ORACLE_SERVICE: The Oracle Database Service name that ORDS should use (default: ORCLPDB1)
       -e ORACLE_PWD:     The Oracle Database SYS password
       -e ORDS_PWD:       The ORDS_PUBLIC_USER password
       -e ORDS_PWD:       The ORDS_PUBLIC_USER password
       -e ORDS_PWD:       The ORDS_PUBLIC_USER password
       -e ORDS_PWD:       The ORDS_PUBLIC_USER password
       -e ORDS_PWD:       The ORDS_PUBLIC_USER password
       -v /opt/oracle/ords/config/ords
                          The data volume to use for the ORDS configuration files.
                          Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
                          If omitted the ORDS configuration files will not be persisted over container recreation.

Once the container has been started, APEX and ORDS configured you need to connect to the database to run the apxchpwd.sql script to setup ADMIN user for INTERNAL workspace. After that you can connect using http://localhost:8888/apex and start to develop. 

## Known issues
None

## Support

## License
To download and run Oracle Instant Client, APEX, ORDS, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleApexORDS](./) repository required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License (UPL), Version 1.0.

