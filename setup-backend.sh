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

echo




echo "		--> creating the nexus components"
if ! oc get bc/nexus ; then 
	oc new-build --name="nexus" --image-stream="jboss-eap70-openshift" --code="https://github.com/sonatype/nexus-public.git" --context-dir="." --to=nexus || { echo "WARNING: could not create build for the nexus component" ; }
	sleep 3s
	oc cancel-build bc/nexus || { echo "WARNING: could not cancel build for nexus component" ; }
	oc patch bc/nexus -p '{ "spec" : {  "resources" : { "requests" : { "cpu" : "900m" , "memory" : "1000Mi" } , "limits" : { "cpu" : "1000m" , "memory" : "1500Mi" } } } }' || { echo "FAILED: could not patch nexus build configuration to ensure sufficient build resources" && exit 1 ; }
	oc start-build bc/nexus || { echo "WARNING: could not restart build for nexus component" ; }
fi

exit


echo "		--> creating the geoserver components"
if ! oc get bc/geoserver ; then 
	oc new-build --name="geoserver" --image-stream="jboss-eap70-openshift" --code="https://github.com/geoserver/geoserver.git" --context-dir="src" --to=geoserver || { echo "WARNING: could not create build for the geoserver component" ; }
	sleep 3s
	oc cancel-build bc/geoserver || { echo "WARNING: could not cancel build for geoserver component" ; }
	oc patch bc/geoserver -p '{ "spec" : {  "resources" : { "requests" : { "cpu" : "900m" , "memory" : "1000Mi" } , "limits" : { "cpu" : "1000m" , "memory" : "1500Mi" } } } }' || { echo "FAILED: could not patch geoserver build configuration to ensure sufficient build resources" && exit 1 ; }
	oc start-build bc/geoserver || { echo "WARNING: could not restart build for geoserver component" ; }
fi
