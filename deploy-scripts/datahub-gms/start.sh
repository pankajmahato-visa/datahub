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
if [ -f ../../env/datahub-gms.env ] ; then
  source ../../env/datahub-gms.env
else
  source env/datahub-gms.env
fi
[ -f ../../env/datahub-gms-creds.env ] && source ../../env/datahub-gms-creds.env
set +o allexport

[  -z "$GMS_HEAP_OPTS" ] && export GMS_HEAP_OPTS="-Xms1g -Xmx4g"

[  -z "$GMS_JAAS_CONF" ] && export GMS_JAAS_CONF="-Djava.security.auth.login.config=conf/jaas.conf"

export GMS_INTERNAL_JAVA_OPTS="${GMS_HEAP_OPTS} \
  ${GMS_JAAS_CONF} \
  -Djavax.net.ssl.keyStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.trustStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD} \
  -Djavax.net.ssl.trustStorePassword=${KEYSTORE_PASSWORD} \
  ${GMS_JAVA_OPTS}"

echo $GMS_INTERNAL_JAVA_OPTS

exec java $GMS_INTERNAL_JAVA_OPTS \
    $OTEL_AGENT \
    $PROMETHEUS_AGENT \
    -jar jetty-runner.jar \
    --jar jetty-util.jar \
    --jar jetty-jmx.jar \
    --config jetty.xml \
    war.war
