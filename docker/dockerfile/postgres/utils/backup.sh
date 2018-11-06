#!/usr/bin/env bash

DATE=$(date +"%Y-%m-%d-%H-%M-%S")

pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} > /backup/${DATE}.sql

zip /backup/${DATE}.sql.zip /backup/${DATE}.sql

if [ ${APP_ENV} == "prod" ];
then
    /utils/supload.sh -u ${SS_USER} -k ${SS_PWD} ${SS_CONTAINER} /backup/${DATE}.sql.zip
fi

rm /backup/${DATE}.sql

exit 0