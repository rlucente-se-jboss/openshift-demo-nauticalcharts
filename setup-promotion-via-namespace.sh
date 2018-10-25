#!/usr/bin/env bash

# Configuration
. ./config-demo-openshift-nauticalcharts.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
# A label filter to identify application components to migrate
APPLICATION_LABEL_FILTER=${1:-nauticalchart-original}

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}
: ${APPLICATION_REPOSITORY_GITHUB?"missing configuration for APPLICATION_REPOSITORY_GITHUB"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_USER_REFERENCE?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
[[ "${PROMOTION_PROCESS_NAMESPACE}" == "true" || "${PROMOTION_PROCESS_APPLICATIONNAME}" == "true" ]] || { echo "FAILED: no application promotion process was specified" && exit 1 ; }

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


# TODO: finish this section -- migrate the application to production;
echo "	--> Automate application promotion from dev to test to prod"
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
	oc export bc,is,dc,route,svc,secrets,configmaps -l app=${APPLICATION_LABEL_FILTER},part=frontend -n ${APPLICATION_SOURCE_NAMESPACE} --as-template=application-${APPLICATION_LABEL_FILTER}-template -o json > ${APPLICATON_RESOURCE_TEMPLATE_TEMP_SOURCE}
	echo "		--> create a source template in the original namespace, if one does not already exist"
	oc get template/application-${APPLICATION_LABEL_FILTER}-template -n ${APPLICATION_SOURCE_NAMESPACE} >/dev/null 2>&1 || oc create -n ${APPLICATION_SOURCE_NAMESPACE} -f ${APPLICATON_RESOURCE_TEMPLATE_TEMP_SOURCE} || { echo "WARNING: could not create a template in the source namespace" ; }
	cp ${APPLICATON_RESOURCE_TEMPLATE_TEMP_SOURCE} ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}
	echo "		--> the template intermediate processing is ${APPLICATON_RESOURCE_TEMPLATE_TEMP_SOURCE} -->  ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}"

	echo "		--> Modify the template to make the target the ${APPLICATION_TARGET_NAMESPACE} namespace"
	## with JQ see https://github.com/stedolan/jq/wiki/FAQ#general-questions
	## def translate_values(v, f): walk( if(type == "object" and value == v) then with_entries( .value |= f ) else . end); , translate_values("namespace", "mepley-ntest") , translate_values("namespace", "mepley-ntest") 

	## with sed
	sed -i "\|namespace.*${APPLICATION_SOURCE_NAMESPACE}|s|${APPLICATION_SOURCE_NAMESPACE}|${APPLICATION_TARGET_NAMESPACE}|" ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}
	sed -i "\|host.*${APPLICATION_SOURCE_NAMESPACE}.${OPENSHIFT_APPS}|s|${APPLICATION_SOURCE_NAMESPACE}.${OPENSHIFT_APPS}|${APPLICATION_TARGET_NAMESPACE}.${OPENSHIFT_APPS}|" ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}
	sed -i "\|image.*${APPLICATION_SOURCE_NAMESPACE}.${OPENSHIFT_APPS}|s|${APPLICATION_SOURCE_NAMESPACE}|${APPLICATION_TARGET_NAMESPACE}|" ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}
	sed -i "\|kind.*DockerImage|{N;s|${APPLICATION_SOURCE_NAMESPACE}|${APPLICATION_TARGET_NAMESPACE}|}" ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET}

	echo "		--> Recreate the application in the target namespace"
	oc get project ${APPLICATION_TARGET_NAMESPACE} || oc new-project ${APPLICATION_TARGET_NAMESPACE} --skip-config-write=true || { echo "FAILED: could not find or create target namespace ${APPLICATION_TARGET_NAMESPACE} for application promotion" && exit 1 ; }
	oc create -f ${APPLICATON_RESOURCE_TEMPLATE_TEMP_TARGET} -n ${APPLICATION_TARGET_NAMESPACE}
	oc new-app -n ${APPLICATION_TARGET_NAMESPACE} --template=application-${APPLICATION_LABEL_FILTER}-template

	# for the next iteration of this loop, the source namespace is the previous target namespace
	APPLICATION_SOURCE_NAMESPACE=${APPLICATION_TARGET_NAMESPACE}
done


echo "Done."
