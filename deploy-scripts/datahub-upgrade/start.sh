#!/bin/bash

# Export all Environment Variables
set -o allexport
source env/datahub-upgrade.env
source env/datahub-upgrade-creds.env
set +o allexport

java -jar datahub-upgrade.jar
