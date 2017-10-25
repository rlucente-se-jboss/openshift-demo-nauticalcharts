#!/bin/bash


# Configuration
. ./config.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
#None

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}
: ${APPLICATION_REPOSITORY_GITHUB?"missing configuration for APPLICATION_REPOSITORY_GITHUB"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_PROJECT?"missing configuration for OPENSHIFT_PROJECT"}
: ${OPENSHIFT_USER?"missing configuration for OPENSHIFT_USER"}
: ${OPENSHIFT_PASSWORD?"missing configuration for OPENSHIFT_PASSWORD"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
echo "OK"

echo "Create Simple PHP nautical chart demo"

OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'

echo "	--> make sure we are logged in"
oc whoami -c | grep ${OPENSHIFT_MASTER} | grep ${OPENSHIFT_USER} || oc login ${OPENSHIFT_MASTER} -u ${OPENSHIFT_USER} -p ${OPENSHIFT_PASSWORD} || { echo "FAILED: could login" && exit 1 ; }
echo "	--> create a project for ${APPLICATION_NAME}"
oc project ${OPENSHIFT_PROJECT} || oc new-project ${OPENSHIFT_PROJECT} ${OPENSHIFT_PROJECT_DESCRIPTION:+"--description"} ${OPENSHIFT_PROJECT_DESCRIPTION_QUOTED} ${OPENSHIFT_PROJECT_DISPLAY_NAME:+"--display-name"} ${OPENSHIFT_PROJECT_DISPLAY_NAME} || { echo "FAILED: could not create project" && exit 1 ; }
echo "	--> Verify the openshift cluster is working normally"
oc status -v || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; }

echo "	--> Create a new application from the ${APPLICATION_NAME} application git repo"
oc get dc/php || oc new-app --code=${APPLICATION_REPOSITORY_GITHUB} --name=${APPLICATION_NAME} -l app=${OPENSHIFT_APPLICATION_NAME},part=frontend || { echo "FAILED: Could not find or create the app=${APPLICATION_NAME},part=frontend " && exit 1; }

oc expose service ${APPLICATION_NAME} || { echo "FAILED: Could not expose the app=${APPLICATION_NAME},part=frontend " && exit 1; }

echo "Done."