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


echo "	--> Make custom S2I template for building to wrap app in classification banners"


oc get is php-secure-1 || oc new-build --name=php-secure-1 --image-stream=php:latest --strategy=docker --dockerfile=$'FROM scratch\nRUN USERID_NUMERIC=`id -u`\nUSER 0\nRUN mv ${STI_SCRIPTS_PATH}/assemble ${STI_SCRIPTS_PATH}/assemble-previous\nRUN echo $\'. ${STI_SCRIPTS_PATH}/assemble-previous\\nmv index.php index-previous.php\\nmv classification.php index.php\\n\' > ${STI_SCRIPTS_PATH}/assemble && chmod a+x ${STI_SCRIPTS_PATH}/assemble \nUSER ${USERID_NUMERIC}\n' --code=https://github.com/michaelepley/openshift-templates.git --context-dir=resources/php/classification --allow-missing-imagestream-tags || { echo "FAILED: could not create custom S2I builder image" && exit 1 ; }

oc get is php-secure || oc new-build --name=php-secure --image-stream=php-secure-1:latest --strategy=docker --dockerfile=$'FROM scratch\nUSER 1001' --allow-missing-imagestream-tags || { echo "FAILED: could not create custom S2I builder image" && exit 1 ; }

echo "	--> modify the current build processes to use the new build process"

# unless overridden, compute the expected test namespace
APPLICATION_ENVIRONMENT_TEST_TAG=`echo ${APPLICATION_ENVIRONMENTS[*]} | grep -o -i test.*`
: ${APPLICATION_TEST_NAMESPACE:-${APPLICATION_ENVIRONMENT_TEST_TAG?"could not determine the production tag"}}
: ${APPLICATION_TEST_NAMESPACE:=${OPENSHIFT_PROJECT}-${APPLICATION_ENVIRONMENT_TEST_TAG}}
# unless overridden, compute the expected production namespace
APPLICATION_ENVIRONMENT_PRODUCTION_TAG=`echo ${APPLICATION_ENVIRONMENTS[*]} | grep -o -i prod.*`
: ${APPLICATION_PRODUCTION_NAMESPACE:-${APPLICATION_ENVIRONMENT_PRODUCTION_TAG?"could not determine the production tag"}}
: ${APPLICATION_PRODUCTION_NAMESPACE:=${OPENSHIFT_PROJECT}-${APPLICATION_ENVIRONMENT_PRODUCTION_TAG}}

echo "	--> create a new copy of the existing build config for the ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME}"
APPLICATON_RESOURCE_TEST_BUILDCONFIG_TEMP=`mktemp`
oc get bc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} -n ${APPLICATION_TEST_NAMESPACE} -- -o json > ${APPLICATON_RESOURCE_TEST_BUILDCONFIG_TEMP}


APPLICATION_NAUTICALCHARTS_ALL_BUILD_CONFIGS=(`oc get bc | grep nauticalchart | awk ' { printf $1 ; } '`)

for APPLICATION_NAUTICALCHARTS_BUILD_CONFIG in ${APPLICATION_NAUTICALCHARTS_ALL_BUILD_CONFIGS[*]} ; do 
	echo "		--> modifying the build ${APPLICATION_NAUTICALCHARTS_BUILD_CONFIG}"
#	oc patch bc/${APPLICATION_NAUTICALCHARTS_BUILD_CONFIG} -p '{}'
	# TODO: check to make sure the trigger has initiated a new build, manually start one if necessary
done 


echo "Done."
