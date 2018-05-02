#!/bin/bash

# Configuration
. ./config-demo-openshift-nauticalcharts.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
#None

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}
: ${APPLICATION_REPOSITORY_GITHUB?"missing configuration for APPLICATION_REPOSITORY_GITHUB"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_USER_REFERENCE?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'
echo "OK"
echo "Setup nautical chart demo Configuration_____________________________________"
echo "	APPLICATION_NAME                     = ${APPLICATION_NAME}"
echo "	APPLICATION_REPOSITORY_GITHUB        = ${APPLICATION_REPOSITORY_GITHUB}"
echo "	OPENSHIFT_MASTER                     = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_MASTER}"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_APPS}"
echo "	CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY   = ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY}"
echo "	OPENSHIFT_OUTPUT_FORMAT              = ${OPENSHIFT_OUTPUT_FORMAT}"

echo "Create Simple PHP nautical chart demo"

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }




echo "	--> prepare for later CI/CD demo by creating a jenkins deployment now (it takes a couple of minutes)"
oc get dc/jenkins >/dev/null 2>&1 || oc new-app --template=jenkins-ephemeral >/dev/null 2>&1 || { echo "FAILED: Could not find or create the jenkins runtime" && exit 1; }

echo "	--> Create the original application from the ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} application git repo"
oc get dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} >/dev/null 2>&1  || oc new-app --name=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --code=${NAUTICALCHART_ORIGINAL_APPLICATION_REPOSITORY_GITHUB} -l app=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME},part=frontend  >/dev/null 2>&1  || { echo "FAILED: Could not find or create the app=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME},part=frontend " && exit 1; }

echo -n "	--> Waiting for the ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} application to start....press any key to proceed"
while ! oc get pods | grep ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} | grep -v build | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Expose a generic endpoint for the original application"
oc get route ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} >/dev/null 2>&1  || oc expose service ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} >/dev/null 2>&1  || { echo "FAILED: Could not verify route to application frontend" && exit 1; } || { echo "FAILED: Could patch frontend" && exit 1; }

echo "	--> Expose a canonical endpoint for external users, which will never change...start them with the ORIGINAL application"
echo "		--> Try it! Go to ${NAUTICALCHART_CANONICAL_APPLICATION_NAME}.${OPENSHIFT_APPS}"
oc get route ${NAUTICALCHART_CANONICAL_APPLICATION_NAME} >/dev/null 2>&1 || oc expose service ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --name ${NAUTICALCHART_CANONICAL_APPLICATION_NAME} -l app=${NAUTICALCHART_CANONICAL_APPLICATION_NAME} --hostname="${NAUTICALCHART_CANONICAL_APPLICATION_NAME}.${OPENSHIFT_APPS}" >/dev/null 2>&1 

echo -n "	--> Waiting for both application endpoints to resolve successfully....press any key to proceed"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && ! curl -f -s -i ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS} >/dev/null 2>&1 && ! curl -f -s -i ${NAUTICALCHART_CANONICAL_APPLICATION_NAME}.${OPENSHIFT_APPS} >/dev/null 2>&1 ; do echo -n "." && read -t 1 -n 1 && break ; done

echo "	--> Checking for the presence of a newly requested weather feature"
curl -f -s -i ${NAUTICALCHART_CANONICAL_APPLICATION_NAME}.${OPENSHIFT_APPS} | grep -i weather >/dev/null 2>&1 || { echo "	--> On Noes! the weather toolbar is missing!" && echo "	--> Let's fix this" ; }

echo "Done."

