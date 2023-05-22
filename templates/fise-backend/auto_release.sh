#!/bin/bash

### Variable list

 # ${DOCKER_IMAGENAME} - the dockerhub image that is released
 # ${DOCKER_IMAGENAME_ESC} - same as ${DOCKER_IMAGENAME}, but with '/' escaped so it can be used in sed
 # ${DOCKER_IMAGEVERSION} - the dockerhub image version that is released
 # ${RANCHER_CATALOG_PATH} - rancher catalog path used in the release
 # ${nextdir} - the new release directory
 # ${lastdir} - the last release directory

 # ${GIT_ORG} - git organization, default eea
 # ${GIT_NAME} - if given, is the git repository name
 
if [[ "${DOCKER_IMAGENAME}" = *"-backend" ]]; then

    sed -i "s/SENTRY_RELEASE:.*/SENTRY_RELEASE: '${DOCKER_IMAGEVERSION}'/" ${nextdir}/docker-compose.yml
    sed -i "s/BACKEND_VERSION:.*/BACKEND_VERSION: '${DOCKER_IMAGEVERSION}'/" ${nextdir}/docker-compose.yml
    echo "Also updating SENTRY_RELEASE and BACKEND_VERSION variable values"
    
else

   echo "No variables need to be updated, as the image is ${DOCKER_IMAGENAME}"
   
fi
