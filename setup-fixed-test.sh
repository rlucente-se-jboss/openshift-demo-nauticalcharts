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


echo "	--> Add a readiness test to determine if our future fix works correctly...we are looking for the missing weather toolbar"
oc set probe dc/${NAUTICALCHART_FORKED_APPLICATION_NAME} --readiness --liveness --remove || { echo "WARNING: could not remove potentially conflicting readiness and liveness probes" ; }
oc set probe dc/${NAUTICALCHART_FORKED_APPLICATION_NAME} --readiness --period-seconds=5 -- /bin/sh -c "curl localhost:8080 | grep -i weather" || { echo "FAILED: could not add readiness probe to check for the desired fix" ; }

echo "	--> Add a canary route to allow us to start sending users to our prospective fix"

oc set route-backends ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME}=90 ${NAUTICALCHART_FORKED_APPLICATION_NAME}=10

echo "	--> Add a webhook to the application build so we can automate attempts to fix the application"
echo "		--> get forked application github webhook url"
{ oc get bc/${NAUTICALCHART_FORKED_APPLICATION_NAME} && OPENSHIFT_NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB=`oc describe bc/${NAUTICALCHART_FORKED_APPLICATION_NAME} | grep github | grep webhooks | awk '{printf $2}'`; } || { echo "FAILED: Could not get metadata about the ${NAUTICALCHART_FORKED_APPLICATION_NAME} build" && exit 1; }


echo "	--> delete any old webhooks to the forked online_map github project"
for NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB_ID in $(curl -s -X GET 'https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/hooks' -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -a -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" | jq '.[].id') ; do 
	curl -i -X DELETE -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -a -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/hooks/${NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB_ID}"
done

echo "	--> add new webhook to the github project"
NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB_CONFIG=$(cat <<EOF_NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB_CONFIG
{
  "name": "web",
  "active": true,
  "events": [
    "push"
  ],
  "config": {
    "url": "${OPENSHIFT_NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB}",
    "insecure_ssl": true,
    "content_type": "json"
  }
}
EOF_NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB_CONFIG
)

echo "		--> webhook configuration is: " && echo ${NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB_CONFIG}
#debug with 'nc -l localhost 8000 &' and adding '--proxy localhost:8000' to curl
echo ${NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB_CONFIG} | curl  -i -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -a -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d @/dev/stdin 'https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/hooks' 

echo "	--> Make sure all our triggers are active"
oc set triggers bc/${NAUTICALCHART_FORKED_APPLICATION_NAME} --auto=true && oc set triggers dc/${NAUTICALCHART_FORKED_APPLICATION_NAME} --auto=true


echo "Done."
