#!/bin/bash

# Export all Environment Variables
set -o allexport
if [ -f ../../env/datahub-upgrade.env ] ; then
  source ../../env/datahub-upgrade.env
else
  source env/datahub-upgrade.env
fi
[ -f ../../env/datahub-upgrade-creds.env ] && source ../../env/datahub-upgrade-creds.env
set +o allexport

TRUSTSTORE_FILE=""
if [[ ! -z ${KEYSTORE_FILE:-} ]]; then
  TRUSTSTORE_FILE="-Djavax.net.ssl.trustStore=$KEYSTORE_FILE"
fi

TRUSTSTORE_PASSWORD=""
if [[ ! -z ${KEYSTORE_PASSWORD:-} ]]; then
  TRUSTSTORE_PASSWORD="-Djavax.net.ssl.trustStorePassword=$KEYSTORE_PASSWORD"
fi

[  -z "$GMS_HEAP_OPTS" ] && export GMS_HEAP_OPTS="-Xms1g -Xmx4g"

export UPGRADE_INTERNAL_JAVA_OPTS="${GMS_HEAP_OPTS} \
  ${TRUSTSTORE_FILE:-} ${TRUSTSTORE_PASSWORD:-} \
  ${GMS_REMOTE_DEBUG:-}"

echo $GMS_INTERNAL_JAVA_OPTS

exec java $UPGRADE_INTERNAL_JAVA_OPTS \
    ${GMS_REMOTE_DEBUG:-} \
    -jar datahub-upgrade.jar \
    -u SystemUpdate