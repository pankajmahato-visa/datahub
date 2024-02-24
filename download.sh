#!/bin/bash
curl -sS --netrc-file <(cat <<<"machine artifactory.trusted.visa.com login $PIPER_CUSTOM_USER password $PIPER_CUSTOM_PASSWORD") https://artifactory.trusted.visa.com:443/central-cache/org/eclipse/jetty/jetty-runner/9.4.53.v20231009/jetty-runner-9.4.53.v20231009.jar --output datahub-artifact/datahub-gms/jetty-runner.jar
curl -sS --netrc-file <(cat <<<"machine artifactory.trusted.visa.com login $PIPER_CUSTOM_USER password $PIPER_CUSTOM_PASSWORD") https://artifactory.trusted.visa.com:443/atlassian-release-cache/org/eclipse/jetty/jetty-jmx/9.4.53.v20231009/jetty-jmx-9.4.53.v20231009.jar --output datahub-artifact/datahub-gms/jetty-jmx.jar
curl -sS --netrc-file <(cat <<<"machine artifactory.trusted.visa.com login $PIPER_CUSTOM_USER password $PIPER_CUSTOM_PASSWORD") https://artifactory.trusted.visa.com:443/central-cache/org/eclipse/jetty/jetty-util/9.4.53.v20231009/jetty-util-9.4.53.v20231009.jar --output datahub-artifact/datahub-gms/jetty-util.jar

