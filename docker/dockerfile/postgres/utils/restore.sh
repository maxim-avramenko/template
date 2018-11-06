#!/usr/bin/env bash

#set -xv

# Если вторым параметром передали название дампа то пытаемся накатить его, иначе последний имеющийся
if [ ! -z "$1" ]; then
    DUMP_NAME="$1"
else
    DUMPS=(`swift -A $SS_URL -U $SS_USER -K $SS_PWD list $SS_CONTAINER`)
    DUMP_NAME=${DUMPS[@]:(-1)}
fi

echo "Trying to restore the postgresql ${DUMP_NAME} to database ${POSTGRES_DB}"

if [ ! -f /backup/${DUMP_NAME} ];
then
    swift download --info -A ${SS_URL} -U ${SS_USER} -K ${SS_PWD} ${SS_CONTAINER} /${DUMP_NAME} --output /backup/${DUMP_NAME}
fi
unzip /backup/${DUMP_NAME}

DUMP_NAME=`echo "${DUMP_NAME}" | sed 's/.zip//'`

dropdb ${POSTGRES_DB}
psql postgres -c "CREATE DATABASE ${POSTGRES_DB} WITH ENCODING 'UTF8'  TEMPLATE template0"
psql --host=localhost --username=root --dbname=${POSTGRES_DB} --file=/backup/${DUMP_NAME}

rm /backup/${DUMP_NAME}

exit 0