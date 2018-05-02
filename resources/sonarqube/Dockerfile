# This dockerfile assumes there is already a base image stream built from the dockerfile at https://github.com/OpenShiftDemos/sonarqube-openshift-docker
FROM sonarqube:latest

MAINTAINER Michael Epley <mepley@redhat.com>

USER root
EXPOSE 9000
ADD root /

RUN set -x \
    && SONARPHP_DISTRIBUTABLE=`curl -s -L https://docs.sonarqube.org/display/PLUG/SonarPHP | sed '\|Download|!d;s|.*href="\(.*\)".*|\1|g' ` \
    && SONARWEB_DISTRIBUTABLE=`curl -s -L https://docs.sonarqube.org/display/PLUG/SonarWeb | sed '\|Download|!d;s|.*href="\(.*\)".*|\1|g' ` \
    && curl -o sonarphp.jar -fSL ${SONARPHP_DISTRIBUTABLE} \
    && curl -o sonarweb.jar -fSL ${SONARWEB_DISTRIBUTABLE} \
    && mv ` command ls -1 *.jar */ | grep sonar` extensions/plugins

RUN /usr/bin/fix-permissions ./extensions/plugins 
