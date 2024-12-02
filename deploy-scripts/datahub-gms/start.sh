#!/bin/bash

# Run the script using below command
# nohup sh start.sh > /dev/null 2> datahub-gms.log < /dev/null & echo $! > datahub-gms.pid

# Export all Environment Variables
set -o allexport
if [ -f ../../env/datahub-gms.env ] ; then
  source ../../env/datahub-gms.env
else
  source env/datahub-gms.env
fi
[ -f ../../env/datahub-gms-creds.env ] && source ../../env/datahub-gms-creds.env
set +o allexport

if [[ $ELASTICSEARCH_USE_SSL == true ]]; then
  ELASTICSEARCH_PROTOCOL=https
else
  ELASTICSEARCH_PROTOCOL=http
fi

OTEL_AGENT=""
if [[ $ENABLE_OTEL == true ]]; then
  OTEL_AGENT="-javaagent:/datahub/monitoring/opentelemetry-javaagent.jar"
fi

PROMETHEUS_AGENT=""
if [[ $ENABLE_PROMETHEUS == true ]]; then
  PROMETHEUS_AGENT="-javaagent:/datahub/monitoring/jmx_prometheus_javaagent.jar=4318:/datahub/monitoring/conf/prometheus-config.yaml "
fi

[  -z "$GMS_HEAP_OPTS" ] && export GMS_HEAP_OPTS="-Xms1g -Xmx4g"

[  -z "$GMS_JAAS_CONF" ] && export GMS_JAAS_CONF="-Djava.security.auth.login.config=conf/jaas.conf"

export GMS_INTERNAL_JAVA_OPTS="${GMS_HEAP_OPTS} \
  ${GMS_JAAS_CONF} \
  -Djavax.net.ssl.keyStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.trustStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD} \
  -Djavax.net.ssl.trustStorePassword=${KEYSTORE_PASSWORD} \
  ${GMS_REMOTE_DEBUG:-} \
  ${GMS_JAVA_OPTS}"

echo $GMS_INTERNAL_JAVA_OPTS

exec java $GMS_INTERNAL_JAVA_OPTS \
    $OTEL_AGENT \
    $PROMETHEUS_AGENT \
    -jar jetty-runner.jar \
    --jar jetty-util.jar \
    --jar jetty-jmx.jar \
    --config jetty.xml \
    --config jetty-jmx.xml \
    war.war
