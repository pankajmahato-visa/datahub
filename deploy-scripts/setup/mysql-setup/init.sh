#!/bin/bash

: ${MYSQL_PORT:=3306}

# Export all Environment Variables
set -o allexport
source env/mysql-setup.env
source env/mysql-setup-creds.env
set +o allexport

sed -e "s/DATAHUB_DB_NAME/${DATAHUB_DB_NAME}/g" init.sql | tee -a /tmp/init-final.sql
mysql -u $MYSQL_USERNAME -p"$MYSQL_PASSWORD" -h $MYSQL_HOST -P $MYSQL_PORT < /tmp/init-final.sql
