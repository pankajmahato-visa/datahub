#!/bin/bash

# Run the script using below command
# nohup sh start.sh > /dev/null 2> datahub-mae-consumer.log < /dev/null & echo $! > datahub-mae-consumer.pid

# Export all Environment Variables
set -o allexport
if [ -f ../../env/datahub-mae-consumer.env ] ; then
  source ../../env/datahub-mae-consumer.env
else
  source env/datahub-mae-consumer.env
fi
[ -f ../../env/datahub-mae-consumer-creds.env ] && source ../../env/datahub-mae-consumer-creds.env
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
  PROMETHEUS_AGENT="-javaagent:/datahub/monitoring/jmx_prometheus_javaagent.jar=4317:/datahub/monitoring/conf/prometheus-config.yaml "
fi

[  -z "$MAE_HEAP_OPTS" ] && export MAE_HEAP_OPTS="-Xms1g -Xmx4g"

[  -z "$MAE_JAAS_CONF" ] && export MAE_JAAS_CONF="-Djava.security.auth.login.config=conf/jaas.conf"

export MAE_INTERNAL_JAVA_OPTS="${MAE_HEAP_OPTS} \
  ${MAE_JAAS_CONF} \
  -Djavax.net.ssl.keyStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.trustStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD} \
  -Djavax.net.ssl.trustStorePassword=${KEYSTORE_PASSWORD} \
  ${MAE_REMOTE_DEBUG:-} \
  ${MAE_JAVA_OPTS}"

echo $MAE_INTERNAL_JAVA_OPTS

exec java $MAE_INTERNAL_JAVA_OPTS \
    $OTEL_AGENT \
    $PROMETHEUS_AGENT \
    -jar mae-consumer-job.jar
