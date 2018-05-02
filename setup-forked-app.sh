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
[[ -v GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT ]] || [[ -v GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT ]] || { echo "FAILED: you must provide a github authorization key" && exit 1 ; } 
: ${SCRIPT_ENCRYPTION_KEY?"missing script encryption key"}
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

echo "========== FORKED deployment =========="
echo "	--> We'll do so in our new, forked version of this application"

#oc expose service ${APPLICATION_NAME} || { echo "FAILED: Could not expose the app=${APPLICATION_NAME},part=frontend " && exit 1; }

echo "	--> delete conflicting repositories if possible"
curl -f -s -i -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -a -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map" >/dev/null 2>&1 && curl -i -X DELETE -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_ALL_ACCESS_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_ALL_ACCESS_CIPHERTEXT} | openssl enc -d -a -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map" >/dev/null 2>&1 || { echo "WARNING: could not confirm removal of potentially conflicting git repositories" ; }

echo -n "	--> Waiting for github delete to succeed...press any key to continue"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && curl -f -s -i -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -a -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map" >/dev/null 2>&1 ; do
	echo -n "." && read -t 1 -n 1 && break
done


echo "	--> fork the application into ${GITHUB_USER_PRIMARY}'s Github account at ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB}"
curl -s -i -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/OpenNauticalChart/online_map/forks" >/dev/null 2>&1 || { echo "FAILED: could not create fork of the application git repositories" && exit 1 ; }
sleep 1s;
echo -n "	--> Waiting for github fork to succeed...press any key to continue"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && ! curl -s -i -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -a -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map" >/dev/null 2>&1 ; do
	echo -n "." && read -t 1 -n 1 && break
done

echo "	--> Let's deploy the forked application so we can make sure it works normally still, and so we can see our work"SCRIPT_ENCRYPTION_KEYSCRIPT_ENCRYPTION_KEYSCRIPT_ENCRYPTION_KEY
echo "	--> Create the application from the forked ${NAUTICALCHART_FORKED_APPLICATION_NAME} application git repo"
oc get dc/${NAUTICALCHART_FORKED_APPLICATION_NAME} >/dev/null 2>&1 || oc new-app --name=${NAUTICALCHART_FORKED_APPLICATION_NAME} --code=${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB}#${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB_BRANCH} -l app=${NAUTICALCHART_FORKED_APPLICATION_NAME},part=frontend >/dev/null 2>&1 || { echo "FAILED: Could not find or create the app=${NAUTICALCHART_FORKED_APPLICATION_NAME},part=frontend " && exit 1; }

echo -n "	--> Waiting for the ${NAUTICALCHART_FORKED_APPLICATION_NAME} application to start....press any key to proceed"
while ! oc get pods | grep ${NAUTICALCHART_FORKED_APPLICATION_NAME} | grep -v build | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Expose a generic endpoint for the forked application"
oc get route ${NAUTICALCHART_FORKED_APPLICATION_NAME} >/dev/null 2>&1  || oc expose service ${NAUTICALCHART_FORKED_APPLICATION_NAME} >/dev/null 2>&1  || { echo "FAILED: Could not verify route to application frontend" && exit 1; }

echo -n "	--> Waiting for the forked application route to resolve successfully...press any key to proceed"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && ! curl -f -s -i ${NAUTICALCHART_FORKED_APPLICATION_NAME}.${OPENSHIFT_APPS} >/dev/null 2>&1 ; do echo -n "." && read -t 1 -n 1 && break ; done

echo "Done."
