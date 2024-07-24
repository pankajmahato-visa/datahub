#!/bin/sh

# Run the script using below command
# nohup sh start.sh > /dev/null 2> datahub-frontend.log < /dev/null & echo $! > datahub-frontend.pid

# Export all Environment Variables
set -o allexport
if [ -f ../../env/datahub-frontend.env ] ; then
  source ../../env/datahub-frontend.env
else
  source env/datahub-frontend.env
fi
[ -f ../../env/datahub-frontend-creds.env ] && source ../../env/datahub-frontend-creds.env
set +o allexport

if [[ ! -z ${DEFAULT_DATAHUB_CREDENTIALS:-} ]]; then
  printf '%s' "${DEFAULT_DATAHUB_CREDENTIALS}" > datahub-frontend/conf/user.props
fi

PROMETHEUS_AGENT=""
if [[ ${ENABLE_PROMETHEUS:-false} == true ]]; then
  PROMETHEUS_AGENT="-javaagent:/datahub/monitoring/jmx_prometheus_javaagent.jar=4319:/datahub/monitoring/conf/prometheus-config.yaml"
fi

OTEL_AGENT=""
if [[ ${ENABLE_OTEL:-false} == true ]]; then
  OTEL_AGENT="-javaagent:/datahub/monitoring/opentelemetry-javaagent.jar"
fi

TRUSTSTORE_FILE=""
if [[ ! -z ${SSL_TRUSTSTORE_FILE:-} ]]; then
  TRUSTSTORE_FILE="-Djavax.net.ssl.trustStore=$SSL_TRUSTSTORE_FILE"
fi

TRUSTSTORE_TYPE=""
if [[ ! -z ${SSL_TRUSTSTORE_TYPE:-} ]]; then
  TRUSTSTORE_TYPE="-Djavax.net.ssl.trustStoreType=$SSL_TRUSTSTORE_TYPE"
fi

TRUSTSTORE_PASSWORD=""
if [[ ! -z ${SSL_TRUSTSTORE_PASSWORD:-} ]]; then
  TRUSTSTORE_PASSWORD="-Djavax.net.ssl.trustStorePassword=$SSL_TRUSTSTORE_PASSWORD"
fi

[  -z "$DATAHUB_FRONTEND_HEAP_OPTS" ] && export DATAHUB_FRONTEND_HEAP_OPTS="-Xms1g -Xmx2g"

export DATAHUB_FRONTEND_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED \
  ${DATAHUB_FRONTEND_HEAP_OPTS} \
  -Dhttp.port=$SERVER_PORT \
  -Dconfig.file=datahub-frontend/conf/application.conf \
  -Djava.security.auth.login.config=/datahub/env/datahub-frontend-jaas.conf \
  -Dlogback.configurationFile=datahub-frontend/conf/logback.xml \
  ${PROMETHEUS_AGENT:-} ${OTEL_AGENT:-} \
  ${TRUSTSTORE_FILE:-} ${TRUSTSTORE_TYPE:-} ${TRUSTSTORE_PASSWORD:-} \
  ${DATAHUB_FRONTEND_REMOTE_DEBUG:-} \
  -Dpidfile.path=/dev/null"

echo $DATAHUB_FRONTEND_OPTS

exec ./datahub-frontend/bin/datahub-frontend
