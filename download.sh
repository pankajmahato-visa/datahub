#!/bin/bash
curl -sS --netrc-file <(cat <<<"machine artifactory.trusted.visa.com login $PIPER_CUSTOM_USER password $PIPER_CUSTOM_PASSWORD") https://artifactory.trusted.visa.com/central/org/eclipse/jetty/jetty-runner/11.0.19/jetty-runner-11.0.19.jar --output datahub-artifact/datahub-gms/jetty-runner.jar
curl -sS --netrc-file <(cat <<<"machine artifactory.trusted.visa.com login $PIPER_CUSTOM_USER password $PIPER_CUSTOM_PASSWORD") https://artifactory.trusted.visa.com/central/org/eclipse/jetty/jetty-jmx/11.0.19/jetty-jmx-11.0.19.jar --output datahub-artifact/datahub-gms/jetty-jmx.jar
curl -sS --netrc-file <(cat <<<"machine artifactory.trusted.visa.com login $PIPER_CUSTOM_USER password $PIPER_CUSTOM_PASSWORD") https://artifactory.trusted.visa.com/central/org/eclipse/jetty/jetty-util/11.0.19/jetty-util-11.0.19.jar --output datahub-artifact/datahub-gms/jetty-util.jar

