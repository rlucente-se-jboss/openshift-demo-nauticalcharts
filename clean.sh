#!/bin/bash


# Configuration
. ./config-demo-openshift-nauticalcharts.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
OPENSHIFT_PROJECTS_TO_CLEAN=(${OPENSHIFT_PROJECT} ${OPENSHIFT_PROJECT}-test ${OPENSHIFT_PROJECT}-prod) 

echo "Delete Simple PHP nautical chart demo"

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

for OPENSHIFT_PROJECT_TO_CLEAN in ${OPENSHIFT_PROJECTS_TO_CLEAN[*]} ; do
	echo "	--> cleaning project ${OPENSHIFT_PROJECT_TO_CLEAN}"
	echo -n "		--> delete all openshift resources for application ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME}..."
	oc delete all -l app=${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} -n ${OPENSHIFT_PROJECT_TO_CLEAN}
	echo -n "		--> delete all openshift resources for application ${NAUTICALCHART_FORKED_APPLICATION_NAME}..."
	oc delete all -l app=${NAUTICALCHART_FORKED_APPLICATION_NAME} -n ${OPENSHIFT_PROJECT_TO_CLEAN}
	echo -n "		--> delete all openshift resources for application ${NAUTICALCHART_FIXED_APPLICATION_NAME}..."
	oc delete all -l app=${NAUTICALCHART_FIXED_APPLICATION_NAME} -n ${OPENSHIFT_PROJECT_TO_CLEAN}
	echo -n "		--> delete all openshift resources for application ${NAUTICALCHART_WRAPPED_APPLICATION_NAME}..."
	oc delete all -l app=${NAUTICALCHART_WRAPPED_APPLICATION_NAME} -n ${OPENSHIFT_PROJECT_TO_CLEAN}
	
	echo -n "	--> delete miscellaneous artifacts (but leave jenkins alone)..."
	OPENSHIFT_PROJECT_MISC_RESOURCES=(`oc get all -n ${OPENSHIFT_PROJECT_TO_CLEAN} | grep -v '^NAME' | grep -v jenkins | awk '{ printf $1 " "; }' `)
	: ${OPENSHIFT_PROJECT_MISC_RESOURCES:-oc delete ${OPENSHIFT_PROJECT_MISC_RESOURCES} -n ${OPENSHIFT_PROJECT_TO_CLEAN} }

	echo "		--> optionally delete the project ... delete the project with 'oc delete project ${OPENSHIFT_PROJECT_TO_CLEAN} '"
	
done

echo "	--> delete all local artifacts"

echo "	--> deleting all local resources"
echo "		--> NOTE: nothing to do"
[[ -n ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL} && "x/" -ne "${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL}" ]] && rm -rf ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL}

echo "Done"
