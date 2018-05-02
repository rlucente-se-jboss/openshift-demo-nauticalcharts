FROM jboss/base-jdk:8

MAINTAINER Michael Epley <mepley@redhat.com>

ENV SONAR_VERSION=6.7 SONARSCANNER_HOME=/opt/sonar-scanner

USER root
EXPOSE 9000
ADD root /

RUN set -x \
    && useradd -r sonar \
    && SONAR_SCANNER_DISTRIBUTABLE=`curl -s -L https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner | sed '\|Linux 64 bit|!d;s|.*href="\(.*\)".*|\1|g' ` \

    # pub   2048R/D26468DE 2015-05-25
    #       Key fingerprint = F118 2E81 C792 9289 21DB  CAB4 CFCA 4A29 D264 68DE
    # uid                  sonarsource_deployer (Sonarsource Deployer) <infra@sonarsource.com>
    # sub   2048R/06855C1D 2015-05-25
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE \

    && cd /opt \
    && curl -o sonar-scanner.zip -fSL ${SONAR_SCANNER_DISTRIBUTABLE} \
    && curl -o sonar-scanner.zip.asc -fSL ${SONAR_SCANNER_DISTRIBUTABLE}.asc \
    && gpg --batch --verify sonar-scanner.zip.asc sonar-scanner.zip \
    && unzip sonar-scanner.zip \
    && mv ` command ls -1 -d */ | grep sonar` sonar-scanner \
    && rm sonar-scanner.zip*

WORKDIR $SONARSCANNER_HOME
COPY run.sh $SONARSCANNER_HOME/bin/

RUN /usr/bin/fix-permissions $SONARSCANNER_HOME \
    && chmod 775 $SONARSCANNER_HOME/bin/run.sh

USER sonar
ENTRYPOINT ["./bin/run.sh"]