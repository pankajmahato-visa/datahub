#!/bin/bash

# Run the script using below command
# nohup sh start.sh > /dev/null 2> datahub-mce-consumer.log < /dev/null & echo $! > datahub-mce-consumer.pid

# Export all Environment Variables
set -o allexport
if [ -f ../../env/datahub-mce-consumer.env ] ; then
  source ../../env/datahub-mce-consumer.env
else
  source env/datahub-mce-consumer.env
fi
[ -f ../../env/datahub-mce-consumer-creds.env ] && source ../../env/datahub-mce-consumer-creds.env
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
  PROMETHEUS_AGENT="-javaagent:/datahub/monitoring/jmx_prometheus_javaagent.jar=4316:/datahub/monitoring/conf/prometheus-config.yaml "
fi

[  -z "$MCE_HEAP_OPTS" ] && export MCE_HEAP_OPTS="-Xms1g -Xmx4g"

[  -z "$MCE_JAAS_CONF" ] && export MCE_JAAS_CONF="-Djava.security.auth.login.config=conf/jaas.conf"

export MCE_INTERNAL_JAVA_OPTS="${MCE_HEAP_OPTS} \
  ${MCE_JAAS_CONF} \
  -Djavax.net.ssl.keyStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.trustStore=${KEYSTORE_FILE} \
  -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD} \
  -Djavax.net.ssl.trustStorePassword=${KEYSTORE_PASSWORD} \
  ${MCE_REMOTE_DEBUG:-} \
  ${MCE_JAVA_OPTS}"

echo $MCE_INTERNAL_JAVA_OPTS

exec java $MCE_INTERNAL_JAVA_OPTS \
    $OTEL_AGENT \
    $PROMETHEUS_AGENT \
    -jar mce-consumer-job.jar
