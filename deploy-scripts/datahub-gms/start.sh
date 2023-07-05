#!/bin/bash

touch env/datahub-gms-creds.env
mkdir -p logs/gms/

if [[ $ELASTICSEARCH_USE_SSL == true ]]; then
  ELASTICSEARCH_PROTOCOL=https
else
  ELASTICSEARCH_PROTOCOL=http
fi

OTEL_AGENT=""
if [[ $ENABLE_OTEL == true ]]; then
  OTEL_AGENT="-javaagent:opentelemetry-javaagent.jar "
fi

PROMETHEUS_AGENT=""
if [[ $ENABLE_PROMETHEUS == true ]]; then
  PROMETHEUS_AGENT="-javaagent:jmx_prometheus_javaagent.jar=4318:/datahub/datahub-gms/scripts/prometheus-config.yaml "
fi

# Export all Environment Variables
set -o allexport
source env/datahub-gms.env
source env/datahub-gms-creds.env
set +o allexport

java $JAVA_OPTS \
    $OTEL_AGENT \
    $PROMETHEUS_AGENT \
    -jar jetty-runner.jar \
    --jar jetty-util.jar \
    --jar jetty-jmx.jar \
    --config jetty.xml \
    war.war
