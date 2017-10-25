#!/bin/bash


# Configuration
. ./config.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
# NONE

echo "Delete Simple PHP nautical chart demo"

echo "	--> make sure we are logged in"
oc whoami || oc login master.rhsademo.net -u mepley -p ${OPENSHIFT_PASSWORD}
echo "	--> make sure we are using the correct project"
oc project ${OPENSHIFT_PROJECT} || { echo "WARNING: missing project -- nothing to do" && exit 0; }

echo "	--> delete all openshift resources for application ${APPLICATION_NAME}"
oc delete all -l app=${APPLICATION_NAME}
echo "	--> delete project ${OPENSHIFT_PROJECT}"
#oc delete project ${OPENSHIFT_PROJECT}
echo "	--> delete all local artifacts"

echo "	--> deleting all local resources"
echo "		--> NOTE: nothing to do"

echo "	--> optionally delete the project"
echo "		--> delete the project ${OPENSHIFT_PROJECT} "

echo "Done"
