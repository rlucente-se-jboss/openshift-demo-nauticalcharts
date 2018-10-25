#!/usr/bin/env bash

set -e

: ${SONARQUBE_SCANNER_TARGET_APPLICATION_NAME?"FAILED: Could not configure sonarqube scanner; application name is missing in runtime configuration"}
: ${SONARQUBE_SERVICE_LOCATION_FQDN:=sonarqube.svc.cluster.local}

if [ "${1:0:1}" != '-' ]; then
  exec "$@"
fi

sonar-scanner -Dsonar.projectKey=${SONARQUBE_SCANNER_TARGET_APPLICATION_NAME} -Dsonar.sources=. -Dsonar.host.url=${SONARQUBE_SERVICE_LOCATION_FQDN} -Dsonar.login=c1619d0efb999dcac4c2a603f176ba06f17afc1e "$@"
