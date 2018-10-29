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
echo "OK"

echo "Create Simple PHP nautical chart demo"

OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }

echo "========== ORIGINAL deployment =========="
echo "		--> press enter to continue" && read

echo "	--> prepare for later CI/CD demo by creating a jenkins deployment now (it takes a couple of minutes)"
oc get dc/jenkins || oc new-app --template=jenkins-ephemeral || { echo "FAILED: Could not find or create the jenkins runtime" && exit 1; }

echo "	--> Create the original application from the ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} application git repo"
oc get dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} >/dev/null 2>&1  || oc new-app --name=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --code=${NAUTICALCHART_ORIGINAL_APPLICATION_REPOSITORY_GITHUB} -l app=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME},part=frontend  >/dev/null 2>&1  || { echo "FAILED: Could not find or create the app=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME},part=frontend " && exit 1; }

# echo oc get dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} 
# echo oc new-app --name=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --code=\'${NAUTICALCHART_ORIGINAL_APPLICATION_REPOSITORY_GITHUB}#${NAUTICALCHART_ORIGINAL_APPLICATION_REPOSITORY_GITHUB_BRANCH}\' -l app=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME},part=frontend


## #${NAUTICALCHART_ORIGINAL_APPLICATION_REPOSITORY_GITHUB_BRANCH}

echo "	--> Waiting for the ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} application to start....press any key to proceed"
while ! oc get pods | grep ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Expose a generic endpoint for the original application"
oc get route ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} >/dev/null 2>&1  || oc expose service ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} >/dev/null 2>&1  || { echo "FAILED: Could not verify route to application frontend" && exit 1; } || { echo "FAILED: Could patch frontend" && exit 1; }

echo "	--> Expose an endpoint for external users...start them with the ORIGINAL application"
echo "		--> Try it! Go to nautical-charts-canonical.apps.rhsademo.net"
oc get route nautical-charts-canonical >/dev/null 2>&1 || oc expose service ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --name nautical-charts-canonical -l app=nautical-charts-canonical --hostname="nautical-charts-canonical.apps.rhsademo.net" >/dev/null 2>&1 

echo "	--> Waiting for both application routes to resolve successfully....press any key to proceed"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && curl -s -i ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME}-${OPENSHIFT_APPS} && curl -s -i nautical-charts-canonical-${OPENSHIFT_APPS} ; do
	echo -n "." && read -t 1 -n 1 && break
done

echo "	--> On Noes! the weather toolbar is missing!"
echo ""
echo "	--> Let's fix this"

exit

# "========== FORKED deployment =========="
echo "	--> We'll do so in our new, forked version of this application"

#oc expose service ${APPLICATION_NAME} || { echo "FAILED: Could not expose the app=${APPLICATION_NAME},part=frontend " && exit 1; }

echo "	--> delete conflicting repositories if possible"
curl -s -i -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/users/${GITHUB_USER_PRIMARY}/repos" | grep name | grep online_map && curl -i -X DELETE -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_ALL_ACCESS_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_ALL_ACCESS_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map"
# wait for the delete to succeed

echo "	--> Waiting for github delete to succeed, press any key to continue"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && curl -s -i -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/users/${GITHUB_USER_PRIMARY}/repos" | grep name | grep online_map ; do
	echo -n "." && read -t 1 -n 1 && break
done



echo "	--> fork the application into ${GITHUB_USER_PRIMARY}'s Github account at ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB}"
# curl  -i -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d @/dev/stdin 'https://api.github.com/repos/OpenNauticalChart/online_map/forks'
curl  -i -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/OpenNauticalChart/online_map/forks"
echo "	--> Waiting for github fork to succeed, press any key to continue"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && ! curl -s -i -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/users/${GITHUB_USER_PRIMARY}/repos" | grep name | grep online_map ; do
	echo -n "." && read -t 1 -n 1 && break
done

echo "	--> Let's deploy the forked application so we can make sure it works normally still, and so we can see our work"
echo "	--> Create the application from the forked ${NAUTICALCHART_FORKED_APPLICATION_NAME} application git repo"
oc get dc/${NAUTICALCHART_FORKED_APPLICATION_NAME} || oc new-app --name=${NAUTICALCHART_FORKED_APPLICATION_NAME} --code=${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB}#${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB_BRANCH} -l app=${NAUTICALCHART_FORKED_APPLICATION_NAME},part=frontend || { echo "FAILED: Could not find or create the app=${NAUTICALCHART_FORKED_APPLICATION_NAME},part=frontend " && exit 1; }

echo "	--> Waiting for the ${NAUTICALCHART_FORKED_APPLICATION_NAME} application to start....press any key to proceed"
while ! oc get pods | grep ${NAUTICALCHART_FORKED_APPLICATION_NAME} | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""



OPENSHIFT_APPLICATION_GITHUB_ISSUE_MISSING_TOOLBAR_WEATHER_CONFIG=$(cat <<EOF_OPENSHIFT_APPLICATION_GITHUB_ISSUE_MISSING_TOOLBAR_WEATHER
{
  "title": "Missing Weather Toolbar",
  "body": "This application was supposed to have a nice toolbar in the upper right corner that lets the user toggle the various map layers, like weather",
  "assignees": [
    "michaelepley"
  ],
  "milestone": 1,
  "labels": [
    "bug"
  ]
}
EOF_OPENSHIFT_APPLICATION_GITHUB_ISSUE_MISSING_TOOLBAR_WEATHER
)

#echo "	--> Looks like our PHB (pointy haired boss) has created a new issue to track the missing weather toolbar, and its been assigned to us!"
#echo ${OPENSHIFT_APPLICATION_GITHUB_ISSUE_MISSING_TOOLBAR_WEATHER_CONFIG} |  curl  -i -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d @/dev/stdin "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/issues"

echo "	--> We've been assigned to fix the missing toolbar, lets create a new branch in our git repository"
#curl -f -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/git/refs/heads/fixed" || { NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB_BRANCH_MASTER_SHA=$(curl  -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/git/refs/heads" | jq -c '.[] | select(.ref | endswith("master")).object.sha?') && curl  -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '{ "ref": "refs/heads/fixed", "sha": "'${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB_BRANCH_MASTER_SHA}'" }' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/git/refs" ; } 
curl -f -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/git/refs/heads/fixed" || { NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB_BRANCH_MASTER_SHA=$(curl  -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/git/refs/heads" | jq -c '.[] | select(.ref | endswith("master")).object.sha?') && curl  -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d '{ "ref": "refs/heads/fixed", "sha": "'${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB_BRANCH_MASTER_SHA}'" }' "https://api.github.com/repos/${GITHUB_USER_PRIMARY}/online_map/git/refs" ; } 

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



echo "	--> Expose a generic endpoint for the forked application"
oc get route ${NAUTICALCHART_FORKED_APPLICATION_NAME} >/dev/null 2>&1  || oc expose service ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} >/dev/null 2>&1  || { echo "FAILED: Could not verify route to application frontend" && exit 1; } || { echo "FAILED: Could patch frontend" && exit 1; }

echo "	--> Waiting for the forked application route to resolve successfully....press any key to proceed"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && curl -s -i ${NAUTICALCHART_FORKED_APPLICATION_NAME}-${OPENSHIFT_APPS} ; do
	echo -n "." && read -t 1 -n 1 && break
done
















echo "	--> create
oc get dc/${NAUTICALCHART_FIXED_APPLICATION_NAME} || oc new-app --name=${NAUTICALCHART_FORKED_APPLICATION_NAME} --code=${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB}#${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_GITHUB_BRANCH} -l app=${NAUTICALCHART_FORKED_APPLICATION_NAME},part=frontend || { echo "FAILED: Could not find or create the app=${NAUTICALCHART_FORKED_APPLICATION_NAME},part=frontend " && exit 1; }


echo "	--> get canary application github webhook url"
{ oc get bc/canary && OPENSHIFT_NAUTICALCHART_FORKED_APPLICATION_WEBHOOK_GITHUB=`oc describe bc/canary | grep github | grep webhooks | awk '{printf $2}'`; } || { echo "FAILED: Could not get metadata about the canary build" && exit 1; }


echo "	--> delete any old webhooks to the phpmysqldemo github project"
for OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB_ID in $(curl -s -X GET 'https://api.github.com/repos/michaelepley/phpmysqldemo/hooks' -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" | jq '.[].id') ; do 
	curl -i -X DELETE -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" 'https://api.github.com/repos/michaelepley/phpmysqldemo/hooks/'${OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB_ID} 
done

echo "	--> add new webhook to the phpmysqldemo github project"
OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB_CONFIG=$(cat <<EOF_OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB_CONFIG
{
  "name": "web",
  "active": true,
  "events": [
    "push"
  ],
  "config": {
    "url": "${OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB}",
    "insecure_ssl": true,
    "content_type": "json"
  }
}
EOF_OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB_CONFIG
)

echo "		--> webhook configuration is: " && echo ${OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB_CONFIG}
#debug with 'nc -l localhost 8000 &' and adding '--proxy localhost:8000' to curl
echo ${OPENSHIFT_APPLICATION_PHP_WEBHOOK_GITHUB_CONFIG} | curl  -i -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`}" -H "Content-Type: application/json" -d @/dev/stdin 'https://api.github.com/repos/michaelepley/phpmysqldemo/hooks' 

echo "	--> Make sure all our triggers are active"
oc set triggers bc/canary --auto=true && oc set triggers dc/canary --auto=true


















# TODO: limit developer rights; automatically add side-car audit log w/ DB to deploymentconfig

# TODO: finish this section -- migrate the application to production;
echo "	--> Automate application promotion from dev to test to prod"
APPLICATION_ENVIRONMENTS=(dev test prod)
OPENSHIFT_PROJECT_REF=${OPENSHIFT_USER_REFERENCE}[3]
OPENSHIFT_PROJECT=${!OPENSHIFT_PROJECT_REF}

# start from the original namespace, no matter what is enumerated in APPLICATION_ENVIRONMENTS
APPLICATION_SOURCE_NAMESPACE=${OPENSHIFT_PROJECT}
for APPLICATION_ENVIRONMENT in ${APPLICATION_ENVIRONMENTS[@]:1} ; do
	APPLICATION_TARGET_NAMESPACE=${OPENSHIFT_PROJECT}-${APPLICATION_ENVIRONMENT}
	echo "	--> Configure application promotion from ${APPLICATION_SOURCE_NAMESPACE} to ${APPLICATION_TARGET_NAMESPACE}"
	APPLICATON_RESOURCE_TEMPLATE_TEMP=`mktemp`
	APPLICATON_RESOURCE_TEMPLATE_TEMP_SOURCE=${APPLICATON_RESOURCE_TEMPLATE_TEMP}-${APPLICATION_SOURCE_NAMESPACE}
	APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET=${APPLICATON_RESOURCE_TEMPLATE_TEMP}-${APPLICATION_TARGET_NAMESPACE}
	echo "		--> extract the current application from the ${APPLICATION_SOURCE_NAMESPACE} environment (as a template)"
	oc export bc,is,dc,route,svc,secrets,configmaps -l app=nauticalchart-original,part=frontend -n mepley-nauticalcharts --as-template=nautical-chart-template -o json > ${APPLICATON_RESOURCE_TEMPLATE_TEMP_SOURCE}
	cp ${APPLICATON_RESOURCE_TEMPLATE_TEMP_SOURCE} ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}

	echo "		--> Modify the template to make the target the test namespace"
	## with JQ see https://github.com/stedolan/jq/wiki/FAQ#general-questions
	## def translate_values(v, f): walk( if(type == "object" and value == v) then with_entries( .value |= f ) else . end); , translate_values("namespace", "mepley-ntest") , translate_values("namespace", "mepley-ntest") 

	## with sed
	sed -i "\|namespace.*${APPLICATION_SOURCE_NAMESPACE}|s|${APPLICATION_SOURCE_NAMESPACE}|${APPLICATION_TARGET_NAMESPACE}|" ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}
	sed -i '\|host.*${APPLICATION_SOURCE_NAMESPACE}.${OPENSHIFT_APPS}|s|${APPLICATION_SOURCE_NAMESPACE}.${OPENSHIFT_APPS}|${APPLICATION_TARGET_NAMESPACE}.${OPENSHIFT_APPS}|' ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}
	sed -i '\|image.*${APPLICATION_SOURCE_NAMESPACE}.${OPENSHIFT_APPS}|s|${APPLICATION_SOURCE_NAMESPACE}|${APPLICATION_TARGET_NAMESPACE}|' ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}
	sed '\|kind.*DockerImage|N;s|${APPLICATION_SOURCE_NAMESPACE}|${APPLICATION_TARGET_NAMESPACE}|' ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}

	echo "		--> Recreate the application in the test namespace"
	oc get project ${APPLICATION_TARGET_NAMESPACE} || oc new-project ${APPLICATION_TARGET_NAMESPACE} --skip-config-write=true || { echo "FAILED: could not find or create target namespace ${APPLICATION_TARGET_NAMESPACE} for application promotion" && exit 1 ; }
	oc create -f ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET} -n ${OPENSHIFT_PROJECT}-prod

	# for the next iteration of this loop, the source namespace is the previous target namespace
	APPLICATION_SOURCE_NAMESPACE=${APPLICATION_TARGET_NAMESPACE}
done









echo "	--> Make custom S2I template for building to wrap app in classification banners"


oc is php-secure-1 
|| oc new-build --name=php-secure-1 --image-stream=php:latest --strategy=docker --dockerfile=$'FROM scratch\nRUN USERID_NUMERIC=`id -u`\nUSER 0\nRUN mv ${STI_SCRIPTS_PATH}/assemble ${STI_SCRIPTS_PATH}/assemble-previous\nRUN echo $\'. ${STI_SCRIPTS_PATH}/assemble-previous\\nmv index.php index-previous.php\\nmv classification.php index.php\\n\' > ${STI_SCRIPTS_PATH}/assemble && chmod a+x ${STI_SCRIPTS_PATH}/assemble \nUSER ${USERID_NUMERIC}\n' --code=https://github.com/michaelepley/openshift-templates.git --context-dir=resources/php/classification 
|| { echo "FAILED: could not create custom S2I builder image" && exit 1 ; }

oc new-build --name=php-secure-2 --image-stream=php-secure-1:latest --strategy=docker --dockerfile=$'FROM scratch\nUSER 1001'


oc get bc nauticalchart-original -o json > resources/buildconfig-nauticalchart-original.json
# 







echo "Done."
