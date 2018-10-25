#!/usr/bin/env bash

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


echo "		--> Clone the fork to a local working directory, so we can fix it"
NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL=${GIT_HOME}
mkdir -p ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL}
pushd ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL}
git clone https://github.com/michaelepley/online_map.git
git checkout fixed
sed -e 's|<? include|<?php include|' index.php
sed -e 's|<? include|<?php include|' weather_index.php
git commit -a -m "Fixed the missing toolbars by correcting php include tags in index.php and weather_index.php"
git push
popd

## delete commit?? curl -f -X DELETE -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/git/refs/d658d935f55b93aeb295e386e77c4d256da60ae8"



echo "Done."