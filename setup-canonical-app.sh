#!/usr/bin/env bash

# Configuration
. ./config-demo-openshift-nauticalcharts.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
APPLICATION_ENVIRONMENT_PRODUCTION_TAG=`echo ${APPLICATION_ENVIRONMENTS[*]} | grep -o -i prod.*`
# unless overridden, compute the expected production namespace
: ${APPLICATION_PRODUCTION_NAMESPACE:-${APPLICATION_ENVIRONMENT_PRODUCTION_TAG?"could not determine the production tag"}}
: ${APPLICATION_PRODUCTION_NAMESPACE:=${OPENSHIFT_PROJECT}-${APPLICATION_ENVIRONMENT_PRODUCTION_TAG}}

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}
: ${APPLICATION_REPOSITORY_GITHUB?"missing configuration for APPLICATION_REPOSITORY_GITHUB"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_USER_REFERENCE?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'
: ${APPLICATION_ENVIRONMENTS?"missing configuration for APPLICATION_ENVIRONMENTS"}
: ${APPLICATION_PRODUCTION_NAMESPACE?"missing definition of the production namespace"}

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

echo "	--> verify the expected production environment is already present"
oc get project ${APPLICATION_PRODUCTION_NAMESPACE} || { echo "FAILED: could not verify the expected production environment is already present" && exot 1 ; }

echo "	--> check for and delete any non-canonical endpoints"
APPLICATION_ROUTES_PRODUCTION_ENVIRONMENT=(`oc get routes --show-kind -n ${APPLICATION_PRODUCTION_NAMESPACE}  | tail -n +2 | awk '{ printf $1 "\n" }'|  grep -v routes/${NAUTICALCHART_CANONICAL_APPLICATION_NAME}$ `)
	: ${APPLICATION_ROUTES_PRODUCTION_ENVIRONMENT:-oc delete ${APPLICATION_ROUTES_PRODUCTION_ENVIRONMENT} -n ${APPLICATION_PRODUCTION_NAMESPACE} }

echo "	--> Expose a canonical endpoint for external users, which will never change...start them with the ORIGINAL application"
echo "		--> Try it! Go to ${NAUTICALCHART_CANONICAL_APPLICATION_NAME}.${OPENSHIFT_APPS}"
oc get route ${NAUTICALCHART_CANONICAL_APPLICATION_NAME} -n ${APPLICATION_PRODUCTION_NAMESPACE} >/dev/null 2>&1 || oc expose service ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --name ${NAUTICALCHART_CANONICAL_APPLICATION_NAME} -l app=${NAUTICALCHART_CANONICAL_APPLICATION_NAME} --hostname="${NAUTICALCHART_CANONICAL_APPLICATION_NAME}.${OPENSHIFT_APPS}" -n ${APPLICATION_PRODUCTION_NAMESPACE} >/dev/null 2>&1 

echo -n "	--> Waiting for both application endpoints to resolve successfully....press any key to proceed"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && ! curl -f -s -i ${NAUTICALCHART_CANONICAL_APPLICATION_NAME}.${OPENSHIFT_APPS} >/dev/null 2>&1 ; do echo -n "." && read -t 1 -n 1 && break ; done


echo -n "	--> scale up the application to a minimum size, 2 instances"
oc scale dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --replicas=2 -n ${APPLICATION_PRODUCTION_NAMESPACE}
echo -n "	--> Waiting for the application to scale up to the requested number of instances....press any key to proceed"
COUNTER=0
while [ $(( COUNTER ++ )) -lt 30 ] && [ `oc get dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} -n ${APPLICATION_PRODUCTION_NAMESPACE} -o jsonpath='{.status.availableReplicas}'` != `oc get dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} -n ${APPLICATION_PRODUCTION_NAMESPACE} -o jsonpath='{.status.replicas}'` ] ; do echo -n "." && read -t 1 -n 1 && break ; done

echo -n "	--> configure an autoscaler manage the application scale dynamically"
oc autoscale dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --min=2 --max=5 --cpu-percent=30 -n ${APPLICATION_PRODUCTION_NAMESPACE}

echo "	--> secure the canonical endpoint with re-encrypting ssl"
oc get route ${NAUTICALCHART_CANONICAL_APPLICATION_NAME} -n ${APPLICATION_PRODUCTION_NAMESPACE} | grep termination | grep edge || oc patch route/${NAUTICALCHART_CANONICAL_APPLICATION_NAME} -n ${APPLICATION_PRODUCTION_NAMESPACE} -p '{"spec" : { "tls" : { "termination" : "edge" , "insecureEdgeTerminationPolicy": "Redirect" } } }'

#TODO try reencrypt + client cert authn/z-- however the PHP S2I container does not have an (easy) way to configure server CA & certs, nor request client certs for authn/z...runtime configuration of php is via /opt/app-root/etc/php.ini.template (processed against environment variables)
#oc patch route/${NAUTICALCHART_CANONICAL_APPLICATION_NAME} -n ${APPLICATION_PRODUCTION_NAMESPACE} -p '{"spec" : { "tls" : { "termination" : "reencrypt" , "insecureEdgeTerminationPolicy": "Redirect" } } }'

echo "	--> disable all automatically build and deployment triggers -- we only want to go to production manually"
oc set triggers dc/${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} --manual -n ${APPLICATION_PRODUCTION_NAMESPACE}

# TODO: need to figure out how to split traffic between the canonical and test apps -- in different namespaces
#echo "	--> we will do continuous A/B testing against the test version of the application"
#oc set route-backends ${NAUTICALCHART_CANONICAL_APPLICATION_NAME} ${NAUTICALCHART_CANONICAL_APPLICATION_NAME}=90 -n ${APPLICATION_PRODUCTION_NAMESPACE}

echo "Done."