#!/bin/bash

set -e

if [ "${1:0:1}" != '-' ]; then
  exec "$@"
fi

sonar-scanner -Dsonar.projectKey=nauticalchart -Dsonar.sources=. -Dsonar.host.url=http://sonarqube-mepley-cd-cicd.apps.rhtps.io -Dsonar.login=c1619d0efb999dcac4c2a603f176ba06f17afc1e "$@"
  
