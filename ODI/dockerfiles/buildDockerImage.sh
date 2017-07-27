#!/bin/bash
# 
# Description: script to build a Docker image for ODI
# 

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] [-t | -e] [-s] [-c]
Builds a Docker Image for Oracle ODI.
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -t: creates image based on standalone agent  distribution
   -e: creates image based on enterprise agent distribution
   -c: enables Docker image layer cache during build
   -s: skips the MD5 check of packages

* select one distribution only: -t or -e

LICENSE CDDL 1.0 + GPL 2.0

EOF
exit 0
}

# Validate packages
checksumPackages() {
  echo "Checking if required packages are present and valid..."
  md5sum Checksum.$DISTRIBUTION
  if [ "$?" -ne 0 ]; then
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION. See *.download files for more information"
    exit $?
  fi
}

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
STANDALONE=0
ENTERPRISE=0
VERSION="12.2.1.2.6"
SKIPMD5=0
NOCACHE=true
while getopts "hcstev:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "s")
      SKIPMD5=1
      ;;
    "t")
      STANDALONE=1
      ;;
    "e")
      ENTERPRISE=1
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "c")
      NOCACHE=false
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

# Which distribution to use?
if [ $((STANDALONE + ENTERPRISE)) -gt 1 ]; then
  usage
elif [ $STANDALONE -eq 1 ]; then
  DISTRIBUTION="standalone"
elif [ $ENTERPRISE -eq 1 ]; then
  DISTRIBUTION="enterprise"
fi

# ODI Image Name
IMAGE_NAME="oracle/odi:$VERSION-$DISTRIBUTION"

# Go into version folder
cd $VERSION

if [ ! "$SKIPMD5" -eq 1 ]; then
  checksumPackages
else
  echo "Skipped MD5 checksum."
fi

echo "====================="

# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=$NOCACHE --no-cache=$NOCACHE $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile.$DISTRIBUTION . || {
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  ODI Docker Image for '$DISTRIBUTION' version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "ODI Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

