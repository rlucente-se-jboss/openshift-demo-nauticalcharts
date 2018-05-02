#!/bin/bash

# example of running standalone
# sonar-scanner -Dsonar.projectKey=nauticalchart -Dsonar.sources=. -Dsonar.projectBaseDir=/opt/src -Dsonar.host.url=http://sonarqube-mepley-cd-cicd.apps.rhtps.io -Dsonar.login=c1619d0efb999dcac4c2a603f176ba06f17afc1e

oc new-build --name=sonar-scanner --context-dir=resources/sonar-scanner https://github.com/michaelepley/openshift-demo-nauticalcharts.git


# TODO: create a config map that build the sonar necessary file at sonar-scanner/conf/sonar-scanner.properties such as:
#----- Default SonarQube server
#sonar.host.url=http://localhost:9000

# or pass this file via -D command line option

# TODO create deployment config that adds the target application container as a side car with shared file system so the scanner can target it

