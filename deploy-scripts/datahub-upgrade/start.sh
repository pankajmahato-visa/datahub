#!/bin/bash

# Export all Environment Variables
set -o allexport
if [ -f ../../env/datahub-upgrade.env ] ; then
  source ../../env/datahub-upgrade.env
else
  source env/datahub-upgrade.env
fi
[ -f ../../env/datahub-upgrade-creds.env ] && source ../../env/datahub-upgrade.env
set +o allexport

java -jar datahub-upgrade.jar
